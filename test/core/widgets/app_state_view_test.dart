// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_base/src/core/widgets/handling_views/app_state_view.dart';
import 'package:flutter_base/src/core/widgets/handling_views/empty_widget.dart';
import 'package:flutter_base/src/core/widgets/handling_views/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: mode,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('transitions from loading to content', (tester) async {
    await tester.pumpWidget(
      _host(
        const AppStateView(
          status: AppViewStatus.loading,
          content: Text('content'),
          message: 'loading',
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const AppStateView(
          status: AppViewStatus.content,
          content: Text('content'),
          message: '',
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final status in [
    AppViewStatus.empty,
    AppViewStatus.error,
    AppViewStatus.noInternet,
    AppViewStatus.permissionRequired,
  ]) {
    testWidgets('$status exposes a retry/action', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          AppStateView(
            status: status,
            content: const SizedBox(),
            message: 'message',
            actionLabel: 'action',
            onAction: () => calls++,
          ),
        ),
      );
      await tester.tap(find.text('action'));
      expect(calls, 1);
    });
  }

  testWidgets('full state is scroll-safe with large RTL text', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: AppStateView(
              status: AppViewStatus.error,
              content: SizedBox(),
              message: 'حدث خطأ طويل ويجب إعادة المحاولة',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('named empty constructor exposes title, visual and action', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        AppStateView.empty(
          title: 'No results',
          message: 'Try another search',
          visual: const Icon(Icons.search_off, key: ValueKey('visual')),
          actionLabel: 'Retry',
          onAction: () => retries++,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('visual')), findsOneWidget);
    expect(find.text('No results'), findsOneWidget);
    expect(
      find.bySemanticsLabel('No results. Try another search'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('named content and loading constructors avoid dummy arguments', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppStateView.content(content: Text('Ready'))),
    );
    expect(find.text('Ready'), findsOneWidget);

    await tester.pumpWidget(
      _host(const AppStateView.loading(message: 'Loading safely')),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading safely'), findsOneWidget);
  });

  testWidgets('legacy empty and error views delegate to AppStateView', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EmptyWidget(title: 'Nothing here', desc: 'Try later')),
    );
    expect(find.byType(AppStateView), findsOneWidget);
    expect(find.bySemanticsLabel('Nothing here. Try later'), findsOneWidget);

    await tester.pumpWidget(_host(const ErrorView(error: 'Safe error')));
    expect(find.byType(AppStateView), findsOneWidget);
    expect(find.bySemanticsLabel('Safe error'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
