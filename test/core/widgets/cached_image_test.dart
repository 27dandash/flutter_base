import 'package:flutter_base/src/core/widgets/image_widgets/cached_image.dart';
import 'package:flutter_base/src/core/widgets/media/app_media_viewer_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
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
}
