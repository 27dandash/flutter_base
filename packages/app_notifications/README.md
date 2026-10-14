# Optional notifications package

FCM (`firebase_messaging`) + local notifications (`flutter_local_notifications`)
behind a small, testable seam. It reproduces the notification behavior of the
reference product and is deliberately **not** a dependency of the root app, so
projects that do not need notifications do not compile or bundle Firebase.

## Behavior

| Situation | What happens |
|---|---|
| App in foreground | The OS does **not** present the message. `NotificationManager` shows it as a local notification (after the optional user-preference gate). |
| App in background / terminated | The OS system tray shows `notification` messages. The background handler only makes sure Firebase is initialized. |
| User taps a notification (local, tray, or the one that launched the app) | The payload is flattened and routed by type through `NotificationTypeRegistry`; unknown types fall back to the generic `action_type` contract. |
| Session-ending type (blocked, deleted account) | The notification is shown, `onSessionEnd` runs once, and the user-preference gate is bypassed. |

Title/body: on Android the `data` block wins (`title`, `message`/`body`, …) and
`notification` is the fallback; on iOS it is the opposite. See
`resolveNotificationText`.

The channel is `high_importance_channel` ("High Importance Notifications",
importance high, sound + vibration). Override it with `NotificationPresentation`.

## Enable it in a consuming app

1. Add a path dependency:

   ```yaml
   dependencies:
     app_notifications:
       path: packages/app_notifications
   ```

2. Add the Firebase platform configuration for each flavor and call
   `Firebase.initializeApp` first.
3. Describe your notification types (the package ships none) and initialize:

   ```dart
   await NotificationManager.instance.initialize(
     router: myRouter, // generic action_type fallback
     typeRegistry: NotificationTypeRegistry(
       types: [
         NotificationTypeSpec('order_created', navigate: (data) => openOrder(data['order_id'])),
         NotificationTypeSpec('blocked', endsSession: true),
       ],
       // Optional: alias legacy transport values onto a registered type.
       resolveType: (type, payload) =>
           type == 'text' && payload['sender_id'] != null ? 'new_message' : type,
     ),
     // Called with the flattened payload; return false when the user turned
     // notifications off. An exception counts as "allowed".
     canHandle: (data) => userWantsNotifications(),
     onSessionEnd: logoutToLogin,
     onFcmToken: registerTokenWithBackend,
     backgroundHandler: myBackgroundHandler, // needed for per-flavor FirebaseOptions
   );
   ```

4. Observe foreground messages (for example to refresh an unread counter) with
   `NotificationManager.instance.addListener(NotificationActionListener(...))`.
5. Permission is requested **once, through Firebase only**
   (`FirebaseMessaging.requestPermission` covers the iOS prompt and Android 13+
   `POST_NOTIFICATIONS`); `flutter_local_notifications` never prompts, so the
   user cannot see a second dialog right after refusing. Concurrent callers
   share one request. `requestPermissionsOnInitialize` defaults to `true`, like
   the reference product. Pass `false` and call `requestPermissions()` from an explicit
   user-facing flow if you prefer a pre-permission screen.

`NotificationPayload.fromMap` and `normalizeNotificationPayload` accept
application data delivered as flat keys, a nested map under `data`, or a JSON
object string under `data`. The outer transport `id` is preserved as
`notification_id` and removed from `id` unless the nested data defines its own,
so an entity id is never confused with the notification record id. The
consuming application must still validate the required target ID; never guess
that an `order_id`, `delivery_id`, chat id or another domain identifier is
interchangeable.

## Native requirements

* Android: `POST_NOTIFICATIONS` permission in the manifest; core library
  desugaring enabled (`flutter_local_notifications`); the launcher icon
  (`@mipmap/ic_launcher` by default) must exist. To make background tray
  notifications use the same channel, add
  `com.google.firebase.messaging.default_notification_channel_id` meta-data.
* iOS: Push Notifications capability and the `aps-environment` entitlement,
  `UIBackgroundModes` → `remote-notification`, and an APNs key uploaded to
  Firebase.
* `firebase_messaging`, `firebase_core` and `flutter_local_notifications` all
  ship Swift Package Manager manifests, so a consuming app can keep using SwiftPM.

## Server contract

Foreground display needs title/body in `data` (Android) or in `notification`
(iOS). Android background delivery is only shown by the OS when the message
carries a `notification` block; a **data-only** message is not displayed while
the app is backgrounded or terminated because the default background handler
does not create a notification. Send notification + data messages, or supply a
`backgroundHandler` that displays data-only messages.

See [NOTIFICATION_GUIDE.md](NOTIFICATION_GUIDE.md) for the flow in detail.
