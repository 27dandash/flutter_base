# Optional WebView module

Add `app_webview` as a path dependency only in products that need a native
WebView. The default policy requires HTTPS, an explicit host allow-list,
JavaScript disabled, no downloads, no JavaScript bridge, and no SSL bypass.

Configure callback matchers and an injected external URL opener. A success,
failure, or cancellation returns one typed `AppWebViewResult`; duplicate URL
callbacks are ignored. Android uses the system WebView and iOS uses WKWebView
through the official `webview_flutter` plugin.

`example/` is a network-free test application for the safe unavailable state.
It demonstrates package ownership without importing this integration into the
root application.
