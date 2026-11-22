/// Remembers the last session-ending pushes so one push ends the session once.
///
/// A block / account-deleted push arrives in the foreground and is tapped
/// afterwards; both must not log the user out twice.
class NotificationSessionDedupe {
  NotificationSessionDedupe({this.maxHandled = 32});

  final int maxHandled;
  final Set<String> _handled = <String>{};

  /// Returns true the first time [eventKey] is seen.
  bool markHandled(String eventKey) {
    if (_handled.contains(eventKey)) return false;
    if (_handled.length >= maxHandled) _handled.remove(_handled.first);
    _handled.add(eventKey);
    return true;
  }

  void clear() => _handled.clear();
}
