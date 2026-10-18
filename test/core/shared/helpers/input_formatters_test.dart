import 'package:flutter/services.dart';
import 'package:flutter_base/src/core/shared/helpers/input_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _v(String text, [int? caret]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret ?? text.length),
);

TextEditingValue _apply(
  TextInputFormatter formatter,
  String before,
  String after, {
  int? caret,
}) => formatter.formatEditUpdate(_v(before), _v(after, caret));

void main() {
  group('Arabic and Persian digits are accepted and converted', () {
    test('NumberOnlyFormatter', () {
      final result = _apply(NumberOnlyFormatter(), '', '٠٥٠١٢٣');
      expect(result.text, '050123');
      expect(result.selection.extentOffset, 6);
      expect(_apply(NumberOnlyFormatter(), '12', '12a').text, '12');
      expect(_apply(NumberOnlyFormatter(), '', '۱۲۳').text, '123');
    });

    test('phone formatters', () {
      expect(_apply(SaudiPhoneFormatter(), '', '+٩٦٦٥٠').text, '+96650');
      expect(
        _apply(PhoneNumberFormatter(), '', '(٠٥٠) ١٢-٣').text,
        '(050) 12-3',
      );
      expect(_apply(SaudiPhoneFormatter(), '+9', '+9x').text, '+9');
    });

    test('integer and decimal formatters', () {
      expect(_apply(IntegerNumberFormatter(), '', '٤٢').text, '42');
      expect(
        _apply(IntegerNumberFormatter(maxValue: 100), '10', '١٠١').text,
        '10',
        reason: 'the cap applies to the converted value',
      );
      expect(_apply(DecimalNumberFormatter(), '', '١٢٫٥').text, '12.5');
      expect(
        _apply(DecimalNumberFormatter(decimalPlaces: 2), '1.25', '1.256').text,
        '1.25',
      );
      expect(_apply(DecimalNumberFormatter(), '1.5', '1.5.').text, '1.5');
    });

    test('currency and IBAN formatters', () {
      expect(_apply(CurrencyFormatter(), '', '١٢٣٤٥٦٧').text, '1,234,567');
      expect(_apply(IbanFormatter(), '', 'sa٠٣٨٠٠٠').text, 'SA03 8000');
    });

    test('date formatter', () {
      expect(_apply(DateTimeFormatter(), '', '٢٥٠١٢٠٢٦').text, '25/01/2026');
    });
  });

  group('the caret stays where the user is typing', () {
    test('currency: typing in the middle does not jump to the end', () {
      // "1,234" → the user inserts a 9 after the first digit: "19,234" typed
      // as "19,234" raw "19234"
      final result = CurrencyFormatter().formatEditUpdate(
        _v('1,234'),
        _v('19,234', 2),
      );

      expect(result.text, '19,234');
      expect(result.selection.extentOffset, 2);
    });

    test('currency: the caret follows a newly inserted separator', () {
      final result = CurrencyFormatter().formatEditUpdate(
        _v('999'),
        _v('9991', 4),
      );

      expect(result.text, '9,991');
      expect(result.selection.extentOffset, 5);
    });

    test('currency: deleting inside keeps the caret in place', () {
      // "12,345" → delete the 2 (caret after "1")
      final result = CurrencyFormatter().formatEditUpdate(
        _v('12,345'),
        _v('1,345', 1),
      );

      expect(result.text, '1,345');
      expect(result.selection.extentOffset, 1);
    });

    test('date: replacing a digit in the middle keeps the caret', () {
      final result = DateTimeFormatter().formatEditUpdate(
        _v('25/01/2026'),
        _v('15/01/2026', 1),
      );

      expect(result.text, '15/01/2026');
      expect(result.selection.extentOffset, 1);
    });

    test('date: an edit that would exceed eight digits is refused', () {
      final result = DateTimeFormatter().formatEditUpdate(
        _v('25/01/2026'),
        _v('215/01/2026', 2),
      );

      expect(result.text, '25/01/2026');
    });

    test('date: typing the third digit moves the caret past the slash', () {
      final result = DateTimeFormatter().formatEditUpdate(
        _v('25'),
        _v('250', 3),
      );

      expect(result.text, '25/0');
      expect(result.selection.extentOffset, 4);
    });

    test('IBAN: typing in the middle keeps the caret', () {
      final result = IbanFormatter().formatEditUpdate(
        _v('SA03 8000'),
        _v('SA0X3 8000', 4),
      );

      expect(result.text, 'SA0X 3800 0');
      expect(result.selection.extentOffset, 4);
    });
  });

  group('currency formatting details', () {
    test('leading zeros are dropped but 0.5 is kept', () {
      expect(_apply(CurrencyFormatter(), '', '0005').text, '5');
      expect(_apply(CurrencyFormatter(), '', '000').text, '0');
      expect(_apply(CurrencyFormatter(), '', '0.5').text, '0.5');
      expect(_apply(CurrencyFormatter(), '', '.5').text, '.5');
    });

    test('the cap and a second decimal point are enforced', () {
      expect(_apply(CurrencyFormatter(maxValue: 100), '99', '999').text, '99');
      expect(_apply(CurrencyFormatter(), '1.5', '1.5.').text, '1.5');
      expect(_apply(CurrencyFormatter(), '1', '1a').text, '1');
    });

    test('empty input is passed through', () {
      expect(_apply(CurrencyFormatter(), '5', '').text, '');
    });
  });
}
