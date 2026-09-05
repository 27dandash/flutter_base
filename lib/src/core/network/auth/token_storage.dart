import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../shared/helpers/cache_service.dart';

/// Persistence boundary used by [TokenStorage].
///
/// Production delegates to encrypted platform storage. The boundary exists so
/// storage failures and concurrency can be verified without a device Keychain.
abstract interface class TokenStorageBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> deleteAll(Iterable<String> keys);
}

final class _SecureTokenStorageBackend implements TokenStorageBackend {
  const _SecureTokenStorageBackend();

  @override
  Future<String?> read(String key) => SecureStorage.read(key);

  @override
  Future<void> write(String key, String value) =>
      SecureStorage.write(key, value);

  @override
  Future<void> deleteAll(Iterable<String> keys) =>
      SecureStorage.deleteAllKeys(keys);
}

/// Source of truth for the user's access + refresh tokens.
///
/// Tokens are stored as one versioned encrypted record so an access/refresh
/// pair cannot be observed half-written. Legacy two-key records are migrated
/// during [init]. Mutations are serialized and every authenticated session has
/// a monotonically increasing [sessionGeneration]. Network work captures that
/// generation and must not publish results after logout or account switching.
class TokenStorage {
  TokenStorage._({TokenStorageBackend? backend})
    : _backend = backend ?? const _SecureTokenStorageBackend();

  static const String _pairKey = 'auth_token_pair_v2';
  static const String _legacyAccessKey = 'auth_access_token';
  static const String _legacyRefreshKey = 'auth_refresh_token';

  /// The single production instance. DI registration must return this object.
  static final TokenStorage instance = TokenStorage._();

  /// Creates an isolated store for deterministic persistence-failure tests.
  @visibleForTesting
  factory TokenStorage.forTesting(TokenStorageBackend backend) =>
      TokenStorage._(backend: backend);

  final TokenStorageBackend _backend;
  String? _accessToken;
  String? _refreshToken;
  bool _hydrated = false;
  int _sessionGeneration = 0;
  Future<void> _mutationTail = Future<void>.value();

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  int get sessionGeneration => _sessionGeneration;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  bool isCurrentGeneration(int generation) => generation == _sessionGeneration;

  /// Hydrates the in-memory cache once and migrates legacy two-key storage.
  Future<void> init() {
    if (_hydrated) return Future<void>.value();
    final requestedGeneration = _sessionGeneration;
    return _serialize(() async {
      if (_hydrated || requestedGeneration != _sessionGeneration) return;

      final encoded = await _backend.read(_pairKey);
      if (requestedGeneration != _sessionGeneration) return;

      if (encoded != null) {
        (String?, String?) pair;
        try {
          pair = _decodePair(encoded);
        } on FormatException {
          // A malformed encrypted value must not poison every future startup.
          // Replace it with an authoritative empty record rather than falling
          // back to legacy keys, which could resurrect older credentials.
          pair = (null, null);
          await _backend.write(_pairKey, _encodePair(null, null));
          await _backend.deleteAll(const [_legacyAccessKey, _legacyRefreshKey]);
        }
        if (requestedGeneration != _sessionGeneration) return;
        _accessToken = pair.$1;
        _refreshToken = pair.$2;
        _hydrated = true;
        return;
      }

      final access = await _backend.read(_legacyAccessKey);
      final refresh = await _backend.read(_legacyRefreshKey);
      if (requestedGeneration != _sessionGeneration) return;

      // Persist even an empty pair. It is an authoritative tombstone that
      // prevents a partially deleted legacy record from being resurrected.
      await _backend.write(_pairKey, _encodePair(access, refresh));
      await _backend.deleteAll(const [_legacyAccessKey, _legacyRefreshKey]);
      if (requestedGeneration != _sessionGeneration) return;

      _accessToken = access;
      _refreshToken = refresh;
      _hydrated = true;
    });
  }

