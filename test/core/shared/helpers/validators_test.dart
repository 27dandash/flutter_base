import 'package:flutter_base/src/config/language/locale_keys.g.dart';
import 'package:flutter_base/src/core/shared/helpers/validators.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => EasyLocalization.logger.enableLevels = []);

  group('Validators', () {
    test('required and script-like values are rejected', () {
      expect(Validators.validateEmpty(null), LocaleKeys.fillField);
      expect(
        Validators.validateEmpty('<script>'),
        LocaleKeys.scripInjectionValidate,
      );
      expect(Validators.validateEmpty('value'), isNull);
    });

    test('email and strong password rules accept representative values', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(
        Validators.validateEmail('not-an-email'),
        LocaleKeys.mailValidation,
      );
      expect(Validators.validatePassword('Valid@123'), isNull);
      expect(Validators.validatePassword('weak'), LocaleKeys.passSymbols);
    });

    test('Saudi identifiers and formatted phone values are validated', () {
      expect(Validators.validateSaudiPhone('+966 50-123-4567'), isNull);
      expect(Validators.validateSaudiPhone('٠٥٠ ١٢٣ ٤٥٦٧'), isNull);
      expect(
        Validators.validateSaudiPhone('٠٤٠ ١٢٣ ٤٥٦٧'),
        LocaleKeys.phoneValidation,
      );
      expect(Validators.validateNationalId('1234567890'), isNull);
      expect(Validators.validateIban('SA12 3456 7890 1234 5678 9012'), isNull);
      expect(
        Validators.validateNationalId('3234567890'),
        LocaleKeys.validatorInvalidNid,
      );
    });

    test(
      'Saudi VAT structure is opt-in and preserves generic VAT behavior',
      () {
        expect(Validators.validateVat('123456789012345'), isNull);
        expect(Validators.validateSaudiVat('٣١٢٣٤٥٦٧٨٩٠١٢٣٣'), isNull);
        expect(
          Validators.validateSaudiVat('123456789012345'),
          LocaleKeys.validatorInvalidVat,
        );
      },
    );

    test('price supports Arabic digits and a maximum', () {
      expect(Validators.validatePrice('١٢٥٫٥٠'), isNull);
      expect(
        Validators.validatePrice('150', maxValue: 100),
        LocaleKeys.validatorPriceTooHigh,
      );
    });

    test('URL validation allows only absolute HTTP(S) URLs', () {
      expect(Validators.validateUrl('https://example.com/path'), isNull);
      expect(
        Validators.validateUrl('javascript:alert(1)'),
        LocaleKeys.validatorInvalidUrl,
      );
      expect(
        Validators.validateUrl('/relative/path'),
        LocaleKeys.validatorInvalidUrl,
      );
    });
  });
}
