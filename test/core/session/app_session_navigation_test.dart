import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base/src/app.dart';
import 'package:flutter_base/src/config/language/languages.dart';
import 'package:flutter_base/src/config/res/config_imports.dart';
import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_base/src/core/network/cubits/connectivity_cubit.dart';
import 'package:flutter_base/src/core/network/cubits/offline_queue_cubit.dart';
import 'package:flutter_base/src/core/shared/cubits/user_cubit/user_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _EmptyBackend implements TokenStorageBackend {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> deleteAll(Iterable<String> keys) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => call.method == 'check' ? <String>['wifi'] : null,
    );
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) {}),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    EasyLocalization.logger.enableLevels = [];
    await EasyLocalization.ensureInitialized();
  });

  tearDown(() async {
    await injector.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: Languages.supportLocales,
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a restore that finished before the first frame still routes to login',
    (tester) async {
      final user = UserCubit(TokenStorage.forTesting(_EmptyBackend()));
      await tester.runAsync(user.init); // restore completes before any frame
      expect(user.state.userStatus, UserStatus.loggedOut);
      injector
        ..registerSingleton<UserCubit>(user)
        ..registerSingleton<ConnectivityCubit>(ConnectivityCubit())
        ..registerSingleton<OfflineQueueCubit>(OfflineQueueCubit());

      await pumpApp(tester);

      expect(
        find.byKey(const ValueKey('login-placeholder')),
        findsOneWidget,
        reason: 'the BlocListener never saw this transition',
      );
    },
  );
}
