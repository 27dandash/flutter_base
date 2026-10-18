import 'package:flutter/services.dart';

import '../extensions/string_extension.dart';

/// Arabic and Persian keyboards produce digits and separators that are not
/// ASCII. Rejecting them (as the formatters used to) silently swallows what the
/// user types, while the validators and the HTTP layer already expect them to
/// be normalized. 1:1 replacements keep the selection and composing ranges
/// valid.
TextEditingValue _asciiDigits(
  TextEditingValue value, {
  bool separators = false,
}) {
  var text = value.text.toEnglishNumbers();
  if (separators) {
    text = text.replaceAll('٫', '.').replaceAll('٬', ',');
  }
  return text == value.text ? value : value.copyWith(text: text);
}

/// Where the caret goes after the text was rewritten with extra or removed
/// separators: right after the same number of significant characters as before.
TextSelection _caretAfterFormatting({
  required String formatted,
  required TextEditingValue input,
  required bool Function(String character) isSeparator,
}) {
  final offset = input.selection.extentOffset.clamp(0, input.text.length);
  var significant = 0;
  for (var i = 0; i < offset; i++) {
    if (!isSeparator(input.text[i])) significant++;
  }
  if (significant == 0) return const TextSelection.collapsed(offset: 0);
  var seen = 0;
  for (var i = 0; i < formatted.length; i++) {
    if (!isSeparator(formatted[i]) && ++seen == significant) {
      return TextSelection.collapsed(offset: i + 1);
    }
  }
  return TextSelection.collapsed(offset: formatted.length);
}

/// Saudi phone formatter - allows only digits and the + prefix
class SaudiPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits and + (for +966 format); Arabic-Indic digits are
    // accepted and converted.
    final value = _asciiDigits(newValue);
    return RegExp(r'^[0-9+]*$').hasMatch(value.text) ? value : oldValue;
  }
}

/// Phone number formatter - allows only digits and common phone number characters
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits, +, -, (, ), and spaces
    final value = _asciiDigits(newValue);
    return RegExp(r'^[0-9+\-() ]*$').hasMatch(value.text) ? value : oldValue;
  }
}

/// Email formatter - allows only valid email characters
class EmailFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow letters, numbers, @, ., -, _, and +
    final RegExp regExp = RegExp(r'^[a-zA-Z0-9@._\-+]*$');

    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}

/// Number only formatter - allows only numeric digits
class NumberOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits; Arabic-Indic digits are accepted and converted.
    final value = _asciiDigits(newValue);
    return RegExp(r'^[0-9]*$').hasMatch(value.text) ? value : oldValue;
  }
}

/// Text only formatter - allows only alphabetic characters and spaces
class TextOnlyFormatter extends TextInputFormatter {
  final bool allowSpaces;
  final bool allowArabic;

  TextOnlyFormatter({this.allowSpaces = true, this.allowArabic = true});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Build regex pattern based on options
    String pattern = r'^[a-zA-Z';

    if (allowArabic) {
      pattern += r'\u0600-\u06FF'; // Arabic Unicode range
    }

    if (allowSpaces) {
      pattern += r' ';
    }

    pattern += r']*$';

    final RegExp regExp = RegExp(pattern);

    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}

/// Text with numbers formatter - allows alphabetic characters, numbers, and spaces
class TextWithNumberFormatter extends TextInputFormatter {
  final bool allowSpaces;
  final bool allowArabic;

  TextWithNumberFormatter({this.allowSpaces = true, this.allowArabic = true});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Build regex pattern based on options
    String pattern = r'^[a-zA-Z0-9';

    if (allowArabic) {
      pattern += r'\u0600-\u06FF'; // Arabic Unicode range
    }

    if (allowSpaces) {
      pattern += r' ';
    }

    pattern += r']*$';

    final RegExp regExp = RegExp(pattern);

    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}

/// Date time formatter - formats date as DD/MM/YYYY
class DateTimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = _asciiDigits(newValue);
    // Allow only digits and /, at most DD/MM/YYYY.
    if (!RegExp(r'^[0-9/]*$').hasMatch(value.text) || value.text.length > 10) {
      return oldValue;
    }

    final digits = value.text.replaceAll('/', '');
    if (digits.length > 8) return oldValue;
    var text = digits;
    if (text.length >= 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    if (text.length >= 5) {
      text = '${text.substring(0, 5)}/${text.substring(5)}';
    }

    return TextEditingValue(
      text: text,
      selection: _caretAfterFormatting(
        formatted: text,
        input: value,
        isSeparator: (c) => c == '/',
      ),
    );
  }
}

