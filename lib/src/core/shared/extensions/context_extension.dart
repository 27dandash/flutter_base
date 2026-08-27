import 'package:flutter/material.dart';

import '../../../config/language/languages.dart';
import '../../../config/res/config_imports.dart';
import 'text_style_extensions.dart';

extension ContextExtension on BuildContext {
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;
  TextStyle get textStyle => theme.textTheme.bodyMedium!.setFontFamily;

  double get width => mediaQuery.size.width;

  double get height => mediaQuery.size.height;

  bool get isKeyboardOpen =>
      MediaQuery.of(this).viewInsets.bottom > ConstantManager.zero;

  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  bool get isDark => theme.brightness == Brightness.dark;

  bool get isLight => theme.brightness == Brightness.light;

  bool get isMaterial => theme.platform == TargetPlatform.android;

  bool get isRight => Directionality.of(this) == TextDirection.rtl;

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';
}

extension LanguageExtension on Widget {
  Widget overRideLocaization({
    required BuildContext context,
    required Languages lang,
  }) {
    return Localizations.override(
      context: context,
      locale: lang.locale,
      child: this,
    );
  }
}
