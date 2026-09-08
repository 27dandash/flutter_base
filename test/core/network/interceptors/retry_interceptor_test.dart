import 'dart:async';
import 'dart:io' show HttpDate;
import 'dart:typed_data';

import 'package:flutter_base/src/core/network/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how many times a request actually hits the network and always
/// replies with [statusCode].
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.statusCode);
  final int statusCode;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_CountingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com/'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(dio, maxRetries: 2, baseDelay: Duration.zero),
  );
  return dio;
}

/// Replies with [statusCode] and an optional `Retry-After` header, counting
/// each network hit so tests can assert retry behaviour.
class _RetryAfterAdapter implements HttpClientAdapter {
  _RetryAfterAdapter(this.statusCode, {this.retryAfter});
  final int statusCode;
  final String? retryAfter;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (retryAfter != null) 'retry-after': [retryAfter!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Wires a [RetryInterceptor] with a fake clock so honored delays are asserted
/// without real waiting. [maxRetryAfterDelay] defaults high so valid headers
/// are honored unless a test overrides it. When [accept4xx] is set the client
/// treats 4xx as a normal response (mirroring the production `validateStatus`),
/// so a 429 flows through `onResponse` instead of `onError`.
Dio _dioWithClock(
  _RetryAfterAdapter adapter,
  List<Duration> recordedDelays, {
  Duration maxRetryAfterDelay = const Duration(seconds: 300),
  Duration baseDelay = const Duration(seconds: 2),
  bool accept4xx = false,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.com/',
      validateStatus: accept4xx
          ? (status) => status != null && status < 500
          : null,
    ),
  );
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(
      dio,
      maxRetries: 2,
      baseDelay: baseDelay,
      maxRetryAfterDelay: maxRetryAfterDelay,
      sleep: (delay) async => recordedDelays.add(delay),
    ),
  );
  return dio;
}

void main() {
  group('RetryInterceptor', () {
    test('GET on 503 is retried (1 + maxRetries attempts)', () async {
      final adapter = _CountingAdapter(503);
      final dio = _dioWith(adapter);
      try {
        await dio.get('/things');
      } on DioException catch (_) {}
      expect(adapter.calls, 3); // initial + 2 retries
    });

    test('POST on 503 is NOT retried (single attempt)', () async {
      final adapter = _CountingAdapter(503);
      final dio = _dioWith(adapter);
      try {
        await dio.post('/things', data: {'a': 1});
      } on DioException catch (_) {}
      expect(adapter.calls, 1);
    });

    test('PUT and DELETE are not retried either', () async {
      final putAdapter = _CountingAdapter(503);
      final putDio = _dioWith(putAdapter);
      try {
        await putDio.put('/things/1', data: {'a': 1});
      } on DioException catch (_) {}
      expect(putAdapter.calls, 1);

      final delAdapter = _CountingAdapter(503);
      final delDio = _dioWith(delAdapter);
      try {
        await delDio.delete('/things/1');
      } on DioException catch (_) {}
      expect(delAdapter.calls, 1);
    });

    test('GET on 200 is not retried', () async {
      final adapter = _CountingAdapter(200);
      final dio = _dioWith(adapter);
      await dio.get('/things');
      expect(adapter.calls, 1);
    });
  });

  group('RetryInterceptor Retry-After', () {
    test('honors a valid delta-seconds header on 503 (GET)', () async {
      final adapter = _RetryAfterAdapter(503, retryAfter: '1');
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays);
      try {
        await dio.get('/things');
      } on DioException catch (_) {}

      expect(adapter.calls, 3); // initial + 2 retries
      expect(delays, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    });

    test('honors a valid delta-seconds header on 429 (GET)', () async {
      final adapter = _RetryAfterAdapter(429, retryAfter: '2');
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays);
      try {
        await dio.get('/things');
      } on DioException catch (_) {}

      expect(adapter.calls, 3);
      expect(delays, [const Duration(seconds: 2), const Duration(seconds: 2)]);
    });

    test('honors a valid HTTP-date header (GET)', () async {
      final when = HttpDate.format(
        DateTime.now().add(const Duration(seconds: 5)),
      );
      final adapter = _RetryAfterAdapter(503, retryAfter: when);
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays);
      try {
        await dio.get('/things');
      } on DioException catch (_) {}

      expect(adapter.calls, 3);
      // ~5s in the future; allow slack for clock drift during the test.
      expect(delays.first, greaterThan(Duration.zero));
      expect(delays.first, lessThanOrEqualTo(const Duration(seconds: 6)));
    });

    test('falls back to exponential backoff for an invalid header', () async {
      final adapter = _RetryAfterAdapter(503, retryAfter: 'not-a-date');
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays);
      try {
        await dio.get('/things');
      } on DioException catch (_) {}

      expect(adapter.calls, 3);
      expect(delays, [const Duration(seconds: 2), const Duration(seconds: 4)]);
    });

    test(
      'falls back to exponential backoff for negative delta-seconds',
      () async {
        final adapter = _RetryAfterAdapter(503, retryAfter: '-1');
        final delays = <Duration>[];
        final dio = _dioWithClock(adapter, delays);
        try {
          await dio.get('/things');
        } on DioException catch (_) {}

        expect(adapter.calls, 3);
        expect(delays, [
          const Duration(seconds: 2),
          const Duration(seconds: 4),
        ]);
      },
    );

    test(
      'refuses to retry when the requested wait exceeds the ceiling',
      () async {
        final adapter = _RetryAfterAdapter(503, retryAfter: '3600');
        final delays = <Duration>[];
        final dio = _dioWithClock(
          adapter,
          delays,
          maxRetryAfterDelay: const Duration(seconds: 30),
        );
        try {
          await dio.get('/things');
        } on DioException catch (_) {}

        // Original response surfaces; no early retry, no wait.
        expect(adapter.calls, 1);
        expect(delays, isEmpty);
      },
    );

    test('never retries a non-idempotent POST despite Retry-After', () async {
      final adapter = _RetryAfterAdapter(503, retryAfter: '1');
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays);
      try {
        await dio.post('/things', data: {'a': 1});
      } on DioException catch (_) {}

      expect(adapter.calls, 1);
      expect(delays, isEmpty);
    });

    test('honors Retry-After through the onResponse path (429, GET)', () async {
      // With validateStatus accepting 4xx (as in production), a 429 arrives as
      // a Response, so retry is driven by onResponse rather than onError.
      final adapter = _RetryAfterAdapter(429, retryAfter: '1');
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays, accept4xx: true);

      final res = await dio.get('/things');

      expect(res.statusCode, 429); // exhausted retries surface the 429
      expect(adapter.calls, 3);
      expect(delays, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    });

    test('clamps a past HTTP-date to an immediate retry', () async {
      final past = HttpDate.format(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final adapter = _RetryAfterAdapter(503, retryAfter: past);
      final delays = <Duration>[];
      final dio = _dioWithClock(adapter, delays);
      try {
        await dio.get('/things');
      } on DioException catch (_) {}

      expect(adapter.calls, 3);
      expect(delays, [Duration.zero, Duration.zero]);
    });
  });
}
