import 'webview_config.dart';

enum WebNavigationAction {
  navigate,
  openExternal,
  completeSuccess,
  completeFailure,
  block,
}

final class WebNavigationDecision {
  const WebNavigationDecision(this.action, this.uri);

  final WebNavigationAction action;
  final Uri? uri;
}

final class WebViewNavigationPolicy {
  const WebViewNavigationPolicy(this.config);

  final AppWebViewConfig config;

  WebNavigationDecision evaluate(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      return const WebNavigationDecision(WebNavigationAction.block, null);
    }
    final scheme = uri.scheme.toLowerCase();
    // A web page on a host outside the allow-list must not be able to finish
    // the flow by serving a matching path (`/success`). Custom-scheme
    // callbacks (`myapp://paid`) are not hosted pages and stay matchable.
    final isWeb = scheme == 'https' || scheme == 'http';
    final mayComplete = !isWeb || config.isHostAllowed(uri.host);
    if (mayComplete && (config.successMatcher?.call(uri) ?? false)) {
      return WebNavigationDecision(WebNavigationAction.completeSuccess, uri);
    }
    if (mayComplete && (config.failureMatcher?.call(uri) ?? false)) {
      return WebNavigationDecision(WebNavigationAction.completeFailure, uri);
    }

    if (scheme == 'https' || (scheme == 'http' && config.allowHttp)) {
      if (!config.isHostAllowed(uri.host)) {
        return WebNavigationDecision(WebNavigationAction.block, uri);
      }
      final isDownload = config.isDownload?.call(uri) ?? false;
      if (isDownload) {
        return WebNavigationDecision(
          config.downloadsEnabled
              ? WebNavigationAction.openExternal
              : WebNavigationAction.block,
          uri,
        );
      }
      return WebNavigationDecision(WebNavigationAction.navigate, uri);
    }
    if (config.approvedExternalSchemes.contains(scheme)) {
      return WebNavigationDecision(WebNavigationAction.openExternal, uri);
    }
    return WebNavigationDecision(WebNavigationAction.block, uri);
  }
}

/// Frame- and resource-level rules the page applies on top of [evaluate].
extension WebViewFrameRules on WebViewNavigationPolicy {
  /// Like [WebViewNavigationPolicy.evaluate] for a navigation that may happen
  /// in a sub-frame (an embedded payment/3-D Secure iframe, an ad frame).
  ///
  /// Only the main frame may complete the flow, open an external app or
  /// replace the page with an error. A sub-frame is allowed to navigate within
  /// the allowed hosts and is otherwise blocked silently.
  WebNavigationDecision evaluateFrame(
    String rawUrl, {
    required bool isMainFrame,
  }) {
    final decision = evaluate(rawUrl);
    if (isMainFrame || decision.action == WebNavigationAction.navigate) {
      return decision;
    }
    return WebNavigationDecision(WebNavigationAction.block, decision.uri);
  }
}

/// Whether an HTTP error response is about the page itself rather than one of
/// its sub-resources (a missing favicon, a failed image or script).
///
/// WebView reports HTTP errors for every resource it loads, so showing the
/// error page for all of them would replace a working page because of a 404
/// image. Fragments are ignored: `#section` does not change the document.
bool httpErrorConcernsPage({required Uri? requestUri, required Uri? pageUri}) {
  if (requestUri == null || pageUri == null) return false;
  return requestUri.removeFragment() == pageUri.removeFragment();
}

final class WebViewCompletionGuard {
  bool _completed = false;

  bool completeOnce() {
    if (_completed) return false;
    _completed = true;
    return true;
  }
}
