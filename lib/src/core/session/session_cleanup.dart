enum SessionTerminationReason {
  logout,
  accountDeleted,
  revoked,
  blocked,
  needsActivation,
  accountSwitch,
}

typedef SessionCleanupAction = Future<void> Function(
  SessionTerminationReason reason,
);

final class SessionCleanupHook {
  const SessionCleanupHook({required this.id, required this.action});

  final String id;
  final SessionCleanupAction action;
}

final class SessionCleanupFailure {
  const SessionCleanupFailure(this.hookId, this.error, this.stackTrace);

  final String hookId;
  final Object error;
  final StackTrace stackTrace;
}

/// Product integrations register user-scoped cleanup here (socket disconnect,
/// notification-token detachment, profile stores, analytics identity, etc.).
/// Core credentials, HTTP cache, and the offline queue are always cleared by
/// `UserCubit` and therefore cannot be accidentally omitted by a product.
final class SessionCleanupRegistry {
  SessionCleanupRegistry._();

  static final SessionCleanupRegistry instance = SessionCleanupRegistry._();

  final Map<String, SessionCleanupAction> _hooks = {};

  void register(SessionCleanupHook hook) {
    if (hook.id.trim().isEmpty) {
      throw ArgumentError.value(hook.id, 'hook.id', 'must not be empty');
    }
    _hooks[hook.id] = hook.action;
  }

  void unregister(String id) => _hooks.remove(id);

  Future<List<SessionCleanupFailure>> run(
    SessionTerminationReason reason,
  ) async {
    final failures = <SessionCleanupFailure>[];
    for (final entry in Map<String, SessionCleanupAction>.of(_hooks).entries) {
      try {
        await entry.value(reason).timeout(const Duration(seconds: 6));
      } catch (error, stackTrace) {
        failures.add(SessionCleanupFailure(entry.key, error, stackTrace));
      }
    }
    return List<SessionCleanupFailure>.unmodifiable(failures);
  }

  void clearForTesting() => _hooks.clear();
}
