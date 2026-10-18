import 'dart:ui' as ui;

import 'package:flutter_base/src/core/widgets/fields/text_fields/default_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'localized_widget_harness.dart';

Widget _host(
  Widget child, {
  ui.TextDirection direction = ui.TextDirection.ltr,
}) {
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
        direction: ui.TextDirection.rtl,
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

  testWidgets('password toggle defaults resolve localized English label', (
    tester,
  ) async {
    await ensureLocalizedTests();
    await pumpLocalized(
      tester,
      const DefaultTextField(isPassword: true, initialValue: 'secret'),
      locale: const Locale('en'),
    );
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, 'Show password');
  });

  testWidgets('password toggle defaults resolve localized Arabic label', (
    tester,
  ) async {
    await ensureLocalizedTests();
    await pumpLocalized(
      tester,
      const DefaultTextField(isPassword: true, initialValue: 'secret'),
      locale: const Locale('ar'),
      direction: ui.TextDirection.rtl,
    );
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, 'إظهار كلمة المرور');
  });

  testWidgets('explicit line limits work without a multiline keyboard type', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const DefaultTextField(maxLines: 3, minLines: 2)),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.maxLines, 3);
    expect(editable.minLines, 2);
  });

  testWidgets(
    'password fields remain single-line when line limits are passed',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const DefaultTextField(isPassword: true, maxLines: 3, minLines: 2),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.maxLines, 1);
      expect(editable.minLines, 1);
    },
  );

  group('autofill and keyboard learning', () {
    EditableText editable(WidgetTester tester) =>
        tester.widget<EditableText>(find.byType(EditableText));

    testWidgets('a password field asks for the password hint only', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const DefaultTextField(isPassword: true)));

      expect(editable(tester).autofillHints, [AutofillHints.password]);
      expect(editable(tester).autocorrect, isFalse);
      expect(editable(tester).enableSuggestions, isFalse);
    });

    testWidgets('typed fields get the matching hint', (tester) async {
      Future<Iterable<String>?> hintsFor(TextInputType type) async {
        await tester.pumpWidget(_host(DefaultTextField(inputType: type)));
        return editable(tester).autofillHints;
      }

      expect(await hintsFor(TextInputType.emailAddress), [AutofillHints.email]);
      expect(await hintsFor(TextInputType.phone), [
        AutofillHints.telephoneNumber,
      ]);
      expect(await hintsFor(TextInputType.url), [AutofillHints.url]);
    });

    testWidgets('free text and numbers get no contact autofill', (
      tester,
    ) async {
      for (final type in [
        TextInputType.text,
        TextInputType.number,
        TextInputType.multiline,
        TextInputType.datetime,
      ]) {
        await tester.pumpWidget(_host(DefaultTextField(inputType: type)));
        expect(editable(tester).autofillHints, isNull, reason: '$type');
      }
    });

    testWidgets('explicit hints are respected', (tester) async {
      await tester.pumpWidget(
        _host(const DefaultTextField(autofillHints: [AutofillHints.username])),
      );

      expect(editable(tester).autofillHints, [AutofillHints.username]);
    });

    testWidgets('ordinary fields keep autocorrect and suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const DefaultTextField()));

      expect(editable(tester).autocorrect, isTrue);
      expect(editable(tester).enableSuggestions, isTrue);
    });
  });
}
