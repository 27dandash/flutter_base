import '../../../config/language/locale_keys.g.dart';
import '../extensions/string_extension.dart';

class Validators {
  // Anchored on both ends, so trailing garbage is rejected, and each domain
  // label may contain hyphens (user@my-company.com) but not start or end with
  // one. A TLD of at least two letters is required.
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$',
  );

  static String? validateEmpty(String? value, {String? fieldTitle}) {
    if (value == null || value.isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    } else if (RegExp(r'[<>]').hasMatch(value)) {
      return LocaleKeys.scripInjectionValidate;
    }

    return null;
  }

  static String? validateEmail(String? value, {String? fieldTitle}) {
    if (value?.trim().isEmpty ?? true) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    } else if (RegExp(r'[<>]').hasMatch(value!)) {
      return LocaleKeys.scripInjectionValidate;
    } else if (!_emailPattern.hasMatch(value.trim())) {
      return LocaleKeys.mailValidation;
    }
    return null;
  }

  static String? validatePassword(String? value, {String? fieldTitle}) {
    if (value?.trim().isEmpty ?? true) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : "${LocaleKeys.filedValidation} $fieldTitle";
    } else if (!RegExp(
      r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[@#$%^&*()_+=\[\]{};:,.<>?/\\|`~!-]).{8,16}$",
    ).hasMatch(value!)) {
      return LocaleKeys.passSymbols;
    }
    // No separate length or '<'/'>' checks: the pattern above already bounds
    // the length (8-16) and accepts '<' and '>' as symbols. Rejecting them
    // afterwards made the pattern and the validator disagree.
    return null;
  }

  static String? validatePasswordConfirm(
    String? value,
    String? pass, {
    String? fieldTitle,
  }) {
    if (value?.trim().isEmpty ?? true) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : "${LocaleKeys.filedValidation} $fieldTitle";
    } else if (RegExp(r'[<>]').hasMatch(value!)) {
      return LocaleKeys.scripInjectionValidate;
    } else if (value != pass) {
      return LocaleKeys.confirmValidation;
    }
    return null;
  }

  static String? validatePhone(String? value, {String? fieldTitle}) {
    if (value?.trim().isEmpty ?? true) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    } else if (RegExp(r'[<>]').hasMatch(value!)) {
      return LocaleKeys.scripInjectionValidate;
    } else if (!RegExp(r'^\d{8,15}$').hasMatch(value)) {
      return LocaleKeys.phoneValidation;
    }
    return null;
  }

  static String? validateSaudiPhone(String? value, {String? fieldTitle}) {
    if (value?.trim().isEmpty ?? true) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    } else if (RegExp(r'[<>]').hasMatch(value!)) {
      return LocaleKeys.scripInjectionValidate;
    }
    // Strip spaces and dashes before validating
    final cleaned = value.toEnglishNumbers().replaceAll(RegExp(r'[\s\-]'), '');
    // Accept: 05XXXXXXXX, 5XXXXXXXX, 9665XXXXXXXX, +9665XXXXXXXX
    if (!RegExp(r'^(\+?966|0)?5\d{8}$').hasMatch(cleaned)) {
      return LocaleKeys.phoneValidation;
    }
    return null;
  }

  /// Saudi national ID / Iqama: 10 digits, must start with 1 or 2.
  static String? validateNationalId(String? value, {String? fieldTitle}) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    if (!RegExp(r'^[12]\d{9}$').hasMatch(value.trim())) {
      return LocaleKeys.validatorInvalidNid;
    }
    return null;
  }

  /// Saudi commercial registration number: 10 digits.
  static String? validateCommercialReg(String? value, {String? fieldTitle}) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return LocaleKeys.validatorInvalidCr;
    }
    return null;
  }

  /// Saudi IBAN: `SA` followed by 22 digits (spaces are ignored).
  static String? validateIban(String? value, {String? fieldTitle}) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    final clean = value.replaceAll(' ', '').toUpperCase();
    if (!RegExp(r'^SA\d{22}$').hasMatch(clean)) {
      return LocaleKeys.validatorInvalidIban;
    }
    return null;
  }

  /// Generic VAT/tax identifier represented by exactly 15 digits.
  ///
  /// Use [validateSaudiVat] when the Saudi `3...3` structure is required.
  static String? validateVat(String? value, {String? fieldTitle}) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    if (!RegExp(r'^\d{15}$').hasMatch(value.trim())) {
      return LocaleKeys.validatorInvalidVat;
    }
    return null;
  }

  /// Saudi VAT number: 15 digits, beginning and ending with `3`.
  ///
  /// Arabic-Indic digits and surrounding whitespace are normalized before
  /// validation. Backend-specific tax rules still belong to the consuming
  /// application.
  static String? validateSaudiVat(String? value, {String? fieldTitle}) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    final clean = value.toEnglishNumbers().trim();
    if (!RegExp(r'^3\d{13}3$').hasMatch(clean)) {
      return LocaleKeys.validatorInvalidVat;
    }
    return null;
  }

  /// Positive price. Accepts thousand separators and Arabic digits;
  /// optionally enforces a [maxValue] cap.
  static String? validatePrice(
    String? value, {
    double? maxValue,
    String? fieldTitle,
  }) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    final clean = value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .toEnglishNumbers();
    final n = double.tryParse(clean);
    if (n == null || n <= 0) return LocaleKeys.validatorInvalidPrice;
    if (maxValue != null && n > maxValue) {
      return LocaleKeys.validatorPriceTooHigh;
    }
    return null;
  }

  /// Absolute URL with a scheme (e.g. `https://example.com`).
  static String? validateUrl(String? value, {String? fieldTitle}) {
    if (value == null || value.trim().isEmpty) {
      return fieldTitle == null
          ? LocaleKeys.fillField
          : '${LocaleKeys.filedValidation} $fieldTitle';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.isAbsolute ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      return LocaleKeys.validatorInvalidUrl;
    }
    return null;
  }

  static String? noValidate(String value) {
    if (RegExp(r'[<>]').hasMatch(value)) {
      return LocaleKeys.scripInjectionValidate;
    } else {
      return null;
    }
  }

  static String? validateDropDown<T>(T? value, {String? fieldTitle}) {
    if (value == null) {
      return fieldTitle != null
          ? '${LocaleKeys.please} $fieldTitle'
          : LocaleKeys.fillField;
    } else {
      return null;
    }
  }
}
