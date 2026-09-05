import 'package:app_webview/app_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('back pops exactly once with a cancelled result', (tester) async {
    AppWebViewResult? result;
    var pops = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final value = await Navigator.of(context)
                    .push<AppWebViewResult>(
                      MaterialPageRoute(
                        builder: (_) => AppWebViewPage(
                          config: AppWebViewConfig(
                            initialUri: Uri.parse('http://unsafe.example.test'),
                            title: 'Payment',
                            allowedHosts: const {'safe.example.test'},
                          ),
                          onResult: (value) => result = value,
                        ),
                      ),
                    );
                pops++;
                result ??= value;
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump();

    expect(result?.outcome, AppWebViewOutcome.cancelled);
    expect(pops, 1);
    expect(find.byType(AppWebViewPage), findsNothing);
  });

  testWidgets('completion guard prevents duplicate success callbacks', (
    tester,
  ) async {
    final guard = WebViewCompletionGuard();
    var completions = 0;

    expect(guard.completeOnce(), isTrue);
    completions++;
    expect(guard.completeOnce(), isFalse);

    expect(completions, 1);
  });

  test('policy success and failure map to completion outcomes', () {
    final policy = WebViewNavigationPolicy(
      AppWebViewConfig(
        initialUri: Uri.parse('https://pay.example.com/start'),
        title: 'Payment',
        allowedHosts: const {'example.com'},
        successMatcher: (uri) => uri.path == '/success',
        failureMatcher: (uri) => uri.path == '/failure',
      ),
    );

    expect(
      policy.evaluate('https://pay.example.com/success').action,
      WebNavigationAction.completeSuccess,
    );
    expect(
      policy.evaluate('https://pay.example.com/failure').action,
      WebNavigationAction.completeFailure,
    );
  });
}
