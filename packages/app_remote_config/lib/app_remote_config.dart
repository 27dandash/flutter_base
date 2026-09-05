// The public `backend` constructor parameter is retained for API compatibility.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

typedef FirebaseInitializer = Future<void> Function(FirebaseOptions? options);

abstract interface class RemoteConfigBackend {
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  });

  Future<bool> fetchAndActivate();
  String getString(String key);
}

/// Richer optional contract. Existing lightweight backends remain compatible
/// with [RemoteConfigBackend].
abstract interface class AdvancedRemoteConfigBackend
    implements RemoteConfigBackend {
  Future<void> setDefaults(Map<String, Object> defaults);
  Future<void> fetch();
  Future<bool> activate();
  bool getBool(String key);
  int getInt(String key);
  double getDouble(String key);
}

final class FirebaseRemoteConfigBackend implements AdvancedRemoteConfigBackend {
  FirebaseRemoteConfigBackend(this.remoteConfig);

  final FirebaseRemoteConfig remoteConfig;

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) => remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: fetchTimeout,
      minimumFetchInterval: minimumFetchInterval,
    ),
  );

  @override
  Future<void> setDefaults(Map<String, Object> defaults) =>
      remoteConfig.setDefaults(defaults);
  @override
  Future<void> fetch() => remoteConfig.fetch();
  @override
  Future<bool> activate() => remoteConfig.activate();
  @override
  Future<bool> fetchAndActivate() => remoteConfig.fetchAndActivate();
  @override
  String getString(String key) => remoteConfig.getString(key);
  @override
  bool getBool(String key) => remoteConfig.getBool(key);
  @override
  int getInt(String key) => remoteConfig.getInt(key);
  @override
  double getDouble(String key) => remoteConfig.getDouble(key);
}

enum RemoteConfigEnvironment { development, staging, production }

final class RemoteConfigPolicy {
  const RemoteConfigPolicy({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
    this.operationTimeout,
  });

  factory RemoteConfigPolicy.forEnvironment(RemoteConfigEnvironment value) =>
      switch (value) {
        RemoteConfigEnvironment.development => const RemoteConfigPolicy(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
        RemoteConfigEnvironment.staging => const RemoteConfigPolicy(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration(minutes: 15),
        ),
        RemoteConfigEnvironment.production => const RemoteConfigPolicy(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration(hours: 1),
        ),
      };

  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  final Duration? operationTimeout;

  Duration get effectiveOperationTimeout =>
      operationTimeout ?? fetchTimeout + const Duration(seconds: 2);
}

enum RemoteConfigOperationStatus {
  activated,
  fetchedNoChange,
  initialized,
  disabled,
  timedOut,
  failed,
}

final class RemoteConfigOperationResult {
  const RemoteConfigOperationResult(this.status, {this.errorCode});

  final RemoteConfigOperationStatus status;
  final String? errorCode;

  bool get isSuccess =>
      status == RemoteConfigOperationStatus.activated ||
      status == RemoteConfigOperationStatus.fetchedNoChange ||
      status == RemoteConfigOperationStatus.initialized;
}

final class RemoteConfigOperationException implements Exception {
  const RemoteConfigOperationException(this.code);

  final String code;

  @override
  String toString() => 'RemoteConfigOperationException($code)';
}

/// Optional, lifecycle-safe boundary around Firebase Remote Config.
///
/// Construction is lazy, so a disabled provider never touches Firebase.
/// Defaults are available before initialization or network work. Concurrent
/// fetch-and-activate calls share one bounded native operation.
final class AppRemoteConfig {
  AppRemoteConfig({
    RemoteConfigBackend? backend,
    FirebaseInitializer? firebaseInitializer,
    this.enabled = true,
  }) : _backend = backend,
       _firebaseInitializer = firebaseInitializer ?? _initializeFirebase;

  RemoteConfigBackend? _backend;
  final FirebaseInitializer _firebaseInitializer;
  final bool enabled;
  final Map<String, Object> _defaults = <String, Object>{};
  Future<void>? _initialization;
  Future<RemoteConfigOperationResult>? _fetchAndActivateInFlight;
  bool _disposed = false;
  bool _defaultsApplied = false;

  Future<void> initialize({FirebaseOptions? options}) {
    _ensureActive();
    if (!enabled) return Future<void>.value();
    return _initialization ??= _initialize(options);
  }

