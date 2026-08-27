import 'package:app_webview_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showcase proves safe state without creating a platform view', (
    tester,
  ) async {
    await tester.pumpWidget(const WebViewExampleApp());
    await tester.pump();
    expect(find.text('Web content is intentionally not configured.'), findsOne);
    expect(tester.takeException(), isNull);
  });
}
