enum AppFlavor { development, staging, production }

final class EnvironmentValidationException implements Exception {
  const EnvironmentValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class AppEnvironment {
  const AppEnvironment._({required this.flavor});

  final AppFlavor flavor;

  static const development = AppEnvironment._(flavor: AppFlavor.development);

  static const staging = AppEnvironment._(flavor: AppFlavor.staging);

  static const production = AppEnvironment._(flavor: AppFlavor.production);

  String get name => flavor.name;

  void validate({required Uri apiBaseUri, required List<String> tlsPins}) {
    if (!apiBaseUri.isAbsolute || apiBaseUri.host.isEmpty) {
      throw const EnvironmentValidationException(
        'API_BASE_URL must be an absolute URL.',
      );
    }
    if (flavor != AppFlavor.production) return;
    if (apiBaseUri.scheme != 'https') {
      throw const EnvironmentValidationException(
        'Production API_BASE_URL must use HTTPS.',
      );
    }
    final host = apiBaseUri.host.toLowerCase();
    if (host == 'api.example.com' ||
        host.contains('localhost') ||
        host.contains('staging') ||
        host.contains('development') ||
        host.startsWith('dev.')) {
      throw const EnvironmentValidationException(
        'Production cannot use a placeholder or non-production API host.',
      );
    }
    if (tlsPins.length < 2) {
      throw const EnvironmentValidationException(
        'Production requires primary and backup TLS pins.',
      );
    }
  }
}