  Future<void> _initialize(FirebaseOptions? options) async {
    try {
      await _firebaseInitializer(options);
      _resolveBackend();
      await _applyDefaultsToBackend();
    } catch (_) {
      _initialization = null;
      throw const RemoteConfigOperationException('initialization_failed');
    }
  }

  Future<RemoteConfigOperationResult> tryInitialize({
    FirebaseOptions? options,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (!enabled) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.disabled,
      );
    }
    try {
      await initialize(options: options).timeout(timeout);
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.initialized,
      );
    } on TimeoutException {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.timedOut,
        errorCode: 'initialization_timeout',
      );
    } catch (_) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.failed,
        errorCode: 'initialization_failed',
      );
    }
  }

  Future<void> setDefaults(Map<String, Object> defaults) async {
    _ensureActive();
    for (final entry in defaults.entries) {
      _validateKey(entry.key);
      if (entry.value is! String &&
          entry.value is! bool &&
          entry.value is! int &&
          entry.value is! double) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'must be a String, bool, int, or double',
        );
      }
    }
    _defaults.addAll(defaults);
    _defaultsApplied = false;
    if (_backend != null) await _applyDefaultsToBackend();
  }

  Future<RemoteConfigOperationResult> fetchAndActivate({
    RemoteConfigPolicy policy = const RemoteConfigPolicy(
      fetchTimeout: Duration(seconds: 10),
      minimumFetchInterval: Duration(hours: 1),
    ),
  }) {
    _ensureActive();
    if (!enabled) {
      return Future<RemoteConfigOperationResult>.value(
        const RemoteConfigOperationResult(RemoteConfigOperationStatus.disabled),
      );
    }
    final existing = _fetchAndActivateInFlight;
    if (existing != null) return existing;

    late final Future<RemoteConfigOperationResult> operation;
    operation = _runFetchAndActivate(policy).whenComplete(() {
      if (identical(_fetchAndActivateInFlight, operation)) {
        _fetchAndActivateInFlight = null;
      }
    });
    _fetchAndActivateInFlight = operation;
    return operation;
  }

  Future<RemoteConfigOperationResult> _runFetchAndActivate(
    RemoteConfigPolicy policy,
  ) async {
    try {
      final backend = _resolveBackend();
      await _applyDefaultsToBackend();
      final activated = await (() async {
        await backend.configure(
          fetchTimeout: policy.fetchTimeout,
          minimumFetchInterval: policy.minimumFetchInterval,
        );
        return backend.fetchAndActivate();
      })().timeout(policy.effectiveOperationTimeout);
      return RemoteConfigOperationResult(
        activated
            ? RemoteConfigOperationStatus.activated
            : RemoteConfigOperationStatus.fetchedNoChange,
      );
    } on TimeoutException {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.timedOut,
        errorCode: 'fetch_timeout',
      );
    } catch (_) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.failed,
        errorCode: 'fetch_failed',
      );
    }
  }

  Future<RemoteConfigOperationResult> fetch({
    RemoteConfigPolicy policy = const RemoteConfigPolicy(
      fetchTimeout: Duration(seconds: 10),
      minimumFetchInterval: Duration(hours: 1),
    ),
  }) async {
    _ensureActive();
    if (!enabled) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.disabled,
      );
    }
    try {
      final backend = _resolveBackend();
      await _applyDefaultsToBackend();
      await backend.configure(
        fetchTimeout: policy.fetchTimeout,
        minimumFetchInterval: policy.minimumFetchInterval,
      );
      if (backend is AdvancedRemoteConfigBackend) {
        await backend.fetch().timeout(policy.effectiveOperationTimeout);
        return const RemoteConfigOperationResult(
          RemoteConfigOperationStatus.fetchedNoChange,
        );
      }
      return await fetchAndActivate(policy: policy);
    } on TimeoutException {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.timedOut,
        errorCode: 'fetch_timeout',
      );
    } catch (_) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.failed,
        errorCode: 'fetch_failed',
      );
    }
  }

  Future<RemoteConfigOperationResult> activate({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    _ensureActive();
    if (!enabled) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.disabled,
      );
    }
    final backend = _resolveBackend();
    if (backend is! AdvancedRemoteConfigBackend) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.failed,
        errorCode: 'activation_unsupported',
      );
    }
    try {
      final activated = await backend.activate().timeout(timeout);
      return RemoteConfigOperationResult(
        activated
            ? RemoteConfigOperationStatus.activated
            : RemoteConfigOperationStatus.fetchedNoChange,
      );
    } on TimeoutException {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.timedOut,
        errorCode: 'activation_timeout',
      );
    } catch (_) {
      return const RemoteConfigOperationResult(
        RemoteConfigOperationStatus.failed,
        errorCode: 'activation_failed',
      );
    }
  }

  Future<String> fetchRequiredString(
    String key, {
    Duration fetchTimeout = const Duration(seconds: 10),
    Duration minimumFetchInterval = const Duration(hours: 1),
    Duration? operationTimeout,
  }) async {
    _validateKey(key);
    final result = await fetchAndActivate(
      policy: RemoteConfigPolicy(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
        operationTimeout: operationTimeout,
      ),
    );
    if (result.status == RemoteConfigOperationStatus.timedOut) {
      throw TimeoutException('Remote Config operation timed out.');
    }
    if (result.status == RemoteConfigOperationStatus.failed) {
      throw const RemoteConfigOperationException('fetch_failed');
    }
    final value = getString(key).trim();
    if (value.isEmpty) {
      throw StateError('Remote Config returned an empty value for "$key".');
    }
    return value;
  }

  String getString(String key, {String fallback = ''}) {
    _validateKey(key);
    final local = _defaults[key];
    final effectiveFallback = local?.toString() ?? fallback;
    if (!enabled || _backend == null) return effectiveFallback;
    try {
      final value = _backend!.getString(key);
      return value.isEmpty ? effectiveFallback : value;
    } catch (_) {
      return effectiveFallback;
    }
  }

  bool getBool(String key, {bool fallback = false}) {
    _validateKey(key);
    final local = _defaults[key];
    final effectiveFallback = local is bool ? local : fallback;
    if (!enabled || _backend == null) return effectiveFallback;
    final backend = _backend!;
    try {
      if (backend is AdvancedRemoteConfigBackend) return backend.getBool(key);
      return _parseBool(backend.getString(key)) ?? effectiveFallback;
    } catch (_) {
      return effectiveFallback;
    }
  }

  int getInt(String key, {int fallback = 0}) {
    _validateKey(key);
    final local = _defaults[key];
    final effectiveFallback = local is int ? local : fallback;
    if (!enabled || _backend == null) return effectiveFallback;
    final backend = _backend!;
    try {
      if (backend is AdvancedRemoteConfigBackend) return backend.getInt(key);
      return int.tryParse(backend.getString(key).trim()) ?? effectiveFallback;
    } catch (_) {
      return effectiveFallback;
    }
  }

  double getDouble(String key, {double fallback = 0}) {
    _validateKey(key);
    final local = _defaults[key];
    final effectiveFallback = local is num ? local.toDouble() : fallback;
    if (!enabled || _backend == null) return effectiveFallback;
    final backend = _backend!;
    try {
      if (backend is AdvancedRemoteConfigBackend) {
        return backend.getDouble(key);
      }
      return double.tryParse(backend.getString(key).trim()) ??
          effectiveFallback;
    } catch (_) {
      return effectiveFallback;
    }
  }

  T getJson<T>(
    String key, {
    required T fallback,
    T Function(Object? decoded)? decode,
  }) {
    final value = getString(key);
    if (value.trim().isEmpty) return fallback;
    try {
      final decoded = jsonDecode(value);
      if (decode != null) return decode(decoded);
      return decoded is T ? decoded : fallback;
    } catch (_) {
      return fallback;
    }
  }

  void dispose() {
    _disposed = true;
    _initialization = null;
    _fetchAndActivateInFlight = null;
  }

  RemoteConfigBackend _resolveBackend() =>
      _backend ??= FirebaseRemoteConfigBackend(FirebaseRemoteConfig.instance);

  Future<void> _applyDefaultsToBackend() async {
    if (_defaultsApplied || _defaults.isEmpty) return;
    final backend = _backend;
    if (backend is AdvancedRemoteConfigBackend) {
      await backend.setDefaults(Map<String, Object>.unmodifiable(_defaults));
    }
    _defaultsApplied = true;
  }

  void _ensureActive() {
    if (_disposed) throw StateError('AppRemoteConfig has been disposed.');
  }

  static void _validateKey(String key) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be empty');
    }
  }

  static bool? _parseBool(String value) => switch (value.trim().toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => null,
  };

  static Future<void> _initializeFirebase(FirebaseOptions? options) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
  }
}
