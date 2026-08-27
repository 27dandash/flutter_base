import 'package:dio/dio.dart';

/// Owns a registry of active CancelTokens keyed by an arbitrary string
/// (e.g. "search:products" or "GET:/users/5"). Allows callers to cancel
/// older in-flight requests when issuing a new one.
class RequestCancellationManager {
  RequestCancellationManager._();
  static final RequestCancellationManager _instance =
      RequestCancellationManager._();
  factory RequestCancellationManager() => _instance;

  final Map<String, CancelToken> _tokens = {};

  CancelToken getToken(String key, {bool cancelPrevious = true}) {
    if (cancelPrevious) {
      final old = _tokens.remove(key);
      if (old != null && !old.isCancelled) {
        old.cancel('superseded:$key');
      }
    } else if (_tokens.containsKey(key)) {
      final existing = _tokens[key]!;
      if (!existing.isCancelled) return existing;
    }
    final token = CancelToken();
    _tokens[key] = token;
    return token;
  }

  void release(String key) {
    _tokens.remove(key);
  }

  void cancel(String key, [String? reason]) {
    final t = _tokens.remove(key);
    if (t != null && !t.isCancelled) t.cancel(reason ?? 'cancelled:$key');
  }

  void cancelAll([String? reason]) {
    for (final t in _tokens.values) {
      if (!t.isCancelled) t.cancel(reason ?? 'cancelAll');
    }
    _tokens.clear();
  }

  bool isActive(String key) {
    final t = _tokens[key];
    return t != null && !t.isCancelled;
  }

  int get activeCount => _tokens.length;
}
