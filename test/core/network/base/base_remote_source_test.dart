import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_base/src/core/network/base/base_remote_source.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/http_method.dart';
import 'package:flutter_base/src/core/network/options/request_extra.dart';
import 'package:flutter_base/src/core/session/session_failure_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a fixed JSON [body] with HTTP 200 (the custom PHP backend signals
/// outcome through the envelope `key`, not the status code).
class _EnvelopeAdapter implements HttpClientAdapter {
  _EnvelopeAdapter(this.body);
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Stamps the auth-failure ownership marker on every request so we can prove
/// how `BaseRemoteSource` honors (or ignores) it per failure type.
class _StampingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[RequestExtra.authFailureHandled] = true;
    handler.next(options);
  }
}

class _TestRemoteSource extends BaseRemoteSource {
  _TestRemoteSource(Dio dio) : super(dio: dio);

  Future<Either<Failure, Unit>> get(String endpoint) => request<Unit>(
    method: HttpMethod.get,
    endpoint: endpoint,
    fromJson: (_) => unit,
  );
}

_TestRemoteSource _sourceReturning(String body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com/'));
  dio.httpClientAdapter = _EnvelopeAdapter(body);
  dio.interceptors.add(_StampingInterceptor());
  return _TestRemoteSource(dio);
}

void main() {
  final coordinator = SessionFailureCoordinator.instance;

  tearDown(() {
    coordinator.onUnauthorized = null;
    coordinator.onBlocked = null;
    coordinator.onNeedsActivation = null;
  });

  test('marker suppresses a duplicate unauthorized transition', () async {
    var unauthorized = 0;
    coordinator.onUnauthorized = () async => unauthorized++;

    final source = _sourceReturning('{"key":"unauthenticated","msg":"x"}');
    final result = await source.get('/protected');

    result.fold(
      (failure) => expect(failure, isA<UnauthorizedFailure>()),
      (_) => fail('expected a failure'),
    );
    // AuthInterceptor already owns this transition ⇒ coordinator stays silent.
    expect(unauthorized, 0);
  });

  test('marker never suppresses a blocked transition', () async {
    var blocked = 0;
    coordinator.onBlocked = (_) async => blocked++;

    final source = _sourceReturning('{"key":"blocked","msg":"x"}');
    final result = await source.get('/protected');

    result.fold(
      (failure) => expect(failure, isA<BlockedFailure>()),
      (_) => fail('expected a failure'),
    );
    // A retained marker must not swallow a blocked transition.
    expect(blocked, 1);
  });

  test('marker never suppresses a needs-activation transition', () async {
    var needsActivation = 0;
    coordinator.onNeedsActivation = (_, _) async => needsActivation++;

    final source = _sourceReturning('{"key":"needActive","msg":"x"}');
    final result = await source.get('/protected');

    result.fold(
      (failure) => expect(failure, isA<NeedActiveFailure>()),
      (_) => fail('expected a failure'),
    );
    expect(needsActivation, 1);
  });
}
