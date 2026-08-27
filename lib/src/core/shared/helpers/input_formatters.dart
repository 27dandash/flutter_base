import 'package:flutter/services.dart';

/// Saudi phone formatter - allows only digits and the + prefix
class SaudiPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits and + (for +966 format)
    final RegExp regExp = RegExp(r'^[0-9+]*$');
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
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
    final RegExp regExp = RegExp(r'^[0-9+\-() ]*$');

    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
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
    // Allow only digits 0-9
    final RegExp regExp = RegExp(r'^[0-9]*$');

    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
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
    // Allow only digits and /
    final RegExp regExp = RegExp(r'^[0-9/]*$');

    if (!regExp.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Limit to 10 characters (DD/MM/YYYY)
    if (newValue.text.length > 10) {
      return oldValue;
    }

    // Auto-add slashes
    String text = newValue.text;

    // Remove all slashes first
    text = text.replaceAll('/', '');

    // Add slashes at appropriate positions
    if (text.length >= 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }
    if (text.length >= 5) {
      text = '${text.substring(0, 5)}/${text.substring(5)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
    // Build regex pattern based on options
    String pattern = r'^';

    if (allowNegative) {
      pattern += r'-?';
    }

    pattern += r'[0-9]*$';

    final RegExp regExp = RegExp(pattern);

    if (!regExp.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Check max value if specified
    if (maxValue != null && newValue.text.isNotEmpty) {
      final int? value = int.tryParse(newValue.text);
      if (value != null && value > maxValue!) {
        return oldValue;
      }
    }

    return newValue;
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
    // Build regex pattern based on options
    String pattern = r'^';

    if (allowNegative) {
      pattern += r'-?';
    }

    pattern += r'[0-9]*\.?[0-9]*$';

    final RegExp regExp = RegExp(pattern);

    if (!regExp.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Check decimal places if specified
    if (decimalPlaces != null && newValue.text.contains('.')) {
      final List<String> parts = newValue.text.split('.');
      if (parts.length > 1 && parts[1].length > decimalPlaces!) {
        return oldValue;
      }
    }

    // Prevent multiple decimal points
    if (newValue.text.split('.').length > 2) {
      return oldValue;
    }

    return newValue;
  }
}

/// Currency formatter - adds thousand separators on every keystroke
/// (e.g. `3000000` → `3,000,000`) and optionally caps the value at [maxValue].
class CurrencyFormatter extends TextInputFormatter {
  CurrencyFormatter({this.maxValue});

  final num? maxValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Keep digits and a single decimal point only.
    String raw = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) return oldValue;

    // Enforce the optional cap on the numeric value.
    if (maxValue != null) {
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed > maxValue!) return oldValue;
    }

    final parts = raw.split('.');
    final intPart = parts.first;
    final grouped = _groupThousands(intPart);
    final formatted = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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
    final raw = newValue.text.replaceAll(' ', '').toUpperCase();
    if (!RegExp(r'^[A-Z0-9]*$').hasMatch(raw)) return oldValue;

    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
