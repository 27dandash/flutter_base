import 'package:flutter/foundation.dart';
import 'package:flutter_base/src/core/shared/helpers/lancher_helper.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeLauncher implements UrlLauncher {
  _FakeLauncher({this.installed = const {}, this.throwOnLaunch = false});

  /// Schemes that can be opened (the fallback web link is always openable).
  final Set<String> installed;
  final bool throwOnLaunch;
  final launched = <Uri>[];

  @override
  Future<bool> canLaunch(Uri uri) async =>
      uri.scheme == 'https' ||
      uri.scheme == 'tel' ||
      uri.scheme == 'mailto' ||
      installed.contains(uri.scheme);

  @override
  Future<bool> launch(Uri uri) async {
    if (throwOnLaunch) throw StateError('plugin failure for $uri');
    launched.add(uri);
    return true;
  }
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    LauncherHelper.launcher = const _NullLauncher();
  });

  group('webUri', () {
    test('adds https to a bare host and keeps http(s) links', () {
      expect(
        LauncherHelper.webUri('example.com/a?b=1')?.toString(),
        'https://example.com/a?b=1',
      );
      expect(LauncherHelper.webUri(' https://example.com ')?.scheme, 'https');
      expect(LauncherHelper.webUri('http://example.com')?.scheme, 'http');
      expect(LauncherHelper.webUri('example.com:8080/p')?.port, 8080);
    });

    test('rejects other schemes instead of wrapping them in https', () {
      for (final bad in [
        'javascript:alert(1)',
        'intent://x#Intent;end',
        'file:///etc/passwd',
        'tel:+966501234567',
        'mailto:a@b.com',
        'data:text/html,<b>x</b>',
        '',
        'localhost',
        'not a url',
      ]) {
        expect(LauncherHelper.webUri(bad), isNull, reason: bad);
      }
    });
  });

  group('WhatsApp', () {
    test('keeps the country code and encodes the message', () {
      expect(
        LauncherHelper.whatsAppUri('+966 50-123-4567', web: true)?.toString(),
        'https://wa.me/966501234567',
      );
      expect(
        LauncherHelper.whatsAppUri(
          '00966501234567',
          message: 'hi there & more',
        )?.toString(),
        'whatsapp://send?phone=966501234567&text=hi+there+%26+more',
      );
    });

    test('rejects values that are not phone numbers', () {
      expect(LauncherHelper.whatsAppUri('abc'), isNull);
      expect(LauncherHelper.whatsAppUri('123'), isNull);
      expect(LauncherHelper.whatsAppUri('966501234567&text=x/../'), isNotNull);
      expect(
        LauncherHelper.whatsAppUri('966501234567&text=x/../')?.toString(),
        isNot(contains('text=x')),
        reason: 'only digits survive',
      );
    });

    test('prefers the native scheme on Android and the link on iOS', () async {
      final android = _FakeLauncher(installed: {'whatsapp'});
      LauncherHelper.launcher = android;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await LauncherHelper.launchWhatsApp('+966501234567'), isTrue);
      expect(android.launched.single.scheme, 'whatsapp');

      final ios = _FakeLauncher(installed: {'whatsapp'});
      LauncherHelper.launcher = ios;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await LauncherHelper.launchWhatsApp('+966501234567'), isTrue);
      expect(ios.launched.single.host, 'wa.me');
    });

    test('falls back to the web link and never throws', () async {
      final fake = _FakeLauncher();
      LauncherHelper.launcher = fake;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(await LauncherHelper.launchWhatsApp('+966501234567'), isTrue);
      expect(fake.launched.single.host, 'wa.me');
      expect(await LauncherHelper.launchWhatsApp('nope'), isFalse);
    });
  });

  group('social handles', () {
    test('opens the app when installed, otherwise the profile page', () async {
      final withApp = _FakeLauncher(installed: {'instagram'});
      LauncherHelper.launcher = withApp;
      expect(await LauncherHelper.launchInstagram('@some.user'), isTrue);
      expect(
        withApp.launched.single.toString(),
        'instagram://user?username=some.user',
      );

      final web = _FakeLauncher();
      LauncherHelper.launcher = web;
      expect(await LauncherHelper.launchInstagram('some.user'), isTrue);
      expect(
        web.launched.single.toString(),
        'https://www.instagram.com/some.user',
      );
    });

    test('every network falls back to its web profile', () async {
      for (final entry in <String, Future<bool> Function(String)>{
        'twitter.com': LauncherHelper.launchTwitter,
        'www.facebook.com': LauncherHelper.launchFacebook,
        'www.snapchat.com': LauncherHelper.launchSnapchat,
        'www.tiktok.com': LauncherHelper.launchTikTok,
      }.entries) {
        final fake = _FakeLauncher();
        LauncherHelper.launcher = fake;
        expect(await entry.value('user_1'), isTrue, reason: entry.key);
        expect(fake.launched.single.host, entry.key);
      }
    });

    test('a hostile handle is rejected, not interpolated', () async {
      final fake = _FakeLauncher();
      LauncherHelper.launcher = fake;
      for (final bad in ['../../evil', 'a b', 'x?y=1', 'a/b', '']) {
        expect(await LauncherHelper.launchTwitter(bad), isFalse, reason: bad);
      }
      expect(fake.launched, isEmpty);
    });
  });

  group('tel and mail', () {
    test('build safe URIs and reject junk', () async {
      final fake = _FakeLauncher();
      LauncherHelper.launcher = fake;

      expect(await LauncherHelper.callPhone(phone: '+966 50 123 4567'), isTrue);
      expect(fake.launched.last.toString(), 'tel:+966501234567');
      expect(await LauncherHelper.sendMail(mail: 'a@b.com'), isTrue);
      expect(fake.launched.last.scheme, 'mailto');

      expect(await LauncherHelper.callPhone(phone: 'abc'), isFalse);
      expect(await LauncherHelper.sendMail(mail: 'no at sign'), isFalse);
    });

    test('a plugin failure is reported as false, not thrown', () async {
      LauncherHelper.launcher = _FakeLauncher(throwOnLaunch: true);
      expect(await LauncherHelper.callPhone(phone: '+966501234567'), isFalse);
      expect(await LauncherHelper.launchURL(url: 'example.com'), isFalse);
    });
  });
}

final class _NullLauncher implements UrlLauncher {
  const _NullLauncher();

  @override
  Future<bool> canLaunch(Uri uri) async => false;

  @override
  Future<bool> launch(Uri uri) async => false;
}
