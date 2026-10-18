import 'dart:convert';

/// Decides whether a presented server certificate matches a configured pin.
///
/// A pin is one of:
///
/// * **64 hex characters** (colons allowed): SHA-256 of the whole DER
///   certificate. It changes whenever the certificate is renewed or re-issued.
/// * **`spki:` + 64 hex characters or the base64 of 32 bytes**: SHA-256 of the
///   certificate's `SubjectPublicKeyInfo` (what `openssl x509 -pubkey | openssl
///   pkey -pubin -outform DER | openssl dgst -sha256` prints). It stays valid
///   across renewals that reuse the key pair, so it is the recommended form for
///   certificates that rotate automatically; always also pin a backup key.
final class CertificatePinningPolicy {
  CertificatePinningPolicy({
    required Iterable<String> fingerprints,
    required Iterable<String> allowedHosts,
  }) : allowedHosts = allowedHosts
           .map((host) => host.trim().toLowerCase())
           .where((host) => host.isNotEmpty)
           .toSet(),
       certificateFingerprints = <String>{},
       spkiFingerprints = <String>{} {
    for (final raw in fingerprints) {
      final pin = raw.trim();
      if (pin.toLowerCase().startsWith(_spkiPrefix)) {
        spkiFingerprints.add(_parseSpki(pin.substring(_spkiPrefix.length)));
      } else {
        certificateFingerprints.add(_parseCertificate(pin));
      }
    }
    if (certificateFingerprints.isEmpty && spkiFingerprints.isEmpty) {
      throw ArgumentError('At least one SHA-256 fingerprint is required.');
    }
    if (this.allowedHosts.isEmpty) {
      throw ArgumentError('At least one pinned host is required.');
    }
  }

  static const String _spkiPrefix = 'spki:';
  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');

  /// SHA-256 of the whole DER certificate, lowercase hex.
  final Set<String> certificateFingerprints;

  /// SHA-256 of the SubjectPublicKeyInfo, lowercase hex.
  final Set<String> spkiFingerprints;
  final Set<String> allowedHosts;

  /// All pins as the hex digests they are compared as (kept for callers that
  /// only care how many pins are configured).
  Set<String> get fingerprints => {
    ...certificateFingerprints,
    ...spkiFingerprints,
  };

  static String normalizeFingerprint(String value) =>
      value.replaceAll(':', '').trim().toLowerCase();

  static String _parseCertificate(String raw) {
    final pin = normalizeFingerprint(raw);
    if (!_hex64.hasMatch(pin)) {
      throw ArgumentError('Every TLS pin must be a 64-character SHA-256 hex.');
    }
    return pin;
  }

  static String _parseSpki(String raw) {
    final value = raw.trim();
    final asHex = normalizeFingerprint(value);
    if (_hex64.hasMatch(asHex)) return asHex;
    try {
      final bytes = base64.decode(base64.normalize(value));
      if (bytes.length == 32) {
        return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }
    } on FormatException {
      // fall through
    }
    throw ArgumentError(
      'A spki: pin must be 64 hex characters or the base64 of a SHA-256.',
    );
  }

  /// [fingerprint] is the SHA-256 of the whole certificate and
  /// [spkiFingerprint] the SHA-256 of its public key info (`null` when it could
  /// not be extracted). Either matching a configured pin is enough, provided
  /// the host is allowed and the certificate is within its validity period.
  bool accepts({
    required String fingerprint,
    String? spkiFingerprint,
    required String host,
    required DateTime notBefore,
    required DateTime notAfter,
    DateTime? now,
  }) {
    final instant = now ?? DateTime.now();
    if (!allowedHosts.contains(host.trim().toLowerCase())) return false;
    if (instant.isBefore(notBefore) || instant.isAfter(notAfter)) return false;
    if (certificateFingerprints.contains(normalizeFingerprint(fingerprint))) {
      return true;
    }
    return spkiFingerprint != null &&
        spkiFingerprints.contains(normalizeFingerprint(spkiFingerprint));
  }
}
