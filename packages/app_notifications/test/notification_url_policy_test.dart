import 'package:app_notifications/app_notifications.dart';
import 'package:app_notifications/src/notification_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationUrlPolicy', () {
    const policy = NotificationUrlPolicy.secureDefault;

    test('rejects malformed, empty, and http URLs by default', () {
      expect(policy.parseAllowedUrl(null), isNull);
      expect(policy.parseAllowedUrl(''), isNull);
      expect(policy.parseAllowedUrl('   '), isNull);
      expect(policy.parseAllowedUrl('not-a-url'), isNull);
      expect(policy.parseAllowedUrl('http://safe.example.test/path'), isNull);
    });

    test('accepts well-formed HTTPS URLs when no host allowlist is set', () {
      final uri = policy.parseAllowedUrl('https://links.example.test/path');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'links.example.test');
    });

    test('restricts HTTPS hosts when an allowlist is configured', () {
      const restricted = NotificationUrlPolicy(
        allowedHttpsHosts: {'allowed.example.test'},
      );

      expect(
        restricted.parseAllowedUrl('https://allowed.example.test/a'),
        isNotNull,
      );
      expect(
        restricted.parseAllowedUrl('https://pay.allowed.example.test/a'),
        isNotNull,
      );
      expect(
        restricted.parseAllowedUrl('https://blocked.example.test/a'),
        isNull,
      );
    });

    test('allows explicitly approved extra schemes', () {
      const custom = NotificationUrlPolicy(
        approvedExtraSchemes: {'MYAPP', 'mailto'},
      );

      expect(custom.parseAllowedUrl('myapp://feature/open'), isNotNull);
      expect(custom.parseAllowedUrl('mailto:support@example.test'), isNotNull);
      expect(custom.parseAllowedUrl('ftp://files.example.test/a'), isNull);
    });

    test('rejects URLs containing embedded credentials', () {
      expect(
        policy.parseAllowedUrl('https://user:secret@links.example.test/path'),
        isNull,
      );
    });

    test('equal policies produce equal hash codes', () {
      const first = NotificationUrlPolicy(
        allowedHttpsHosts: {'a.example.test', 'b.example.test'},
      );
      const second = NotificationUrlPolicy(
        allowedHttpsHosts: {'b.example.test', 'a.example.test'},
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('NotificationController.parseAction', () {
    test('maps open_url through the policy and fails closed', () {
      expect(
        NotificationController.parseAction(const {
          'action_type': 'open_url',
          'url': 'http://unsafe.example.test',
        }),
        isA<DismissAction>(),
      );

      final allowed = NotificationController.parseAction(
        const {
          'action_type': 'open_url',
          'url': 'https://links.example.test/path',
        },
        policy: const NotificationUrlPolicy(
          allowedHttpsHosts: {'links.example.test'},
        ),
      );
      expect(allowed, isA<OpenUrl>());
      expect((allowed as OpenUrl).url.host, 'links.example.test');
    });

    test('unknown schemes require explicit opt-in', () {
      expect(
        NotificationController.parseAction(const {
          'action_type': 'open_url',
          'url': 'custom://open',
        }),
        isA<DismissAction>(),
      );

      final optedIn = NotificationController.parseAction(const {
        'action_type': 'open_url',
        'url': 'custom://open',
      }, policy: const NotificationUrlPolicy(approvedExtraSchemes: {'custom'}));
      expect(optedIn, isA<OpenUrl>());
    });
  });
}
