import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_base/bootstrap/app_environment.dart';
import 'package:flutter_base/bootstrap/bootstrap.dart';
import 'package:flutter_base/src/config/res/config_imports.dart';
import 'package:flutter_base/src/core/navigation/navigator.dart';
import 'package:flutter_base/src/core/shared/cubits/user_cubit/user_cubit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('development bootstrap stays usable across session and routing', (
    tester,
  ) async {
    bootstrap(AppEnvironment.development);

    await _pumpUntil(
      tester,
      () =>
          injector.isRegistered<UserCubit>() &&
          injector<UserCubit>().state.userStatus != UserStatus.restoring &&
          (find.byKey(const ValueKey('base-ready')).evaluate().isNotEmpty ||
              find
                  .byKey(const ValueKey('login-placeholder'))
                  .evaluate()
                  .isNotEmpty),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);

    Go.navigatorKey.currentState!.pushNamed('/integration-test-unknown');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('unknown-route')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final didPop = await Go.navigatorKey.currentState!.maybePop();
    expect(didPop, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byKey(const ValueKey('unknown-route')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(
    predicate(),
    isTrue,
    reason: 'Bootstrap did not render a usable route.',
  );
}
