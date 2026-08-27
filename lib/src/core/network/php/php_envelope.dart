import 'dart:convert';

import 'php_response_keys.dart';

/// A recognized response envelope from the custom PHP backend.
///
/// The backend signals the logical outcome of every request through a string
/// [key] in the JSON body (not the HTTP status code, which is almost always
/// 200). [tryFrom] is the single recognizer used by both `ResponseParser` (to
/// map the body to an `Either<Failure, T>`) and `AuthInterceptor` (to detect an
/// `unauthenticated` body and trigger the refresh-token cycle) — one source of
/// truth so the two never drift.
///
/// Pure value object: it reads no feature flag and performs no side effects, so
/// it is trivially unit-testable with plain decoded maps.
class PhpEnvelope {
  const PhpEnvelope._({
    required this.key,
    required this.raw,
    this.msg,
    this.data,
    this.countNotifications,
  });

  /// The logical state — guaranteed to be one of [PhpResponseKeys.known].
  final String key;

  /// The whole decoded envelope. Passed verbatim to `fromJson` on success so
  /// existing parsers that dig `json['data']` keep working, and ad-hoc extras
  /// (`url`, `id`, `type`, ...) stay reachable.
  final Map<String, dynamic> raw;

  /// User-facing message (`msg`), already localized by the server when present.
  final String? msg;

  /// Optional payload (`data`) — present with success / needActive / exception.
  final dynamic data;

  /// Optional unread-notifications count (`count_notifications`, success only).
  final int? countNotifications;

  /// Returns a [PhpEnvelope] when [decoded] is a Map whose `key` is a known
  /// logical state; otherwise `null` — the "not a PHP envelope" sentinel that
  /// tells callers to fall back to the default status-code handling (HTML
  /// error pages, redirects, legacy/partial JSON, etc.).
  static PhpEnvelope? tryFrom(dynamic decoded) {
    // Decode a String body so the interceptor (which inspects the raw
    // `response.data`) and the parser (which pre-runs `_safeDecode`) classify
    // identical bytes identically — even when a request overrides responseType
    // to plain or the server sends JSON under a non-JSON content type.
    final value = decoded is String ? _tryDecode(decoded) : decoded;
    if (value is! Map) return null;
    final key = value[PhpResponseKeys.key];
    if (key is! String || !PhpResponseKeys.known.contains(key)) return null;

    final raw = value is Map<String, dynamic>
        ? value
        : value.map<String, dynamic>((k, v) => MapEntry(k.toString(), v));
    final msg = raw[PhpResponseKeys.msg];

    return PhpEnvelope._(
      key: key,
      raw: raw,
      msg: msg is String ? msg : null,
      data: raw[PhpResponseKeys.data],
      countNotifications: _asInt(raw[PhpResponseKeys.countNotifications]),
    );
  }

  /// Reads an ad-hoc top-level extra (e.g. `url`, `id`, `type`) added by the
  /// backend via `successOtherData()`.
  dynamic extra(String name) => raw[name];

  /// Best-effort JSON decode of a String body; `null` on empty or non-JSON
  /// (so a plain-text / HTML body is treated as "not an envelope").
  static dynamic _tryDecode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
