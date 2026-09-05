// Dio network-layer audit — deterministic, NO real network.
//
// Every response is mocked. Two mocking strategies are used (both sanctioned
// by `package:dio`):
//   * `http_mock_adapter`'s `DioAdapter` — declarative request→reply (see the
//     "http_mock_adapter" test in the status-code group).
//   * a hand-written `HttpClientAdapter` (`_ScriptAdapter` / `_CaptureAdapter`)
//     — used where a test must inspect the OUTGOING request (headers, body
//     bytes), count network hits, or return different replies per attempt.
//
// Tests assert on the user-facing `Failure` TYPE (never `.userMessage`, which
// would require easy_localization to be initialised), mirroring the existing
// suite's convention.
//
// This is a regression suite for the fixes applied to the Dio layer. Each test
// asserts the corrected, user-facing behaviour (all should pass):
//   * S4 — a non-JSON body under a JSON content-type -> clean ParseFailure.
//   * S5 — 401 -> single refresh -> retry (no QueuedInterceptor deadlock).
//   * S7 — queryParameters & asFormData survive digit-normalization; a 401'd
//          multipart upload is retried with a rebuilt (non-empty) body.
//   * S9 — offline replay carries a stable Idempotency-Key.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_base/src/core/network/base/base_remote_source.dart';
import 'package:flutter_base/src/core/network/cache/cache_config.dart';
import 'package:flutter_base/src/core/network/cancel/request_cancellation_manager.dart';
import 'package:flutter_base/src/core/network/dio_client.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/network/http_method.dart';
import 'package:flutter_base/src/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_base/src/core/network/offline/offline_queue_manager.dart';
import 'package:flutter_base/src/core/network/parser/response_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

// ════════════════════════════════════════════════════════════════════
// Test infrastructure
// ════════════════════════════════════════════════════════════════════

/// A Dio configured exactly like `DioClient._baseOptions` so every test sees
/// the same `validateStatus`/timeout/responseType behaviour as production.
Dio _prodDio() => Dio(
  BaseOptions(
    baseUrl: 'https://api.test/',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    responseType: ResponseType.json,
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) => status != null && status < 500,
  ),
);

/// Concrete `BaseRemoteSource` so we can exercise the real `request()` /
/// `safeApiCall()` pipeline with an injected Dio.
class _TestSource extends BaseRemoteSource {
  _TestSource(Dio dio) : super(dio: dio);
}

ResponseBody _json(String body, int code) => ResponseBody.fromString(
  body,
  code,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

ResponseBody _body(String body, int code, String contentType) =>
    ResponseBody.fromString(
      body,
      code,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );

Future<Uint8List> _drain(Stream<Uint8List>? stream) async {
  if (stream == null) return Uint8List(0);
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

/// Programmable adapter: the test supplies a [responder] that decides each
/// reply (or throws a [DioException]). Records every outgoing [RequestOptions]
/// and honours cancellation via the `cancelFuture` Dio passes in.
class _ScriptAdapter implements HttpClientAdapter {
  _ScriptAdapter(this.responder);

  final FutureOr<ResponseBody> Function(
    RequestOptions o,
    Uint8List body,
    int callNumber,
  )
  responder;

  int calls = 0;
  final List<RequestOptions> seen = <RequestOptions>[];

  List<String> get paths => seen.map((o) => o.path).toList();
  int callsForPath(String fragment) =>
      paths.where((p) => p.contains(fragment)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    seen.add(options);
    final body = await _drain(requestStream);
    final response = Future<ResponseBody>.sync(
      () => responder(options, body, calls),
    );
    if (cancelFuture != null) {
      return await Future.any<ResponseBody>([
        response,
        cancelFuture.then<ResponseBody>(
          (_) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          ),
        ),
      ]);
    }
    return await response;
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory mock of the flutter_secure_storage platform channel so the real
/// [TokenStorage] can read/write/clear without a device Keychain.
void _installSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        final args = (call.arguments as Map?) ?? const {};
        switch (call.method) {
          case 'write':
            store[args['key'] as String] = args['value'] as String;
            return null;
          case 'read':
            return store[args['key'] as String];
          case 'delete':
            store.remove(args['key'] as String);
            return null;
          case 'deleteAll':
            store.clear();
            return null;
          case 'readAll':
            return Map<String, String>.from(store);
          case 'containsKey':
            return store.containsKey(args['key'] as String);
        }
        return null;
      });
}

