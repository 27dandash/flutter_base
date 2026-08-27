import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_base/src/core/network/base/base_remote_source.dart';
import 'package:flutter_base/src/core/network/cancel/request_cancellation_manager.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/http_method.dart';
import 'package:flutter_base/src/core/network/interceptors/retry_interceptor.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _LocalApiServer server;

  setUpAll(() async {
    server = await _LocalApiServer.start();
  });

  tearDownAll(() => server.close());

  test('real socket handles JSON, empty, content type and redirects', () async {
    final source = _LiveSource(_client(server.baseUrl));

    final json = await source.get('/json');
    expect(json.fold((_) => null, (value) => value), {'value': 42});

    final empty = await source.get('/empty');
    expect(empty.isRight(), isTrue);

    final textJson = await source.get('/text-json');
    expect(textJson.fold((_) => null, (value) => value), {
      'value': 'text-content-type',
    });

    final redirect = await source.get('/redirect');
    expect(redirect.fold((_) => null, (value) => value), {'value': 42});
  });

  test('real status responses map to typed failures', () async {
    final source = _LiveSource(_client(server.baseUrl));
    final expected = <int, Type>{
      400: ValidationFailure,
      401: UnauthorizedFailure,
      403: PermissionFailure,
      404: NotFoundFailure,
      409: ConflictFailure,
      422: ValidationFailure,
      429: RateLimitFailure,
      500: ServerFailure,
      502: ServerFailure,
      503: MaintenanceFailure,
    };

    for (final entry in expected.entries) {
      final result = await source.get('/status/${entry.key}');
      result.fold((failure) {
        expect(failure.runtimeType, entry.value, reason: 'HTTP ${entry.key}');
        expect(failure.userMessage, isNot('raw backend detail ${entry.key}'));
      }, (_) => fail('HTTP ${entry.key} unexpectedly succeeded'));
    }
  });

  test('malformed JSON and large/slow streams are controlled', () async {
    final source = _LiveSource(_client(server.baseUrl));
    final malformed = await source.get('/malformed');
    expect(
      malformed.fold((failure) => failure, (_) => null),
      isA<ParseFailure>(),
    );

    final large = await source.get('/large');
    expect(
      large.fold((_) => -1, (value) => (value['payload'] as String).length),
      256 * 1024,
    );

    final streamed = await source.get('/stream');
    expect(streamed.fold((_) => null, (value) => value['done']), isTrue);
  });

  test(
    'timeouts, refusal and cancellation use silent typed failures',
    () async {
      final timeoutClient = _client(
        server.baseUrl,
        receiveTimeout: const Duration(milliseconds: 40),
      );
      final timedOut = await _LiveSource(timeoutClient).get('/slow');
      expect(
        timedOut.fold((failure) => failure, (_) => null),
        isA<TimeoutFailure>(),
      );

      final manager = RequestCancellationManager();
      final cancellable = _LiveSource(
        _client(server.baseUrl),
        manager: manager,
      );
      final pending = cancellable.get('/slow', cancelKey: 'live-cancel');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      manager.cancel('live-cancel');
      final cancelled = await pending;
      final cancellation = cancelled.fold((failure) => failure, (_) => null);
      expect(cancellation, isA<CancelledFailure>());
      expect(cancellation!.userMessage, isEmpty);

      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final refusedPort = socket.port;
      await socket.close();
      final refused = await _LiveSource(
        _client('http://127.0.0.1:$refusedPort'),
      ).get('/refused');
      expect(
        refused.fold((failure) => failure, (_) => null),
        isA<NetworkFailure>(),
      );
    },
  );

  test('retry is idempotent and unsafe mutation is not replayed', () async {
    server.resetCounters();
    final dio = _client(server.baseUrl);
    // The interceptor replays through the same configured client.
    dio.interceptors.add(
      RetryInterceptor(dio, maxRetries: 1, baseDelay: Duration.zero),
    );
    final source = _LiveSource(dio);

    final get = await source.get('/retry');
    expect(get.fold((_) => null, (value) => value['attempt']), 2);
    expect(server.retryGets, 2);

    final post = await source.post('/retry');
    expect(post.isLeft(), isTrue);
    expect(server.retryPosts, 1);
  });

  test('concurrency and multipart cross the real HTTP adapter', () async {
    final source = _LiveSource(_client(server.baseUrl));
    final results = await Future.wait([
      source.get('/json', cancelKey: 'concurrent-a'),
      source.get('/json', cancelKey: 'concurrent-b'),
    ]);
    expect(results.every((result) => result.isRight()), isTrue);

    final upload = await source.multipart('/multipart');
    expect(upload.fold((_) => null, (value) => value['multipart']), isTrue);
    expect(
      upload.fold((_) => 0, (value) => value['bytes'] as int),
      greaterThan(0),
    );
  });
}

