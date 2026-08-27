import 'dart:async';
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
}
