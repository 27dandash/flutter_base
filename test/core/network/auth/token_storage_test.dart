import 'package:flutter_base/src/core/network/auth/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('TokenStorage instance identity (P0-1)', () {
    final getIt = GetIt.instance;

    tearDown(() => getIt.reset());

    test('DI lookup resolves to the same object as the static instance', () {
      // Mirrors setUpGeneralDependencies() wiring.
      getIt.registerLazySingleton<TokenStorage>(() => TokenStorage.instance);

      expect(identical(TokenStorage.instance, getIt<TokenStorage>()), isTrue);
    });

    test('static instance is a stable singleton', () {
      expect(identical(TokenStorage.instance, TokenStorage.instance), isTrue);
    });
  });
}
