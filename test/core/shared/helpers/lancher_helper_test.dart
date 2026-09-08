import 'package:flutter_base/src/core/shared/helpers/lancher_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LauncherHelper.debugLaunchDiagnostic redaction', () {
    test('keeps the operation label and exception runtime type', () {
      final message = LauncherHelper.debugLaunchDiagnostic(
        'launchTwitter',
        const FormatException('boom'),
      );

      expect(message, contains('launchTwitter'));
      expect(message, contains('FormatException'));
    });

    test('never leaks the raw exception text, URL, or username', () {
      final error = Exception(
        'Could not launch https://twitter.com/secret_user for +966501234567',
      );

      final message = LauncherHelper.debugLaunchDiagnostic(
        'launchTwitter',
        error,
      );

      expect(message, isNot(contains('secret_user')));
      expect(message, isNot(contains('twitter.com')));
      expect(message, isNot(contains('https')));
      expect(message, isNot(contains('966501234567')));
      expect(message, isNot(contains('Could not launch')));
    });

    test('is stable and identifier-free across differing payloads', () {
      final first = LauncherHelper.debugLaunchDiagnostic(
        'launchInstagram',
        const FormatException('user=alice url=https://ig.test/alice'),
      );
      final second = LauncherHelper.debugLaunchDiagnostic(
        'launchInstagram',
        const FormatException('user=bob phone=0501112222'),
      );

      // Same operation + same runtime type ⇒ identical, payload-independent
      // diagnostic. No user/phone/URL can distinguish the two.
      expect(first, second);
      expect(first, 'LauncherHelper.launchInstagram failed (FormatException)');
    });
  });
}
