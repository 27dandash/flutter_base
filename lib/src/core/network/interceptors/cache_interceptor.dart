import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

import '../cache/cache_config.dart';

/// Thin wrapper around Dio's in-memory cache interceptor.
///
/// The global policy is cache-off. Individual safe GET requests opt in through
/// `CacheConfig.requestOptions(...).toExtra()`.
class AppCacheInterceptor {
  AppCacheInterceptor._();

  static Interceptor build() {
    return DioCacheInterceptor(options: CacheConfig.defaultOptions);
  }
}
