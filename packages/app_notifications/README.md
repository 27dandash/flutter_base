# Optional notifications package

This package isolates Awesome Notifications + FCM from the application base.
It is deliberately **not** a dependency of the root app, so projects that do
not need notifications do not compile or bundle their native SDKs.

## Enable it in a consuming app

1. Add a path dependency:

   ```yaml
   dependencies:
     app_notifications:
       path: packages/app_notifications
   ```

2. Add the Firebase platform configuration for each flavor.
3. Initialize Firebase, implement `NotificationRouter`, then initialize
   `NotificationManager.instance`.
4. Request notification permission only from an explicit user-facing flow.
5. Persist the FCM token through the optional `onFcmToken` callback.

The root application remains buildable without Firebase configuration by
leaving `FIREBASE_ENABLED` unset or false.

## iOS dependency manager limitation

At the time this base was verified, `awesome_notifications` and
`awesome_notifications_fcm` did not advertise Flutter Swift Package Manager
support. A consuming app that enables this package must therefore verify the
plugins' current support and may need CocoaPods until upstream support lands.
The root app itself uses Swift Package Manager only.

See [NOTIFICATION_GUIDE.md](NOTIFICATION_GUIDE.md) for payload and platform
configuration details.
