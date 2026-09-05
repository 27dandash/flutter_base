import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_base/src/config/language/languages.dart';

Future<void> ensureLocalizedTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getAll') {
          return <String, Object>{};
        }
        return null;
      });
  EasyLocalization.logger.enableLevels = [];
  await EasyLocalization.ensureInitialized();
}

Widget localizedHost(
  Widget child, {
  Locale locale = const Locale('en'),
  ui.TextDirection direction = ui.TextDirection.ltr,
  ThemeData? theme,
}) {
  return EasyLocalization(
    supportedLocales: Languages.supportLocales,
    path: 'assets/translations',
    startLocale: locale,
    fallbackLocale: const Locale('en'),
    child: Builder(
      builder: (context) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            theme: theme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Directionality(
              textDirection: direction,
              child: Scaffold(body: child),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  ui.TextDirection direction = ui.TextDirection.ltr,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    localizedHost(child, locale: locale, direction: direction, theme: theme),
  );
  await tester.pumpAndSettle();
}
