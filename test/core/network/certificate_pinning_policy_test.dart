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
}
