part of 'config_imports.dart';

final GetIt injector = GetIt.instance;

class ConstantManager {
  static const String appName = 'Flutter Base';
  static const String fontFamily = 'Beiruti';

  static const int splashTimer = 3000;
  static const String emptyText = '';
  static const int zero = 0;
  static const zeroAsDouble = 0.0;
  static const int pinCodeFieldsCount = 4;
  static const int connectTimeoutDuration = 5000;
  static const int recieveTimeoutDuration = 5000;
  static const String ar = 'ar';
  static const String en = 'en';
  static const String arabic = 'العربية';
  static const String english = 'English';
  static const int pgSize = 10;
  static const int pgFirst = 1;
  static const int maxLines = 5;
  static String get platform =>
      defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';

  static Map<String, dynamic>? paginateJson(int page) => {
    'page': page,
    'paginate': pgSize,
  };
}

final class SkeltonizerManager {
  static const String short = "Loading..";
  static const String medium = "Loading.. Loading...";
  static const String long =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book";
  static const String veryLong =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book . /n Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book /n/n Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book ";
}
