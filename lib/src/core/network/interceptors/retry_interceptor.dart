import 'dart:io' show HttpDate;

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
/// ## `Retry-After`
///
/// For a `429`/`503` response that carries a standards-compatible
/// [`Retry-After`](https://httpwg.org/specs/rfc9110.html#field.retry-after)
/// header — either delta-seconds (`Retry-After: 30`) or an HTTP-date
/// (`Retry-After: Wed, 21 Oct 2026 07:28:00 GMT`) — the server-requested delay
/// is honored **for idempotent requests only**. Missing, malformed, or
/// negative values fall back to the exponential schedule.
///
/// The automatic wait is bounded by [maxRetryAfterDelay]. A valid request that
/// asks for a longer wait is **not** retried early: the original response/error
/// is surfaced so the caller decides, and the client never blocks for an
/// attacker-influenced or unbounded duration.
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
    this.maxRetryAfterDelay = const Duration(seconds: 30),
    Future<void> Function(Duration delay)? sleep,
  }) : _sleep = sleep ?? _defaultSleep;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  /// Upper bound on how long an honored `Retry-After` may make the client
  /// wait automatically. A valid header asking for more surfaces the original
  /// response instead of retrying earlier than the server requested.
  final Duration maxRetryAfterDelay;

  /// Indirection over `Future.delayed` so tests assert timing deterministically
  /// without real waits. Production uses the real clock.
  final Future<void> Function(Duration delay) _sleep;

  static Future<void> _defaultSleep(Duration delay) =>
      Future<void>.delayed(delay);

  static const _retryCountKey = '__retry_count';
  static const _retryableStatus = {408, 429, 500, 502, 503, 504};
  static const _retryAfterStatus = {429, 503};
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

    final delay = _delayFor(count, response);
    // Server asked to wait longer than we auto-wait: don't retry early.
    if (delay == null) return handler.next(response);

    req.extra[_retryCountKey] = count + 1;
    await _sleep(delay);

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

    final delay = _delayFor(count, err.response);
    // Server asked to wait longer than we auto-wait: don't retry early.
    if (delay == null) return handler.next(err);

    req.extra[_retryCountKey] = count + 1;
    await _sleep(delay);

    try {
      final res = await _dio.fetch(req);
      return handler.resolve(res);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  /// Resolves the wait before the next attempt.
  ///
  /// Returns the honored `Retry-After` delay when the response supplies a
  /// valid one within [maxRetryAfterDelay], the exponential fallback when no
  /// usable header is present, or `null` when a valid header requests a wait
  /// beyond the ceiling (signalling "surface, do not retry").
  Duration? _delayFor(int count, Response? response) {
    final requested = _retryAfter(response);
    if (requested == null) return baseDelay * (1 << count);
    if (requested > maxRetryAfterDelay) return null;
    return requested;
  }

  /// Parses a standards-compatible `Retry-After` from a `429`/`503` response.
  /// Returns `null` for any other status, a missing header, or a malformed or
  /// negative value so the caller falls back to exponential backoff.
  Duration? _retryAfter(Response? response) {
    if (response == null) return null;
    if (!_retryAfterStatus.contains(response.statusCode ?? 0)) return null;

    final raw = response.headers.value('retry-after')?.trim();
    if (raw == null || raw.isEmpty) return null;

    // delta-seconds form (e.g. "120").
    final seconds = int.tryParse(raw);
    if (seconds != null) {
      return seconds < 0 ? null : Duration(seconds: seconds);
    }

    // HTTP-date form (e.g. "Wed, 21 Oct 2026 07:28:00 GMT").
    try {
      final until = HttpDate.parse(raw);
      final delta = until.difference(DateTime.now());
      return delta.isNegative ? Duration.zero : delta;
    } catch (_) {
      return null;
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
