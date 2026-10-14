import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_base/src/core/network/base/base_remote_source.dart';
import 'package:flutter_base/src/core/network/cancel/request_cancellation_manager.dart';
import 'package:flutter_base/src/core/network/http_method.dart';
import 'package:flutter_test/flutter_test.dart';

final class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _Source extends BaseRemoteSource {
  _Source(Dio dio)
    : super(dio: dio, cancelManager: RequestCancellationManager());

  Future<void> post(Map<String, dynamic> body, {bool normalize = true}) =>
      request<Object?>(
        method: HttpMethod.post,
        endpoint: 'submit',
        body: body,
        queryParameters: {'q': '٣٤'},
        fromJson: (json) => json,
        normalizeArabicDigits: normalize,
      );
}

void main() {
  late _CapturingAdapter adapter;
  late _Source source;

  setUp(() {
    adapter = _CapturingAdapter();
    source = _Source(
      Dio(BaseOptions(baseUrl: 'https://example.test/'))
        ..httpClientAdapter = adapter,
    );
  });

  test('digits are normalized in ordinary fields and in the query', () async {
    await source.post({
      'phone': '٠٥٠١٢٣٤٥٦٧',
      'nested': {'otp': '١٢٣٤'},
      'list': ['٥', '٦'],
      'count': 3,
    });

    final data = adapter.last!.data as Map;
    expect(data['phone'], '0501234567');
    expect((data['nested'] as Map)['otp'], '1234');
    expect(data['list'], ['5', '6']);
    expect(data['count'], 3);
    expect(adapter.last!.queryParameters['q'], '34');
  });

  test('password values reach the backend exactly as typed', () async {
    await source.post({
      'password': 'Pass١٢٣!',
      'password_confirmation': 'Pass١٢٣!',
      'current_password': 'Old٤٥٦!',
      'new_password': 'New٧٨٩!',
      'phone': '٠٥٠',
    });

    final data = adapter.last!.data as Map;
    expect(data['password'], 'Pass١٢٣!');
    expect(data['password_confirmation'], 'Pass١٢٣!');
    expect(data['current_password'], 'Old٤٥٦!');
    expect(data['new_password'], 'New٧٨٩!');
    expect(data['phone'], '050');
  });

  test('normalization can still be switched off', () async {
    await source.post({'phone': '٠٥٠'}, normalize: false);

    expect((adapter.last!.data as Map)['phone'], '٠٥٠');
    expect(adapter.last!.queryParameters['q'], '٣٤');
  });
}
