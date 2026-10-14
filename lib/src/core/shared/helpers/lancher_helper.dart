import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Seam over `url_launcher` so URL building and fallback order are testable.
abstract interface class UrlLauncher {
  Future<bool> canLaunch(Uri uri);
  Future<bool> launch(Uri uri);
}

final class _PluginUrlLauncher implements UrlLauncher {
  const _PluginUrlLauncher();

  @override
  Future<bool> canLaunch(Uri uri) => canLaunchUrl(uri);

  @override
  Future<bool> launch(Uri uri) => launchUrl(uri);
}

/// Opens external apps and links.
///
/// Every method returns whether something was opened and never throws: a
/// missing app, a malformed value or a plugin error is `false`. Values are
/// validated and percent-encoded here, never interpolated into a URL.
///
/// Deep links to other apps (`whatsapp://`, `instagram://`, …) can only be
/// probed with `canLaunchUrl` when they are declared in the host app: the
/// `<queries>` block of `AndroidManifest.xml` and `LSApplicationQueriesSchemes`
/// in `Info.plist` (both already list the schemes used below).
class LauncherHelper {
  LauncherHelper._();

  @visibleForTesting
  static UrlLauncher launcher = const _PluginUrlLauncher();

  /// The only diagnostic a launch failure is allowed to emit.
  ///
  /// Structurally redacted: it carries a stable operation label and the
  /// exception's runtime type only — never the raw error text, target URL,
  /// username, phone, or email that the failing value may embed. Exposed for
  /// tests that assert this privacy contract.
  @visibleForTesting
  static String debugLaunchDiagnostic(String operation, Object error) =>
      'LauncherHelper.$operation failed (${error.runtimeType})';

  /// Emits [debugLaunchDiagnostic] in debug builds only. Release builds stay
  /// silent so no raw exception text or identifying data can ever be logged.
  static void _logLaunchFailure(String operation, Object error) {
    if (!kDebugMode) return;
    developer.log(
      debugLaunchDiagnostic(operation, error),
      name: 'LauncherHelper',
    );
  }

  // ── URL builders (pure) ─────────────────────────────────────────

