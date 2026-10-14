import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/language/languages.dart';
import '../../../config/res/config_imports.dart';

class Helpers {
  static void changeStatusbarColor({
    required Color statusBarColor,
    Brightness? statusBarIconBrightness,
  }) {
    return SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
        systemNavigationBarColor: AppColors.main,
      ),
    );
  }

  /// Starts the platform share flow and lets the caller own any loading UI.
  static Future<ShareResult> shareApp(String url) {
    final ShareParams params = ShareParams(uri: Uri.parse(url));
    return SharePlus.instance.share(params);
  }

  static String getDeviceType() {
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  /// Normalizes a Saudi mobile number to the canonical `9665XXXXXXXX` form.
  /// Handles inputs starting with `05`, `5`, `+966` and `966`.
  static String normalizeSaudiPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('966')) return digits;
    if (digits.startsWith('05')) return '966${digits.substring(1)}';
    if (digits.startsWith('5')) return '966$digits';
    return digits;
  }

  static String showByLang({required String ar, required String en}) {
    if (Languages.currentLanguage.languageCode == 'ar') {
      return ar;
    } else {
      return en;
    }
  }
}
