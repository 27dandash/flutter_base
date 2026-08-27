import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/foundation.dart';

import 'notification_controller.dart';
import 'notification_router.dart';

final class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  static const String _isolatePortName = 'notification_action_port';

  ReceivePort? _receivePort;
  NotificationRouter? _router;
  Future<bool>? _initialization;
  bool _initialized = false;
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;
  bool get isInitialized => _initialized;

  Future<bool> initialize({
    required NotificationRouter router,
    FutureOr<void> Function(String token)? onFcmToken,
    bool debug = false,
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (_initialized) return Future<bool>.value(true);
    return _initialization ??= _initialize(
      router: router,
      onFcmToken: onFcmToken,
      debug: debug,
      timeout: timeout,
    ).whenComplete(() => _initialization = null);
  }

  Future<bool> _initialize({
    required NotificationRouter router,
    required FutureOr<void> Function(String token)? onFcmToken,
    required bool debug,
    required Duration timeout,
  }) async {
    _router = router;
    NotificationController.onFcmToken = (token) async {
      _tokenRefreshController.add(token);
      await Future<void>.sync(() => onFcmToken?.call(token));
    };

    try {
      await (() async {
        final diagnosticsEnabled = debug && kDebugMode;
        await NotificationController.initializeLocalNotifications(
          debug: diagnosticsEnabled,
        );
        await NotificationController.initializeRemoteNotifications(
          debug: diagnosticsEnabled,
        );
        await _initializeIsolateReceivePort();
        await NotificationController.startListeningNotificationEvents();
        await _getInitialNotificationAction();
      })().timeout(timeout);
      _initialized = true;
      return true;
    } catch (_) {
      await _disposeReceivePort();
      _router = null;
      return false;
    }
  }

  Future<void> _initializeIsolateReceivePort() async {
    _receivePort = ReceivePort('notification_main_port');

    IsolateNameServer.removePortNameMapping(_isolatePortName);
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _isolatePortName,
    );

    _receivePort!.listen((receivedAction) {
      if (receivedAction is ReceivedAction) {
        NotificationController.routeAction(receivedAction);
      }
    });
  }

  Future<void> _getInitialNotificationAction() async {
    final receivedAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);

    if (receivedAction == null) return;
    await NotificationController.routeAction(receivedAction);
  }

  Future<String?> requestToken({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final token = await AwesomeNotificationsFcm()
          .requestFirebaseAppToken()
          .timeout(timeout);
      if (token.trim().isEmpty) return null;
      await Future<void>.sync(
        () => NotificationController.onFcmToken?.call(token),
      );
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermissions({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications()
          .timeout(timeout);
    } catch (_) {
      return false;
    }
  }

  Future<void> route(NotificationAction action) async {
    final router = _router;
    if (router != null) await router.route(action);
  }

  Future<void> dispose() async {
    await _disposeReceivePort();
    _router = null;
    _initialized = false;
  }

  Future<void> _disposeReceivePort() async {
    IsolateNameServer.removePortNameMapping(_isolatePortName);
    _receivePort?.close();
    _receivePort = null;
  }
}
