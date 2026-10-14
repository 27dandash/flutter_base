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

    test('email accepts hyphenated and multi-label domains', () {
      for (final ok in [
        'user@my-company.com',
        'first.last+tag@mail.example.co.uk',
        'a_b@x1.io',
      ]) {
        expect(Validators.validateEmail(ok), isNull, reason: ok);
      }
    });

    test('email rejects trailing garbage and malformed domains', () {
      for (final bad in [
        'a@b.co garbage',
        'user@example.com.',
        'user@-bad.com',
        'user@bad-.com',
        'user@nodot',
        'user@.com',
        'user@@example.com',
        '@example.com',
      ]) {
        expect(
          Validators.validateEmail(bad),
          LocaleKeys.mailValidation,
          reason: bad,
        );
      }
    });

    test('password rules agree with their symbol set', () {
      // '<' and '>' are listed symbols, so they must not be rejected later.
      expect(Validators.validatePassword('Abcdef1<'), isNull);
      expect(Validators.validatePassword('Abcdef1>x'), isNull);
      // Length is bounded by the pattern alone.
      expect(
        Validators.validatePassword('Abcdef1!Abcdef1!x'),
        LocaleKeys.passSymbols,
      );
      expect(Validators.validatePassword('Ab1!'), LocaleKeys.passSymbols);
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
