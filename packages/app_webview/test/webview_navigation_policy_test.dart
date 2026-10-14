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

  test('allowHttp permits only approved HTTP hosts', () {
    final policy = WebViewNavigationPolicy(
      AppWebViewConfig(
        initialUri: Uri.parse('http://pay.example.com/start'),
        title: 'Payment',
        allowedHosts: const {'example.com'},
        allowHttp: true,
      ),
    );
    expect(
      policy.evaluate('http://pay.example.com/next').action,
      WebNavigationAction.navigate,
    );
    expect(
      policy.evaluate('http://evil.example.net/next').action,
      WebNavigationAction.block,
    );
  });

  test('downloads require explicit enablement', () {
    bool isDownload(Uri _) => true;
    final blocked = WebViewNavigationPolicy(
      AppWebViewConfig(
        initialUri: Uri.parse('https://pay.example.com/start'),
        title: 'Payment',
        allowedHosts: const {'example.com'},
        isDownload: isDownload,
      ),
    );
    final allowed = WebViewNavigationPolicy(
      AppWebViewConfig(
        initialUri: Uri.parse('https://pay.example.com/start'),
        title: 'Payment',
        allowedHosts: const {'example.com'},
        downloadsEnabled: true,
        isDownload: isDownload,
      ),
    );

    expect(
      blocked.evaluate('https://pay.example.com/file.pdf').action,
      WebNavigationAction.block,
    );
    expect(
      allowed.evaluate('https://pay.example.com/file.pdf').action,
      WebNavigationAction.openExternal,
    );
  });

  test('external-open policy uses injected approved schemes only', () {
    final policy = WebViewNavigationPolicy(
      AppWebViewConfig(
        initialUri: Uri.parse('https://pay.example.com/start'),
        title: 'Payment',
        allowedHosts: const {'example.com'},
        approvedExternalSchemes: const {'maps'},
      ),
    );

    expect(
      policy.evaluate('maps://search?q=value').action,
      WebNavigationAction.openExternal,
    );
    expect(
      policy.evaluate('tel:+201000000000').action,
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

  group('frame and resource rules', () {
    final policy = WebViewNavigationPolicy(
      AppWebViewConfig(
        initialUri: Uri.parse('https://pay.example.com/start'),
        title: 'Pay',
        allowedHosts: const {'pay.example.com'},
        successMatcher: (uri) => uri.path == '/done',
      ),
    );

    test('a sub-frame may navigate within allowed hosts only', () {
      expect(
        policy
            .evaluateFrame('https://pay.example.com/3ds', isMainFrame: false)
            .action,
        WebNavigationAction.navigate,
      );
      expect(
        policy
            .evaluateFrame('https://ads.evil.test/x', isMainFrame: false)
            .action,
        WebNavigationAction.block,
      );
    });

    test('a sub-frame can never complete the flow or open an app', () {
      expect(
        policy
            .evaluateFrame('https://pay.example.com/done', isMainFrame: false)
            .action,
        WebNavigationAction.block,
      );
      expect(
        policy.evaluateFrame('tel:+966500000000', isMainFrame: false).action,
        WebNavigationAction.block,
      );
    });

    test('the main frame keeps the full decision set', () {
      expect(
        policy
            .evaluateFrame('https://pay.example.com/done', isMainFrame: true)
            .action,
        WebNavigationAction.completeSuccess,
      );
      expect(
        policy.evaluateFrame('tel:+966500000000', isMainFrame: true).action,
        WebNavigationAction.openExternal,
      );
    });

    test('only an error for the page itself counts as a page failure', () {
      final page = Uri.parse('https://pay.example.com/start?x=1');
      expect(
        httpErrorConcernsPage(
          requestUri: Uri.parse('https://pay.example.com/start?x=1#top'),
          pageUri: page,
        ),
        isTrue,
      );
      expect(
        httpErrorConcernsPage(
          requestUri: Uri.parse('https://pay.example.com/favicon.ico'),
          pageUri: page,
        ),
        isFalse,
      );
      expect(httpErrorConcernsPage(requestUri: null, pageUri: page), isFalse);
      expect(httpErrorConcernsPage(requestUri: page, pageUri: null), isFalse);
    });
  });
}
