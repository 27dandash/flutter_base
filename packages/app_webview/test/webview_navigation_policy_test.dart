import 'package:app_webview/app_webview.dart';
import 'package:flutter_test/flutter_test.dart';

AppWebViewConfig _config() => AppWebViewConfig(
  initialUri: Uri.parse('https://pay.example.com/start'),
  title: 'Payment',
  allowedHosts: const {'example.com'},
  successMatcher: (uri) => uri.path == '/success',
  failureMatcher: (uri) => uri.path == '/failure',
);

void main() {
  test('validates initial HTTPS host', () {
    expect(_config().validate(), isNull);
  });

  test('blocks malformed, insecure, and disallowed navigation', () {
    final policy = WebViewNavigationPolicy(_config());
    expect(policy.evaluate('not a url').action, WebNavigationAction.block);
    expect(
      policy.evaluate('http://pay.example.com').action,
      WebNavigationAction.block,
    );
    expect(
      policy.evaluate('https://evil.example.net').action,
      WebNavigationAction.block,
    );
  });

  test('allows the exact host and its subdomains', () {
    final policy = WebViewNavigationPolicy(_config());
    expect(
      policy.evaluate('https://example.com/next').action,
      WebNavigationAction.navigate,
    );
    expect(
      policy.evaluate('https://pay.example.com/next').action,
      WebNavigationAction.navigate,
    );
  });

  test('maps success, failure, and approved external schemes', () {
    final policy = WebViewNavigationPolicy(_config());
    expect(
      policy.evaluate('https://pay.example.com/success').action,
      WebNavigationAction.completeSuccess,
    );
    expect(
      policy.evaluate('https://pay.example.com/failure').action,
      WebNavigationAction.completeFailure,
    );
    expect(
      policy.evaluate('tel:+201000000000').action,
      WebNavigationAction.openExternal,
    );
    expect(
      policy.evaluate('unknown://value').action,
      WebNavigationAction.block,
    );
  });

  test('completion guard rejects duplicate callbacks', () {
    final guard = WebViewCompletionGuard();
    expect(guard.completeOnce(), isTrue);
    expect(guard.completeOnce(), isFalse);
  });
}
