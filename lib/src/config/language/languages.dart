import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum Languages {
  english(Locale('en'), 'English', "en"),
  arabic(Locale('ar'), 'Arabic', "ar");

  final String title;
  final Locale locale;
  final String languageCode;

  const Languages(this.locale, this.title, this.languageCode);

  static List<Locale> get supportLocales =>
      Languages.values.map((e) => e.locale).toList();

  static List<String> get titles =>
      Languages.values.map((e) => e.title).toList();

  /// Changes language using the mounted UI context so localization state is
  /// never retained globally or resolved from a navigation singleton.
  static Future<void> setLocaleWithContext(
    BuildContext context,
    Languages lang,
  ) async {
    Intl.defaultLocale = lang.languageCode;
    await context.setLocale(lang.locale);
  }

  static String getLanguageCode(Languages language) {
    return language.locale.languageCode;
  }

  static Languages get currentLanguage {
    final code = Intl.getCurrentLocale().split(RegExp('[-_]')).first;
    return Languages.values.firstWhere(
      (language) => language.languageCode == code,
      orElse: () => Languages.arabic,
    );
  }

  static Languages of(BuildContext context) {
    final locale = context.locale;
    return Languages.values.firstWhere(
      (language) => language.languageCode == locale.languageCode,
      orElse: () => Languages.arabic,
    );
  }
}
