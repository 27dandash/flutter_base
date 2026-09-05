import 'dart:convert';

import 'package:flutter_base/src/core/network/offline/offline_queue_cipher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cipher = OfflineQueueCipher(List<int>.generate(32, (index) => index));

  test('AES-GCM round trip authenticates the owner scope', () async {
    final encrypted = await cipher.encrypt(const {
      'endpoint': 'orders',
      'body': {'value': 1},
    }, ownerScope: 'user-a');

    expect(await cipher.decrypt(encrypted), {
      'endpoint': 'orders',
      'body': {'value': 1},
    });
    expect(cipher.ownerScopeOf(encrypted), 'user-a');
  });

  test('uses a unique nonce for every record', () async {
    final first = jsonDecode(
      await cipher.encrypt(const {'id': 1}, ownerScope: 'user-a'),
    ) as Map;
    final second = jsonDecode(
      await cipher.encrypt(const {'id': 1}, ownerScope: 'user-a'),
    ) as Map;

    expect(first['nonce'], isNot(second['nonce']));
  });

  test('rejects corrupted ciphertext and authentication tags', () async {
    final encoded = await cipher.encrypt(const {'id': 1}, ownerScope: 'user-a');
    final envelope = jsonDecode(encoded) as Map<String, dynamic>;
    envelope['mac'] = base64UrlEncode(List<int>.filled(16, 0));

    expect(() => cipher.decrypt(jsonEncode(envelope)), throwsA(anything));
  });

  test('rejects an encrypted record relabelled to another owner', () async {
    final encoded = await cipher.encrypt(const {'id': 1}, ownerScope: 'user-a');
    final envelope = jsonDecode(encoded) as Map<String, dynamic>;
    envelope['ownerScope'] = 'user-b';

    await expectLater(cipher.decrypt(jsonEncode(envelope)), throwsA(anything));
  });

  test('rejects truncated and legacy records', () async {
    expect(() => cipher.decrypt('{"version":1}'), throwsA(anything));
    expect(() => cipher.decrypt('{"version":0}'), throwsFormatException);
  });
}
