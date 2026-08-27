import 'package:flutter_base/src/core/widgets/fields/text_fields/default_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('supports an initial value without a controller', (tester) async {
    await tester.pumpWidget(
      _host(const DefaultTextField(initialValue: 'initial')),
    );

    expect(find.text('initial'), findsOneWidget);
  });

  testWidgets('password visibility starts hidden and can be toggled once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const DefaultTextField(
          isPassword: true,
          initialValue: 'secret',
          showPasswordSemanticsLabel: 'show',
          hidePasswordSemanticsLabel: 'hide',
        ),
      ),
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('show'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('hide'), findsOneWidget);
  });

  testWidgets('disabled field cannot toggle a password', (tester) async {
    await tester.pumpWidget(
      _host(
        const DefaultTextField(
          isPassword: true,
          enabled: false,
          initialValue: 'secret',
        ),
      ),
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('prefix and suffix remain directional under RTL', (tester) async {
    await tester.pumpWidget(
      _host(
        const DefaultTextField(
          prefixIcon: Icon(Icons.email, key: ValueKey('prefix')),
          suffixIcon: Icon(Icons.check, key: ValueKey('suffix')),
        ),
        direction: TextDirection.rtl,
      ),
    );

    final prefixX = tester.getCenter(find.byKey(const ValueKey('prefix'))).dx;
    final suffixX = tester.getCenter(find.byKey(const ValueKey('suffix'))).dx;
    expect(prefixX, greaterThan(suffixX));
  });

  testWidgets('supports keyboard focus, dark theme, semantics and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: DefaultTextField(
                title: 'Email',
                semanticLabel: 'Email address',
                focusNode: focus,
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'a@example.test');
    expect(focus.hasFocus, isTrue);
    expect(find.bySemanticsLabel('Email address'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
