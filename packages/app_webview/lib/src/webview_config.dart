import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum AppWebViewOutcome { success, failure, cancelled }

final class AppWebViewResult {
  const AppWebViewResult(this.outcome, {this.uri, this.error});

  final AppWebViewOutcome outcome;
  final Uri? uri;
  final String? error;
}

typedef WebCallbackMatcher = bool Function(Uri uri);
typedef ExternalUrlOpener = Future<bool> Function(Uri uri);

@immutable
final class AppWebViewMessages {
  const AppWebViewMessages({
    this.loadFailed = 'This page could not be loaded.',
    this.navigationBlocked = 'This link cannot be opened safely.',
    this.retry = 'Retry',
    this.loading = 'Loading page',
  });

  final String loadFailed;
  final String navigationBlocked;
  final String retry;
  final String loading;
}

@immutable
final class AppWebViewConfig {
  const AppWebViewConfig({
    required this.initialUri,
    required this.title,
    required this.allowedHosts,
    this.successMatcher,
    this.failureMatcher,
    this.openExternal,
    this.approvedExternalSchemes = const {'tel', 'mailto'},
    this.javaScriptMode = JavaScriptMode.disabled,
    this.cookies = const [],
    this.allowHttp = false,
    this.downloadsEnabled = false,
    this.isDownload,
    this.messages = const AppWebViewMessages(),
  });

  final Uri initialUri;
  final String title;
  final Set<String> allowedHosts;
  final WebCallbackMatcher? successMatcher;
  final WebCallbackMatcher? failureMatcher;
  final ExternalUrlOpener? openExternal;
  final Set<String> approvedExternalSchemes;
  final JavaScriptMode javaScriptMode;
  final List<WebViewCookie> cookies;
  final bool allowHttp;
  final bool downloadsEnabled;
  final bool Function(Uri uri)? isDownload;
  final AppWebViewMessages messages;

  String? validate() {
    if (!initialUri.hasScheme || initialUri.host.trim().isEmpty) {
      return 'The initial URL is invalid.';
    }
    if (initialUri.scheme != 'https' &&
        !(allowHttp && initialUri.scheme == 'http')) {
      return 'Only HTTPS URLs are allowed.';
    }
    if (allowedHosts.isEmpty) return 'At least one allowed host is required.';
    if (!isHostAllowed(initialUri.host)) {
      return 'The initial URL host is not allowed.';
    }
    return null;
  }

  bool isHostAllowed(String host) {
    final normalized = host.toLowerCase();
    return allowedHosts.any((allowed) {
      final candidate = allowed.toLowerCase().trim();
      return normalized == candidate || normalized.endsWith('.$candidate');
    });
  }
}
