import 'dart:async';

import 'package:flutter_base/src/core/startup/startup_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartupCoordinator', () {
    test('bounds a critical task with its timeout', () async {
      final coordinator = StartupCoordinator([
        StartupTask(
          id: 'never',
          kind: StartupTaskKind.critical,
          timeout: const Duration(milliseconds: 5),
          action: () => Completer<void>().future,
        ),
      ]);

      final report = await coordinator.runCritical();

      expect(report.succeeded, isFalse);
      expect(report.results.single.status, StartupTaskStatus.timedOut);
    });

    test('runs the same task at most once across repeated calls', () async {
      var calls = 0;
      final coordinator = StartupCoordinator([
        StartupTask(
          id: 'once',
          kind: StartupTaskKind.critical,
          action: () => calls++,
        ),
      ]);

      await coordinator.runCritical();
      await coordinator.runCritical();

      expect(calls, 1);
    });

    test('critical startup never waits for optional work', () async {
      var optionalStarted = false;
      final coordinator = StartupCoordinator([
        StartupTask(
          id: 'critical',
          kind: StartupTaskKind.critical,
          action: () {},
        ),
        StartupTask(
          id: 'optional',
          kind: StartupTaskKind.optional,
          action: () => optionalStarted = true,
        ),
      ]);

      final report = await coordinator.runCritical();

      expect(report.succeeded, isTrue);
      expect(optionalStarted, isFalse);
      coordinator.startBackground();
      await Future<void>.delayed(Duration.zero);
      expect(optionalStarted, isTrue);
    });

    test('reports optional failure without throwing into startup', () async {
      final result = Completer<StartupTaskResult>();
      final coordinator = StartupCoordinator([
        StartupTask(
          id: 'optional',
          kind: StartupTaskKind.optional,
          action: () => throw StateError('unavailable'),
        ),
      ], onBackgroundResult: result.complete);

      coordinator.startBackground();

      expect((await result.future).status, StartupTaskStatus.failed);
    });
  });
}
