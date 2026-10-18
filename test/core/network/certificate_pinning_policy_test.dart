import 'package:flutter_base/src/core/network/security/certificate_pinning_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pin =
      '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

  test('rejects missing and malformed configuration', () {
    expect(
      () => CertificatePinningPolicy(
        fingerprints: const [],
        allowedHosts: const {'api.example.com'},
      ),
      throwsArgumentError,
    );
    expect(
      () => CertificatePinningPolicy(
        fingerprints: const ['0011'],
        allowedHosts: const {'api.example.com'},
      ),
      throwsArgumentError,
    );
  });

  test('accepts only a valid pin for the configured host and date', () {
    final policy = CertificatePinningPolicy(
      fingerprints: const [pin],
      allowedHosts: const {'api.example.com'},
    );
    final now = DateTime.utc(2026, 1, 1);

    expect(
      policy.accepts(
        fingerprint: pin,
        host: 'api.example.com',
        notBefore: DateTime.utc(2025),
        notAfter: DateTime.utc(2027),
        now: now,
      ),
      isTrue,
    );
    expect(
      policy.accepts(
        fingerprint: pin,
        host: 'evil.example.com',
        notBefore: DateTime.utc(2025),
        notAfter: DateTime.utc(2027),
        now: now,
      ),
      isFalse,
    );
    expect(
      policy.accepts(
        fingerprint: List<String>.filled(64, 'f').join(),
        host: 'api.example.com',
        notBefore: DateTime.utc(2025),
        notAfter: DateTime.utc(2027),
        now: now,
      ),
      isFalse,
    );
  });

  test('rejects not-yet-valid and expired certificates', () {
    final policy = CertificatePinningPolicy(
      fingerprints: const [pin],
      allowedHosts: const {'api.example.com'},
    );
    final now = DateTime.utc(2026, 1, 1);

    expect(
      policy.accepts(
        fingerprint: pin,
        host: 'api.example.com',
        notBefore: DateTime.utc(2027),
        notAfter: DateTime.utc(2028),
        now: now,
      ),
      isFalse,
    );
    expect(
      policy.accepts(
        fingerprint: pin,
        host: 'api.example.com',
        notBefore: DateTime.utc(2024),
        notAfter: DateTime.utc(2025),
        now: now,
      ),
      isFalse,
    );
  });

  group('spki pins', () {
    final window = (
      notBefore: DateTime.utc(2025),
      notAfter: DateTime.utc(2027),
      now: DateTime.utc(2026, 1, 1),
    );
    const certificate =
        'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';
    const keyHex =
        '0a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f9';
    // base64 of the 32 bytes above.
    const keyBase64 = 'ChssPU5fYHGCk6S1xtfo+QobLD1OX2BxgpOktcbX6Pk=';

    bool accepts(
      CertificatePinningPolicy policy, {
      String fingerprint = certificate,
      String? spki,
      String host = 'api.example.com',
    }) => policy.accepts(
      fingerprint: fingerprint,
      spkiFingerprint: spki,
      host: host,
      notBefore: window.notBefore,
      notAfter: window.notAfter,
      now: window.now,
    );

    test('hex and base64 spki pins are equivalent', () {
      for (final pin in ['spki:$keyHex', 'spki:$keyBase64', 'SPKI:$keyHex']) {
        final policy = CertificatePinningPolicy(
          fingerprints: [pin],
          allowedHosts: const {'api.example.com'},
        );
        expect(policy.spkiFingerprints, {keyHex}, reason: pin);
        expect(accepts(policy, fingerprint: pin, spki: keyHex), isTrue);
      }
    });

    test('a key pin survives a renewed certificate with the same key', () {
      final policy = CertificatePinningPolicy(
        fingerprints: const ['spki:$keyHex'],
        allowedHosts: const {'api.example.com'},
      );

      expect(accepts(policy, fingerprint: 'a' * 64, spki: keyHex), isTrue);
      expect(accepts(policy, fingerprint: 'a' * 64, spki: 'b' * 64), isFalse);
      expect(accepts(policy, fingerprint: 'a' * 64), isFalse);
    });

    test('a certificate pin and a key pin can be mixed', () {
      final policy = CertificatePinningPolicy(
        fingerprints: const [certificate, 'spki:$keyHex'],
        allowedHosts: const {'api.example.com'},
      );

      expect(accepts(policy), isTrue);
      expect(accepts(policy, fingerprint: 'c' * 64, spki: keyHex), isTrue);
      expect(policy.fingerprints, hasLength(2));
    });

    test('host and validity still apply to a matching key pin', () {
      final policy = CertificatePinningPolicy(
        fingerprints: const ['spki:$keyHex'],
        allowedHosts: const {'api.example.com'},
      );

      expect(accepts(policy, spki: keyHex, host: 'evil.example.com'), isFalse);
      expect(
        policy.accepts(
          fingerprint: certificate,
          spkiFingerprint: keyHex,
          host: 'api.example.com',
          notBefore: DateTime.utc(2027),
          notAfter: DateTime.utc(2028),
          now: window.now,
        ),
        isFalse,
      );
    });

    test('malformed spki pins are rejected', () {
      for (final bad in [
        'spki:',
        'spki:not-base64!!',
        'spki:abcd',
        'spki:${'a' * 63}',
        'spki:QUJD', // base64 of 3 bytes
      ]) {
        expect(
          () => CertificatePinningPolicy(
            fingerprints: [bad],
            allowedHosts: const {'api.example.com'},
          ),
          throwsArgumentError,
          reason: bad,
        );
      }
    });
  });
}
