import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_base/src/config/app_config.dart';
import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_base/src/core/network/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _prodDio() => Dio(
  BaseOptions(
    baseUrl: 'https://api.test/',
    responseType: ResponseType.json,
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) => status != null && status < 500,
  ),
);

ResponseBody _json(String body, int code) => ResponseBody.fromString(
  body,
  code,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
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

class _ScriptAdapter implements HttpClientAdapter {
  _ScriptAdapter(this.responder);
  final FutureOr<ResponseBody> Function(RequestOptions o, int n) responder;
  int calls = 0;
  final List<RequestOptions> seen = <RequestOptions>[];
  int callsForPath(String fragment) =>
      seen.where((o) => o.path.contains(fragment)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    seen.add(options);
    await _drain(requestStream);
    return responder(options, calls);
  }

  @override
  void close({bool force = false}) {}
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _installSecureStorageMock();

  group(
    'PHP-mode AuthInterceptor (unauthenticated key)',
    () {
      setUp(() async => TokenStorage.instance.clear());
      tearDown(() async => TokenStorage.instance.clear());

      test(
        '200 {key:unauthenticated} -> one refresh -> retry with new token',
        () async {
          await TokenStorage.instance.save(access: 'old', refresh: 'r');
          var refreshCalls = 0;
          final adapter = _ScriptAdapter((o, n) {
            if (o.path.contains('refresh-token')) {
              refreshCalls += 1;
              return _json(
                '{"key":"success","data":{"access_token":"new","refresh_token":"r2"}}',
                200,
              );
            }
            if (o.headers['Authorization'] == 'Bearer new') {
              return _json('{"key":"success","data":{"ok":true}}', 200);
            }
            return _json('{"key":"unauthenticated","msg":"expired"}', 200);
          });
          final dio = _prodDio()..httpClientAdapter = adapter;
          dio.interceptors.add(
            AuthInterceptor(dio, storage: TokenStorage.instance),
          );

          final res = await dio
              .get<dynamic>('me')
              .timeout(const Duration(seconds: 4));

          expect(res.statusCode, 200);
          expect(refreshCalls, 1, reason: 'exactly one refresh');
          expect(adapter.callsForPath('me'), 2, reason: 'original + one retry');
          expect(TokenStorage.instance.accessToken, 'new');
        },
      );

      test(
        'retry still unauthenticated -> one refresh, no infinite loop',
        () async {
          await TokenStorage.instance.save(access: 'old', refresh: 'r');
          var refreshCalls = 0;
          final adapter = _ScriptAdapter((o, n) {
            if (o.path.contains('refresh-token')) {
              refreshCalls += 1;
              return _json(
                '{"key":"success","data":{"access_token":"new"}}',
                200,
              );
            }
            return _json('{"key":"unauthenticated"}', 200);
          });
          final dio = _prodDio()..httpClientAdapter = adapter;
          dio.interceptors.add(
            AuthInterceptor(dio, storage: TokenStorage.instance),
          );

          final res = await dio
              .get<dynamic>('me')
              .timeout(const Duration(seconds: 4));

          expect(res.statusCode, 200);
          expect(
            refreshCalls,
            1,
            reason: 'retried request must NOT re-refresh',
          );
          expect(
            adapter.callsForPath('me'),
            2,
            reason: 'original + exactly one retry (no loop)',
          );
        },
      );

      test(
        'concurrent unauthenticated 200s trigger exactly ONE refresh',
        () async {
          await TokenStorage.instance.save(access: 'old', refresh: 'r');
          var refreshCalls = 0;
          final adapter = _ScriptAdapter((o, n) {
            if (o.path.contains('refresh-token')) {
              refreshCalls += 1;
              return _json(
                '{"key":"success","data":{"access_token":"new"}}',
                200,
              );
            }
            if (o.headers['Authorization'] == 'Bearer new') {
              return _json('{"key":"success","data":{"ok":true}}', 200);
            }
            return _json('{"key":"unauthenticated"}', 200);
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
          expect(
            refreshCalls,
            1,
            reason: '3 concurrent unauthenticated -> single-flight 1 refresh',
          );
        },
      );
    },
    skip: AppConfig.phpResponseMode
        ? false
        : 'PHP mode off in this build — run with '
              '--dart-define=PHP_RESPONSE_MODE=true',
  );
}
