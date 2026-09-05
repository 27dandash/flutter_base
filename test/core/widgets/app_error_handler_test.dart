import 'package:flutter/material.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/widgets/handling_views/app_error_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'localized_widget_harness.dart';

void main() {
  setUpAll(ensureLocalizedTests);

  testWidgets(
    'maps every failure type to safe UI and the correct retry policy',
    (tester) async {
      final cases = <({Failure failure, IconData icon, bool retryable})>[
        (
          failure: const NetworkFailure(technical: 'private endpoint'),
          icon: Icons.wifi_off_rounded,
          retryable: true,
        ),
        (
          failure: const TimeoutFailure(),
          icon: Icons.timer_off_outlined,
          retryable: true,
        ),
        (
          failure: const UnauthorizedFailure(),
          icon: Icons.lock_outline,
          retryable: false,
        ),
        (
          failure: const PermissionFailure(),
          icon: Icons.block_outlined,
          retryable: false,
        ),
        (
          failure: const NotFoundFailure(),
          icon: Icons.search_off_rounded,
          retryable: false,
        ),
        (
          failure: const MaintenanceFailure(),
          icon: Icons.construction_rounded,
          retryable: true,
        ),
        (
          failure: const RateLimitFailure(),
          icon: Icons.speed_outlined,
          retryable: true,
        ),
        (
          failure: const PayloadTooLargeFailure(),
          icon: Icons.attach_file_outlined,
          retryable: false,
        ),
        (
          failure: const ValidationFailure(),
          icon: Icons.rule_outlined,
          retryable: false,
        ),
        (
          failure: const BadCertificateFailure(),
          icon: Icons.gpp_bad_outlined,
          retryable: false,
        ),
        (
          failure: const ParseFailure(),
          icon: Icons.error_outline_rounded,
          retryable: false,
        ),
        (
          failure: const UnknownFailure(),
          icon: Icons.error_outline_rounded,
          retryable: false,
        ),
        (
          failure: const ServerFailure(),
          icon: Icons.error_outline_rounded,
          retryable: true,
        ),
        (
          failure: const ConflictFailure(),
          icon: Icons.merge_type_outlined,
          retryable: false,
        ),
        (
          failure: const NeedActiveFailure(),
          icon: Icons.mark_email_unread_outlined,
          retryable: false,
        ),
        (
          failure: const BlockedFailure(),
          icon: Icons.no_accounts_outlined,
          retryable: false,
        ),
      ];
      final retries = List<int>.filled(cases.length, 0);

      await pumpLocalized(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              for (var index = 0; index < cases.length; index++)
                SizedBox(
                  key: ValueKey('failure-$index'),
                  child: AppErrorHandler(
                    failure: cases[index].failure,
                    onRetry: () => retries[index]++,
                    compact: true,
                  ),
                ),
            ],
          ),
        ),
      );

      for (var index = 0; index < cases.length; index++) {
        final testCase = cases[index];
        final scope = find.byKey(ValueKey('failure-$index'));
        expect(
          find.descendant(of: scope, matching: find.byIcon(testCase.icon)),
          findsOneWidget,
          reason: '${testCase.failure.runtimeType} icon mapping',
        );
        expect(
          find.descendant(
            of: scope,
            matching: find.text(testCase.failure.userMessage),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: scope, matching: find.byType(TextButton)),
          testCase.retryable ? findsOneWidget : findsNothing,
          reason: '${testCase.failure.runtimeType} retry policy',
        );
        if (testCase.retryable) {
          await tester.tap(
            find.descendant(of: scope, matching: find.byType(TextButton)),
            warnIfMissed: false,
          );
          expect(retries[index], 1);
        }
      }

      expect(find.textContaining('private endpoint'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled work is silent in compact and full layouts', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      const Column(
        children: [
          AppErrorHandler(failure: CancelledFailure()),
          AppErrorHandler(failure: CancelledFailure(), compact: true),
        ],
      ),
    );

    expect(find.byType(Icon), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
