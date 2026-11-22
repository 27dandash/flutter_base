import 'package:flutter_base/src/core/widgets/otp/app_otp_field.dart';
import 'package:flutter_base/src/core/widgets/otp/otp_resend_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'localized_widget_harness.dart';

void main() {
  group('AppOtpField', () {
    test('converts Arabic and Persian digits', () {
      expect(AppOtpField.toEnglishDigits('١٢٣٤'), '1234');
      expect(AppOtpField.toEnglishDigits('۱۲۳۴'), '1234');
      expect(AppOtpField.toEnglishDigits('12a4'), '12a4');
    });

    testWidgets('fires onCompleted once with English digits', (tester) async {
      final completed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppOtpField(onCompleted: completed.add, autofocus: true),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '١٢٣');
      expect(completed, isEmpty);
      await tester.enterText(find.byType(TextField), '١٢٣٤');
      await tester.pump();
      expect(completed, ['1234']);
      // Extra input is cut to the code length and does not fire again.
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      expect(completed, ['1234']);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('boxes stay left-to-right under RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: AppOtpField(onCompleted: (_) {})),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      final one = tester.getTopLeft(find.text('1')).dx;
      final two = tester.getTopLeft(find.text('2')).dx;
      expect(one, lessThan(two));
    });
  });

  group('OtpResendRow', () {
    Future<void> pumpRow(
      WidgetTester tester,
      Future<bool> Function() onResend,
    ) => pumpLocalized(tester, OtpResendRow(onResend: onResend, seconds: 3));

    testWidgets('counts down, then resends once and restarts', (tester) async {
      var calls = 0;
      await pumpRow(tester, () async {
        calls++;
        return true;
      });
      expect(find.text('Resend'), findsNothing);
      expect(find.textContaining('00:03'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Resend'), findsOneWidget);

      await tester.tap(find.text('Resend'));
      await tester.pump();
      await tester.tap(find.byType(TextButton), warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);
      expect(find.text('A new code has been sent'), findsOneWidget);
      expect(find.textContaining('00:03'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a failed resend keeps the link enabled', (tester) async {
      // Plain host; find by widget type so the test does not depend on
      // whether translations happen to be initialised by an earlier test.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpResendRow(onResend: () async => false, seconds: 3),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(TextButton), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
