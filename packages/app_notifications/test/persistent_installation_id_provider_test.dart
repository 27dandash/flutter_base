import 'package:app_notifications/app_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates once and then reuses the persisted installation id', () async {
    String? stored;
    var writes = 0;
    final provider = PersistentInstallationIdProvider(
      read: () async => stored,
      write: (value) async {
        writes++;
        stored = value;
      },
    );

    final first = await provider.getOrCreate();
    final second = await provider.getOrCreate();

    expect(first, second);
    expect(first, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(writes, 1);
  });
}
