import 'package:dio/dio.dart';

/// Retries **idempotent** failures with exponential backoff (2s, 4s, 8s).
///
/// Only `GET`, `HEAD` and `OPTIONS` are retried — replaying a `POST`/`PUT`/
/// `PATCH`/`DELETE` that the server may have already processed would cause
/// duplicate writes (double charges, duplicate sign-ups, …).
///
/// Retries on: connect/receive/send timeout, connection errors, and the
/// transient status codes 408, 429, 500, 502, 503, 504.
///
/// The retry re-issues the request through the **shared** [Dio] instance so
/// it passes through the full interceptor chain again (auth, locale,
/// logging, …). Re-entrancy is bounded by [maxRetries] via a per-request
/// counter stored in `RequestOptions.extra`.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 2),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _retryCountKey = '__retry_count';
  static const _retryableStatus = {408, 429, 500, 502, 503, 504};
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  bool _isIdempotent(RequestOptions req) =>
      _idempotentMethods.contains(req.method.toUpperCase());

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final code = response.statusCode ?? 0;
    if (!_retryableStatus.contains(code)) return handler.next(response);

    final req = response.requestOptions;
    if (!_isIdempotent(req)) return handler.next(response);

    final count = (req.extra[_retryCountKey] as int?) ?? 0;
    if (count >= maxRetries) return handler.next(response);

    req.extra[_retryCountKey] = count + 1;
    await Future.delayed(baseDelay * (1 << count));

    try {
      final res = await _dio.fetch(req);
      return handler.resolve(res);
    } catch (_) {
      return handler.next(response);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) return handler.next(err);

    final req = err.requestOptions;
    final count = (req.extra[_retryCountKey] as int?) ?? 0;
    if (count >= maxRetries) return handler.next(err);

    req.extra[_retryCountKey] = count + 1;
    await Future.delayed(baseDelay * (1 << count)); // 2s, 4s, 8s

    try {
      final res = await _dio.fetch(req);
      return handler.resolve(res);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  bool _isRetryable(DioException err) {
    if (!_isIdempotent(err.requestOptions)) return false;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return _retryableStatus.contains(code);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