Future<void> _pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

// ════════════════════════════════════════════════════════════════════

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _installSecureStorageMock();

  // ──────────────────────────────────────────────────────────────────
  // S1 — Timeouts
  // ──────────────────────────────────────────────────────────────────
  group('S1 timeouts', () {
    for (final type in const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type maps to a readable TimeoutFailure', () async {
        final dio = _prodDio()
          ..httpClientAdapter = _ScriptAdapter(
            (o, b, n) => throw DioException(requestOptions: o, type: type),
          );
        final result = await _TestSource(dio).request<dynamic>(
          method: HttpMethod.post,
          endpoint: 'thing',
          body: const {'a': 1},
          fromJson: (j) => j,
          cancelKey: 'timeout-$type',
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<TimeoutFailure>()),
          (_) => fail('expected Left(TimeoutFailure)'),
        );
      });
    }
  });

  // ──────────────────────────────────────────────────────────────────
  // S2 — Network / connectivity
  // ──────────────────────────────────────────────────────────────────
  group('S2 connectivity', () {
    test('connectionError(SocketException) -> NetworkFailure', () async {
      final dio = _prodDio()
        ..httpClientAdapter = _ScriptAdapter(
          (o, b, n) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
            error: const SocketException('Failed host lookup'),
          ),
        );
      final result = await _TestSource(dio).request<dynamic>(
        method: HttpMethod.post,
        endpoint: 'thing',
        body: const {},
        fromJson: (j) => j,
        cancelKey: 'net-conn',
      );
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left(NetworkFailure)'),
      );
    });

    test('a raw SocketException is caught (nothing escapes to the UI)', () {
      final failure = ResponseParser.parseUnknownError(
        const SocketException('no route to host'),
      );
      expect(failure, isA<NetworkFailure>());
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // S3 — Status codes (well-formed JSON bodies)
  // ──────────────────────────────────────────────────────────────────
  group('S3 status codes', () {
    const expected = <int, Type>{
      400: ValidationFailure,
      401: UnauthorizedFailure, // no AuthInterceptor here -> clean map
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
      test('HTTP ${entry.key} -> ${entry.value}', () async {
        final dio = _prodDio()
          ..httpClientAdapter = _ScriptAdapter(
            (o, b, n) => _json('{"message":"e"}', entry.key),
          );
        final result = await _TestSource(dio).request<dynamic>(
          method: HttpMethod.get,
          endpoint: 'status/${entry.key}',
          fromJson: (j) => j,
          cancelKey: 'status-${entry.key}',
        );
        expect(result.isLeft(), isTrue, reason: '${entry.key} should be Left');
        result.fold(
          (f) => expect(
            f.runtimeType,
            entry.value,
            reason: '${entry.key} -> ${entry.value}',
          ),
          (_) => fail('expected Left for ${entry.key}'),
        );
      });
    }

    test('(http_mock_adapter) 404 via DioAdapter -> NotFoundFailure', () async {
      final dio = _prodDio();
      final mock = DioAdapter(dio: dio);
      mock.onGet(
        'widgets/1',
        (server) => server.reply(404, {'message': 'gone'}),
      );
      final result = await _TestSource(dio).request<dynamic>(
        method: HttpMethod.get,
        endpoint: 'widgets/1',
        fromJson: (j) => j,
        cancelKey: 'widgets-1',
      );
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('expected Left(NotFoundFailure)'),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // S4 — HTML / non-JSON instead of JSON
  // ──────────────────────────────────────────────────────────────────
  group('S4 html-not-json', () {
    test('HTML (Content-Type: text/html) on 200 -> ParseFailure', () async {
      final dio = _prodDio()
        ..httpClientAdapter = _ScriptAdapter(
          (o, b, n) => _body(
            '<!doctype html><html><body>login</body></html>',
            200,
            'text/html',
          ),
        );
      final result = await _TestSource(dio).request<dynamic>(
        method: HttpMethod.get,
        endpoint: 'portal',
        fromJson: (j) => j,
        cancelKey: 'html-200',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ParseFailure>()),
        (_) => fail('expected Left(ParseFailure)'),
      );
    });

    test('HTML (Content-Type: text/html) on 502 -> ParseFailure', () async {
      final dio = _prodDio()
        ..httpClientAdapter = _ScriptAdapter(
          (o, b, n) => _body(
            '<html><head></head><body>502 Bad Gateway</body></html>',
            502,
            'text/html',
          ),
        );
      final result = await _TestSource(dio).request<dynamic>(
        method: HttpMethod.post,
        endpoint: 'portal',
        body: const {},
        fromJson: (j) => j,
        cancelKey: 'html-502',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ParseFailure>()),
        (_) => fail('expected Left(ParseFailure)'),
      );
    });

    test('HTML mislabelled as Content-Type: application/json -> ParseFailure', () async {
      // The real Cloudflare/WAF case: a challenge/redirect HTML page returned
      // with a JSON content-type. Dio's transformer runs jsonDecode -> throws
      // FormatException BEFORE ResponseParser's _looksLikeHtml guard runs, and
      // parseDioError maps the unknown error to NetworkFailure.
      final dio = _prodDio()
        ..httpClientAdapter = _ScriptAdapter(
          (o, b, n) => _body(
            '<!doctype html><html><body>blocked by WAF</body></html>',
            200,
            'application/json',
          ),
        );
      final result = await _TestSource(dio).request<dynamic>(
        method: HttpMethod.get,
        endpoint: 'data',
        fromJson: (j) => j,
        cancelKey: 'html-json-ct',
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(
          f,
          isA<ParseFailure>(),
          reason:
              'HTML under a JSON content-type must map to ParseFailure '
              '(not a misleading NetworkFailure); got ${f.runtimeType}',
        ),
        (_) => fail('expected Left'),
      );
    });

    test(
      'malformed JSON (Content-Type: application/json) -> ParseFailure',
      () async {
        final dio = _prodDio()
          ..httpClientAdapter = _ScriptAdapter(
            (o, b, n) => _body('<<< truncated >>>', 400, 'application/json'),
          );
        final result = await _TestSource(dio).request<dynamic>(
          method: HttpMethod.get,
          endpoint: 'data',
          fromJson: (j) => j,
          cancelKey: 'malformed-json',
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(
            f,
            isA<ParseFailure>(),
            reason:
                'a malformed/truncated JSON body must map to ParseFailure; '
                'got ${f.runtimeType}',
          ),
          (_) => fail('expected Left'),
        );
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // S5 — Refresh-token flow
  // ──────────────────────────────────────────────────────────────────
  group('S5 refresh-token', () {
    setUp(() async => TokenStorage.instance.clear());
    tearDown(() async => TokenStorage.instance.clear());

    test(
      '401 WITHOUT a refresh token -> clean UnauthorizedFailure (no hang)',
      () async {
        await TokenStorage.instance.save(access: 'old'); // refresh stays null
        final dio = _prodDio()
          ..httpClientAdapter = _ScriptAdapter(
            (o, b, n) => _json('{"message":"unauth"}', 401),
          );
        dio.interceptors.add(
          AuthInterceptor(dio, storage: TokenStorage.instance),
        );

        final result = await _TestSource(dio)
            .request<dynamic>(
              method: HttpMethod.get,
              endpoint: 'me',
              fromJson: (j) => j,
              cancelKey: 'me-no-refresh',
            )
            .timeout(const Duration(seconds: 4));

        result.fold(
          (f) => expect(f, isA<UnauthorizedFailure>()),
          (_) => fail('expected Left(UnauthorizedFailure)'),
        );
      },
    );

    test(
      '401 WITH a refresh token: refresh once, then retry with new token',
      () async {
        await TokenStorage.instance.save(access: 'old', refresh: 'r');
        var refreshCalls = 0;
        final adapter = _ScriptAdapter((o, b, n) {
          if (o.path.contains('refresh-token')) {
            refreshCalls += 1;
            return _json('{"access_token":"new"}', 200);
          }
          if (o.headers['Authorization'] == 'Bearer new') {
            return _json('{"ok":true}', 200);
          }
          return _json('{"message":"unauth"}', 401);
        });
        final dio = _prodDio()..httpClientAdapter = adapter;
        dio.interceptors.add(
          AuthInterceptor(dio, storage: TokenStorage.instance),
        );

        Response<dynamic>? res;
        try {
          res = await dio
              .get<dynamic>(
                'me',
                options: Options(headers: const {'Accept-Language': 'ar'}),
              )
              .timeout(const Duration(seconds: 4));
        } on TimeoutException {
          fail(
            'REGRESSION: the 401→refresh cycle deadlocked again '
            '(refreshCalls=$refreshCalls, totalHits=${adapter.calls}, '
            'paths=${adapter.paths}). AuthInterceptor must stay a plain '
            'Interceptor and refresh on a throwaway Dio so it never hangs.',
          );
        }
        expect(res.statusCode, 200);
        expect(refreshCalls, 1, reason: 'exactly one refresh');
        expect(adapter.callsForPath('me'), 2, reason: 'original + one retry');
        final refreshRequest = adapter.seen.singleWhere(
          (request) => request.path.contains('refresh-token'),
        );
        expect(
          refreshRequest.headers['Accept-Language'],
          'ar',
          reason: 'refresh must preserve the challenged request locale',
        );
        expect(
          adapter.seen
              .where((request) => request.path.contains('me'))
              .map((request) => request.headers['Accept-Language']),
          everyElement('ar'),
          reason: 'the original request and its retry keep the same locale',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'concurrent 401s trigger exactly ONE refresh (single-flight)',
      () async {
        await TokenStorage.instance.save(access: 'old', refresh: 'r');
        var refreshCalls = 0;
        final adapter = _ScriptAdapter((o, b, n) {
          if (o.path.contains('refresh-token')) {
            refreshCalls += 1;
            return _json('{"access_token":"new"}', 200);
          }
          if (o.headers['Authorization'] == 'Bearer new') {
            return _json('{"ok":true}', 200);
          }
          return _json('{"message":"unauth"}', 401);
        });
        final dio = _prodDio()..httpClientAdapter = adapter;
        dio.interceptors.add(
          AuthInterceptor(dio, storage: TokenStorage.instance),
        );

        final results = await Future.wait([
          dio.get<dynamic>('me'),
          dio.get<dynamic>('users'),
          dio.get<dynamic>('products'),
        ]).timeout(const Duration(seconds: 5));

        expect(results.every((r) => r.statusCode == 200), isTrue);
        expect(refreshCalls, 1, reason: '3 concurrent 401s -> 1 refresh');
      },
    );

    test(
      'delayed refresh cannot overwrite or retry under a newer account',
      () async {
        await TokenStorage.instance.save(access: 'old', refresh: 'old-r');
        final refreshStarted = Completer<void>();
        final releaseRefresh = Completer<void>();
        var protectedCalls = 0;
        final adapter = _ScriptAdapter((o, b, n) async {
          if (o.path.contains('refresh-token')) {
            refreshStarted.complete();
            await releaseRefresh.future;
            return _json(
              '{"access_token":"stale-access","refresh_token":"stale-r"}',
              200,
            );
          }
          protectedCalls++;
          return _json('{"message":"unauth"}', 401);
        });
        final dio = _prodDio()..httpClientAdapter = adapter;
        dio.interceptors.add(
          AuthInterceptor(dio, storage: TokenStorage.instance),
        );

        final oldRequest = dio.get<dynamic>('me');
        await refreshStarted.future;
        await TokenStorage.instance.clear();
        await TokenStorage.instance.save(
          access: 'new-account-access',
          refresh: 'new-account-refresh',
        );
        releaseRefresh.complete();

        await expectLater(
          oldRequest,
          throwsA(
            isA<DioException>().having(
              (error) => error.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        expect(TokenStorage.instance.accessToken, 'new-account-access');
        expect(TokenStorage.instance.refreshToken, 'new-account-refresh');
        expect(
          protectedCalls,
          1,
          reason: 'the old request must never retry with the new account',
        );
      },
    );

    test('successful old-session response is cancelled after logout', () async {
      await TokenStorage.instance.save(access: 'old', refresh: 'old-r');
      final requestStarted = Completer<void>();
      final releaseRequest = Completer<void>();
      final adapter = _ScriptAdapter((o, b, n) async {
        requestStarted.complete();
        await releaseRequest.future;
        return _json('{"private":"old-user-data"}', 200);
      });
      final dio = _prodDio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(dio, storage: TokenStorage.instance),
      );

      final oldRequest = dio.get<dynamic>('private-data');
      await requestStarted.future;
      await TokenStorage.instance.clear();
      releaseRequest.complete();

      await expectLater(
        oldRequest,
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // S6 — skipAuth flag
  // ──────────────────────────────────────────────────────────────────
  group('S6 skipAuth', () {
    setUp(() async => TokenStorage.instance.clear());
    tearDown(() async => TokenStorage.instance.clear());

    test('skipAuth:true omits the Authorization header', () async {
      await TokenStorage.instance.save(access: 'tok');
      final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
      final dio = _prodDio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(dio, storage: TokenStorage.instance),
      );

      await _TestSource(dio).request<dynamic>(
        method: HttpMethod.post,
        endpoint: 'login',
        body: const {'email': 'a@b.c'},
        skipAuth: true,
        fromJson: (j) => j,
        cancelKey: 'login',
      );

      expect(adapter.seen.single.headers.containsKey('Authorization'), isFalse);
    });

    test('without skipAuth the Bearer token IS attached', () async {
      await TokenStorage.instance.save(access: 'tok');
      final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
      final dio = _prodDio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(dio, storage: TokenStorage.instance),
      );

      await _TestSource(dio).request<dynamic>(
        method: HttpMethod.get,
        endpoint: 'me',
        fromJson: (j) => j,
        cancelKey: 'me-auth',
      );

      expect(adapter.seen.single.headers['Authorization'], 'Bearer tok');
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // S7 — Query / body / multipart
  // ──────────────────────────────────────────────────────────────────
  group('S7 query/body/multipart', () {
    tearDown(() async => TokenStorage.instance.clear());

    test(
      'queryParameters (default digit-normalization) reaches the network',
      () async {
        // Regression: _normalizeArabicDigits must keep the query map a
        // Map<String,dynamic> so request()'s `as Map<String,dynamic>` cast does
        // not throw before safeApiCall's try/catch.
        final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
        final dio = _prodDio()..httpClientAdapter = adapter;
        try {
          await _TestSource(dio).request<dynamic>(
            method: HttpMethod.get,
            endpoint: 'products',
            queryParameters: const {'page': 1, 'search': 'shoe'},
            fromJson: (j) => j,
            cancelKey: 'q-default',
          );
        } catch (e) {
          fail(
            'request() with queryParameters threw "$e" instead of returning '
            'Either — _normalizeArabicDigits must return Map<String,dynamic>.',
          );
        }
        expect(adapter.seen.single.queryParameters, {
          'page': 1,
          'search': 'shoe',
        });
      },
    );

    test(
      '(control) queryParameters with normalizeArabicDigits:false works',
      () async {
        final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
        final dio = _prodDio()..httpClientAdapter = adapter;
        final result = await _TestSource(dio).request<dynamic>(
          method: HttpMethod.get,
          endpoint: 'products',
          queryParameters: const {'page': 1, 'search': 'shoe'},
          normalizeArabicDigits: false,
          fromJson: (j) => j,
          cancelKey: 'q-off',
        );
        expect(result.isRight(), isTrue);
        expect(adapter.seen.single.queryParameters, {
          'page': 1,
          'search': 'shoe',
        });
      },
    );

    test(
      'request(asFormData:true) sends a multipart body (default normalize)',
      () async {
        // Regression: with the digit-normalization fix the body stays a
        // Map<String,dynamic>, so the asFormData guard passes and FormData.fromMap
        // runs even with the default normalizeArabicDigits:true.
        final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
        final dio = _prodDio()..httpClientAdapter = adapter;
        final result = await _TestSource(dio).request<dynamic>(
          method: HttpMethod.post,
          endpoint: 'upload',
          body: {
            'note': 'avatar',
            'file': MultipartFile.fromBytes(const [1, 2, 3], filename: 'a.bin'),
          },
          asFormData: true,
          fromJson: (j) => j,
          cancelKey: 'upload-default',
        );
        expect(result.isRight(), isTrue);
        expect(
          adapter.callsForPath('upload'),
          1,
          reason: 'upload must reach the network as multipart',
        );
        final contentType = adapter
            .seen
            .single
            .headers[Headers.contentTypeHeader]
            .toString();
        expect(contentType, contains('multipart/form-data'));
      },
    );

    test(
      '(control) asFormData with normalizeArabicDigits:false -> multipart',
      () async {
        final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
        final dio = _prodDio()..httpClientAdapter = adapter;
        await _TestSource(dio).request<dynamic>(
          method: HttpMethod.post,
          endpoint: 'upload',
          body: {
            'note': 'avatar',
            'file': MultipartFile.fromBytes(const [1, 2, 3], filename: 'a.bin'),
          },
          asFormData: true,
          normalizeArabicDigits: false,
          fromJson: (j) => j,
          cancelKey: 'upload-off',
        );
        final contentType = adapter
            .seen
            .single
            .headers[Headers.contentTypeHeader]
            .toString();
        // Boundary is generated by Dio, not hardcoded.
        expect(contentType, contains('multipart/form-data'));
        expect(contentType, contains('boundary'));
      },
    );

    test("a 401'd multipart upload is retried with a rebuilt, non-empty body", () async {
      // The real path: request(asFormData) -> 401 -> AuthInterceptor refresh ->
      // _retry, which must clone the single-use FormData so the replayed upload
      // carries the body (and the user is NOT spuriously logged out).
      await TokenStorage.instance.save(access: 'old', refresh: 'r');
      var firstUploadLen = -1;
      var retryUploadLen = -1;
      final adapter = _ScriptAdapter((o, body, n) {
        if (o.path.contains('refresh-token')) {
          return _json('{"access_token":"new"}', 200);
        }
        if (o.headers['Authorization'] == 'Bearer new') {
          retryUploadLen = body.length; // the retried upload
          return _json('{"ok":true}', 200);
        }
        firstUploadLen = body.length; // the first (401'd) upload
        return _json('{"message":"unauth"}', 401);
      });
      final dio = _prodDio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(dio, storage: TokenStorage.instance),
      );

      final result = await _TestSource(dio)
          .request<dynamic>(
            method: HttpMethod.post,
            endpoint: 'upload',
            body: {
              'note': 'avatar',
              'file': MultipartFile.fromBytes(const [
                1,
                2,
                3,
                4,
                5,
              ], filename: 'a.bin'),
            },
            asFormData: true,
            fromJson: (j) => j,
            cancelKey: 'upload-401',
          )
          .timeout(const Duration(seconds: 5));

      expect(
        result.isRight(),
        isTrue,
        reason: 'upload succeeds after refresh + retry',
      );
      expect(firstUploadLen, greaterThan(0));
      expect(
        retryUploadLen,
        greaterThan(0),
        reason: 'retried multipart body is rebuilt (cloned), not empty',
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // S8 — Cancellation
  // ──────────────────────────────────────────────────────────────────
  group('S8 cancellation', () {
    test('a cancelled request -> CancelledFailure (silent UI no-op)', () async {
      final adapter = _ScriptAdapter(
        (o, b, n) => Completer<ResponseBody>().future, // never resolves itself
      );
      final dio = _prodDio()..httpClientAdapter = adapter;
      final source = _TestSource(dio);
      final manager = RequestCancellationManager();

      final future = source.request<dynamic>(
        method: HttpMethod.get,
        endpoint: 'slow',
        fromJson: (j) => j,
        cancelKey: 'cancel-solo',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      manager.cancel('cancel-solo');

      final result = await future.timeout(const Duration(seconds: 4));
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CancelledFailure>()),
        (_) => fail('expected Left(CancelledFailure)'),
      );
    });

    test('cancelling one request does not cancel an unrelated one', () async {
      final adapter = _ScriptAdapter((o, b, n) {
        if (o.path.contains('slow')) {
          return Completer<ResponseBody>().future;
        }
        return _json('{"ok":true}', 200);
      });
      final dio = _prodDio()..httpClientAdapter = adapter;
      final source = _TestSource(dio);
      final manager = RequestCancellationManager();

      final slow = source.request<dynamic>(
        method: HttpMethod.get,
        endpoint: 'slow',
        fromJson: (j) => j,
        cancelKey: 'cancel-A',
      );
      final keep = await source
          .request<dynamic>(
            method: HttpMethod.get,
            endpoint: 'keep',
            fromJson: (j) => j,
            cancelKey: 'cancel-B',
          )
          .timeout(const Duration(seconds: 4));
      expect(keep.isRight(), isTrue, reason: 'unrelated request succeeds');

      manager.cancel('cancel-A');
      final slowResult = await slow.timeout(const Duration(seconds: 4));
      slowResult.fold(
        (f) => expect(f, isA<CancelledFailure>()),
        (_) => fail('expected the cancelled one to be CancelledFailure'),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // S9 — Offline queue
  // ──────────────────────────────────────────────────────────────────
  group('S9 offline queue', () {
    late _ScriptAdapter counting;

    setUpAll(() async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      // connectivity_plus method channel -> always "wifi".
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => call.method == 'check' ? <String>['wifi'] : null,
      );
      // connectivity_plus event channel -> open, emit nothing.
      messenger.setMockStreamHandler(
        const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
        MockStreamHandler.inline(onListen: (args, sink) {}),
      );

      final dir = await Directory.systemTemp.createTemp('hive_offline_audit');
      Hive.init(dir.path);
      await CacheConfig.init();

      counting = _ScriptAdapter((o, b, n) => _json('{"id":1}', 200));
      DioClient().dio.httpClientAdapter = counting;

      await OfflineQueueManager().init(encryptionKey: Hive.generateSecureKey());
      OfflineQueueManager().activateOwnerScope('test-user');
    });

    setUp(() async => OfflineQueueManager().clearAll());

    test('an offline op is replayed exactly once then removed', () async {
      final before = counting.callsForPath('products');
      await OfflineQueueManager().enqueue(
        endpoint: 'products',
        method: 'POST',
        body: const {'name': 'x'},
        ownerScope: 'test-user',
      );
      await _pumpUntil(() => OfflineQueueManager().pendingCount == 0);

      expect(
        OfflineQueueManager().pendingCount,
        0,
        reason: 'op removed after a successful replay',
      );
      expect(
        counting.callsForPath('products') - before,
        1,
        reason: 'replayed exactly once',
      );
    });

    test(
      'replayed non-idempotent op carries a stable Idempotency-Key',
      () async {
        final op = await OfflineQueueManager().enqueue(
          endpoint: 'orders',
          method: 'POST',
          body: const {'sku': 'A1'},
          ownerScope: 'test-user',
        );
        await _pumpUntil(() => OfflineQueueManager().pendingCount == 0);

        final replay = counting.seen.lastWhere(
          (o) => o.path.contains('orders'),
        );
        final headers = <String, dynamic>{
          for (final e in replay.headers.entries) e.key.toLowerCase(): e.value,
        };
        expect(
          headers['idempotency-key'],
          op.id,
          reason:
              'offline replay must send a stable Idempotency-Key (the op id) so a '
              'lost-response retry cannot create a duplicate write',
        );
      },
    );

    test(
      'owner switch cancels in-flight replay and never starts the next op',
      () async {
        final firstStarted = Completer<void>();
        final releaseFirst = Completer<void>();
        final delayed = _ScriptAdapter((o, b, n) async {
          if (!firstStarted.isCompleted) firstStarted.complete();
          await releaseFirst.future;
          return _json('{"id":1}', 200);
        });
        var staleSuccessCallback = false;
        final manager = OfflineQueueManager();
        manager.activateOwnerScope(null);
        await manager.enqueue(
          endpoint: 'owner-a/first',
          method: 'POST',
          ownerScope: 'owner-a',
        );
        await manager.enqueue(
          endpoint: 'owner-a/second',
          method: 'POST',
          ownerScope: 'owner-a',
        );
        DioClient().dio.httpClientAdapter = delayed;
        manager.onOperationSucceeded = (_, _) => staleSuccessCallback = true;

        manager.activateOwnerScope('owner-a');
        await firstStarted.future.timeout(const Duration(seconds: 5));
        manager.activateOwnerScope(null);
        await manager.clearPending();
        manager.activateOwnerScope('owner-b');
        releaseFirst.complete();
        await _pumpUntil(() => manager.pendingCount == 0);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(delayed.calls, 1);
        expect(staleSuccessCallback, isFalse);

        manager.onOperationSucceeded = null;
        DioClient().dio.httpClientAdapter = counting;
        manager.activateOwnerScope('test-user');
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // S10 — Interceptor structure
  // ──────────────────────────────────────────────────────────────────
  group('S10 interceptor structure', () {
    test(
      'an interceptor that never calls a handler hangs the request',
      () async {
        // Guard test: proves a missing next/resolve/reject = infinite hang, so
        // the audit's claim that every real interceptor path calls a handler is
        // a meaningful one.
        final dio = _prodDio()
          ..httpClientAdapter = _ScriptAdapter(
            (o, b, n) => _json('{"ok":true}', 200),
          );
        dio.interceptors.add(_BlackHoleInterceptor());

        await expectLater(
          dio.get<dynamic>('x').timeout(const Duration(seconds: 2)),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('a well-behaved request interceptor always forwards', () async {
      final adapter = _ScriptAdapter((o, b, n) => _json('{"ok":true}', 200));
      final dio = _prodDio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            o.headers['X-Test'] = '1';
            h.next(o);
          },
        ),
      );
      final res = await dio
          .get<dynamic>('x')
          .timeout(const Duration(seconds: 3));
      expect(res.statusCode, 200);
      expect(adapter.seen.single.headers['X-Test'], '1');
    });
  });
}

// ════════════════════════════════════════════════════════════════════
// Helper interceptor for the S10 structure test
// ════════════════════════════════════════════════════════════════════

/// Swallows every request without calling a handler — models the scenario-10
/// failure mode (a missing next/resolve/reject hangs the request forever).
class _BlackHoleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Intentionally never calls handler.next/resolve/reject.
  }
}
