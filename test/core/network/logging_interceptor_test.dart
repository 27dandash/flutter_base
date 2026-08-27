import 'package:flutter_base/src/core/network/interceptors/logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"token":"response-secret"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('debug diagnostics never contain URL, headers, or bodies', () async {
    final messages = <String>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previous);

    final dio = Dio()
      ..httpClientAdapter = _SuccessAdapter()
      ..interceptors.add(LoggingInterceptor.build());
    await dio.post<dynamic>(
      'https://private.example/users/42?api_key=query-secret',
      data: const {'password': 'body-secret'},
      options: Options(
        headers: const {'Authorization': 'Bearer header-secret'},
      ),
    );

    final output = messages.join('\n');
    expect(output, contains('HTTP request POST'));
    expect(output, contains('HTTP response POST 200'));
    for (final secret in const [
      'private.example',
      '/users/42',
      'query-secret',
      'body-secret',
      'header-secret',
      'response-secret',
      'Authorization',
    ]) {
      expect(output, isNot(contains(secret)));
    }
  });
}
