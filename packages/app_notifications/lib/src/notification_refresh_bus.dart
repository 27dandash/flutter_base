import 'dart:async';

/// "Something changed on the server" signal derived from a notification.
///
/// A notification is only a TRIGGER: the open page decides whether it is
/// affected ([scope] + [entityId]) and then re-fetches from the API. The
/// payload is never trusted as the source of truth.
final class NotificationRefresh {
  const NotificationRefresh({
    required this.scope,
    this.entityId,
    this.type = '',
    this.fromTap = false,
  });

  /// What changed, for example `order`, `chat`, `wallet`, `profile`.
  final String scope;

  /// Id of the changed entity (order id, room id…). Null = the whole scope.
  final String? entityId;

  /// The raw notification type that produced this event (diagnostics only).
  final String type;

  /// True when the user tapped the notification, false when it arrived while
  /// the app was in the foreground.
  final bool fromTap;

  /// Whether a page watching [watchedScopes] / [watchedEntityId] is affected.
  bool matches(Set<String> watchedScopes, {String? watchedEntityId}) {
    if (!watchedScopes.contains(scope)) return false;
    if (watchedEntityId == null || entityId == null) return true;
    return watchedEntityId == entityId;
  }
}

/// App-wide broadcast bus for [NotificationRefresh] events.
///
/// Identical events (same scope + entity) arriving within [dedupeWindow]
/// (a duplicated push, or foreground message followed by a tap) trigger ONE
/// refresh.
final class NotificationRefreshBus {
  NotificationRefreshBus({this.dedupeWindow = const Duration(seconds: 2)});

  static final NotificationRefreshBus instance = NotificationRefreshBus();

  final Duration dedupeWindow;
  final StreamController<NotificationRefresh> _controller =
      StreamController<NotificationRefresh>.broadcast(sync: true);
  final Map<String, DateTime> _recent = <String, DateTime>{};

  Stream<NotificationRefresh> get stream => _controller.stream;

  /// Emits [event] unless an identical one was emitted within the dedupe
  /// window. Returns whether it was emitted.
  bool emit(NotificationRefresh event, {DateTime? now}) {
    final at = now ?? DateTime.now();
    _recent.removeWhere((_, time) => at.difference(time) > dedupeWindow);
    final key = '${event.scope}|${event.entityId ?? '*'}';
    if (_recent.containsKey(key)) return false;
    _recent[key] = at;
    if (!_controller.isClosed) _controller.add(event);
    return true;
  }

  void reset() => _recent.clear();
}
