part of 'config_imports.dart';

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color brand = Color(0xFFB77F4A);
  static const Color brandLight = Color(0xFFD4A374);
  static const Color brandDark = Color(0xFFB17B48);
  static const Color brandSurface = Color(0xFFFFF9F0);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color main = Color(0xFF1C1C1C);
  static const Color primary = Color(0xFF474747);
  static const Color hintText = Color(0xFF8B8B8B);
  static const Color textDisabled = Color(0xFFCCCCCC);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textBrand = Color(0xFFB77F4A);

  // ── Surface ──────────────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFFBFBFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color fill = Color(0xFFF7F7F8);
  static const Color surfaceBrand = Color(0xFFB77F4A);

  // ── Border ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFEBEBEB);
  static const Color borderStrong = Color(0xFFCCCCCC);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF0C9D61);
  static const Color successSurface = Color(0xFFE8F8F1);
  static const Color error = Color(0xFFEC2D30);
  static const Color dangerSurface = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFFE9B0E);
  static const Color warningSurface = Color(0xFFFFF8EC);
  static const Color info = Color(0xFF3A70E2);
  static const Color infoSurface = Color(0xFFEEF3FD);

  // ── Base ─────────────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ── Legacy aliases (backward compatibility) ──────────────────────────────
  static const Color secondary = primary;
  static const Color third = main;
  static const Color forth = brand;
  static const Color buttonColor = brand;
  static const Color buttonText = textOnDark;
  static const Color activeBorder = brand;
  static const Color loginPrimary = brand;
  static const Color grey1 = border;
  static const Color grey2 = borderStrong;

  static const LinearGradient gradient = LinearGradient(
    colors: [brandDark, brand],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient disableGradient = LinearGradient(
    colors: [grey1, grey2],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static BoxShadow containerShadow = BoxShadow(
    color: const Color(0xFFF0F0F0).withValues(alpha: 1.0),
    offset: const Offset(0, 0),
    blurRadius: 4.0,
    spreadRadius: 0.0,
  );
}

extension ColorExtension on Color {
  bool get isDark => computeLuminance() < 0.5;
}

class AppColorsWithDarkMode {
  AppColorsWithDarkMode._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color brand = Color(0xFFD4A374);
  static const Color brandLight = Color(0xFFE8C4A0);
  static const Color brandDark = Color(0xFFB77F4A);
  static const Color brandSurface = Color(0xFF2A2318);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color main = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFE5E5E5);
  static const Color hintText = Color(0xFFA3A3A3);
  static const Color textDisabled = Color(0xFF666666);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textBrand = Color(0xFFD4A374);

  // ── Surface ──────────────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color fill = Color(0xFF2A2A2A);
  static const Color surfaceBrand = Color(0xFFB77F4A);

  // ── Border ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF3D3D3D);
  static const Color borderStrong = Color(0xFF525252);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color successSurface = Color(0xFF1A2E24);
  static const Color error = Color(0xFFF87171);
  static const Color dangerSurface = Color(0xFF2E1A1A);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningSurface = Color(0xFF2E2618);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoSurface = Color(0xFF1A2433);

  // ── Base ─────────────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ── Legacy aliases (backward compatibility) ──────────────────────────────
  static const Color secondary = primary;
  static const Color third = main;
  static const Color forth = brand;
  static const Color buttonColor = brand;
  static const Color buttonText = textOnDark;
  static const Color activeBorder = brand;
  static const Color loginPrimary = brand;
  static const Color grey1 = border;
  static const Color grey2 = borderStrong;

  static const LinearGradient gradient = LinearGradient(
    colors: [brandDark, brand],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const LinearGradient disableGradient = LinearGradient(
    colors: [grey1, grey2],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static BoxShadow containerShadow = BoxShadow(
    color: const Color(0xFF000000).withValues(alpha: 0.24),
    offset: const Offset(0, 0),
    blurRadius: 4.0,
    spreadRadius: 0.0,
  );
}
