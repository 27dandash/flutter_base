import 'dart:async';
import 'dart:io';

import 'package:flutter_base/src/core/widgets/image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PickerService implements AppImagePickerService {
  AppImagePickResult next = const AppImagePickCancelled();
  Completer<AppImagePickResult>? pending;
  int calls = 0;

  @override
  Future<AppImagePickResult> pick({
    required AppImagePickSource source,
    required bool multiple,
    required bool crop,
    int? maxBytes,
  }) {
    calls++;
    return pending?.future ?? Future.value(next);
  }

  @override
  Future<AppImagePickResult> recoverLost({int? maxBytes}) async => next;
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('cancellation does not mutate the field', (tester) async {
    final service = _PickerService();
    var changes = 0;
    await tester.pumpWidget(
      _host(
        AppImagePickerField(
          service: service,
          recoverLostOnStart: false,
          allowCamera: false,
          onChanged: (_) => changes++,
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(changes, 0);
  });

  testWidgets('permission and size failures are safe and retryable', (
    tester,
  ) async {
    final service = _PickerService()
      ..next = const AppImagePickPermissionDenied();
    await tester.pumpWidget(
      _host(
        AppImagePickerField(
          service: service,
          recoverLostOnStart: false,
          allowCamera: false,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(find.byType(OutlinedButton), findsOneWidget);

    service.next = const AppImagePickTooLarge();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(service.calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('success supports replacement, removal and maximum count', (
    tester,
  ) async {
    final service = _PickerService();
    final first = File('/tmp/canonical-picker-first.jpg');
    final second = File('/tmp/canonical-picker-second.jpg');
    final changes = <List<File>>[];
    service.next = AppImagePickSuccess([first]);
    await tester.pumpWidget(
      _host(
        AppImagePickerField(
          service: service,
          recoverLostOnStart: false,
          allowCamera: false,
          maxCount: 1,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    expect(changes.single, [first]);
    expect(find.byType(OutlinedButton), findsNothing);

    service.next = AppImagePickSuccess([second]);
    await tester.tap(find.byTooltip('image_replace'));
    await tester.pump();
    expect(changes.last, [second]);

    await tester.tap(find.byTooltip('image_remove'));
    await tester.pump();
    expect(changes.last, isEmpty);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('repeated taps and async disposal are guarded', (tester) async {
    final service = _PickerService()..pending = Completer<AppImagePickResult>();
    await tester.pumpWidget(
      _host(
        AppImagePickerField(
          service: service,
          recoverLostOnStart: false,
          allowCamera: false,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
    expect(service.calls, 1);
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    service.pending!.complete(const AppImagePickCancelled());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
