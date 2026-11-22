import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'webview_config.dart';
import 'webview_navigation_policy.dart';

final class AppWebViewPage extends StatefulWidget {
  const AppWebViewPage({super.key, required this.config, this.onResult});

  final AppWebViewConfig config;
  final ValueChanged<AppWebViewResult>? onResult;

  @override
  State<AppWebViewPage> createState() => _AppWebViewPageState();
}

/// Everything the page body shows. Held in a [ValueNotifier] so progress
/// ticks rebuild only the body (no page-level `setState`).
@immutable
final class _WebViewState {
  const _WebViewState({this.controller, this.progress = 0, this.error});

  final WebViewController? controller;
  final int progress;
  final String? error;

  _WebViewState copyWith({
    WebViewController? controller,
    int? progress,
    String? error,
    bool clearError = false,
  }) => _WebViewState(
    controller: controller ?? this.controller,
    progress: progress ?? this.progress,
    error: clearError ? null : (error ?? this.error),
  );
}

final class _AppWebViewPageState extends State<AppWebViewPage> {
  final ValueNotifier<_WebViewState> _state = ValueNotifier(
    const _WebViewState(),
  );
  late final WebViewNavigationPolicy _policy;
  final WebViewCompletionGuard _completion = WebViewCompletionGuard();
  Uri? _pageUri;

  WebViewController? get _controller => _state.value.controller;

  void _update(_WebViewState Function(_WebViewState current) change) {
    if (!mounted) return;
    _state.value = change(_state.value);
  }

  void _fail(String message) => _update((s) => s.copyWith(error: message));

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _policy = WebViewNavigationPolicy(widget.config);
    final error = widget.config.validate();
    if (error != null) {
      _state.value = _state.value.copyWith(
        error: widget.config.messages.loadFailed,
      );
      return;
    }
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final cookieManager = WebViewCookieManager();
      for (final cookie in widget.config.cookies) {
        await cookieManager.setCookie(cookie);
      }
      final controller = WebViewController()
        ..setJavaScriptMode(widget.config.javaScriptMode)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              _update((s) => s.copyWith(progress: progress));
            },
            onPageStarted: (url) {
              _pageUri = Uri.tryParse(url);
              _update((s) => s.copyWith(clearError: true));
            },
            onPageFinished: (_) {
              _update((s) => s.copyWith(progress: 100));
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == false) return;
              _fail(widget.config.messages.loadFailed);
            },
            onHttpError: (error) {
              // Sub-resource failures (favicon, images, scripts) must not
              // replace a page that loaded.
              final concernsPage = httpErrorConcernsPage(
                requestUri: error.request?.uri,
                pageUri: _pageUri,
              );
              if (concernsPage) _fail(widget.config.messages.loadFailed);
            },
            onNavigationRequest: _onNavigationRequest,
            onUrlChange: (change) {
              final url = change.url;
              if (url == null) return;
              _pageUri = Uri.tryParse(url);
              _handleCompletion(_policy.evaluate(url));
            },
          ),
        );
      await controller.loadRequest(widget.config.initialUri);
      _update((s) => s.copyWith(controller: controller));
    } catch (_) {
      _fail(widget.config.messages.loadFailed);
    }
  }

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final decision = _policy.evaluateFrame(
      request.url,
      isMainFrame: request.isMainFrame,
    );
    switch (decision.action) {
      case WebNavigationAction.navigate:
        return NavigationDecision.navigate;
      case WebNavigationAction.openExternal:
        final uri = decision.uri;
        if (uri != null) await widget.config.openExternal?.call(uri);
        return NavigationDecision.prevent;
      case WebNavigationAction.completeSuccess:
      case WebNavigationAction.completeFailure:
        _handleCompletion(decision);
        return NavigationDecision.prevent;
      case WebNavigationAction.block:
        // A blocked sub-frame is dropped quietly; only the page itself
        // being blocked is worth telling the user about.
        if (request.isMainFrame) {
          _fail(widget.config.messages.navigationBlocked);
        }
        return NavigationDecision.prevent;
    }
  }

  void _handleCompletion(WebNavigationDecision decision) {
    final outcome = switch (decision.action) {
      WebNavigationAction.completeSuccess => AppWebViewOutcome.success,
      WebNavigationAction.completeFailure => AppWebViewOutcome.failure,
      _ => null,
    };
    if (outcome == null || !_completion.completeOnce() || !mounted) return;
    final result = AppWebViewResult(outcome, uri: decision.uri);
    widget.onResult?.call(result);
    Navigator.of(context).pop(result);
  }

  Future<void> _retry() async {
    final controller = _controller;
    if (controller == null) {
      _update((s) => s.copyWith(clearError: true));
      await _initialize();
    } else {
      _update((s) => s.copyWith(clearError: true, progress: 0));
      await controller.reload();
    }
  }

  Future<void> _handleBack() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    if (!mounted || !_completion.completeOnce()) return;
    const result = AppWebViewResult(AppWebViewOutcome.cancelled);
    widget.onResult?.call(result);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _handleBack(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title),
          leading: BackButton(onPressed: _handleBack),
        ),
        body: ValueListenableBuilder<_WebViewState>(
          valueListenable: _state,
          builder: (context, state, _) => _buildBody(state),
        ),
      ),
    );
  }

  Widget _buildBody(_WebViewState state) {
    final error = state.error;
    if (error != null) {
      return Semantics(
        liveRegion: true,
        label: error,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _retry,
                  child: Text(widget.config.messages.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final controller = state.controller;
    if (controller == null) {
      return Semantics(
        liveRegion: true,
        label: widget.config.messages.loading,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (state.progress < 100)
          LinearProgressIndicator(
            value: state.progress == 0 ? null : state.progress / 100,
          ),
      ],
    );
  }
}
