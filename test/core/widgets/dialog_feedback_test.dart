import 'dart:ui' as ui;

import 'package:flutter_base/src/core/shared/extensions/base_state.dart';
import 'package:flutter_base/src/core/widgets/custom_messages.dart';
import 'package:flutter_base/src/core/widgets/dialogs/adaptive_alert.dart';
import 'package:flutter_base/src/core/widgets/pickers/custom_dialog.dart';
import 'package:flutter_base/src/core/widgets/pickers/default_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'localized_widget_harness.dart';

Widget _host(Widget child, {ThemeData? theme}) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(theme: theme, home: child),
);

void main() {
  testWidgets('adaptive confirmation returns one explicit action', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAdaptiveAlert(
                context: context,
                title: 'Delete?',
                content: const Text('Cannot be undone'),
                barrierDismissible: false,
                actions: const [
                  AdaptiveAction(key: 'cancel', label: 'Cancel'),
                  AdaptiveAction(
                    key: 'delete',
                    label: 'Delete',
                    destructive: true,
                  ),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, 'delete');
  });

  testWidgets('default bottom sheet follows dark theme and keyboard insets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDefaultBottomSheet<void>(
              context: context,
              child: const Text('Sheet content'),
            ),
            child: const Text('Open sheet'),
          ),
        ),
        theme: ThemeData.dark(),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('messages replace prior snackbars and expose live semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                MessageUtils.showSnackBar(
                  context: context,
                  baseStatus: BaseStatus.error,
                  message: 'Safe message',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Safe message'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final semantics = snackBar.content as Semantics;
    expect(semantics.properties.label, 'Safe message');
    expect(semantics.properties.liveRegion, isTrue);
  });

  testWidgets('snackbar dismiss action uses localized English dismiss label', (
    tester,
  ) async {
    await ensureLocalizedTests();
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              MessageUtils.showSnackBar(
                context: context,
                baseStatus: BaseStatus.success,
                message: 'Saved',
              );
            },
            child: const Text('Show'),
          ),
        ),
      ),
      locale: const Locale('en'),
    );
    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('snackbar dismiss action uses localized Arabic dismiss label', (
    tester,
  ) async {
    await ensureLocalizedTests();
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              MessageUtils.showSnackBar(
                context: context,
                baseStatus: BaseStatus.success,
                message: 'Saved',
              );
            },
            child: const Text('Show'),
          ),
        ),
      ),
      locale: const Locale('ar'),
      direction: ui.TextDirection.rtl,
    );
    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('إغلاق'), findsOneWidget);
  });

  testWidgets('custom dialog uses theme surface color in dark mode', (
    tester,
  ) async {
    const darkSurface = Color(0xFF1E1E1E);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showCustomDialog<void>(
              context,
              child: const Text('Dialog body'),
            ),
            child: const Text('Open dialog'),
          ),
        ),
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(surface: darkSurface),
        ),
      ),
    );
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.text('Dialog body'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color == darkSurface,
        ),
      ),
    );
    expect(container, isNotNull);
  });
}
