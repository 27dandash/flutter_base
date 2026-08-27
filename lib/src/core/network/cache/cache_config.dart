import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

/// Wires `dio_cache_interceptor` to an in-memory `MemCacheStore`.
///
/// We dropped `dio_cache_interceptor_hive_store` (discontinued upstream and
/// incompatible with `hive_ce`). If you need cache to survive an app
/// restart, swap [_store] for a custom `CacheStore` backed by Hive CE,
/// sqflite, or any other persistent backend.
class CacheConfig {
  CacheConfig._();

  /// Caps the cache around ~5 MB (50 000 bytes per entry × 100 entries) — a
  /// reasonable default for screen-level GET responses. Tune per project.
  static const int _maxSize = 5 * 1024 * 1024;
  static const int _maxEntrySize = 50 * 1024;

  static final MemCacheStore _store = MemCacheStore(
    maxSize: _maxSize,
    maxEntrySize: _maxEntrySize,
  );

  /// Retained as an idempotent compatibility hook. The memory store is created
  /// synchronously so Dio can be composed before optional persistence starts.
  static Future<void> init() async {}

  static CacheStore get store => _store;

  /// The global interceptor is deliberately cache-off.
  ///
  /// Caching authenticated responses by URL alone can leak one user's data to
  /// another user after logout/login. Call [requestOptions] explicitly only for
  /// endpoints whose caching semantics are understood.
  static CacheOptions get defaultOptions => CacheOptions(
    store: store,
    policy: CachePolicy.noCache,
    hitCacheOnErrorExcept: const [401, 403],
    priority: CachePriority.normal,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  );

  /// Builds opt-in cache options scoped to a public audience or user session.
  ///
  /// [scope] must be stable for the lifetime of the cached audience, for
  /// example `public` or a non-secret user id. The language header is included
  /// automatically so localized responses never share a cache entry.
  static CacheOptions requestOptions({
    required String scope,
    CachePolicy policy = CachePolicy.refreshForceCache,
    Duration maxStale = const Duration(minutes: 15),
  }) {
    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Must not be empty.');
    }

    return CacheOptions(
      store: store,
      policy: policy,
      hitCacheOnErrorExcept: const [401, 403],
      maxStale: maxStale,
      priority: CachePriority.normal,
      keyBuilder: (RequestOptions request) {
        final locale = request.headers['Accept-Language']?.toString() ?? '';
        final material = '${scope.trim()}|$locale|${request.uri}';
        return sha256.convert(utf8.encode(material)).toString();
      },
      allowPostMethod: false,
    );
  }

  /// Clears every cached response at an authentication/session boundary.
  static Future<void> clearAll() async {
    await _store.clean();
  }
}
