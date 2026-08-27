import 'package:flutter_base/src/core/shared/helpers/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Helpers.normalizeSaudiPhone', () {
    test('05XXXXXXXX -> 9665XXXXXXXX', () {
      expect(Helpers.normalizeSaudiPhone('0501234567'), '966501234567');
    });

    test('5XXXXXXXX -> 9665XXXXXXXX', () {
      expect(Helpers.normalizeSaudiPhone('501234567'), '966501234567');
    });

    test('+966 prefix is normalized', () {
      expect(Helpers.normalizeSaudiPhone('+966501234567'), '966501234567');
    });

    test('already-966 is preserved', () {
      expect(Helpers.normalizeSaudiPhone('966501234567'), '966501234567');
    });

    test('strips spaces and separators', () {
      expect(Helpers.normalizeSaudiPhone('05 0123-4567'), '966501234567');
    });
  });
}
