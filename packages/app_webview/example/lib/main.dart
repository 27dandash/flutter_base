import 'package:app_webview/app_webview.dart';
import 'package:flutter/material.dart';

void main() => runApp(const WebViewExampleApp());

class WebViewExampleApp extends StatelessWidget {
  const WebViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    home: AppWebViewPage(
      config: AppWebViewConfig(
        // Deliberately invalid: the example is executable without a real URL
        // and proves safe localized configuration failure behavior.
        initialUri: Uri.parse('http://not-configured.invalid'),
        title: 'Optional WebView showcase',
        allowedHosts: const {'configured.example'},
        messages: const AppWebViewMessages(
          loadFailed: 'Web content is intentionally not configured.',
          retry: 'Retry',
          loading: 'Loading',
        ),
      ),
    ),
  );
}
