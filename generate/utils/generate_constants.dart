abstract class GenerateConstants{
  //print_colors
  static const String blueColorCode = '\x1B[34m';
  static const String orangeColorCode = '\x1B[33m';
  static const String redColorCode = '\x1B[31m';
  static const String greenColorCode = '\x1B[32m';
  static const String resetColorCode = '\x1B[0m';
  //generate_strings
  static const String langJsonAssetFilePath = 'assets/translations/lang.json';
  static const String langEnJsonAssetFilePath = 'assets/translations/en.json';
  static const String langArJsonAssetFilePath = 'assets/translations/ar.json';
  static const String outputStringsFilePath = 'lib/src/config/language/locale_keys.g.dart';
  //generate_features
  static const String projectFeaturesPath = 'lib/src/features';
  static const String requestsAssetsPath = 'assets/requests';
}