  /// Starts a new authenticated session and persists its token pair.
  ///
  /// Memory changes only after the single encrypted record is written. A
  /// later logout/account switch invalidates this write immediately through
  /// [sessionGeneration], even if platform storage completes out of order.
  Future<void> save({required String access, String? refresh}) {
    // A new session must never inherit the preceding account's refresh token.
    // Same-session rotations use [saveIfCurrent], which intentionally retains
    // the current refresh token when the backend omits a replacement.
    final retainedRefresh = refresh;
    final generation = ++_sessionGeneration;
    // Fail closed while the new session is being committed. If the platform
    // write fails, callers see the error and no previous account token remains
    // usable in memory under the new generation.
    _accessToken = null;
    _refreshToken = null;
    _hydrated = true;
    return _serialize(() async {
      await _backend.write(_pairKey, _encodePair(access, retainedRefresh));
      await _backend.deleteAll(const [_legacyAccessKey, _legacyRefreshKey]);
      if (!isCurrentGeneration(generation)) return;
      _accessToken = access;
      _refreshToken = retainedRefresh;
      _hydrated = true;
    });
  }

  /// Rotates tokens only if [expectedGeneration] still owns the session.
  ///
  /// A delayed refresh from an old account therefore cannot overwrite the
  /// credentials of a newer account.
  Future<bool> saveIfCurrent({
    required int expectedGeneration,
    required String access,
    String? refresh,
  }) {
    if (!isCurrentGeneration(expectedGeneration)) {
      return Future<bool>.value(false);
    }
    return _serialize(() async {
      if (!isCurrentGeneration(expectedGeneration)) return false;
      final retainedRefresh = refresh ?? _refreshToken;
      await _backend.write(_pairKey, _encodePair(access, retainedRefresh));
      if (!isCurrentGeneration(expectedGeneration)) return false;
      _accessToken = access;
      _refreshToken = retainedRefresh;
      _hydrated = true;
      return true;
    });
  }

  /// Invalidates the current session synchronously, then persists a tombstone.
  ///
  /// Residual durability limitation: the in-memory session is always
  /// invalidated up front (fail-closed — no request can present the old token
  /// and the generation is bumped so a delayed write cannot resurrect it), but
  /// the returned future rejects if the OS secure store refuses the tombstone
  /// write. We deliberately do not fall back to an insecure store, so a total
  /// secure-storage outage means the tombstone may not reach disk and a prior
  /// token could still be present on the next launch. Callers surface this as a
  /// cleanup failure rather than silently masking it.
  Future<void> clear() {
    _beginClear();
    return _persistClear();
  }

  /// Clears only when [expectedGeneration] still owns the session.
  ///
  /// Shares the [clear] durability semantics: on success the in-memory session
  /// is invalidated regardless of whether the durable tombstone write lands.
  Future<bool> clearIfCurrent(int expectedGeneration) {
    if (!isCurrentGeneration(expectedGeneration)) {
      return Future<bool>.value(false);
    }
    _beginClear();
    return _persistClear().then((_) => true);
  }

  void _beginClear() {
    _sessionGeneration++;
    _accessToken = null;
    _refreshToken = null;
    _hydrated = true;
  }

  Future<void> _persistClear() => _serialize(() async {
    await _backend.write(_pairKey, _encodePair(null, null));
    await _backend.deleteAll(const [_legacyAccessKey, _legacyRefreshKey]);
  });

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static String _encodePair(String? access, String? refresh) =>
      jsonEncode({'version': 2, 'access': access, 'refresh': refresh});

  static (String?, String?) _decodePair(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map || decoded['version'] != 2) {
      throw const FormatException('Invalid persisted token pair.');
    }
    final access = decoded['access'];
    final refresh = decoded['refresh'];
    if ((access != null && access is! String) ||
        (refresh != null && refresh is! String)) {
      throw const FormatException('Invalid persisted token values.');
    }
    return (access as String?, refresh as String?);
  }
}
