// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter_base/src/core/widgets/buttons/custom_animated_button.dart';
import 'package:flutter_base/src/core/widgets/buttons/button_close.dart';
import 'package:flutter_base/src/core/widgets/buttons/default_button.dart';
import 'package:flutter_base/src/core/widgets/buttons/loading_button.dart';
import 'package:flutter_base/src/core/widgets/image_widgets/cached_image.dart';
import 'package:flutter_base/src/core/widgets/media/app_media_viewer_page.dart';
import 'package:flutter_base/src/core/widgets/scaffolds/arrow_widget.dart';
import 'package:flutter_base/src/core/widgets/scaffolds/default_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DefaultButton disabled state cannot invoke its callback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: DefaultButton(
              title: 'Legacy',
              disabled: true,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Legacy'));
    expect(taps, 0);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('DefaultButton exposes a real 48dp minimum tap target', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: DefaultButton(title: 'Legacy', onTap: () {}),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(ElevatedButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: DefaultButton(height: 56, title: 'Large', onTap: () {}),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ElevatedButton)).height, 56);
  });

  testWidgets('animated compatibility button is safe after async disposal', (
    tester,
  ) async {
    final completion = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomAnimatedButton(
            width: 200,
            height: 48,
            loader: const CircularProgressIndicator(),
            semanticLabel: 'Legacy submit',
            onTap: () => completion.future,
            child: const Text('Submit'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoadingButton has a real disabled action and semantics', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              title: 'Unavailable',
              isDisabled: true,
              onTap: () async => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Unavailable'));
    expect(calls, 0);
    expect(find.bySemanticsLabel('Unavailable'), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('CachedImage ignoreClick has no implicit viewer action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CachedImage(
            url: 'https://example.invalid/image.png',
            ignoreClick: true,
            semanticLabel: 'Profile image',
            placeHolder: SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.bySemanticsLabel('Profile image'), findsOneWidget);
  });

  testWidgets('CachedImage default action opens the canonical viewer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CachedImage(
            url: 'https://example.invalid/image.png',
            semanticLabel: 'Open profile image',
            placeHolder: SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Open profile image').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AppMediaViewerPage), findsOneWidget);
  });

  testWidgets('legacy close action pops its contextual navigator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/next',
        routes: {
          '/': (_) => const Scaffold(body: Text('Home')),
          '/next': (_) => const Scaffold(body: ButtonClose()),
        },
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('legacy back arrow is directional and context-owned', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          initialRoute: '/next',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
            '/next': (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: ArrowWidget()),
            ),
          },
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('DefaultScaffold compatibility path does not suppress Back', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          initialRoute: '/legacy',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
            '/legacy': (_) => const DefaultScaffold(
              title: 'Legacy page',
              body: Text('Legacy body'),
            ),
          },
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
