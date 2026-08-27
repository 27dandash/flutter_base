import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:uuid/uuid.dart';

import '../dio_client.dart';
import '../network_info.dart';
import '../../shared/helpers/cache_service.dart';
import 'queued_operation.dart';
import 'offline_queue_cipher.dart';

enum SyncStatus { idle, syncing }

/// Persists Add/Update/Delete operations that the user triggers while
/// offline and replays them in FIFO order once the network comes back.
class OfflineQueueManager {
  OfflineQueueManager._();
  static final OfflineQueueManager _instance = OfflineQueueManager._();
  factory OfflineQueueManager() => _instance;

  static const String _boxName = 'offline_queue_gcm_v2';
  static const String _legacyBoxName = 'offline_queue';
  static const String _encryptionKeyName = 'offline_queue_aes_key';
  static const int _maxRetries = 5;

  /// Body/header keys that must never be written to disk in a queued op.
  /// Auth headers are re-attached by the AuthInterceptor at replay time, so
  /// dropping them here is safe and keeps secrets out of the Hive box.
  static const Set<String> _sensitiveKeys = {
    'password',
    'password_confirmation',
    'current_password',
    'new_password',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'api_key',
    'secret',
    'otp',
    'pin',
    'cvv',
    'card_number',
  };

  late final Box<String> _box;
  late final OfflineQueueCipher _cipher;
  bool _initialized = false;
  final _uuid = const Uuid();
  final NetworkInfo _network = NetworkInfo();
  final Dio _dio = DioClient().dio;

  final StreamController<int> _pendingController =
      StreamController<int>.broadcast();
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  /// Optional callback invoked when an operation is dropped permanently
  /// (4xx or retry exhausted). Wire to your local DB if you keep optimistic
  /// records that need to be marked as failed.
  void Function(QueuedOperation op, Object? error)? onOperationFailed;

  /// Optional callback invoked when an operation succeeds. Receives the
  /// server response so you can sync the local record (e.g. assign the
  /// server id to a row keyed by `localId`).
  void Function(QueuedOperation op, Response response)? onOperationSucceeded;

  bool _processing = false;
  StreamSubscription<bool>? _netSub;
  String? _activeOwnerScope;

  /// Called when an authenticated queue record is corrupted or truncated.
  /// The record is removed and never replayed.
  void Function(Object error)? onQueueCorruption;

  Stream<int> get pendingStream => _pendingController.stream;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Safe to read while optional persistence is still starting. The stream
  /// publishes the real value immediately after [init] completes.
  int get pendingCount => _initialized ? _box.length : 0;

  Future<void> init({
    List<int>? encryptionKey,
    String? legacyOwnerScope,
  }) async {
    if (_initialized) return;
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(QueuedOperationAdapter());
    }
    final key = encryptionKey ?? await _loadOrCreateEncryptionKey();
    if (key.length != 32) {
      throw StateError('Offline queue encryption key must contain 32 bytes.');
    }
    _cipher = OfflineQueueCipher(key);
    _box = await Hive.openBox<String>(_boxName);
    await _migrateLegacyQueue(key, legacyOwnerScope: legacyOwnerScope);
    _initialized = true;
    _pendingController.add(_box.length);

    _netSub = _network.onStatusChange.listen((online) {
      if (online) _processQueue();
    });

