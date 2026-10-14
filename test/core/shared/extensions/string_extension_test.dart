import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_base/src/core/shared/extensions/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  group('String helpers on empty or invalid input', () {
    test('capitalize and toCamelCase do not throw on an empty string', () {
      expect(''.capitalize(), '');
      expect(''.toCamelCase(), '');
      expect('hello'.capitalize(), 'Hello');
      expect('snake_case_value'.toCamelCase(), 'SnakeCaseValue');
    });

    test('toCurrency returns a non-number unchanged', () {
      expect('1234567'.toCurrency(), '1,234,567');
      expect('abc'.toCurrency(), 'abc');
      expect(''.toCurrency(), '');
    });
  });

  group('DateTime formatting honours the locale argument', () {
    final date = DateTime(2026, 3, 9, 14, 5);

    test('month and day names follow the requested locale', () {
      expect(date.toMonth('en'), 'March');
      expect(date.toMonth('ar'), isNot('March'));
      expect(date.toDay('en'), 'Monday');
      expect(date.toDay('ar'), isNot('Monday'));
      expect(date.toDayMonthYear('en'), '09 March 2026');
      expect(date.toDayMonthYearShort('en'), '09 Mar 2026');
    });

    test('numeric formats stay stable for the default locale', () {
      Intl.defaultLocale = 'en';
      expect(date.toFullDate(), '2026-03-09');
      expect(date.toFullDate(key: '/'), '2026/03/09');
      expect(date.toFullDateTime(), '2026-03-09 14:05');
      expect(date.toDayMonthYearTime('en'), '09 March 2026 14:05');
    });
  });
}
