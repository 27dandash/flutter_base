import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_base/src/core/network/security/spki_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tls_fixtures.dart';

String _sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();

void main() {
  group('extractSubjectPublicKeyInfo', () {
    test('matches openssl for an RSA certificate', () {
      final spki = extractSubjectPublicKeyInfo(TlsFixtures.rsa.der);

      expect(spki, isNotNull);
      expect(_sha256Hex(spki!), TlsFixtures.rsa.spkiHex);
    });

    test('matches openssl for an EC certificate', () {
      final spki = extractSubjectPublicKeyInfo(TlsFixtures.ec.der);

      expect(_sha256Hex(spki!), TlsFixtures.ec.spkiHex);
    });

    test('differs between keys and ignores the certificate wrapper', () {
      final a = extractSubjectPublicKeyInfo(TlsFixtures.ec.der)!;
      final b = extractSubjectPublicKeyInfo(TlsFixtures.other.der)!;

      expect(_sha256Hex(a), isNot(_sha256Hex(b)));
      // Whole-certificate hashes differ from the key hash.
      expect(_sha256Hex(TlsFixtures.ec.der), isNot(_sha256Hex(a)));
    });

    test('returns null instead of throwing for malformed input', () {
      final der = TlsFixtures.ec.der;
      expect(extractSubjectPublicKeyInfo(Uint8List(0)), isNull);
      expect(extractSubjectPublicKeyInfo(Uint8List.fromList([0x30])), isNull);
      expect(
        extractSubjectPublicKeyInfo(Uint8List.fromList([1, 2, 3, 4])),
        isNull,
      );
      expect(
        extractSubjectPublicKeyInfo(Uint8List.sublistView(der, 0, 40)),
        isNull,
        reason: 'truncated certificate',
      );
      final corrupted = Uint8List.fromList(der)..[1] = 0xFF;
      expect(extractSubjectPublicKeyInfo(corrupted), isNull);
      // Every prefix must be survivable.
      for (var length = 0; length < der.length; length += 7) {
        expect(
          () => extractSubjectPublicKeyInfo(
            Uint8List.sublistView(der, 0, length),
          ),
          returnsNormally,
        );
      }
    });
  });
}
