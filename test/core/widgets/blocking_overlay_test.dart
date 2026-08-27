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
}
