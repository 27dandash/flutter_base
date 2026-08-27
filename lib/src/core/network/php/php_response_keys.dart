/// Field names and logical key values used by the custom PHP backend's
/// response envelope.
///
/// Single source of truth shared by [PhpEnvelope] (the recognizer used in
/// `ResponseParser`) and `AuthInterceptor` (which peeks for `unauthenticated`),
/// so the two classifiers can never drift apart.
///
/// The envelope shape:
/// ```json
/// { "key": "success", "msg": "...", "data": { ... }, "count_notifications": 3 }
/// ```
class PhpResponseKeys {
  PhpResponseKeys._();

  // ── Envelope field names ──────────────────────────────────────────
  static const String key = 'key';
  static const String msg = 'msg';
  static const String data = 'data';
  static const String countNotifications = 'count_notifications';

  // ── Logical key values ────────────────────────────────────────────
  /// Operation succeeded; may carry `data`.
  static const String success = 'success';

  /// Logical / business failure or validation error (invalid coupon,
  /// insufficient balance, wrong verification code, ...). Message in `msg`.
  static const String fail = 'fail';

  /// User exists but the account/phone is not activated; usually carries
  /// `data` used to send an activation code.
  static const String needActive = 'needActive';

  /// User is blocked; the server already invalidated the session.
  static const String blocked = 'blocked';

  /// Not logged in, or the token is invalid/expired.
  static const String unauthenticated = 'unauthenticated';

  /// Logged in but not permitted to perform this operation.
  static const String unauthorized = 'unauthorized';

  /// An API exception occurred; `data` carries developer-only `{line, file}`.
  static const String exception = 'exception';

  /// Every recognized logical state. [PhpEnvelope.tryFrom] only treats a body
  /// as an envelope when its `key` is in this set.
  static const Set<String> known = {
    success,
    fail,
    needActive,
    blocked,
    unauthenticated,
    unauthorized,
    exception,
  };
}
