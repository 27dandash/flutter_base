import '../../shared/helpers/cache_service.dart';

/// Source of truth for the user's access + refresh tokens.
///
/// Two layers:
///   - **In-memory cache** — read on every Dio request via the
///     `AuthInterceptor`, so we keep it sync.
///   - **Encrypted disk** — backed by [SecureStorage] so tokens survive
///     an app restart. Call [init] once during bootstrap to hydrate the
///     in-memory cache from disk.
///
/// All writes go to both layers atomically so the in-memory side is
/// never stale.
///
/// Registered manually as a lazy singleton in `setUpGeneralDependencies()`
/// that simply returns [instance], so DI lookups (`injector<TokenStorage>()`)
/// and the static accessor (`TokenStorage.instance`) resolve to the **same**
/// object. This guarantees the in-memory cache hydrated in `main()` is the
/// one the `AuthInterceptor` reads on every request.
class TokenStorage {
  TokenStorage._();

  static const String _accessKey = 'auth_access_token';
  static const String _refreshKey = 'auth_refresh_token';

  /// The single shared instance. Both [instance] and the DI registration
  /// resolve to this object.
  static final TokenStorage instance = TokenStorage._();

  String? _accessToken;
  String? _refreshToken;
  bool _hydrated = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  /// Hydrate the in-memory cache from disk. Safe to call multiple times.
  Future<void> init() async {
    if (_hydrated) return;
    _accessToken = await SecureStorage.read(_accessKey);
    _refreshToken = await SecureStorage.read(_refreshKey);
    _hydrated = true;
  }

  /// Persist a new pair. Pass `refresh: null` to keep the current one
  /// (common after a silent refresh that only rotates the access token).
  Future<void> save({required String access, String? refresh}) async {
    _accessToken = access;
    await SecureStorage.write(_accessKey, access);
    if (refresh != null) {
      _refreshToken = refresh;
      await SecureStorage.write(_refreshKey, refresh);
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await SecureStorage.deleteAllKeys(const [_accessKey, _refreshKey]);
  }
}
