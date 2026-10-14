import 'package:app_notifications/app_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      authorizationStatus: status,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const localChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final localCalls = <String>[];

  setUp(() {
    localCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localChannel, (call) async {
          localCalls.add(call.method);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localChannel, null);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    group('permission on $platform', () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('is requested once, through Firebase only', () async {
        var firebaseRequests = 0;
        final subject = DefaultNotificationManagerPlatform(
          permissionRequester: () async {
            firebaseRequests++;
            return _settings(AuthorizationStatus.authorized);
          },
        );

        expect(await subject.requestPermissions(), isTrue);

        expect(firebaseRequests, 1);
        expect(
          localCalls,
          isEmpty,
          reason:
              'flutter_local_notifications must not prompt a second time '
              '(a second dialog after a refusal breaks Google Play policy)',
        );
      });

      test('maps the Firebase authorization status', () async {
        Future<bool> granted(AuthorizationStatus status) =>
            DefaultNotificationManagerPlatform(
              permissionRequester: () async => _settings(status),
            ).requestPermissions();

        expect(await granted(AuthorizationStatus.authorized), isTrue);
        expect(await granted(AuthorizationStatus.provisional), isTrue);
        expect(await granted(AuthorizationStatus.denied), isFalse);
        expect(await granted(AuthorizationStatus.notDetermined), isFalse);
        expect(localCalls, isEmpty);
      });
    });
  }
}
