import 'package:flutter/services.dart';

class ArabicNumbersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    bool containsArabicNumber = false;

    // Check if the new text contains Arabic numbers
    if (newText.codeUnits.any(
      (codeUnit) => codeUnit >= 0x0660 && codeUnit <= 0x0669,
    )) {
      containsArabicNumber = true;
    }

    // Convert Arabic numbers to English numbers
    if (containsArabicNumber) {
      String englishNumbers = '';
      for (int codeUnit in newText.codeUnits) {
        englishNumbers += (codeUnit >= 0x0660 && codeUnit <= 0x0669)
            ? String.fromCharCode(codeUnit - 0x0630)
            : String.fromCharCode(codeUnit);
      }
      newText = englishNumbers;
    }

    return newValue.copyWith(text: newText);
  }
}
