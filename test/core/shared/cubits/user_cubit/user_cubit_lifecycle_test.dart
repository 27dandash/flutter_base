// UserCubit lifecycle-coordination audit — deterministic, no real storage.
//
// Proves the session lifecycle is serialized and epoch-guarded so that:
//   * a slow restore can never emit "logged in" after a newer explicit
//     transition (logout / login / switch) has superseded it;
//   * overlapping login and logout resolve to the latest requested transition,
//     with credentials and emitted state kept consistent (never mixed);
//   * account switching is a single atomic transition.
//
// TokenStorage runs against an in-memory backend whose read can be gated, so a
// restore can be pinned "in flight" while a competing transition is requested.
// SecureStorage is faked through its platform channel. OfflineQueueManager is
// never initialized here, so owner-scope activation stays a pure in-memory flag
// flip and touches neither Hive nor connectivity.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_base/src/core/shared/cubits/user_cubit/user_cubit.dart';
import 'package:flutter_base/src/core/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// TokenStorage backend whose first `read` can be gated to pin a restore
/// mid-flight while a competing transition is requested.
final class _GatedTokenBackend implements TokenStorageBackend {
  _GatedTokenBackend([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;
  Completer<void>? readGate;
  Completer<void>? readStarted;

  @override
  Future<String?> read(String key) async {
    final gate = readGate;
    if (gate != null && !gate.isCompleted) {
      readStarted?.complete();
      readStarted = null;
      await gate.future;
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}

String _pair(String access, String? refresh) =>
    jsonEncode({'version': 2, 'access': access, 'refresh': refresh});

UserModel _user(String id) => UserModel.initial().copyWith(id: id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secureStore;
  late bool failUserWrite;

  setUp(() {
    secureStore = <String, String>{};
    failUserWrite = false;
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'write':
              if (failUserWrite && args['key'] == 'auth_user_payload') {
                throw PlatformException(
                  code: 'write_failed',
                  message: 'private simulated payload',
                );
              }
              secureStore[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return secureStore[args['key'] as String];
            case 'delete':
              secureStore.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              secureStore.clear();
              return null;
            case 'readAll':
              return Map<String, String>.from(secureStore);
            case 'containsKey':
              return secureStore.containsKey(args['key'] as String);
          }
          return null;
        });
  });

  group('UserCubit stale restore', () {
    test('a valid stored session restores to logged-in when nothing '
        'supersedes it', () async {
      secureStore['auth_user_payload'] = jsonEncode(
        _user('stored-user').toJson(),
      );
      final storage = TokenStorage.forTesting(
        _GatedTokenBackend({'auth_token_pair_v2': _pair('tok', 'r')}),
      );
      final cubit = UserCubit(storage);

      final restored = await cubit.init();

      expect(restored, isTrue);
      expect(cubit.state.userStatus, UserStatus.loggedIn);
      expect(cubit.state.userModel.id, 'stored-user');
      await cubit.close();
    });

    test('a restore in flight never emits logged-in after a logout is '
        'requested', () async {
      secureStore['auth_user_payload'] = jsonEncode(
        _user('stored-user').toJson(),
      );
      final backend =
          _GatedTokenBackend({'auth_token_pair_v2': _pair('t', 'r')})
            ..readGate = Completer<void>()
            ..readStarted = Completer<void>();
      final storage = TokenStorage.forTesting(backend);
      final cubit = UserCubit(storage);

      final restore = cubit.init();
      final logout = cubit.logout();
      await backend.readStarted!.future; // restore is pinned at the gated read
      backend.readGate!.complete();

      await Future.wait<Object?>([restore, logout]);

      expect(await restore, isFalse, reason: 'the stale restore does not win');
      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(cubit.state.userModel.id, isEmpty);
      await cubit.close();
    });

    test('a restore in flight defers to an explicit login for another '
        'user', () async {
      secureStore['auth_user_payload'] = jsonEncode(
        _user('stored-user').toJson(),
      );
      final backend =
          _GatedTokenBackend({'auth_token_pair_v2': _pair('t', 'r')})
            ..readGate = Completer<void>()
            ..readStarted = Completer<void>();
      final storage = TokenStorage.forTesting(backend);
      final cubit = UserCubit(storage);

      final restore = cubit.init();
      final login = cubit.setUserLoggedIn(
        user: _user('explicit-user'),
        token: 'explicit-token',
        refreshToken: 'explicit-refresh',
      );
      await backend.readStarted!.future;
      backend.readGate!.complete();

      await Future.wait<Object?>([restore, login]);

      expect(await restore, isFalse);
      expect(cubit.state.userStatus, UserStatus.loggedIn);
      expect(cubit.state.userModel.id, 'explicit-user');
      expect(storage.accessToken, 'explicit-token');
      await cubit.close();
    });
  });

  group('UserCubit overlapping transitions', () {
    test('login then logout resolves to logged-out with cleared '
        'credentials', () async {
      final storage = TokenStorage.forTesting(_GatedTokenBackend());
      final cubit = UserCubit(storage);

      final login = cubit.setUserLoggedIn(
        user: _user('user-a'),
        token: 'token-a',
        refreshToken: 'refresh-a',
      );
      final logout = cubit.logout();

      await Future.wait<Object?>([login, logout]);

      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(storage.accessToken, isNull);
      expect(storage.hasAccessToken, isFalse);
      await cubit.close();
    });

    test('logout then login resolves to logged-in for the newer '
        'user', () async {
      final storage = TokenStorage.forTesting(_GatedTokenBackend());
      final cubit = UserCubit(storage);

      final logout = cubit.logout();
      final login = cubit.setUserLoggedIn(
        user: _user('user-b'),
        token: 'token-b',
        refreshToken: 'refresh-b',
      );

      await Future.wait<Object?>([logout, login]);

      expect(cubit.state.userStatus, UserStatus.loggedIn);
      expect(cubit.state.userModel.id, 'user-b');
      expect(storage.accessToken, 'token-b');
      expect(storage.refreshToken, 'refresh-b');
      await cubit.close();
    });

    test('switchAccount atomically replaces the session', () async {
      final storage = TokenStorage.forTesting(_GatedTokenBackend());
      final cubit = UserCubit(storage);

      await cubit.setUserLoggedIn(user: _user('user-a'), token: 'token-a');
      await cubit.switchAccount(
        user: _user('user-b'),
        token: 'token-b',
        refreshToken: 'refresh-b',
      );

      expect(cubit.state.userStatus, UserStatus.loggedIn);
      expect(cubit.state.userModel.id, 'user-b');
      expect(storage.accessToken, 'token-b');
      expect(storage.refreshToken, 'refresh-b');
      // The old payload was replaced, not merged.
      expect(jsonDecode(secureStore['auth_user_payload']!)['id'], 'user-b');
      await cubit.close();
    });

    test('failed user persistence rolls back the complete session', () async {
      final backend = _GatedTokenBackend();
      final storage = TokenStorage.forTesting(backend);
      final cubit = UserCubit(storage);
      failUserWrite = true;

      await expectLater(
        cubit.setUserLoggedIn(user: _user('user-a'), token: 'token-a'),
        throwsA(isA<PlatformException>()),
      );

      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(storage.hasAccessToken, isFalse);
      expect(storage.accessToken, isNull);
      expect(secureStore.containsKey('auth_user_payload'), isFalse);
      expect(
        jsonDecode(backend.values['auth_token_pair_v2']!)['access'],
        isNull,
      );
      await cubit.close();
    });
  });

  group('UserCubit incomplete persisted session', () {
    test('token without a user is cleared during restore', () async {
      final backend = _GatedTokenBackend({
        'auth_token_pair_v2': _pair('orphan-token', 'orphan-refresh'),
      });
      final storage = TokenStorage.forTesting(backend);
      final cubit = UserCubit(storage);

      expect(await cubit.init(), isFalse);

      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(storage.hasAccessToken, isFalse);
      expect(
        jsonDecode(backend.values['auth_token_pair_v2']!)['access'],
        isNull,
      );
      await cubit.close();
    });

    test('user without a token is cleared during restore', () async {
      secureStore['auth_user_payload'] = jsonEncode(
        _user('orphan-user').toJson(),
      );
      final storage = TokenStorage.forTesting(_GatedTokenBackend());
      final cubit = UserCubit(storage);

      expect(await cubit.init(), isFalse);

      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(secureStore.containsKey('auth_user_payload'), isFalse);
      await cubit.close();
    });
  });
}
