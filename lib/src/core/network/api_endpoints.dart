class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL, switchable per environment via `--dart-define`:
  ///
  /// ```bash
  /// flutter run   --dart-define=API_BASE_URL=https://dev.api.com/api/v1/
  /// flutter build --dart-define=API_BASE_URL=https://api.production.com/api/v1/
  /// ```
  ///
  /// MUST end with a trailing `/` so relative endpoints resolve correctly.
  /// `DioClient` prepends this base to every (relative) endpoint below.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com/api/v1/',
  );

  // Endpoints are RELATIVE — DioClient already prepends [baseUrl].
  // No leading slash, no base prefix.

  // Auth
  static const String login = 'auth/login';
  static const String register = 'auth/register';
  static const String refreshToken = 'auth/refresh-token';
  static const String logout = 'auth/logout';
  static const String forgotPassword = 'auth/forgot-password';
  static const String resetPassword = 'auth/reset-password';

  // User
  static const String me = 'users/me';
  static const String users = 'users';
  static String userById(int id) => 'users/$id';
  static const String updateProfile = 'users/profile';

  // Generic resource paths — replace with real ones per project
  static const String products = 'products';
  static String productById(int id) => 'products/$id';
}
