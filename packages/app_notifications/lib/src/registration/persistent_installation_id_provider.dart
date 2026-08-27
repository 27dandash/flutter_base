import 'dart:math';

import 'device_registration.dart';

typedef InstallationIdReader = Future<String?> Function();
typedef InstallationIdWriter = Future<void> Function(String value);

/// Storage-agnostic installation-id implementation. A consuming product
/// supplies secure-storage callbacks; the generated UUID is never an FCM token
/// and must be sent under an explicitly named `installationId` field.
final class PersistentInstallationIdProvider implements InstallationIdProvider {
  PersistentInstallationIdProvider({required this.read, required this.write});

  final InstallationIdReader read;
  final InstallationIdWriter write;
  Future<String>? _inFlight;

  @override
  Future<String> getOrCreate() {
    return _inFlight ??= _loadOrCreate().whenComplete(() => _inFlight = null);
  }

  Future<String> _loadOrCreate() async {
    final stored = (await read())?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    final generated = _uuidV4();
    await write(generated);
    return generated;
  }

  static String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
