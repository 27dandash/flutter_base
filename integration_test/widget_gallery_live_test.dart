import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../tool/widget_gallery/main.dart' as gallery;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('canonical gallery supports live interaction', (tester) async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const gallery.WidgetGalleryApp(),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Canonical widget gallery'), findsOneWidget);

    expect(find.byKey(const Key('button-primary')), findsOneWidget);

    await tester.tap(find.byKey(const Key('button-primary')));
    await tester.tap(find.byKey(const Key('button-primary')));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await _pumpUi(tester);

    final disabled = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(const Key('button-disabled')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(disabled.properties.enabled, isFalse);

    await tester.tap(find.byKey(const Key('gallery-theme')));
    await _pumpUi(tester);
    expect(
      Theme.of(tester.element(find.text('Canonical widget gallery')))
          .brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const Key('gallery-locale')));
    await _pumpUi(tester);
    expect(
      Directionality.of(tester.element(find.text('Canonical widget gallery'))),
      ui.TextDirection.rtl,
    );

    await _reveal(tester, const Key('field-standard'));
    await tester.tap(find.byKey(const Key('field-standard')));
    await tester.enterText(find.byType(TextFormField).first, 'qa@example.test');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _pumpUi(tester);

    await _reveal(tester, const Key('dropdown-single'));
    await tester.tap(find.byKey(const Key('dropdown-single')));
    await _pumpUi(tester);
    expect(find.text('Alpha'), findsOneWidget);
    await tester.tap(find.text('Alpha'));
    await _pumpUi(tester);
    final confirm = find.text('تأكيد');
    await tester.tap(
      confirm.evaluate().isEmpty ? find.text('Confirm') : confirm,
    );
    await _pumpUi(tester);
    expect(find.text('Alpha'), findsOneWidget);

    await _reveal(tester, const Key('open-confirmation'));
    await tester.tap(find.byKey(const Key('open-confirmation')));
    await _pumpUi(tester);
    expect(find.text('Confirm safe action'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await _pumpUi(tester);

    await tester.tap(find.byKey(const Key('open-bottom-sheet')));
    await _pumpUi(tester);
    expect(find.text('Keyboard-safe bottom sheet'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await _pumpUi(tester);

    await tester.tap(find.byKey(const Key('show-message')));
    await tester.pump();
    expect(find.text('Accessible feedback'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byKey(const Key('show-message'))))
        .clearSnackBars();
    await _pumpUi(tester);

    await tester.tap(find.byKey(const Key('show-overlay')));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(ModalBarrier), findsWidgets);
    await tester.pump(const Duration(milliseconds: 300));
    await _pumpUi(tester);

    await _reveal(tester, const Key('missing-media'));
    await _pumpUi(tester);
    expect(find.byKey(const Key('missing-media')), findsOneWidget);

    await _reveal(tester, const Key('open-sliver-page'));
    await tester.tap(find.byKey(const Key('open-sliver-page')));
    await _pumpUi(tester);
    expect(find.text('Sliver page shell'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpUi(tester);
    expect(find.text('Canonical widget gallery'), findsOneWidget);
  });
}

Future<void> _reveal(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    500,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('gallery-list')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await _pumpUi(tester);
}

Future<void> _pumpUi(WidgetTester tester) async {
  // The gallery deliberately keeps loading indicators alive, so
  // pumpAndSettle would never terminate. Two bounded frames cover route,
  // dialog, sheet, locale, and theme animations without hiding a hang.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}
