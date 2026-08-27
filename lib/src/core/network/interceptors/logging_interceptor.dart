import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only network diagnostics that deliberately exclude URLs, query
/// parameters, headers, bodies and exception messages.
///
/// Those values routinely contain credentials or personal data. Detailed
/// payload logging belongs in an explicitly configured, redacting development
/// adapter rather than in the production base.
class LoggingInterceptor {
  LoggingInterceptor._();

  static Interceptor build() => _SafeDebugLoggingInterceptor();
}

class _SafeDebugLoggingInterceptor extends Interceptor {
  static const _startedAtKey = '_safe_log_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    if (kDebugMode) {
      debugPrint('HTTP request ${options.method}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        'HTTP response ${response.requestOptions.method} '
        '${response.statusCode ?? 'unknown'} '
        '(${_elapsed(response.requestOptions)} ms)',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        'HTTP failure ${error.requestOptions.method} '
        '${error.type.name} ${error.response?.statusCode ?? 'no-status'} '
        '(${_elapsed(error.requestOptions)} ms)',
      );
    }
    handler.next(error);
  }

  int _elapsed(RequestOptions options) {
    final startedAt = options.extra.remove(_startedAtKey);
    return startedAt is DateTime
        ? DateTime.now().difference(startedAt).inMilliseconds
        : 0;
  }
}
