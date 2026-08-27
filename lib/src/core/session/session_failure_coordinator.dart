import '../network/error/failures.dart';

typedef UnauthorizedSessionCallback = Future<void> Function();
typedef BlockedSessionCallback = Future<void> Function(String? message);
typedef ActivationSessionCallback = Future<void> Function(
  String? message,
  Object? activationData,
);

/// Global network-session boundary configured at the composition root.
/// It deliberately owns callbacks rather than a navigator or BuildContext.
final class SessionFailureCoordinator {
  SessionFailureCoordinator._();

  static final SessionFailureCoordinator instance =
      SessionFailureCoordinator._();

  UnauthorizedSessionCallback? onUnauthorized;
  BlockedSessionCallback? onBlocked;
  ActivationSessionCallback? onNeedsActivation;

  Future<bool> handle(Failure failure) async {
    switch (failure) {
      case UnauthorizedFailure():
        await onUnauthorized?.call();
        return true;
      case BlockedFailure():
        await onBlocked?.call(failure.userMessage);
        return true;
      case NeedActiveFailure(:final activationData):
        await onNeedsActivation?.call(failure.userMessage, activationData);
        return true;
      default:
        return false;
    }
  }
}
