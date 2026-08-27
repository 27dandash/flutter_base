import 'package:app_webview/app_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invalid configuration renders injected safe localized copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const messages = AppWebViewMessages(
      loadFailed: 'تعذر تحميل الصفحة',
      retry: 'إعادة المحاولة',
      loading: 'جار التحميل',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AppWebViewPage(
              config: AppWebViewConfig(
                initialUri: Uri.parse('http://unsafe.example.test'),
                title: 'الدفع',
                allowedHosts: const {'safe.example.test'},
                messages: messages,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(messages.loadFailed), findsOneWidget);
    expect(find.text(messages.retry), findsOneWidget);
    expect(find.textContaining('HTTPS'), findsNothing);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any((widget) => widget.properties.label == messages.loadFailed),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
