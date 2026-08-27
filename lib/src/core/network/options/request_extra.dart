/// Public keys used in Dio's `Options.extra` map.
///
/// Interceptors look these up at runtime to alter their behaviour for a
/// single request (e.g. skip auth on login/register, mark a payload as
/// idempotent so the retry interceptor can re-send it, …).
///
/// Keep them in one place so they never drift between callers and
/// interceptors.
class RequestExtra {
  RequestExtra._();

  /// When `true`, [AuthInterceptor] will NOT attach a `Bearer` token to
  /// this request. Use on public endpoints — login, register, the public
  /// catalog, base-URL bootstrap, etc.
  static const String skipAuth = 'skipAuth';

  /// Internal flag used by [AuthInterceptor] to avoid retrying the same
  /// request twice after a 401 → refresh-token cycle. Not meant for
  /// callers — exposed for documentation only.
  static const String retried = '__auth_retried';
}
