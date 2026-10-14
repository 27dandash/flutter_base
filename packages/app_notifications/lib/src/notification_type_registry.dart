import 'dart:async';

/// Handles a tapped notification of a registered type. Receives the payload
/// after nested `data` has been flattened (see `normalizeNotificationPayload`).
typedef NotificationNavigate = FutureOr<void> Function(
  Map<String, dynamic> data,
);

/// Maps the raw `type` value to the key used for registry lookup. Lets a
/// product alias legacy transport values (for example a generic `text` event
/// carrying a sender id) onto one of its registered types.
typedef NotificationTypeResolver = String Function(
  String type,
  Map<String, dynamic> payload,
);

/// One product-defined notification type.
///
/// A type either navigates when tapped, ends the session (blocked or deleted
/// account), or does nothing.
final class NotificationTypeSpec {
  const NotificationTypeSpec(
    this.key, {
    this.navigate,
    this.endsSession = false,
  }) : assert(
         !endsSession || navigate == null,
         'A session-ending type is routed to onSessionEnd, not navigate.',
       );

  final String key;
  final NotificationNavigate? navigate;

  /// When true the manager shows the notification, then invokes
  /// `onSessionEnd` and bypasses the user-preference gate.
  final bool endsSession;
}

/// Product-owned table of notification types. The package ships no business
/// types: routes, entities and identifiers belong to the consuming app.
final class NotificationTypeRegistry {
  NotificationTypeRegistry({
    Iterable<NotificationTypeSpec> types = const [],
    this.resolveType,
  }) : _types = {for (final spec in types) spec.key: spec};

  /// A registry with no types: every message falls through to the generic
  /// `action_type` routing.
  static final NotificationTypeRegistry empty = NotificationTypeRegistry();

  final Map<String, NotificationTypeSpec> _types;
  final NotificationTypeResolver? resolveType;

  NotificationTypeSpec? specFor(String key) => _types[key];

  /// Extracts the type key from a raw `type` value, which may be a string or
  /// an object such as `{value: 'order_created'}`.
  static String keyOf(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      return raw['value']?.toString() ?? raw['key']?.toString() ?? '';
    }
    return raw.toString();
  }

  /// The resolved registry key for [payload].
  String keyFor(Map<String, dynamic> payload) {
    final type = keyOf(payload['type']);
    return resolveType?.call(type, payload) ?? type;
  }

  NotificationTypeSpec? specForPayload(Map<String, dynamic> payload) =>
      specFor(keyFor(payload));
}

/// Observes foreground messages of the given types (for example to refresh an
/// unread counter or an open order screen).
final class NotificationActionListener {
  const NotificationActionListener({
    required this.types,
    required this.onMessage,
  });

  final Set<String> types;
  final void Function(Map<String, dynamic> data) onMessage;

  bool conditionCheck(String type) => types.contains(type);
}
