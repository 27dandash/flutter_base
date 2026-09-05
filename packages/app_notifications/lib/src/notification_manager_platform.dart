import 'package:awesome_notifications/awesome_notifications.dart';

import 'notification_controller.dart';

/// Narrow platform seam for [NotificationManager] initialization.
///
/// Production code uses [defaultNotificationManagerPlatform]. Tests may inject a
/// fake implementation to avoid native notification plugins.
abstract interface class NotificationManagerPlatform {
  Future<void> initializeLocalNotifications({bool debug = false});
  Future<void> initializeRemoteNotifications({bool debug = false});
  Future<void> startListeningNotificationEvents();
  Future<ReceivedAction?> getInitialNotificationAction();
}

final class DefaultNotificationManagerPlatform
    implements NotificationManagerPlatform {
  const DefaultNotificationManagerPlatform();

  @override
  Future<void> initializeLocalNotifications({bool debug = false}) =>
      NotificationController.initializeLocalNotifications(debug: debug);

  @override
  Future<void> initializeRemoteNotifications({bool debug = false}) =>
      NotificationController.initializeRemoteNotifications(debug: debug);

  @override
  Future<void> startListeningNotificationEvents() =>
      NotificationController.startListeningNotificationEvents();

  @override
  Future<ReceivedAction?> getInitialNotificationAction() =>
      AwesomeNotifications().getInitialNotificationAction(
        removeFromActionEvents: true,
      );
}

const NotificationManagerPlatform defaultNotificationManagerPlatform =
    DefaultNotificationManagerPlatform();
