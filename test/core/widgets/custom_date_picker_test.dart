import 'package:flutter/material.dart';
import 'package:flutter_base/src/core/navigation/navigator.dart';
import 'package:flutter_base/src/core/widgets/pickers/custom_date_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a past initial date with the default range opens the picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: Go.navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    // The default firstDate is today; a birth-date style initialDate in the past
    // used to trip showDatePicker's range assertion.
    final controller = TextEditingController();
    final future = showCustomDatePicker(
      controller: controller,
      initialDate: DateTime(1990, 5, 20),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await future, isNull);
    controller.dispose();
  });

  testWidgets('a future initial date beyond the range is clamped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: Go.navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    final controller = TextEditingController();
    final future = showCustomDatePicker(
      controller: controller,
      initialDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await future, isNull);
    controller.dispose();
  });
}
