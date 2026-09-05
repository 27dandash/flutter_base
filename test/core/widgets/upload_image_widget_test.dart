import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_base/src/core/widgets/image_widgets/upload_image.dart';

import 'localized_widget_harness.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('does not invoke upload callback after dispose', (tester) async {
    var uploads = 0;

    await tester.pumpWidget(
      _host(
        UploadImageWidget(
          tappedItem: const Text('pick'),
          onUpload: (_) => uploads++,
        ),
      ),
    );

    await tester.tap(find.text('pick'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(uploads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker exposes accessible semantics label', (tester) async {
    await ensureLocalizedTests();
    await pumpLocalized(
      tester,
      const UploadImageWidget(tappedItem: Text('pick')),
      locale: const Locale('en'),
    );

    final semanticsFinder = find.descendant(
      of: find.byType(UploadImageWidget),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label != null &&
            widget.properties.label!.isNotEmpty,
      ),
    );
    expect(semanticsFinder, findsOneWidget);
  });
}
