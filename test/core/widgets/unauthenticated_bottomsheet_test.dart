import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_base/src/core/widgets/unauthenticated/unauthenticated_bottomsheet.dart';

import 'localized_widget_harness.dart';

void main() {
  testWidgets('presenter is duplicate-safe and shows blocked copy', (
    tester,
  ) async {
    await ensureLocalizedTests();
    final presenter = UnauthenticatedSheetPresenter();

    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => presenter.show(context, isBlocked: false),
          child: const Text('show'),
        ),
      ),
      locale: const Locale('en'),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.text('Login'), findsOneWidget);
    await tester.tap(find.text('show'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Login'), findsOneWidget);

    final sheetContext = tester.element(find.text('Login'));
    Navigator.of(sheetContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => presenter.show(context, isBlocked: true),
          child: const Text('show blocked'),
        ),
      ),
      locale: const Locale('en'),
    );

    await tester.tap(find.text('show blocked'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your account has been blocked by the administration'),
      findsOneWidget,
    );
  });
}
