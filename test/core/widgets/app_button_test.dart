import 'dart:async';

import 'package:flutter_base/src/core/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('prevents duplicate async submissions and restores the action', (
    tester,
  ) async {
    final completion = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _host(
        AppButton(
          label: 'Save',
          loadingLabel: 'Saving',
          onPressed: () {
            calls++;
            return completion.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Saving'), findsOneWidget);

    completion.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('disabled button does not invoke a callback', (tester) async {
    await tester.pumpWidget(
      _host(const AppButton(label: 'Disabled', onPressed: null)),
    );
    await tester.tap(find.text('Disabled'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all variants expose minimum accessible tap targets', (
    tester,
  ) async {
    for (final variant in AppButtonVariant.values) {
      await tester.pumpWidget(
        _host(
          Center(
            child: AppButton(
              label: variant.name,
              variant: variant,
              fullWidth: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
  });

  testWidgets('async completion after disposal does not call setState', (
    tester,
  ) async {
    final completion = Completer<void>();
    await tester.pumpWidget(
      _host(AppButton(label: 'Submit', onPressed: () => completion.future)),
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'external loading disables action and keyboard activation works',
    (tester) async {
      var calls = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Continue',
            semanticLabel: 'Continue safely',
            focusNode: focus,
            autofocus: true,
            onPressed: () => calls++,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 1);
      expect(find.bySemanticsLabel('Continue safely'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          AppButton(
            label: 'Continue',
            isLoading: true,
            loadingLabel: 'Working',
            onPressed: () => calls++,
          ),
        ),
      );
      await tester.tap(find.byType(AppButton));
      expect(calls, 1);
      expect(find.text('Working'), findsOneWidget);
    },
  );
}
