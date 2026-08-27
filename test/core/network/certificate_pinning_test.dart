import 'package:flutter_base/src/core/network/cache/cache_config.dart';
import 'package:flutter_base/src/core/network/dio_client.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(CacheConfig.init);

  test('certificate pinning rejects an empty allow-list', () {
    expect(
      () => DioClient().enableCertificatePinning(const <String>[]),
      throwsArgumentError,
    );
  });

  test('certificate pinning installs leaf-certificate validation', () {
    DioClient().enableCertificatePinning(const <String>[
      '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff',
    ]);

    final adapter = DioClient().dio.httpClientAdapter as IOHttpClientAdapter;

    expect(adapter.createHttpClient, isNotNull);
    expect(adapter.validateCertificate, isNotNull);
    expect(adapter.validateCertificate!(null, 'api.example.com', 443), isFalse);
  });
}
