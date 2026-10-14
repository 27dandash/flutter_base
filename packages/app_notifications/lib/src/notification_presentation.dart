import 'package:flutter/foundation.dart';

/// Visual and channel configuration for notifications that the app displays
/// itself while it is in the foreground.
///
/// The defaults reproduce the channel used by the reference product: a single
/// high-importance channel with sound and vibration.
@immutable
final class NotificationPresentation {
  const NotificationPresentation({
    this.channelId = 'high_importance_channel',
    this.channelName = 'High Importance Notifications',
    this.channelDescription,
    this.androidIcon = '@mipmap/ic_launcher',
    this.fallbackTitle = 'إشعار جديد',
  });

  final String channelId;
  final String channelName;
  final String? channelDescription;

  /// Android drawable/mipmap resource used as the small icon.
  final String androidIcon;

  /// Shown when neither the message nor its data carries a title.
  final String fallbackTitle;
}

/// Display text resolved from an FCM message.
typedef NotificationText = ({String title, String body});

/// Resolves the title and body to display for an FCM message.
///
/// The backend delivers text in different places per platform: on iOS the
/// `notification` block wins and `data` is the fallback; on Android the `data`
/// block wins and `notification` is the fallback. Empty strings are valid
/// values and are not replaced, matching the reference implementation.
NotificationText resolveNotificationText({
  required Map<String, dynamic> data,
  required String? notificationTitle,
  required String? notificationBody,
  required bool isIOS,
  required String fallbackTitle,
}) {
  String? read(String key) => data[key]?.toString();

  if (isIOS) {
    return (
      title:
          notificationTitle ?? read('title') ?? read('Title') ?? fallbackTitle,
      body:
          notificationBody ??
          read('body') ??
          read('Body') ??
          read('message') ??
          read('body_ar') ??
          read('body_en') ??
          '',
    );
  }
  return (
    title: read('title') ?? read('Title') ?? notificationTitle ?? fallbackTitle,
    body:
        read('message') ??
        read('body') ??
        read('Body') ??
        read('body_ar') ??
        read('body_en') ??
        notificationBody ??
        '',
  );
}
