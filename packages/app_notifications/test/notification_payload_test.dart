import 'package:app_notifications/app_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeNotificationPayload', () {
    test('keeps an already-flat payload unchanged', () {
      final source = <String, dynamic>{
        'id': 'notification-1',
        'type': 'alert',
        'item_id': '42',
      };

      expect(normalizeNotificationPayload(source), source);
      expect(source, isNot(contains('notification_id')));
    });

    test('flattens nested map and retains a colliding transport id', () {
      final normalized = normalizeNotificationPayload({
        'id': 'notification-1',
        'type': 'message',
        'data': {'id': 'entity-7', 'type': 'alert', 'item_id': 7},
      });

      expect(normalized['id'], 'entity-7');
      expect(normalized['notification_id'], 'notification-1');
      expect(normalized['type'], 'alert');
      expect(normalized['item_id'], 7);
    });

    test('flattens a JSON object string and ignores malformed data', () {
      expect(
        normalizeNotificationPayload({
          'data': '{"type":"media","item_id":"8"}',
        }),
        containsPair('item_id', '8'),
      );
      expect(
        normalizeNotificationPayload({'type': 'call', 'data': '{broken'}),
        containsPair('type', 'call'),
      );
    });
  });

  group('NotificationPayload', () {
    test('parses nested transport data and localized text', () {
      final payload = NotificationPayload.fromMap({
        'id': 'notification-9',
        'data': {
          'type': 'alert',
          'channel': 'system',
          'item_id': 91,
          'title_ar': 'عنوان آمن',
          'title_en': 'Safe title',
          'body_ar': 'رسالة آمنة',
          'body_en': 'Safe body',
        },
      }, languageCode: 'ar');

      expect(payload.id, 'notification-9');
      expect(payload.type, NotificationType.alert);
      expect(payload.channel, NotificationChannel.system);
      expect(payload.itemId, '91');
      expect(payload.title, 'عنوان آمن');
      expect(payload.body, 'رسالة آمنة');
      expect(payload.data['item_id'], 91);
    });

    test('unknown product type remains data and uses safe visual fallback', () {
      final payload = NotificationPayload.fromMap({
        'data': '{"type":"product_order_changed","order_id":"12"}',
      }, languageCode: 'en');

      expect(payload.type, NotificationType.message);
      expect(payload.data['type'], 'product_order_changed');
      expect(payload.data['order_id'], '12');
    });
  });
}
