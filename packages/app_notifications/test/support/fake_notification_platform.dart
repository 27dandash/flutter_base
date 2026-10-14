import 'dart:async';

import 'package:app_notifications/app_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final class ShownNotification {
  const ShownNotification(this.id, this.title, this.body, this.message);

  final int id;
  final String title;
  final String body;
  final RemoteMessage message;
}

/// In-memory [NotificationManagerPlatform]: no native plugin is touched.
final class FakeNotificationPlatform implements NotificationManagerPlatform {
  FakeNotificationPlatform({
    this.blockOn,
    this.blockGate,
    this.token = 'token-1',
    this.tokenFailures = 0,
    this.initialMessage,
    this.failOn = const {},
  });

  /// Step name that waits on [blockGate]: `local`, `options`, `permissions`,
  /// `initial`.
  final String? blockOn;
  final Completer<void>? blockGate;
  final Set<String> failOn;

  String? token;
  int tokenFailures;
  RemoteMessage? initialMessage;

  final messages = StreamController<RemoteMessage>.broadcast();
  final opened = StreamController<RemoteMessage>.broadcast();
  final refreshes = StreamController<String>.broadcast();
  final shown = <ShownNotification>[];

  var localCalls = 0;
  var optionCalls = 0;
  var permissionCalls = 0;
  var tokenCalls = 0;
  var backgroundHandlerRegistrations = 0;
  BackgroundMessageHandler? backgroundHandler;
  NotificationPresentation? presentation;
  void Function(RemoteMessage message)? onTap;
  bool showFails = false;

  Future<void> _step(String name) async {
    if (blockOn == name) await blockGate!.future;
    if (failOn.contains(name)) throw StateError('$name failed');
  }

  @override
  Future<void> initializeLocalNotifications({
    required NotificationPresentation presentation,
    required void Function(RemoteMessage message) onTap,
    bool debug = false,
  }) async {
    localCalls++;
    this.presentation = presentation;
    this.onTap = onTap;
    await _step('local');
  }

  @override
  Future<void> setForegroundPresentationOptions() async {
    optionCalls++;
    await _step('options');
  }

  @override
  Future<bool> requestPermissions() async {
    permissionCalls++;
    await _step('permissions');
    return true;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    await _step('initial');
    return initialMessage;
  }

  @override
  void registerBackgroundHandler(BackgroundMessageHandler handler) {
    backgroundHandlerRegistrations++;
    backgroundHandler = handler;
  }

  @override
  Stream<RemoteMessage> get onMessage => messages.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => opened.stream;

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Future<String?> getToken() async {
    tokenCalls++;
    if (tokenFailures > 0) {
      tokenFailures--;
      throw StateError('token unavailable');
    }
    return token;
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required RemoteMessage message,
    required NotificationPresentation presentation,
  }) async {
    if (showFails) throw StateError('show failed');
    shown.add(ShownNotification(id, title, body, message));
  }

  Future<void> close() async {
    await messages.close();
    await opened.close();
    await refreshes.close();
  }
}

/// Lets queued microtasks and zero-duration timers run.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
