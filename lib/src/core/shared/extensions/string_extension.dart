import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

extension FormatString on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits to ASCII.
  String toEnglishNumbers() {
    return replaceAllMapped(RegExp('[\u06F0-\u06F9]'), (m) {
          return String.fromCharCode(m[0]!.codeUnitAt(0) - 0x06F0 + 0x30);
        })
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  /// Formats a numeric string with thousand separators; a value that is not a
  /// number is returned unchanged instead of throwing.
  String toCurrency() {
    final value = double.tryParse(this);
    if (value == null) return this;
    return NumberFormat('#,###').format(value);
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: this));
  }

  String get locale {
    return this.tr();
  }

  bool isNumeric() {
    return double.tryParse(this) != null;
  }

  String toCamelCase() {
    if (isEmpty) return this;
    return this[0].toUpperCase() +
        substring(1).replaceAllMapped(
          RegExp('[_-](.)'),
          (Match match) => match.group(1)!.toUpperCase(),
        );
  }
}

extension FormatDouble on double {
  String toCurrency() {
    final formatter = NumberFormat('#,###');
    return formatter.format(this);
  }
}

extension DateTimeFormatHelper on DateTime {
  String toTime([String? locale]) {
    return DateFormat('hh:mm a', locale).format(this);
  }

  String toTimeWithoutPmAndAm([String? locale]) {
    return DateFormat('hh:mm', locale).format(this);
  }

  String toAmAndPm([String? locale]) {
    return DateFormat('a', locale).format(this);
  }

  String toFullDate({String? locale, String key = '-'}) {
    return DateFormat('yyyy${key}MM${key}dd', locale).format(this);
  }

  String toFullDateTime([String? locale]) {
    return DateFormat('yyyy-MM-dd HH:mm', locale).format(this);
  }

  String toDay([String? locale]) {
    return DateFormat('EEEE', locale).format(this);
  }

  String toMonth([String? locale]) {
    return DateFormat('MMMM', locale).format(this);
  }

  String toMonthShort([String? locale]) {
    return DateFormat('MMM', locale).format(this);
  }

  String toDayMonth([String? locale]) {
    return DateFormat('dd MMMM', locale).format(this);
  }

  String toDayMonthShort([String? locale]) {
    return DateFormat('dd MMM', locale).format(this);
  }

  String toDayMonthYear([String? locale]) {
    return DateFormat('dd MMMM yyyy', locale).format(this);
  }

  String toDayMonthYearShort([String? locale]) {
    return DateFormat('dd MMM yyyy', locale).format(this);
  }

  String toDayMonthYearTime([String? locale]) {
    return DateFormat('dd MMMM yyyy HH:mm', locale).format(this);
  }

  String toDayMonthYearTimeShort([String? locale]) {
    return DateFormat('dd MMM yyyy HH:mm', locale).format(this);
  }

  String toDayMonthYearTimeSeconds([String? locale]) {
    return DateFormat('dd MMMM yyyy HH:mm:ss', locale).format(this);
  }

  String toDayMonthYearTimeSecondsShort([String? locale]) {
    return DateFormat('dd MMM yyyy HH:mm:ss', locale).format(this);
  }
}
