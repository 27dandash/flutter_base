import 'package:dio/dio.dart';

/// Owns a registry of active CancelTokens keyed by an arbitrary string
/// (e.g. "search:products" or "GET:/users/5"). Allows callers to cancel
/// older in-flight requests when issuing a new one.
///
/// A request releases the key **by token identity**: a request that was
/// superseded must not remove the token of the request that replaced it,
/// otherwise the newer request could no longer be cancelled (for example by
/// [cancelAll] at logout) or superseded by a later one.
class RequestCancellationManager {
  RequestCancellationManager._();
  static final RequestCancellationManager _instance =
      RequestCancellationManager._();
  factory RequestCancellationManager() => _instance;

  final Map<String, _Entry> _entries = {};

  CancelToken getToken(String key, {bool cancelPrevious = true}) {
    final existing = _entries[key];
    if (cancelPrevious) {
      _entries.remove(key);
      if (existing != null && !existing.token.isCancelled) {
        existing.token.cancel('superseded:$key');
      }
    } else if (existing != null && !existing.token.isCancelled) {
      // Callers share the in-flight token; it is released by the last one.
      existing.users++;
      return existing.token;
    }
    final entry = _Entry(CancelToken());
    _entries[key] = entry;
    return entry.token;
  }

  /// Releases one user of [token] for [key]. Without a [token] the key is
  /// cleared unconditionally (legacy behavior). A stale [token] — one that
  /// has already been replaced for [key] — is ignored.
  void release(String key, [CancelToken? token]) {
    final entry = _entries[key];
    if (entry == null) return;
    if (token == null) {
      _entries.remove(key);
      return;
    }
    if (!identical(entry.token, token)) return;
    entry.users--;
    if (entry.users <= 0) _entries.remove(key);
  }

  void cancel(String key, [String? reason]) {
    final entry = _entries.remove(key);
    if (entry != null && !entry.token.isCancelled) {
      entry.token.cancel(reason ?? 'cancelled:$key');
    }
  }

  void cancelAll([String? reason]) {
    final entries = List.of(_entries.values);
    _entries.clear();
    for (final entry in entries) {
      if (!entry.token.isCancelled) entry.token.cancel(reason ?? 'cancelAll');
    }
  }

  bool isActive(String key) {
    final entry = _entries[key];
    return entry != null && !entry.token.isCancelled;
  }

  int get activeCount => _entries.length;
}

final class _Entry {
  _Entry(this.token);

  final CancelToken token;
  int users = 1;
}
