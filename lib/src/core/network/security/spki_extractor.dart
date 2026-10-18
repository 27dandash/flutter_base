import 'dart:typed_data';

/// Extracts the DER-encoded `SubjectPublicKeyInfo` from a DER X.509
/// certificate, or `null` when [certificate] is not a well-formed certificate.
///
/// `dart:io` exposes only the whole certificate (`X509Certificate.der`), but
/// pinning the public key survives certificate renewal as long as the key pair
/// is reused, which a pin on the whole certificate does not.
///
/// ```text
/// Certificate  ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signature }
/// tbsCertificate ::= SEQUENCE {
///   [0] version (optional), serialNumber, signature, issuer, validity,
///   subject, subjectPublicKeyInfo, ... }
/// ```
Uint8List? extractSubjectPublicKeyInfo(Uint8List certificate) {
  try {
    final certificateSeq = _read(certificate, 0, certificate.length);
    if (certificateSeq == null || certificateSeq.tag != _sequence) return null;
    final tbs = _read(
      certificate,
      certificateSeq.contentStart,
      certificateSeq.end,
    );
    if (tbs == null || tbs.tag != _sequence) return null;

    var offset = tbs.contentStart;
    final first = _read(certificate, offset, tbs.end);
    if (first == null) return null;
    // Optional explicit [0] version.
    if (first.tag == 0xA0) offset = first.end;

    // serialNumber, signature, issuer, validity, subject
    for (var i = 0; i < 5; i++) {
      final element = _read(certificate, offset, tbs.end);
      if (element == null) return null;
      offset = element.end;
    }
    final spki = _read(certificate, offset, tbs.end);
    if (spki == null || spki.tag != _sequence) return null;
    return Uint8List.sublistView(certificate, spki.start, spki.end);
  } on RangeError {
    return null;
  }
}

const int _sequence = 0x30;

final class _Tlv {
  const _Tlv(this.tag, this.start, this.contentStart, this.end);

  final int tag;
  final int start;
  final int contentStart;
  final int end;
}

/// Reads one DER element at [offset]; `null` when it is truncated, uses an
/// indefinite length or a multi-byte tag (none occur on the path walked above).
_Tlv? _read(Uint8List bytes, int offset, int limit) {
  if (offset + 2 > limit) return null;
  final tag = bytes[offset];
  if (tag & 0x1F == 0x1F) return null; // high-tag-number form

  var cursor = offset + 1;
  final first = bytes[cursor++];
  int length;
  if (first < 0x80) {
    length = first;
  } else {
    final count = first & 0x7F;
    if (count == 0 || count > 4 || cursor + count > limit) return null;
    length = 0;
    for (var i = 0; i < count; i++) {
      length = (length << 8) | bytes[cursor++];
    }
  }
  final end = cursor + length;
  if (end > limit || end < cursor) return null;
  return _Tlv(tag, offset, cursor, end);
}
