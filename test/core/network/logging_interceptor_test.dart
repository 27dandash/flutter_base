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
      '{"token":"response-secret","name":"Visible Name"}',
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
  test(
    'request is red, response is green, credentials never printed',
    () async {
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
        data: const {'password': 'body-secret', 'city': 'Riyadh'},
        options: Options(
          headers: const {'Authorization': 'Bearer header-secret'},
        ),
      );

      final output = messages.join('\n');
      expect(output, contains('HTTP request POST /users/42'));
      expect(output, contains('HTTP response POST /users/42 200'));
      // Request lines are red, response lines are green.
      expect(
        messages.firstWhere((m) => m.contains('HTTP request')),
        startsWith('\u001b[31m'),
      );
      expect(
        messages.firstWhere((m) => m.contains('HTTP response')),
        startsWith('\u001b[32m'),
      );
      // Non-sensitive data is visible for debugging.
      expect(output, contains('Riyadh'));
      expect(output, contains('Visible Name'));
      for (final secret in const [
        'private.example',
        'body-secret',
        'header-secret',
        'response-secret',
        'Authorization',
      ]) {
        expect(output, isNot(contains(secret)));
      }
      // Credential-like keys are printed as <redacted>.
      expect(output, contains('<redacted>'));
    },
  );
}
