import 'package:app_remote_config/app_remote_config.dart';

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeBackend implements RemoteConfigBackend {
  String value = '';
  Duration? fetchTimeout;
  Duration? minimumFetchInterval;
  var fetchCalls = 0;
  bool neverCompletes = false;
  Object? fetchError;

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {
    this.fetchTimeout = fetchTimeout;
    this.minimumFetchInterval = minimumFetchInterval;
  }

  @override
  Future<bool> fetchAndActivate() async {
    fetchCalls++;
    if (neverCompletes) return Completer<bool>().future;
    if (fetchError != null) throw fetchError!;
    return true;
  }

  @override
  String getString(String key) => value;
}

final class _AdvancedFakeBackend implements AdvancedRemoteConfigBackend {
  final Map<String, Object> values = <String, Object>{};
  Duration? fetchTimeout;
  Duration? minimumFetchInterval;
  var configureCalls = 0;
  var fetchCalls = 0;
  var activateCalls = 0;
  var fetchAndActivateCalls = 0;
  bool activationResult = true;
  Object? fetchError;
  Object? activationError;
  Completer<bool>? pendingFetchAndActivate;

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {
    configureCalls++;
    this.fetchTimeout = fetchTimeout;
    this.minimumFetchInterval = minimumFetchInterval;
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    for (final entry in defaults.entries) {
      values.putIfAbsent(entry.key, () => entry.value);
    }
  }

  @override
  Future<void> fetch() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
  }

  @override
  Future<bool> activate() async {
    activateCalls++;
    if (activationError != null) throw activationError!;
    return activationResult;
  }

  @override
  Future<bool> fetchAndActivate() {
    fetchAndActivateCalls++;
    if (fetchError != null) return Future<bool>.error(fetchError!);
    return pendingFetchAndActivate?.future ??
        Future<bool>.value(activationResult);
  }

  @override
  String getString(String key) => values[key]?.toString() ?? '';
  @override
  bool getBool(String key) => values[key] as bool? ?? false;
  @override
  int getInt(String key) => values[key] as int? ?? 0;
  @override
  double getDouble(String key) => (values[key] as num?)?.toDouble() ?? 0;
}