  /// Returns an `http(s)` URI for [raw], or `null` when it is not a web link.
  ///
  /// A value without a scheme gets `https://`. A value that carries any other
  /// scheme (`javascript:`, `intent:`, `file:`, `tel:` …) is rejected rather
  /// than being wrapped into a bogus `https://javascript:…` URL.
  @visibleForTesting
  static Uri? webUri(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final match = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):(.*)$')
        .firstMatch(value);
    if (match != null) {
      final scheme = match.group(1)!.toLowerCase();
      if (scheme == 'http' || scheme == 'https') {
        final uri = Uri.tryParse(value);
        return uri != null && uri.host.isNotEmpty && uri.userInfo.isEmpty
            ? uri
            : null;
      }
      // "example.com:8080/path" is a host and port, not a scheme.
      final isHostAndPort = RegExp(r'^\d+([/?#]|$)').hasMatch(match.group(2)!);
      if (!isHostAndPort) return null;
    }
    final uri = Uri.tryParse('https://$value');
    if (uri == null ||
        uri.host.isEmpty ||
        !uri.host.contains('.') ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  /// International digits only: `+966 50-123-4567` and `00966501234567` both
  /// become `966501234567`. The country code is kept — WhatsApp needs it.
  @visibleForTesting
  static String? internationalDigits(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    digits = digits.replaceAll('+', '');
    return digits.length >= 8 && digits.length <= 15 ? digits : null;
  }

  @visibleForTesting
  static Uri? whatsAppUri(String phone, {String? message, bool web = false}) {
    final digits = internationalDigits(phone);
    if (digits == null) return null;
    final text = message?.trim();
    final query = text == null || text.isEmpty ? null : {'text': text};
    return web
        ? Uri(
            scheme: 'https',
            host: 'wa.me',
            path: digits,
            queryParameters: query,
          )
        : Uri(
            scheme: 'whatsapp',
            host: 'send',
            queryParameters: {'phone': digits, ...?query},
          );
  }

  /// Social handles: leading `@` and surrounding spaces are stripped; anything
  /// that is not a plausible handle is rejected (it ends up inside a path).
  @visibleForTesting
  static String? handle(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'^@+'), '');
    return RegExp(r'^[A-Za-z0-9._-]{1,64}$').hasMatch(value) ? value : null;
  }

  // ── Launching ───────────────────────────────────────────────────

  static Future<bool> _open(String operation, Iterable<Uri?> candidates) async {
    try {
      for (final uri in candidates) {
        if (uri == null) continue;
        if (await launcher.canLaunch(uri) && await launcher.launch(uri)) {
          return true;
        }
      }
    } catch (error) {
      _logLaunchFailure(operation, error);
    }
    return false;
  }

  static Future<bool> launchURL({required String url}) =>
      _open('launchURL', [webUri(url)]);

  /// Opens a chat with [phone] (international format; the country code is
  /// required). [message] pre-fills the text field when given.
  static Future<bool> launchWhatsApp(String phone, {String? message}) {
    // iOS universal link first (works without the app being probed), then the
    // native scheme; Android prefers the native scheme.
    final web = whatsAppUri(phone, message: message, web: true);
    final native = whatsAppUri(phone, message: message);
    final iOS = defaultTargetPlatform == TargetPlatform.iOS;
    return _open('launchWhatsApp', iOS ? [web, native] : [native, web]);
  }

  static Future<bool> launchYoutube({required String url}) =>
      _open('launchYoutube', [webUri(url)]);

  static Future<bool> launchTwitter(String userName) {
    final name = handle(userName);
    if (name == null) return Future.value(false);
    return _open('launchTwitter', [
      Uri(
        scheme: 'twitter',
        host: 'user',
        queryParameters: {'screen_name': name},
      ),
      Uri.https('twitter.com', '/$name'),
    ]);
  }

  static Future<bool> launchInstagram(String userName) {
    final name = handle(userName);
    if (name == null) return Future.value(false);
    return _open('launchInstagram', [
      Uri(
        scheme: 'instagram',
        host: 'user',
        queryParameters: {'username': name},
      ),
      Uri.https('www.instagram.com', '/$name'),
    ]);
  }

  static Future<bool> launchFacebook(String userName) {
    final name = handle(userName);
    if (name == null) return Future.value(false);
    final page = Uri.https('www.facebook.com', '/$name');
    return _open('launchFacebook', [
      Uri(
        scheme: 'fb',
        host: 'facewebmodal',
        path: '/f',
        queryParameters: {'href': page.toString()},
      ),
      page,
    ]);
  }

  static Future<bool> launchSnapchat(String userName) {
    final name = handle(userName);
    if (name == null) return Future.value(false);
    return _open('launchSnapchat', [
      Uri(scheme: 'snapchat', host: 'add', path: '/$name'),
      Uri.https('www.snapchat.com', '/add/$name'),
    ]);
  }

  static Future<bool> launchTikTok(String userName) {
    final name = handle(userName);
    if (name == null) return Future.value(false);
    return _open('launchTikTok', [
      Uri(scheme: 'snssdk1233', host: 'user', queryParameters: {'u': name}),
      Uri.https('www.tiktok.com', '/@$name'),
    ]);
  }

  static Future<bool> callPhone({required String phone}) {
    final value = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.isEmpty) return Future.value(false);
    return _open('callPhone', [Uri(scheme: 'tel', path: value)]);
  }

  static Future<bool> sendMail({required String mail}) {
    final value = mail.trim();
    if (!value.contains('@') || value.contains(RegExp(r'[\s<>]'))) {
      return Future.value(false);
    }
    return _open('sendMail', [Uri(scheme: 'mailto', path: value)]);
  }
}
