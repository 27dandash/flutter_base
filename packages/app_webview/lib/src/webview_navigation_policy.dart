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
    if (config.successMatcher?.call(uri) ?? false) {
      return WebNavigationDecision(WebNavigationAction.completeSuccess, uri);
    }
    if (config.failureMatcher?.call(uri) ?? false) {
      return WebNavigationDecision(WebNavigationAction.completeFailure, uri);
    }

    final scheme = uri.scheme.toLowerCase();
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

final class WebViewCompletionGuard {
  bool _completed = false;

  bool completeOnce() {
    if (_completed) return false;
    _completed = true;
    return true;
  }
}
