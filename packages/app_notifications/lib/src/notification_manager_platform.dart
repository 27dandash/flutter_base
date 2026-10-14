import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_presentation.dart';

/// Default [BackgroundMessageHandler] (from `firebase_messaging`): makes sure
/// Firebase is initialized in the background isolate. The system tray displays
/// `notification` messages by itself, so nothing else is required here.
///
/// A product that needs per-flavor `FirebaseOptions` supplies its own
/// top-level handler to `NotificationManager.initialize`.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (error) {
    if (!error.code.contains('duplicate-app')) rethrow;
  }
}

/// Narrow platform seam for `NotificationManager`.
///
/// Production code uses [defaultNotificationManagerPlatform]. Tests inject a
/// fake implementation so no native plugin is touched.
abstract interface class NotificationManagerPlatform {
  /// Initializes the local-notification plugin and the Android channel.
  /// [onTap] receives the original FCM message when the user taps a
  /// notification that this package displayed.
  Future<void> initializeLocalNotifications({
    required NotificationPresentation presentation,
    required void Function(RemoteMessage message) onTap,
    bool debug = false,
  });

  /// Stops the OS from presenting foreground messages itself, so the app
  /// controls display (and can apply the user's notification preference).
  Future<void> setForegroundPresentationOptions();

  /// Asks for notification permission. Returns whether it was granted.
  Future<bool> requestPermissions();

  /// The message that launched the app from a terminated state, if any.
  Future<RemoteMessage?> getInitialMessage();

  void registerBackgroundHandler(BackgroundMessageHandler handler);

  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Stream<String> get onTokenRefresh;

  Future<String?> getToken();

  /// Displays [message] as a local notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required RemoteMessage message,
    required NotificationPresentation presentation,
  });
}

final class DefaultNotificationManagerPlatform
    implements NotificationManagerPlatform {
  const DefaultNotificationManagerPlatform({this.permissionRequester});

  /// Replaces the Firebase permission call. Only for tests.
  @visibleForTesting
  final Future<NotificationSettings> Function()? permissionRequester;

  static FlutterLocalNotificationsPlugin get _local =>
      FlutterLocalNotificationsPlugin();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<void> initializeLocalNotifications({
    required NotificationPresentation presentation,
    required void Function(RemoteMessage message) onTap,
    bool debug = false,
  }) async {
    await _local.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings(presentation.androidIcon),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = json.decode(payload);
          if (decoded is! Map) return;
          onTap(RemoteMessage.fromMap(Map<String, dynamic>.from(decoded)));
        } on FormatException {
          // A malformed payload cannot be routed; ignore the tap.
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            presentation.channelId,
            presentation.channelName,
            description: presentation.channelDescription,
            importance: Importance.high,
          ),
        );
  }

  @override
  Future<void> setForegroundPresentationOptions() =>
      _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

  /// Asks for permission **once, through Firebase only**.
  ///
  /// `FirebaseMessaging.requestPermission` already covers both platforms: the
  /// iOS alert/badge/sound prompt and the Android 13+ `POST_NOTIFICATIONS`
  /// prompt. Asking again through `flutter_local_notifications` would show a
  /// second system dialog right after a refusal on Android (against Google's
  /// guidance) and an extra request on iOS. The local plugin is initialized
  /// with all permission requests disabled for the same reason.
  @override
  Future<bool> requestPermissions() async {
    final request = permissionRequester ?? _requestFirebasePermission;
    final settings = await request();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<NotificationSettings> _requestFirebasePermission() =>
      _messaging.requestPermission(alert: true, badge: true, sound: true);

  @override
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  @override
  void registerBackgroundHandler(BackgroundMessageHandler handler) =>
      FirebaseMessaging.onBackgroundMessage(handler);

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required RemoteMessage message,
    required NotificationPresentation presentation,
  }) {
    return _local.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          presentation.channelId,
          presentation.channelName,
          channelDescription: presentation.channelDescription,
          enableVibration: true,
          playSound: true,
          icon: presentation.androidIcon,
          importance: Importance.high,
          priority: Priority.max,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: json.encode(message.toMap()),
    );
  }
}

const NotificationManagerPlatform defaultNotificationManagerPlatform =
    DefaultNotificationManagerPlatform();
