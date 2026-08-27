final class CertificatePinningPolicy {
  CertificatePinningPolicy({
    required Iterable<String> fingerprints,
    required Iterable<String> allowedHosts,
  }) : fingerprints = fingerprints.map(normalizeFingerprint).toSet(),
       allowedHosts = allowedHosts
           .map((host) => host.trim().toLowerCase())
           .where((host) => host.isNotEmpty)
           .toSet() {
    if (this.fingerprints.isEmpty) {
      throw ArgumentError('At least one SHA-256 fingerprint is required.');
    }
    if (this.fingerprints.any(
      (pin) => !RegExp(r'^[0-9a-f]{64}$').hasMatch(pin),
    )) {
      throw ArgumentError('Every TLS pin must be a 64-character SHA-256 hex.');
    }
    if (this.allowedHosts.isEmpty) {
      throw ArgumentError('At least one pinned host is required.');
    }
  }

  final Set<String> fingerprints;
  final Set<String> allowedHosts;

  static String normalizeFingerprint(String value) =>
      value.replaceAll(':', '').trim().toLowerCase();

  bool accepts({
    required String fingerprint,
    required String host,
    required DateTime notBefore,
    required DateTime notAfter,
    DateTime? now,
  }) {
    final instant = now ?? DateTime.now();
    return allowedHosts.contains(host.trim().toLowerCase()) &&
        !instant.isBefore(notBefore) &&
        !instant.isAfter(notAfter) &&
        fingerprints.contains(normalizeFingerprint(fingerprint));
  }
}
