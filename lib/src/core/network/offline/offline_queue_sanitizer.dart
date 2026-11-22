/// Removes secrets from a queued operation before it is written to disk.
///
/// Body/header keys that must never be persisted. Auth headers are re-attached
/// by the AuthInterceptor at replay time, so dropping them here is safe and
/// keeps secrets out of the Hive box.
abstract final class OfflineQueueSanitizer {
  static const Set<String> sensitiveKeys = {
    'password',
    'password_confirmation',
    'current_password',
    'new_password',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'api_key',
    'secret',
    'otp',
    'pin',
    'cvv',
    'card_number',
  };

  /// Recursively removes [sensitiveKeys] (case-insensitively) from a map.
  static Map<String, dynamic>? strip(Map<String, dynamic>? input) {
    if (input == null) return null;
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) return;
      out[key] = _sanitizeValue(value);
    });
    return out;
  }

  static Object? _sanitizeValue(Object? value) {
    if (value is Map) return strip(value.cast<String, dynamic>());
    if (value is List) return value.map(_sanitizeValue).toList();
    return value;
  }
}