void main() {
  test(
    'initialization is injectable and does not require native Firebase',
    () async {
      FirebaseOptions? received;
      final client = AppRemoteConfig(
        backend: _FakeBackend(),
        firebaseInitializer: (options) async => received = options,
      );

      await client.initialize();

      expect(received, isNull);
    },
  );

  test('applies bounded settings and returns a required value', () async {
    final backend = _FakeBackend()..value = ' https://api.example.com ';
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    final value = await client.fetchRequiredString(
      'api_url',
      fetchTimeout: const Duration(seconds: 3),
      minimumFetchInterval: const Duration(minutes: 15),
    );

    expect(value, 'https://api.example.com');
    expect(backend.fetchTimeout, const Duration(seconds: 3));
    expect(backend.minimumFetchInterval, const Duration(minutes: 15));
    expect(backend.fetchCalls, 1);
  });

  test('rejects empty keys and missing values', () async {
    final client = AppRemoteConfig(
      backend: _FakeBackend(),
      firebaseInitializer: (_) async {},
    );

    expect(() => client.fetchRequiredString(' '), throwsArgumentError);
    expect(client.fetchRequiredString('missing'), throwsStateError);
  });

  test('bounds a stalled backend operation', () async {
    final backend = _FakeBackend()..neverCompletes = true;
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    expect(
      client.fetchRequiredString(
        'key',
        operationTimeout: const Duration(milliseconds: 5),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('disabled provider remains lazy and keeps local defaults', () async {
    var initializationCalls = 0;
    final client = AppRemoteConfig(
      enabled: false,
      firebaseInitializer: (_) async => initializationCalls++,
    );

    await client.setDefaults(<String, Object>{
      'title': 'Default',
      'enabled': true,
      'count': 4,
      'ratio': 1.5,
    });
    await client.initialize();
    final result = await client.fetchAndActivate();

    expect(initializationCalls, 0);
    expect(result.status, RemoteConfigOperationStatus.disabled);
    expect(client.getString('title'), 'Default');
    expect(client.getBool('enabled'), isTrue);
    expect(client.getInt('count'), 4);
    expect(client.getDouble('ratio'), 1.5);
  });

  test('defaults are available before fetch and passed to backend', () async {
    final backend = _AdvancedFakeBackend();
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    await client.setDefaults(<String, Object>{
      'message': 'fallback',
      'feature_enabled': true,
    });

    expect(client.getString('message'), 'fallback');
    expect(client.getBool('feature_enabled'), isTrue);
    expect(backend.values, containsPair('message', 'fallback'));
  });

  test('environment policies keep development and production distinct', () {
    final development = RemoteConfigPolicy.forEnvironment(
      RemoteConfigEnvironment.development,
    );
    final staging = RemoteConfigPolicy.forEnvironment(
      RemoteConfigEnvironment.staging,
    );
    final production = RemoteConfigPolicy.forEnvironment(
      RemoteConfigEnvironment.production,
    );

    expect(development.minimumFetchInterval, Duration.zero);
    expect(staging.minimumFetchInterval, const Duration(minutes: 15));
    expect(production.minimumFetchInterval, const Duration(hours: 1));
    expect(production.fetchTimeout, const Duration(seconds: 10));
  });

  test('fetch-and-activate reports activation and no-change states', () async {
    final backend = _AdvancedFakeBackend();
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    final activated = await client.fetchAndActivate(
      policy: RemoteConfigPolicy.forEnvironment(
        RemoteConfigEnvironment.staging,
      ),
    );
    backend.activationResult = false;
    final unchanged = await client.fetchAndActivate();

    expect(activated.status, RemoteConfigOperationStatus.activated);
    expect(unchanged.status, RemoteConfigOperationStatus.fetchedNoChange);
    expect(backend.minimumFetchInterval, const Duration(hours: 1));
  });

  test(
    'concurrent fetch-and-activate calls share one native request',
    () async {
      final backend = _AdvancedFakeBackend()
        ..pendingFetchAndActivate = Completer<bool>();
      final client = AppRemoteConfig(
        backend: backend,
        firebaseInitializer: (_) async {},
      );

      final first = client.fetchAndActivate();
      final second = client.fetchAndActivate();
      await Future<void>.delayed(Duration.zero);
      backend.pendingFetchAndActivate!.complete(true);

      expect(await first, same(await second));
      expect(backend.fetchAndActivateCalls, 1);
    },
  );

  test('fetch failures and offline errors use safe result codes', () async {
    final backend = _AdvancedFakeBackend()
      ..fetchError = Exception('sensitive native detail');
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    final result = await client.fetchAndActivate();

    expect(result.status, RemoteConfigOperationStatus.failed);
    expect(result.errorCode, 'fetch_failed');
    expect(result.errorCode, isNot(contains('sensitive')));
  });

  test('separate fetch and activation support failure and no-change', () async {
    final backend = _AdvancedFakeBackend()..activationResult = false;
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    expect(
      (await client.fetch()).status,
      RemoteConfigOperationStatus.fetchedNoChange,
    );
    expect(
      (await client.activate()).status,
      RemoteConfigOperationStatus.fetchedNoChange,
    );
    backend.activationError = StateError('native');
    expect((await client.activate()).errorCode, 'activation_failed');
  });

  test('typed parsing falls back for malformed basic-backend values', () {
    final backend = _FakeBackend()..value = 'not-a-number';
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    expect(client.getBool('flag', fallback: true), isTrue);
    expect(client.getInt('count', fallback: 7), 7);
    expect(client.getDouble('ratio', fallback: 2.5), 2.5);
    backend.value = '1';
    expect(client.getBool('flag'), isTrue);
  });

  test('JSON parsing returns typed content or a safe fallback', () {
    final backend = _FakeBackend()..value = '{"enabled":true}';
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    expect(
      client.getJson<Map<String, dynamic>>(
        'payload',
        fallback: <String, dynamic>{},
      ),
      <String, dynamic>{'enabled': true},
    );
    backend.value = '{bad';
    expect(
      client.getJson<List<Object?>>('payload', fallback: <Object?>[]),
      isEmpty,
    );
  });

  test('repeated initialization shares work and failure can retry', () async {
    var calls = 0;
    final gate = Completer<void>();
    final client = AppRemoteConfig(
      backend: _FakeBackend(),
      firebaseInitializer: (_) {
        calls++;
        return gate.future;
      },
    );

    final first = client.initialize();
    final second = client.initialize();
    gate.complete();
    await Future.wait(<Future<void>>[first, second]);
    expect(calls, 1);

    var retryCalls = 0;
    final retrying = AppRemoteConfig(
      backend: _FakeBackend(),
      firebaseInitializer: (_) async {
        retryCalls++;
        if (retryCalls == 1) throw StateError('missing config');
      },
    );
    await expectLater(
      retrying.initialize(),
      throwsA(isA<RemoteConfigOperationException>()),
    );
    await retrying.initialize();
    expect(retryCalls, 2);
  });

  test('tryInitialize reports initialized without fetching', () async {
    final backend = _FakeBackend();
    final client = AppRemoteConfig(
      backend: backend,
      firebaseInitializer: (_) async {},
    );

    final result = await client.tryInitialize();

    expect(result.status, RemoteConfigOperationStatus.initialized);
    expect(result.isSuccess, isTrue);
    expect(backend.fetchCalls, 0);
  });

  test(
    'tryInitialize bounds missing configuration without raw errors',
    () async {
      final client = AppRemoteConfig(
        backend: _FakeBackend(),
        firebaseInitializer: (_) async => throw StateError('private detail'),
      );

      final result = await client.tryInitialize();

      expect(result.status, RemoteConfigOperationStatus.failed);
      expect(result.errorCode, 'initialization_failed');
    },
  );

  test('disposed provider rejects lifecycle operations', () {
    final client = AppRemoteConfig(
      backend: _FakeBackend(),
      firebaseInitializer: (_) async {},
    )..dispose();

    expect(client.initialize, throwsStateError);
    expect(client.fetchAndActivate, throwsStateError);
    expect(
      () => client.setDefaults(<String, Object>{'key': 'value'}),
      throwsStateError,
    );
  });
}
