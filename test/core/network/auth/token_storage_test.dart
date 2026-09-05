import 'dart:async';
import 'dart:convert';

import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

final class _MemoryBackend implements TokenStorageBackend {
  final values = <String, String>{};
  Completer<void>? nextWriteGate;
  bool failNextWrite = false;
  Completer<void>? writeStarted;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writeStarted?.complete();
    writeStarted = null;
    await nextWriteGate?.future;
    nextWriteGate = null;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated secure-storage failure');
    }
    values[key] = value;
  }

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}

Map<String, dynamic> _persistedPair(_MemoryBackend backend) => jsonDecode(
  backend.values.values.singleWhere((value) => value.contains('"version":2')),
) as Map<String, dynamic>;

void main() {
  group('TokenStorage instance identity (P0-1)', () {
    final getIt = GetIt.instance;

    tearDown(() => getIt.reset());

    test('DI lookup resolves to the same object as the static instance', () {
      // Mirrors setUpGeneralDependencies() wiring.
      getIt.registerLazySingleton<TokenStorage>(() => TokenStorage.instance);

      expect(identical(TokenStorage.instance, getIt<TokenStorage>()), isTrue);
    });

    test('static instance is a stable singleton', () {
      expect(identical(TokenStorage.instance, TokenStorage.instance), isTrue);
    });
  });

  group('TokenStorage persistence and session generations', () {
    test('stores the token pair in one versioned record', () async {
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);

      await storage.save(access: 'access-a', refresh: 'refresh-a');

      expect(storage.accessToken, 'access-a');
      expect(storage.refreshToken, 'refresh-a');
      expect(_persistedPair(backend), {
        'version': 2,
        'access': 'access-a',
        'refresh': 'refresh-a',
      });
    });

    test('failed new-session write fails closed in memory', () async {
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);
      await storage.save(access: 'old', refresh: 'old-refresh');
      final previousGeneration = storage.sessionGeneration;
      backend.failNextWrite = true;

      await expectLater(
        storage.save(access: 'new', refresh: 'new-refresh'),
        throwsStateError,
      );

      expect(storage.sessionGeneration, previousGeneration + 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.hasAccessToken, isFalse);
    });

    test(
      'new session without refresh does not inherit the old token',
      () async {
        final backend = _MemoryBackend();
        final storage = TokenStorage.forTesting(backend);
        await storage.save(access: 'old', refresh: 'old-refresh');

        await storage.save(access: 'new');

        expect(storage.accessToken, 'new');
        expect(storage.refreshToken, isNull);
        expect(_persistedPair(backend)['refresh'], isNull);
      },
    );

    test('logout and account switch supersede a delayed token write', () async {
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);
      final gate = backend.nextWriteGate = Completer<void>();
      final started = backend.writeStarted = Completer<void>();

      final staleSave = storage.save(
        access: 'old-access',
        refresh: 'old-refresh',
      );
      await started.future;
      final clear = storage.clear();
      final newSave = storage.save(
        access: 'new-access',
        refresh: 'new-refresh',
      );
      gate.complete();

      await Future.wait([staleSave, clear, newSave]);
      expect(storage.accessToken, 'new-access');
      expect(storage.refreshToken, 'new-refresh');
      expect(_persistedPair(backend)['access'], 'new-access');
    });

    test('silent refresh cannot save into a newer session', () async {
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);
      await storage.save(access: 'old', refresh: 'old-refresh');
      final oldGeneration = storage.sessionGeneration;
      await storage.clear();
      await storage.save(access: 'new', refresh: 'new-refresh');

      final saved = await storage.saveIfCurrent(
        expectedGeneration: oldGeneration,
        access: 'stale-refresh-result',
      );

      expect(saved, isFalse);
      expect(storage.accessToken, 'new');
      expect(_persistedPair(backend)['access'], 'new');
    });

    test('clearIfCurrent clears only when the generation still owns the '
        'session', () async {
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);
      await storage.save(access: 'a', refresh: 'r');
      final generation = storage.sessionGeneration;

      final cleared = await storage.clearIfCurrent(generation);

      expect(cleared, isTrue);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.hasAccessToken, isFalse);
      // The tombstone (null/null pair) is durably persisted.
      expect(_persistedPair(backend), {
        'version': 2,
        'access': null,
        'refresh': null,
      });
    });

    test('clearIfCurrent with a stale generation is a no-op', () async {
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);
      await storage.save(access: 'a', refresh: 'r');
      final staleGeneration = storage.sessionGeneration;
      await storage.clear();
      await storage.save(access: 'b', refresh: 'rb');

      final cleared = await storage.clearIfCurrent(staleGeneration);

      expect(cleared, isFalse, reason: 'a stale generation must not clear');
      expect(storage.accessToken, 'b', reason: 'newer session is untouched');
      expect(storage.refreshToken, 'rb');
      expect(_persistedPair(backend)['access'], 'b');
    });

    test('clearIfCurrent fails closed in memory even when the durable '
        'tombstone write fails', () async {
      // Documents the residual durability limitation: we cannot guarantee the
      // OS secure store accepted the tombstone, but the in-memory session is
      // invalidated immediately so no request can present the old token, and
      // the generation is bumped so a delayed write cannot resurrect it.
      final backend = _MemoryBackend();
      final storage = TokenStorage.forTesting(backend);
      await storage.save(access: 'a', refresh: 'r');
      final generation = storage.sessionGeneration;
      backend.failNextWrite = true;

      await expectLater(storage.clearIfCurrent(generation), throwsStateError);

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.hasAccessToken, isFalse);
      expect(
        storage.sessionGeneration,
        generation + 1,
        reason: 'the session generation advanced despite the durable failure',
      );
    });

    test('migrates a legacy two-key pair once during init', () async {
      final backend = _MemoryBackend()
        ..values['auth_access_token'] = 'legacy-access'
        ..values['auth_refresh_token'] = 'legacy-refresh';
      final storage = TokenStorage.forTesting(backend);

      await storage.init();

      expect(storage.accessToken, 'legacy-access');
      expect(storage.refreshToken, 'legacy-refresh');
      expect(backend.values.containsKey('auth_access_token'), isFalse);
      expect(backend.values.containsKey('auth_refresh_token'), isFalse);
      expect(_persistedPair(backend)['version'], 2);
    });

    test('corrupted pair is replaced by an authoritative tombstone', () async {
      final backend = _MemoryBackend()
        ..values['auth_token_pair_v2'] = '{"version":1,"access":"stale"}';
      final storage = TokenStorage.forTesting(backend);

      await storage.init();

      expect(storage.hasAccessToken, isFalse);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(_persistedPair(backend), {
        'version': 2,
        'access': null,
        'refresh': null,
      });
    });
  });
}