    // App-start sync (the queue itself re-verifies real reachability).
    if (_box.isNotEmpty && await _network.isReallyOnline()) {
      unawaited(_processQueue());
    }
  }

  void activateOwnerScope(String? ownerScope) {
    final normalized = ownerScope?.trim();
    _activeOwnerScope = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    if (_activeOwnerScope != null && _initialized && _network.isOnline) {
      unawaited(_processQueue());
    }
  }

  Future<List<int>> _loadOrCreateEncryptionKey() async {
    final encoded = await SecureStorage.read(_encryptionKeyName);
    if (encoded != null) {
      final key = base64Url.decode(encoded);
      if (key.length != 32) {
        throw StateError('Stored offline queue encryption key is invalid.');
      }
      return key;
    }

    final key = Hive.generateSecureKey();
    await SecureStorage.write(_encryptionKeyName, base64UrlEncode(key));
    return key;
  }

  Future<void> _migrateLegacyQueue(
    List<int> key, {
    required String? legacyOwnerScope,
  }) async {
    if (!await Hive.boxExists(_legacyBoxName)) return;
    final scope = legacyOwnerScope?.trim();
    if (scope == null || scope.isEmpty) {
      // Old records have no user ownership metadata. Replaying them under a
      // guessed account is unsafe, so fail closed and remove them.
      await Hive.deleteBoxFromDisk(_legacyBoxName);
      return;
    }
    final legacy = await Hive.openBox<QueuedOperation>(
      _legacyBoxName,
      encryptionCipher: HiveAesCipher(key),
    );
    try {
      for (final operation in legacy.values) {
        final migrated = QueuedOperation(
          id: operation.id,
          endpoint: operation.endpoint,
          method: operation.method,
          body: operation.body,
          headers: operation.headers,
          createdAt: operation.createdAt,
          retryCount: operation.retryCount,
          localId: operation.localId,
          ownerScope: scope,
        );
        await _writeOperation(migrated);
      }
    } finally {
      await legacy.close();
      await Hive.deleteBoxFromDisk(_legacyBoxName);
    }
  }

  /// Drops queued writes at a session boundary so they can never be replayed
  /// with another user's credentials.
  Future<void> clearPending() async {
    if (!_initialized) return;
    await _box.clear();
    _pendingController.add(0);
  }

  Future<QueuedOperation> enqueue({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
    String? localId,
    required String ownerScope,
  }) async {
    if (!_initialized) {
      throw StateError('Offline queue is unavailable before initialization.');
    }
    if (ownerScope.trim().isEmpty) {
      throw ArgumentError.value(ownerScope, 'ownerScope', 'must not be empty');
    }
    final op = QueuedOperation(
      id: _uuid.v4(),
      endpoint: endpoint,
      method: method.toUpperCase(),
      body: _stripSensitive(body),
      headers: _stripSensitive(headers),
      createdAt: DateTime.now(),
      retryCount: 0,
      localId: localId,
      ownerScope: ownerScope,
    );
    await _writeOperation(op);
    _pendingController.add(_box.length);

    // Try immediately if online.
    if (_network.isOnline) unawaited(_processQueue());
    return op;
  }

  /// Recursively removes [_sensitiveKeys] (case-insensitively) from a map
  /// before it is persisted to the Hive box.
  Map<String, dynamic>? _stripSensitive(Map<String, dynamic>? input) {
    if (input == null) return null;
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      if (_sensitiveKeys.contains(key.toLowerCase())) return;
      out[key] = _sanitizeValue(value);
    });
    return out;
  }

  Object? _sanitizeValue(Object? value) {
    if (value is Map) {
      return _stripSensitive(value.cast<String, dynamic>());
    }
    if (value is List) return value.map(_sanitizeValue).toList();
    return value;
  }

  Future<void> _processQueue() async {
    final activeOwnerScope = _activeOwnerScope;
    if (_processing || _box.isEmpty || activeOwnerScope == null) return;

    // connectivity_plus can report "online" behind a captive portal / dead
    // router. Probe real reachability before burning retries on requests
    // that are guaranteed to fail.
    if (!await _network.isReallyOnline()) return;

    _processing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      // FIFO order by createdAt.
      final ops = await _readOperations(activeOwnerScope)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final op in ops) {
        if (!_network.isOnline) break;
        await _runOne(op);
      }
    } finally {
      _processing = false;
      _statusController.add(SyncStatus.idle);
      _pendingController.add(_box.length);
    }
  }

  Future<void> _runOne(QueuedOperation op) async {
    // Stable idempotency key for THIS op, reused across every retry, so a reply
    // lost after the server already committed cannot create a duplicate
    // (double charge / double sign-up). op.id is a v4 UUID set at enqueue time;
    // a server that honours Idempotency-Key collapses the retried write.
    final headers = <String, dynamic>{...?op.headers, 'Idempotency-Key': op.id};
    try {
      final res = await _dio.request<dynamic>(
        op.endpoint,
        data: op.body,
        options: Options(method: op.method, headers: headers),
      );

      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        await _box.delete(op.id);
        onOperationSucceeded?.call(op, res);
        return;
      }

      // 4xx = hard fail, drop.
      if (code >= 400 && code < 500) {
        await _box.delete(op.id);
        onOperationFailed?.call(op, 'status:$code');
        return;
      }

      // 5xx → retry.
      await _bumpRetry(op);
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code >= 400 && code < 500) {
        await _box.delete(op.id);
        onOperationFailed?.call(op, e);
        return;
      }
      await _bumpRetry(op, error: e);
    } catch (e) {
      await _bumpRetry(op, error: e);
    }
  }

  Future<void> _bumpRetry(QueuedOperation op, {Object? error}) async {
    op.retryCount += 1;
    if (op.retryCount >= _maxRetries) {
      await _box.delete(op.id);
      onOperationFailed?.call(op, error);
      return;
    }
    await _writeOperation(op);
  }

  Future<void> _writeOperation(QueuedOperation operation) async {
    final encrypted = await _cipher.encrypt(
      operation.toJson(),
      ownerScope: operation.ownerScope,
    );
    await _box.put(operation.id, encrypted);
  }

  Future<List<QueuedOperation>> _readOperations(String ownerScope) async {
    final operations = <QueuedOperation>[];
    for (final entry in _box.toMap().entries) {
      try {
        if (_cipher.ownerScopeOf(entry.value) != ownerScope) continue;
        final value = await _cipher.decrypt(entry.value);
        final operation = QueuedOperation.fromJson(value);
        if (operation.ownerScope == ownerScope) operations.add(operation);
      } catch (error) {
        await _box.delete(entry.key);
        onQueueCorruption?.call(error);
      }
    }
    return operations;
  }

  @visibleForTesting
  Future<void> clearAll() async {
    await _box.clear();
    _pendingController.add(0);
  }

  Future<void> dispose() async {
    await _netSub?.cancel();
    await _pendingController.close();
    await _statusController.close();
  }
}
