import 'dart:convert';

import 'package:cryptography/cryptography.dart';

final class OfflineQueueCipher {
  OfflineQueueCipher(List<int> key)
    : _secretKey = SecretKey(key),
      _algorithm = AesGcm.with256bits() {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', 'must contain 32 bytes');
    }
  }

  final SecretKey _secretKey;
  final AesGcm _algorithm;

  Future<String> encrypt(
    Map<String, dynamic> value, {
    required String ownerScope,
  }) async {
    if (ownerScope.trim().isEmpty) {
      throw ArgumentError.value(ownerScope, 'ownerScope', 'must not be empty');
    }
    final box = await _algorithm.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: _secretKey,
      aad: utf8.encode(ownerScope),
    );
    return jsonEncode({
      'version': 1,
      'ownerScope': ownerScope,
      'nonce': base64UrlEncode(box.nonce),
      'cipherText': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    });
  }

  Future<Map<String, dynamic>> decrypt(String encoded) async {
    final envelope = jsonDecode(encoded);
    if (envelope is! Map || envelope['version'] != 1) {
      throw const FormatException('Unsupported offline queue envelope.');
    }
    final ownerScope = envelope['ownerScope'];
    if (ownerScope is! String || ownerScope.trim().isEmpty) {
      throw const FormatException('Missing offline queue owner scope.');
    }
    final box = SecretBox(
      base64Url.decode(envelope['cipherText']! as String),
      nonce: base64Url.decode(envelope['nonce']! as String),
      mac: Mac(base64Url.decode(envelope['mac']! as String)),
    );
    final clear = await _algorithm.decrypt(
      box,
      secretKey: _secretKey,
      aad: utf8.encode(ownerScope),
    );
    final value = jsonDecode(utf8.decode(clear));
    if (value is! Map) {
      throw const FormatException('Invalid offline queue record.');
    }
    return Map<String, dynamic>.from(value);
  }

  String ownerScopeOf(String encoded) {
    final envelope = jsonDecode(encoded);
    if (envelope is! Map || envelope['ownerScope'] is! String) {
      throw const FormatException('Missing offline queue owner scope.');
    }
    return envelope['ownerScope']! as String;
  }
}
