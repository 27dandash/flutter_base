/// HTTP verbs supported by [BaseRemoteSource.request].
///
/// We use a typed enum instead of raw strings so a misspelled `'GET'` /
/// `'gat'` becomes a compile-time error.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete;

  /// Upper-case wire value Dio expects in `Options.method`.
  String get value => name.toUpperCase();
}
