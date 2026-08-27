import 'package:flutter_base/src/config/themes/app_theme.dart';
import 'package:flutter_base/src/core/navigation/route_generator.dart';
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
}
