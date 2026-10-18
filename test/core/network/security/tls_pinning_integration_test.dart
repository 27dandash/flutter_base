import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_base/src/core/network/cache/cache_config.dart';
import 'package:flutter_base/src/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tls_fixtures.dart';

/// A refused pin surfaces as `badCertificate` (validateCertificate) or as a
/// failed TLS handshake (badCertificateCallback returned false).
final _certificateRejection = isA<DioException>().having(
  (e) =>
      e.type == DioExceptionType.badCertificate ||
      e.error is HandshakeException ||
      e.error is TlsException,
  'is a certificate rejection',
  isTrue,
);

/// Real TLS handshakes against a local HTTPS server: proves the pins are
/// enforced end to end, not only that the policy object compares strings.
void main() {
  late HttpServer server;
  late int port;

  setUpAll(() async {
    await CacheConfig.init();
    final context = SecurityContext()
      ..useCertificateChainBytes(TlsFixtures.ec.pem.codeUnits)
      ..usePrivateKeyBytes(TlsFixtures.privateKeyPem.codeUnits);
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    port = server.port;
    server.listen((request) {
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"ok":true}')
        ..close();
    });
  });

  tearDownAll(() => server.close(force: true));

  Future<Response<dynamic>> get() =>
      DioClient().dio.get<dynamic>('https://127.0.0.1:$port/ping');

  void pin(List<String> pins, {Set<String> hosts = const {'127.0.0.1'}}) {
    // A fresh adapter per scenario: the HttpClient is cached per adapter.
    DioClient().dio.httpClientAdapter = IOHttpClientAdapter();
    DioClient().enableCertificatePinning(pins, allowedHosts: hosts);
  }

  test('a matching key pin lets the request through', () async {
    pin([
      'spki:${TlsFixtures.ec.spkiBase64}',
      'spki:${TlsFixtures.other.spkiHex}',
    ]);

    final response = await get();

    expect(response.statusCode, 200);
  });

  test('a matching certificate pin lets the request through', () async {
    pin([TlsFixtures.ec.derSha256, TlsFixtures.other.derSha256]);

    expect((await get()).statusCode, 200);
  });

  test('pins of other keys are rejected as a bad certificate', () async {
    pin([
      'spki:${TlsFixtures.other.spkiHex}',
      'spki:${TlsFixtures.rsa.spkiHex}',
    ]);

    await expectLater(get(), throwsA(_certificateRejection));
  });

  test('a pin of the right key is not enough for an unlisted host', () async {
    pin(['spki:${TlsFixtures.ec.spkiHex}'], hosts: const {'api.example.test'});

    await expectLater(get(), throwsA(_certificateRejection));
  });

  test('without pinning a self-signed certificate is refused', () async {
    DioClient().dio.httpClientAdapter = IOHttpClientAdapter();

    await expectLater(get(), throwsA(_certificateRejection));
  });
}
