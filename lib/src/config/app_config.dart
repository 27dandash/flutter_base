/// App-wide compile-time configuration flags.
///
/// Values are `String.fromEnvironment`-style constants seeded by
/// `--dart-define`, mirroring the `API_BASE_URL` idiom in [ApiEndpoints].
/// Because they are `const`, every `if (AppConfig.flag)` guard is a
/// compile-time branch the Dart/AOT compiler can tree-shake when the flag is
/// off — so an opt-in feature adds zero runtime cost (and zero behavior) to
/// builds that do not enable it.
class AppConfig {
  AppConfig._();

  /// Custom-PHP response mode. **On by default** — this app's backend signals
  /// every request's logical outcome through a `key` inside the JSON envelope
  /// (`success` / `needActive` / `blocked` / …), not the HTTP status code
  /// (`needActive` ships as HTTP 203, which the status-code path would otherwise
  /// read as success). See `PhpEnvelope` / `PhpResponseKeys`.
  ///
  /// Bodies without a recognized `key` fall through to the unchanged
  /// status-code handling, so non-envelope endpoints are unaffected. Disable
  /// for a pure status-code backend with:
  /// ```bash
  /// flutter run --dart-define=PHP_RESPONSE_MODE=false
  /// ```
  static const bool phpResponseMode = bool.fromEnvironment(
    'PHP_RESPONSE_MODE',
    defaultValue: true,
  );

  /// Comma-separated leaf-certificate SHA-256 fingerprints. Production must
  /// provide at least a primary and a backup/next certificate pin.
  static const String tlsSha256Pins = String.fromEnvironment('TLS_SHA256_PINS');

  static List<String> get tlsPins => tlsSha256Pins
      .split(',')
      .map((pin) => pin.trim())
      .where((pin) => pin.isNotEmpty)
      .toList(growable: false);
}
