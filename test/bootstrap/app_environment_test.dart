import 'package:flutter_base/bootstrap/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each entry point has a distinct, stable environment', () {
    expect(AppEnvironment.development.flavor, AppFlavor.development);
    expect(AppEnvironment.staging.flavor, AppFlavor.staging);
    expect(AppEnvironment.production.flavor, AppFlavor.production);

    expect(
      {
        AppEnvironment.development.name,
        AppEnvironment.staging.name,
        AppEnvironment.production.name,
      },
      {'development', 'staging', 'production'},
    );
  });

  test(
    'production rejects placeholders, insecure URLs, and missing backup pin',
    () {
      expect(
        () => AppEnvironment.production.validate(
          apiBaseUri: Uri.parse('https://api.example.com'),
          tlsPins: const ['a'],
        ),
        throwsA(isA<EnvironmentValidationException>()),
      );
      expect(
        () => AppEnvironment.production.validate(
          apiBaseUri: Uri.parse('http://api.product.com'),
          tlsPins: const ['a', 'b'],
        ),
        throwsA(isA<EnvironmentValidationException>()),
      );
      expect(
        () => AppEnvironment.production.validate(
          apiBaseUri: Uri.parse('https://api.product.com'),
          tlsPins: const ['primary'],
        ),
        throwsA(isA<EnvironmentValidationException>()),
      );
    },
  );

  test('production accepts an HTTPS host with primary and backup pins', () {
    expect(
      () => AppEnvironment.production.validate(
        apiBaseUri: Uri.parse('https://api.product.com/v1/'),
        tlsPins: const ['primary', 'backup'],
      ),
      returnsNormally,
    );
  });
}