Dio _client(String baseUrl, {Duration? receiveTimeout}) => Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(milliseconds: 500),
    sendTimeout: const Duration(milliseconds: 500),
    receiveTimeout: receiveTimeout ?? const Duration(milliseconds: 800),
    responseType: ResponseType.json,
    headers: const {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  ),
);

class _LiveSource extends BaseRemoteSource {
  _LiveSource(Dio dio, {RequestCancellationManager? manager})
    : super(dio: dio, cancelManager: manager);

  Future<Either<Failure, dynamic>> get(String path, {String? cancelKey}) =>
      request<dynamic>(
        method: HttpMethod.get,
        endpoint: path,
        fromJson: (value) => value,
        cancelKey: cancelKey,
      );

  Future<Either<Failure, dynamic>> post(String path) => request<dynamic>(
    method: HttpMethod.post,
    endpoint: path,
    body: const {'mutation': true},
    fromJson: (value) => value,
  );

  Future<Either<Failure, dynamic>> multipart(String path) => request<dynamic>(
    method: HttpMethod.post,
    endpoint: path,
    asFormData: true,
    body: {'name': 'runtime', 'file': MultipartFile.fromString('payload')},
    fromJson: (value) => value,
  );
}

class _LocalApiServer {
  _LocalApiServer._(this._server);

  final HttpServer _server;
  int retryGets = 0;
  int retryPosts = 0;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_LocalApiServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final api = _LocalApiServer._(server);
    unawaited(api._serve());
    return api;
  }

  void resetCounters() {
    retryGets = 0;
    retryPosts = 0;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final request in _server) {
      await _handle(request);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path == '/redirect') {
      await request.response.redirect(Uri.parse('$baseUrl/json'));
      return;
    }
    if (path == '/empty') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }
    if (path == '/malformed') {
      request.response.headers.contentType = ContentType.json;
      request.response.write('{broken');
      await request.response.close();
      return;
    }
    if (path == '/slow') {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await _json(request.response, {'slow': true});
      return;
    }
    if (path == '/stream') {
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"done":');
      await request.response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      request.response.write('true}');
      await request.response.close();
      return;
    }
    if (path == '/large') {
      await _json(request.response, {
        'payload': List<String>.filled(256 * 1024, 'x').join(),
      });
      return;
    }
    if (path == '/text-json') {
      request.response.headers.contentType = ContentType.text;
      request.response.write('{"value":"text-content-type"}');
      await request.response.close();
      return;
    }
    if (path == '/multipart') {
      final body = await utf8.decoder.bind(request).join();
      await _json(request.response, {
        'multipart':
            request.headers.contentType?.mimeType == 'multipart/form-data',
        'bytes': body.length,
      });
      return;
    }
    if (path == '/retry') {
      final isGet = request.method == 'GET';
      final attempt = isGet ? ++retryGets : ++retryPosts;
      if (attempt == 1) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        await _json(request.response, {'message': 'temporary'});
      } else {
        await _json(request.response, {'attempt': attempt});
      }
      return;
    }
    if (path.startsWith('/status/')) {
      final status = int.parse(path.split('/').last);
      request.response.statusCode = status;
      await _json(request.response, {
        'message': 'raw backend detail $status',
        if (status == 422)
          'data': {
            'items': {
              'email': ['raw field detail'],
            },
          },
      });
      return;
    }
    await _json(request.response, {'value': 42});
  }

  Future<void> _json(HttpResponse response, Object value) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(value));
    await response.close();
  }
}
