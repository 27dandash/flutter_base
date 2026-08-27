enum NotificationPermissionState {
  authorized,
  provisional,
  denied,
  permanentlyDenied,
  notDetermined,
}

final class DeviceRegistration {
  const DeviceRegistration({
    required this.installationId,
    required this.fcmToken,
    required this.platform,
    required this.appVersion,
    required this.flavor,
    this.userId,
  });

  final String installationId;
  final String fcmToken;
  final String platform;
  final String appVersion;
  final String flavor;
  final String? userId;

  Map<String, String> toMap() {
    final values = <String, String>{
      'installationId': installationId,
      'fcmToken': fcmToken,
      'platform': platform,
      'appVersion': appVersion,
      'flavor': flavor,
    };
    final scopedUserId = userId;
    if (scopedUserId != null) values['userId'] = scopedUserId;
    return values;
  }

  String get fingerprint => [
    installationId,
    fcmToken,
    platform,
    appVersion,
    flavor,
    userId ?? '',
  ].join('|');
}

abstract interface class InstallationIdProvider {
  Future<String> getOrCreate();
}

abstract interface class FcmTokenProvider {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
}

abstract interface class NotificationPermissionProvider {
  Future<NotificationPermissionState> currentStatus();
  Future<NotificationPermissionState> requestPermission();
}

abstract interface class DeviceRegistrationBackend {
  Future<void> upsert(DeviceRegistration registration);
  Future<void> remove(DeviceRegistration registration);
}