/// Integer number formatter - allows only positive integers
class IntegerNumberFormatter extends TextInputFormatter {
  final bool allowNegative;
  final int? maxValue;

  IntegerNumberFormatter({this.allowNegative = false, this.maxValue});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = _asciiDigits(newValue);
    final pattern = allowNegative ? r'^-?[0-9]*$' : r'^[0-9]*$';
    if (!RegExp(pattern).hasMatch(value.text)) return oldValue;

    // Check max value if specified
    if (maxValue != null && value.text.isNotEmpty) {
      final int? parsed = int.tryParse(value.text);
      if (parsed != null && parsed > maxValue!) return oldValue;
    }

    return value;
  }
}

/// Decimal number formatter - allows decimal numbers
class DecimalNumberFormatter extends TextInputFormatter {
  final bool allowNegative;
  final int? decimalPlaces;

  DecimalNumberFormatter({this.allowNegative = false, this.decimalPlaces});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Arabic digits and the Arabic decimal separator are converted.
    final value = _asciiDigits(newValue, separators: true);
    final pattern = allowNegative
        ? r'^-?[0-9]*\.?[0-9]*$'
        : r'^[0-9]*\.?[0-9]*$';
    if (!RegExp(pattern).hasMatch(value.text)) return oldValue;

    // Check decimal places if specified
    if (decimalPlaces != null && value.text.contains('.')) {
      final parts = value.text.split('.');
      if (parts.length > 1 && parts[1].length > decimalPlaces!) {
        return oldValue;
      }
    }
    return value;
  }
}

/// Currency formatter - adds thousand separators on every keystroke
/// (e.g. `3000000` → `3,000,000`) and optionally caps the value at [maxValue].
/// The caret stays where the user is typing, leading zeros are dropped and
/// Arabic-Indic digits are accepted.
class CurrencyFormatter extends TextInputFormatter {
  CurrencyFormatter({this.maxValue});

  final num? maxValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = _asciiDigits(newValue, separators: true);
    if (value.text.isEmpty) return value;

    // Keep digits and a single decimal point only.
    final raw = value.text.replaceAll(',', '');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) return oldValue;

    // Enforce the optional cap on the numeric value.
    if (maxValue != null) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed > maxValue!) return oldValue;
    }

    final parts = raw.split('.');
    final grouped = _groupThousands(_withoutLeadingZeros(parts.first));
    final formatted = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;

    return TextEditingValue(
      text: formatted,
      selection: _caretAfterFormatting(
        formatted: formatted,
        input: value,
        isSeparator: (c) => c == ',',
      ),
    );
  }

  /// `0005` → `5`, `000` → `0`, empty stays empty (".5" keeps its integer part
  /// empty so the user sees what they typed).
  String _withoutLeadingZeros(String digits) {
    if (digits.length <= 1) return digits;
    final stripped = digits.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? '0' : stripped;
  }

  String _groupThousands(String digits) {
    if (digits.isEmpty) return digits;
    final buffer = StringBuffer();
    final reversed = digits.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write(',');
      buffer.write(reversed[i]);
    }
    return buffer.toString().split('').reversed.join();
  }
}

/// IBAN formatter - inserts a space every 4 characters and upper-cases input
/// (e.g. `SA0380000000608010167519` → `SA03 8000 0000 6080 1016 7519`).
class IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Accept Arabic-Indic digits typed by an Arabic keyboard.
    final value = _asciiDigits(newValue);
    final raw = value.text.replaceAll(' ', '').toUpperCase();
    if (!RegExp(r'^[A-Z0-9]*$').hasMatch(raw)) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: _caretAfterFormatting(
        formatted: formatted,
        input: value,
        isSeparator: (c) => c == ' ',
      ),
    );
  }
}

/// No special characters formatter - allows only letters, numbers, and spaces
class NoSpecialCharactersFormatter extends TextInputFormatter {
  final bool allowSpaces;
  final bool allowArabic;

  NoSpecialCharactersFormatter({
    this.allowSpaces = true,
    this.allowArabic = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Build regex pattern based on options
    String pattern = r'^[a-zA-Z0-9';

    if (allowArabic) {
      pattern += r'\u0600-\u06FF';
    }

    if (allowSpaces) {
      pattern += r' ';
    }

    pattern += r']*$';

    final RegExp regExp = RegExp(pattern);

    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}
