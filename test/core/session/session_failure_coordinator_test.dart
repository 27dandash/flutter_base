import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/session/session_failure_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final coordinator = SessionFailureCoordinator.instance;

  tearDown(() {
    coordinator.onUnauthorized = null;
    coordinator.onBlocked = null;
    coordinator.onNeedsActivation = null;
  });

  test('converts an unauthorized failure into a session callback', () async {
    var calls = 0;
    coordinator.onUnauthorized = () async => calls++;

    expect(await coordinator.handle(const UnauthorizedFailure()), isTrue);
    expect(calls, 1);
  });

  test('preserves blocked and activation payloads', () async {
    String? blockedMessage;
    Object? activationPayload;
    coordinator.onBlocked = (message) async => blockedMessage = message;
    coordinator.onNeedsActivation = (_, data) async => activationPayload = data;

    await coordinator.handle(
      const BlockedFailure(customMessage: 'internal account reason'),
    );
    await coordinator.handle(
      const NeedActiveFailure(activationData: {'channel': 'sms'}),
    );

    expect(blockedMessage, isNot('internal account reason'));
    expect(blockedMessage, isNotEmpty);
    expect(activationPayload, const {'channel': 'sms'});
  });

  test('ignores failures that do not change session state', () async {
    expect(await coordinator.handle(const NetworkFailure()), isFalse);
  });
}
