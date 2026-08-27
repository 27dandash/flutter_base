import 'package:flutter_base/src/core/widgets/scaffolds/app_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('normal page keeps framework back behavior and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageShell(
          title: const Text('Title'),
          actions: const [Icon(Icons.add)],
          body: const Text('Body'),
        ),
      ),
    );
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.byType(PopScope<Object?>), findsNothing);
  });

  testWidgets('contextual back is invoked without popping blindly', (
    tester,
  ) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageShell(
          title: const Text('Edit'),
          onBack: () => backs++,
          body: const Text('Unsaved'),
        ),
      ),
    );
    await tester.tap(find.byType(BackButton));
    expect(backs, 1);
  });

  testWidgets('sliver page survives RTL, dark theme and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: AppPageShell.sliver(
              title: Text('عنوان طويل'),
              slivers: [SliverToBoxAdapter(child: Text('المحتوى'))],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
