import 'dart:ui';

import 'notification_enums.dart';
import 'notification_payload_normalizer.dart';

final class NotificationPayload {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationChannel channel;
  final String? imageUrl;
  final String? itemId;
  final String? sender;
  final String? senderModel;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.channel,
    required this.receivedAt,
    this.imageUrl,
    this.itemId,
    this.sender,
    this.senderModel,
    this.data = const {},
  });

  factory NotificationPayload.fromMap(
    Map<String, dynamic> data, {
    String? languageCode,
  }) {
    final payload = normalizeNotificationPayload(data);
    final lang =
        languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    final isAr = lang == 'ar';

    return NotificationPayload(
      id:
          (data['id']?.toString()) ??
          (payload['notification_id']?.toString()) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _pick(
        payload,
        isAr: isAr,
        arKey: 'title_ar',
        enKey: 'title_en',
        fallbackKey: 'title',
      ),
      body: _pick(
        payload,
        isAr: isAr,
        arKey: 'body_ar',
        enKey: 'body_en',
        fallbackKey: 'body',
      ),
      type: _parseEnum(
        NotificationType.values,
        payload['type']?.toString(),
        NotificationType.message,
      ),
      channel: _parseEnum(
        NotificationChannel.values,
        payload['channel']?.toString(),
        NotificationChannel.general,
      ),
      imageUrl: payload['image_url']?.toString(),
      itemId: payload['item_id']?.toString(),
      sender: payload['sender']?.toString(),
      senderModel: payload['sender_model']?.toString(),
      data: payload,
      receivedAt: DateTime.now(),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static String _pick(
    Map<String, dynamic> data, {
    required bool isAr,
    required String arKey,
    required String enKey,
    required String fallbackKey,
  }) {
    final localized = isAr ? data[arKey] : data[enKey];
    if (localized != null && localized.toString().isNotEmpty) {
      return localized.toString();
    }
    return data[fallbackKey]?.toString() ?? '';
  }

  static T _parseEnum<T extends Enum>(List<T> values, String? raw, T fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
