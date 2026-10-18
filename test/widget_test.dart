import 'package:flutter_base/src/config/res/config_imports.dart';
import 'package:flutter_base/src/config/themes/app_theme.dart';
import 'package:flutter_base/src/core/navigation/route_generator.dart';
import 'package:flutter_base/src/core/widgets/scaffolds/app_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  testWidgets('light and dark themes expose the correct brightness', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SizedBox.shrink(),
        ),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.brightness, Brightness.light);
    expect(app.darkTheme!.brightness, Brightness.dark);
  });

  testWidgets('layout honors an RTL direction boundary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('العربية', key: Key('rtl-text')),
          ),
        ),
      ),
    );

    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, AlignmentDirectional.centerStart);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('rtl-text')))),
      TextDirection.rtl,
    );
  });

  testWidgets('unknown routes display a controlled fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/unknown',
        onGenerateRoute: RouterGenerator.getRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unknown-route')), findsOneWidget);
  });

  group('AppTheme content colors', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    /// The themes size padding through ScreenUtil, so they can only be built
    /// once it is initialized.
    Future<ThemeData> buildTheme(
      WidgetTester tester,
      ThemeData Function() build,
    ) async {
      late ThemeData theme;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) {
            theme = build();
            return const SizedBox.shrink();
          },
        ),
      );
      return theme;
    }

    for (final entry in <String, ThemeData Function()>{
      'light': () => AppTheme.light,
      'dark': () => AppTheme.dark,
    }.entries) {
      testWidgets('${entry.key}: app bar content is readable', (tester) async {
        final theme = await buildTheme(tester, entry.value);
        final background =
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
        expect(
          contrast(theme.appBarTheme.foregroundColor!, background),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('${entry.key}: default icons are visible on the scaffold', (
        tester,
      ) async {
        final theme = await buildTheme(tester, entry.value);
        expect(
          contrast(theme.iconTheme.color!, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    testWidgets('AppPageShell title and a bare icon are readable in light', (
      tester,
    ) async {
      late ThemeData light;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) {
            light = AppTheme.light;
            return MaterialApp(
              theme: light,
              home: const AppPageShell(
                title: Text('Title', key: Key('title')),
                body: Icon(Icons.close, key: Key('icon')),
              ),
            );
          },
        ),
      );

      final icon = tester.widget<Icon>(find.byKey(const Key('icon')));
      expect(icon.color, isNull);
      final iconColor = IconTheme.of(
        tester.element(find.byKey(const Key('icon'))),
      ).color!;
      expect(
        contrast(iconColor, light.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );

      final titleColor = DefaultTextStyle.of(
        tester.element(find.byKey(const Key('title'))),
      ).style.color!;
      expect(
        contrast(titleColor, light.appBarTheme.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('AppTheme uses the design tokens for Material 3 roles', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
    }

    test('light scheme is built from AppColors, not the default purple', () {
      final scheme = AppTheme.lightColorScheme;
      expect(scheme.primary, AppColors.brand);
      expect(scheme.onPrimary, AppColors.textOnDark);
      expect(scheme.error, AppColors.error);
      expect(scheme.surface, AppColors.card);
      expect(scheme.brightness, Brightness.light);
      // Large/bold button label contrast (WCAG large text).
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(3),
      );
    });

    test('dark scheme is built from AppColorsWithDarkMode', () {
      final scheme = AppTheme.darkColorScheme;
      expect(scheme.primary, AppColorsWithDarkMode.brand);
      expect(scheme.error, AppColorsWithDarkMode.error);
      expect(scheme.surface, AppColorsWithDarkMode.card);
      expect(scheme.brightness, Brightness.dark);
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('both themes expose those schemes', (tester) async {
      late ThemeData light;
      late ThemeData dark;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) {
            light = AppTheme.light;
            dark = AppTheme.dark;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(light.colorScheme.primary, AppColors.brand);
      expect(dark.colorScheme.primary, AppColorsWithDarkMode.brand);
    });

    testWidgets('system bar icons contrast with the active theme', (
      tester,
    ) async {
      late ThemeData light;
      late ThemeData dark;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) {
            light = AppTheme.light;
            dark = AppTheme.dark;
            return const SizedBox.shrink();
          },
        ),
      );

      final onLight = AppTheme.systemUiStyleFor(light);
      final onDark = AppTheme.systemUiStyleFor(dark);
      expect(onLight.statusBarIconBrightness, Brightness.dark);
      expect(onDark.statusBarIconBrightness, Brightness.light);
      expect(onLight.statusBarBrightness, Brightness.light);
      expect(onDark.statusBarBrightness, Brightness.dark);
      expect(onDark.systemNavigationBarColor, dark.scaffoldBackgroundColor);
      expect(onLight.statusBarColor, Colors.transparent);
    });
  });
}
