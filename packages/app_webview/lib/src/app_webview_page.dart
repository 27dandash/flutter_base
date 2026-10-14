import 'dart:async';

import 'package:flutter/material.dart';
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

final class _AppWebViewPageState extends State<AppWebViewPage> {
  WebViewController? _controller;
  late final WebViewNavigationPolicy _policy;
  final WebViewCompletionGuard _completion = WebViewCompletionGuard();
  int _progress = 0;
  String? _error;
  Uri? _pageUri;

  @override
  void initState() {
    super.initState();
    _policy = WebViewNavigationPolicy(widget.config);
    final error = widget.config.validate();
    if (error != null) {
      _error = widget.config.messages.loadFailed;
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
              if (mounted) setState(() => _progress = progress);
            },
            onPageStarted: (url) {
              _pageUri = Uri.tryParse(url);
              if (mounted) setState(() => _error = null);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _progress = 100);
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == false || !mounted) return;
              setState(() => _error = widget.config.messages.loadFailed);
            },
            onHttpError: (error) {
              // Sub-resource failures (favicon, images, scripts) must not
              // replace a page that loaded.
              final concernsPage = httpErrorConcernsPage(
                requestUri: error.request?.uri,
                pageUri: _pageUri,
              );
              if (concernsPage && mounted) {
                setState(() => _error = widget.config.messages.loadFailed);
              }
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
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(() => _error = widget.config.messages.loadFailed);
      }
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
        if (request.isMainFrame && mounted) {
          setState(() => _error = widget.config.messages.navigationBlocked);
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
      setState(() => _error = null);
      await _initialize();
    } else {
      setState(() {
        _error = null;
        _progress = 0;
      });
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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final error = _error;
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
    final controller = _controller;
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
        if (_progress < 100)
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress / 100,
          ),
      ],
    );
  }
}
