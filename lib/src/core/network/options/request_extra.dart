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

  /// Internal generation captured when an authenticated request starts.
  /// Responses from an older generation are cancelled after logout/account
  /// switching so old-user data cannot enter the new session.
  static const String authSessionGeneration = '__auth_session_generation';

  /// Ownership marker set by [AuthInterceptor] once it has driven the
  /// session-termination callback for a request whose token refresh failed.
  ///
  /// The interceptor owns the session transition for that failed-refresh flow;
  /// the marker tells `BaseRemoteSource` not to invoke
  /// `SessionFailureCoordinator` a second time for the same 401, so a single
  /// failed refresh triggers termination/cleanup/navigation at most once.
  /// Internal — not meant for callers.
  static const String authFailureHandled = '__auth_failure_handled';
}
