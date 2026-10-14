import 'package:app_notifications/src/notification_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug notification logs redact content and identifiers', () {
    const secrets = [
      'private title',
      'private body',
      'user-42',
      '/private/route',
      'https://secret.example/path',
      'raw plugin exception',
    ];
    final log = NotificationController.formatDebugLog('ACTION', {
      'title': secrets[0],
      'body': secrets[1],
      'userId': secrets[2],
      'route': secrets[3],
      'url': secrets[4],
      'error': secrets[5],
      'startedByForeground': 'foreground',
    });

    for (final secret in secrets) {
      expect(log, isNot(contains(secret)));
    }
    expect(log, contains('startedByForeground: foreground'));
    expect(RegExp('<redacted>').allMatches(log), hasLength(secrets.length));
  });
}
