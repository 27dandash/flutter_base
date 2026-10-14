import 'dart:convert';

/// Flattens an optional nested notification `data` object without throwing.
///
/// FCM gateways and backends may deliver product data as a map, a JSON object
/// string or already-flat keys. Nested keys take precedence because they are
/// the actual application payload. The outer transport identifier is always
/// preserved as `notification_id`; it only remains as `id` when the nested
/// data does not define its own `id`, so an entity id is never confused with
/// the id of the notification record that carried it.
Map<String, dynamic> normalizeNotificationPayload(Map<String, dynamic> source) {
  final normalized = Map<String, dynamic>.from(source);
  final nested = _nestedData(source['data']);
  if (nested == null) return normalized;

  final transportId = normalized['id'];
  normalized.addAll(nested);
  if (transportId != null) {
    normalized.putIfAbsent('notification_id', () => transportId);
    if (!nested.containsKey('id')) normalized.remove('id');
  }
  return normalized;
}

Map<String, dynamic>? _nestedData(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } on Object {
      return null;
    }
  }
  if (value is! String) return null;

  final text = value.trim();
  if (!text.startsWith('{') || !text.endsWith('}')) return null;
  try {
    final decoded = jsonDecode(text);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } on FormatException {
    return null;
  }
}
