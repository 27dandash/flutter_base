import 'package:flutter/foundation.dart';
import 'package:flutter_base/src/config/res/config_imports.dart';
import 'package:flutter_base/src/core/navigation/page_router/imports_page_router_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  // dart:io's Platform throws on the web; these paths must rely on
  // defaultTargetPlatform only.
  for (final platform in TargetPlatform.values) {
    test('router setup and platform lookups work on $platform', () {
      debugDefaultTargetPlatformOverride = platform;

      expect(() => PageRouterBuilder().initAppRouter(), returnsNormally);
      expect(
        ConstantManager.platform,
        platform == TargetPlatform.android ? 'android' : 'ios',
      );
    });
  }
}
