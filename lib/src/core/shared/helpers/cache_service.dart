import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key/value store. The only storage primitive the app uses
/// at rest — `shared_preferences` was intentionally removed because the
/// product handles tokens and user data that must be encrypted on disk.
///
/// Values are always `String`s. Serialize maps/lists yourself with
/// `jsonEncode` / `jsonDecode` before/after read.
class SecureStorage {
  SecureStorage._();

  // EncryptedSharedPreferences was deprecated upstream (Jetpack Security
  // discontinued by Google). flutter_secure_storage v10+ encrypts via custom
  // ciphers automatically, so no Android `encryptedSharedPreferences` flag is
  // needed. On iOS we pin the Keychain accessibility class explicitly so
  // secrets are only readable after the device's first unlock.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Underlying storage exposed for advanced callers (e.g. tests that
  /// inject a custom implementation). Prefer the `read`/`write` helpers.
  static FlutterSecureStorage get raw => _storage;

  // ── Core ────────────────────────────────────────────────────────

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> deleteAll() => _storage.deleteAll();

  // ── Conveniences ────────────────────────────────────────────────

  /// True when [key] has a value (any non-null string, including empty).
  static Future<bool> contains(String key) => _storage.containsKey(key: key);

  /// One-shot batch write — fewer await boundaries than calling [write]
  /// in a loop.
  static Future<void> writeAll(Map<String, String> entries) async {
    await Future.wait(
      entries.entries.map((e) => _storage.write(key: e.key, value: e.value)),
    );
  }

  static Future<void> deleteAllKeys(Iterable<String> keys) async {
    await Future.wait(keys.map((k) => _storage.delete(key: k)));
  }
}
