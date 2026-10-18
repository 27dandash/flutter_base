import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../res/config_imports.dart';

class AppTheme {
  /// Material 3 derives every component color (buttons, switches, focus rings,
  /// date pickers, progress indicators) from the [ColorScheme]. `primarySwatch`
  /// is ignored under Material 3, so without an explicit scheme the whole app
  /// rendered in the framework's default purple instead of the design tokens.
  static final ColorScheme lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.brand,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.brandSurface,
        onPrimaryContainer: AppColors.main,
        secondary: AppColors.primary,
        onSecondary: AppColors.textOnDark,
        surface: AppColors.card,
        onSurface: AppColors.main,
        onSurfaceVariant: AppColors.hintText,
        surfaceContainerHighest: AppColors.fill,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        error: AppColors.error,
        onError: AppColors.textOnDark,
      );

  static final ColorScheme darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColorsWithDarkMode.brand,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColorsWithDarkMode.brand,
        onPrimary: AppColors.main,
        primaryContainer: AppColorsWithDarkMode.brandSurface,
        onPrimaryContainer: AppColorsWithDarkMode.main,
        secondary: AppColorsWithDarkMode.primary,
        onSecondary: AppColors.main,
        surface: AppColorsWithDarkMode.card,
        onSurface: AppColorsWithDarkMode.main,
        onSurfaceVariant: AppColorsWithDarkMode.hintText,
        surfaceContainerHighest: AppColorsWithDarkMode.fill,
        outline: AppColorsWithDarkMode.borderStrong,
        outlineVariant: AppColorsWithDarkMode.border,
        error: AppColorsWithDarkMode.error,
        onError: AppColors.main,
      );

  /// System bar style that matches [theme]: dark icons on a light theme and
  /// light icons on a dark one (iOS reads `statusBarBrightness`, which is the
  /// brightness of the *content behind* the bar, hence inverted).
  static SystemUiOverlayStyle systemUiStyleFor(ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    final iconBrightness = isLight ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      primaryColor: AppColors.primary,
      useMaterial3: true,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      fontFamily: ConstantManager.fontFamily,
      bottomSheetTheme: const BottomSheetThemeData(
        modalBackgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.hintText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.pW4),
          foregroundColor: AppColors.primary,
          minimumSize: Size(AppSize.sW30, AppSize.sH30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.sH0),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.2),
        selectionHandleColor: AppColors.primary,
      ),
      // Content colors must contrast with the light surfaces they sit on:
      // the app bar and the default icon color are dark ink, never white.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: AppColors.main,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: AppColors.main),
      inputDecorationTheme: const InputDecorationTheme(
        prefixIconColor: AppColors.border,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      primaryColor: AppColorsWithDarkMode.primary,
      useMaterial3: true,
      fontFamily: ConstantManager.fontFamily,
      bottomSheetTheme: const BottomSheetThemeData(
        modalBackgroundColor: AppColorsWithDarkMode.white,
      ),
      scaffoldBackgroundColor: AppColorsWithDarkMode.scaffoldBackground,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsWithDarkMode.white,
        selectedItemColor: AppColorsWithDarkMode.primary,
        unselectedItemColor: AppColorsWithDarkMode.hintText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.pW4),
          foregroundColor: AppColorsWithDarkMode.primary,
          minimumSize: Size(AppSize.sW30, AppSize.sH30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.sH0),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsWithDarkMode.scaffoldBackground,
        foregroundColor: AppColorsWithDarkMode.main,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: AppColorsWithDarkMode.main),
      inputDecorationTheme: const InputDecorationTheme(
        prefixIconColor: AppColorsWithDarkMode.border,
      ),
    );
  }
}
