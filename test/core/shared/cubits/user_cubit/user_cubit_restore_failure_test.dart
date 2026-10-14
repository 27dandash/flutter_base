import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_base/src/core/network/offline/offline_queue_manager.dart';
import 'package:flutter_base/src/core/shared/cubits/user_cubit/user_cubit.dart';
import 'package:flutter_base/src/core/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MemoryBackend implements TokenStorageBackend {
  _MemoryBackend(this.values);

  final Map<String, String> values;
  Completer<void>? readGate;

  @override
  Future<String?> read(String key) async {
    final gate = readGate;
    if (gate != null) await gate.future;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }
}

String _pair() => jsonEncode({'version': 2, 'access': 'tok', 'refresh': 'r'});

UserModel _user(String id) => UserModel.initial().copyWith(id: id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secureStore;
  late bool failReads;

  setUp(() {
    secureStore = <String, String>{};
    failReads = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = (call.arguments as Map?) ?? const {};
            switch (call.method) {
              case 'write':
                secureStore[args['key'] as String] = args['value'] as String;
                return null;
              case 'read':
                if (failReads) {
                  throw PlatformException(code: 'keystore_unavailable');
                }
                return secureStore[args['key'] as String];
              case 'delete':
                secureStore.remove(args['key'] as String);
                return null;
            }
            return null;
          },
        );
  });

  group('session restore when secure storage is unavailable', () {
    test(
      'a platform error signs out for now but keeps the stored session',
      () async {
        secureStore['auth_user_payload'] = jsonEncode(_user('u1').toJson());
        final backend = _MemoryBackend({'auth_token_pair_v2': _pair()});
        final cubit = UserCubit(TokenStorage.forTesting(backend));
        failReads = true;

        expect(await cubit.init(), isFalse);

        expect(cubit.state.userStatus, UserStatus.loggedOut);
        expect(
          secureStore['auth_user_payload'],
          isNotNull,
          reason: 'not wiped',
        );
        expect(backend.values['auth_token_pair_v2'], _pair());

        // Storage recovers: the very same session restores on the next attempt.
        failReads = false;
        expect(await cubit.init(), isTrue);
        expect(cubit.state.userStatus, UserStatus.loggedIn);
        expect(cubit.state.userModel.id, 'u1');
        await cubit.close();
      },
    );

    test('a read that times out does not destroy the stored session', () async {
      secureStore['auth_user_payload'] = jsonEncode(_user('u1').toJson());
      final backend = _MemoryBackend({'auth_token_pair_v2': _pair()})
        ..readGate = Completer<void>();
      final cubit = UserCubit(TokenStorage.forTesting(backend));

      expect(
        await cubit.init(timeout: const Duration(milliseconds: 20)),
        isFalse,
      );

      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(secureStore['auth_user_payload'], isNotNull);
      expect(backend.values['auth_token_pair_v2'], _pair());
      backend.readGate!.complete();
      await cubit.close();
    });

    test('a corrupt stored payload still ends the session for good', () async {
      secureStore['auth_user_payload'] = '{not json';
      final backend = _MemoryBackend({'auth_token_pair_v2': _pair()});
      final cubit = UserCubit(TokenStorage.forTesting(backend));

      expect(await cubit.init(), isFalse);

      expect(cubit.state.userStatus, UserStatus.loggedOut);
      expect(secureStore.containsKey('auth_user_payload'), isFalse);
      expect(backend.values['auth_token_pair_v2'], contains('"access":null'));
      await cubit.close();
    });
  });

  group('offline queue owner scope', () {
    tearDown(() => OfflineQueueManager().activateOwnerScope(null));

    test('a user without an id does not enable the offline queue', () async {
      final cubit = UserCubit(
        TokenStorage.forTesting(_MemoryBackend(<String, String>{})),
      );

      await cubit.setUserLoggedIn(user: _user(''), token: 'tok');

      expect(cubit.state.userStatus, UserStatus.loggedIn);
      expect(OfflineQueueManager().activeOwnerScope, isNull);
      await cubit.close();
    });

    test('distinct ids get distinct, stable scopes', () async {
      final cubit = UserCubit(
        TokenStorage.forTesting(_MemoryBackend(<String, String>{})),
      );

      await cubit.setUserLoggedIn(user: _user('a'), token: 't');
      final first = OfflineQueueManager().activeOwnerScope;
      await cubit.switchAccount(user: _user('b'), token: 't2');
      final second = OfflineQueueManager().activeOwnerScope;
      await cubit.switchAccount(user: _user('a'), token: 't3');

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, isNot(second));
      expect(OfflineQueueManager().activeOwnerScope, first);
      await cubit.close();
    });
  });
}
