import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart'
    hide NotificationChannel;

import 'notification_enums.dart';

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
    final lang =
        languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    final isAr = lang == 'ar';

    return NotificationPayload(
      id:
          (data['id']?.toString()) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _pick(
        data,
        isAr: isAr,
        arKey: 'title_ar',
        enKey: 'title_en',
        fallbackKey: 'title',
      ),
      body: _pick(
        data,
        isAr: isAr,
        arKey: 'body_ar',
        enKey: 'body_en',
        fallbackKey: 'body',
      ),
      type: _parseEnum(
        NotificationType.values,
        data['type']?.toString(),
        NotificationType.message,
      ),
      channel: _parseEnum(
        NotificationChannel.values,
        data['channel']?.toString(),
        NotificationChannel.general,
      ),
      imageUrl: data['image_url']?.toString(),
      itemId: data['item_id']?.toString(),
      sender: data['sender']?.toString(),
      senderModel: data['sender_model']?.toString(),
      data: Map<String, dynamic>.from(data),
      receivedAt: DateTime.now(),
    );
  }

  factory NotificationPayload.fromReceivedNotification(
    ReceivedNotification n, {
    String? languageCode,
  }) {
    final lang =
        languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    final isAr = lang == 'ar';

    final payloadMap = <String, dynamic>{
      if (n.payload != null) ...n.payload!,
      'title': n.title ?? '',
      'body': n.body ?? '',
    };

    return NotificationPayload(
      id: n.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _pick(
        payloadMap,
        isAr: isAr,
        arKey: 'title_ar',
        enKey: 'title_en',
        fallbackKey: 'title',
      ),
      body: _pick(
        payloadMap,
        isAr: isAr,
        arKey: 'body_ar',
        enKey: 'body_en',
        fallbackKey: 'body',
      ),
      type: _parseEnum(
        NotificationType.values,
        payloadMap['type']?.toString(),
        NotificationType.message,
      ),
      channel: _parseEnum(
        NotificationChannel.values,
        n.channelKey,
        NotificationChannel.general,
      ),
      imageUrl: n.bigPicture ?? n.largeIcon,
      itemId: payloadMap['item_id']?.toString(),
      sender: payloadMap['sender']?.toString(),
      senderModel: payloadMap['sender_model']?.toString(),
      data: payloadMap,
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
