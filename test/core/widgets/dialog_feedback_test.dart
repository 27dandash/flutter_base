import 'package:flutter_base/src/core/shared/extensions/base_state.dart';
import 'package:flutter_base/src/core/widgets/custom_messages.dart';
import 'package:flutter_base/src/core/widgets/dialogs/adaptive_alert.dart';
import 'package:flutter_base/src/core/widgets/pickers/default_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
}
