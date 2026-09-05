import 'package:flutter_base/src/core/shared/helpers/loading_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('controller scopes loading state and releases the barrier', (
    tester,
  ) async {
    final first = BlockingOverlayController();
    final second = BlockingOverlayController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FullScreenLoadingManager(
          controller: first,
          loadingLabel: 'Loading',
          child: const Text('content'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Loading'), findsNothing);

    first.show();
    await tester.pump();
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(second.value, isFalse);

    first.hide();
    await tester.pump();
    expect(find.bySemanticsLabel('Loading'), findsNothing);
  });

  testWidgets('loading overlay blocks system Back by default', (tester) async {
    final controller = BlockingOverlayController();
    addTearDown(controller.dispose);
    var popped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FullScreenLoadingManager(
            controller: controller,
            loadingLabel: 'Loading',
            child: Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => FullScreenLoadingManager(
                        controller: controller,
                        loadingLabel: 'Loading',
                        child: const Scaffold(body: Text('detail')),
                      ),
                    ),
                  );
                  popped = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    controller.show();
    await tester.pump();

    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('detail'), findsOneWidget);
    expect(popped, isFalse);

    controller.hide();
    await tester.pump();
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(popped, isTrue);
  });

  testWidgets('allowBackWhileLoading opts out of Back blocking', (
    tester,
  ) async {
    final controller = BlockingOverlayController();
    addTearDown(controller.dispose);
    var popped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FullScreenLoadingManager(
            controller: controller,
            allowBackWhileLoading: true,
            loadingLabel: 'Loading',
            child: Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => FullScreenLoadingManager(
                        controller: controller,
                        allowBackWhileLoading: true,
                        loadingLabel: 'Loading',
                        child: const Scaffold(body: Text('detail')),
                      ),
                    ),
                  );
                  popped = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    controller.show();
    await tester.pump();
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(popped, isTrue);
  });

  testWidgets('repeated show/hide keeps Back blocking in sync', (tester) async {
    final controller = BlockingOverlayController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: FullScreenLoadingManager(
          controller: controller,
          loadingLabel: 'Loading',
          child: const Scaffold(body: Text('detail')),
        ),
      ),
    );

    controller.show();
    await tester.pump();
    controller.hide();
    await tester.pump();
    controller.show();
    await tester.pump();

    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    controller.hide();
    await tester.pump();
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
  });
}
