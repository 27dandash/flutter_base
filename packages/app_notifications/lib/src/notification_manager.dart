import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/foundation.dart';

import 'notification_controller.dart';
import 'notification_manager_platform.dart';
import 'notification_router.dart';
import 'notification_url_policy.dart';

final class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  static const String _isolatePortName = 'notification_action_port';

  ReceivePort? _receivePort;
  NotificationRouter? _router;
  Future<bool>? _initialization;
  bool _initialized = false;
  int _lifecycleGeneration = 0;
  FutureOr<void> Function(String token)? _ownedFcmTokenCallback;
  NotificationUrlPolicy? _ownedUrlPolicy;
  NotificationUrlPolicy? _previousUrlPolicy;
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;
  bool get isInitialized => _initialized;

  Future<bool> initialize({
    required NotificationRouter router,
    FutureOr<void> Function(String token)? onFcmToken,
    bool debug = false,
    Duration timeout = const Duration(seconds: 10),
    NotificationUrlPolicy urlPolicy = NotificationUrlPolicy.secureDefault,
    NotificationManagerPlatform platform = defaultNotificationManagerPlatform,
  }) {
    if (_initialized) return Future<bool>.value(true);
    return _initialization ??= _initialize(
      router: router,
      onFcmToken: onFcmToken,
      debug: debug,
      timeout: timeout,
      urlPolicy: urlPolicy,
      platform: platform,
    ).whenComplete(() => _initialization = null);
  }

  Future<bool> _initialize({
    required NotificationRouter router,
    required FutureOr<void> Function(String token)? onFcmToken,
    required bool debug,
    required Duration timeout,
    required NotificationUrlPolicy urlPolicy,
    required NotificationManagerPlatform platform,
  }) async {
    final generation = _lifecycleGeneration;
    _router = router;
    _installOwnedUrlPolicy(urlPolicy);
    _ownedFcmTokenCallback = (token) async {
      if (generation != _lifecycleGeneration || _router == null) return;
      _tokenRefreshController.add(token);
      await Future<void>.sync(() => onFcmToken?.call(token));
    };
    NotificationController.onFcmToken = _ownedFcmTokenCallback;

    try {
      final diagnosticsEnabled = debug && kDebugMode;
      await _runPlatformBootstrap(
        generation: generation,
        platform: platform,
        diagnosticsEnabled: diagnosticsEnabled,
      ).timeout(timeout);
      if (!_isActiveInitialization(generation)) {
        return await _abortInitialization(generation);
      }
      _initialized = true;
      return true;
    } on TimeoutException {
      if (generation == _lifecycleGeneration) {
        return await _abortInitialization(generation);
      }
      return false;
    } catch (_) {
      if (generation == _lifecycleGeneration) {
        return await _abortInitialization(generation);
      }
      return false;
    }
  }

  Future<void> _runPlatformBootstrap({
    required int generation,
    required NotificationManagerPlatform platform,
    required bool diagnosticsEnabled,
  }) async {
    await platform.initializeLocalNotifications(debug: diagnosticsEnabled);
    if (!_isActiveInitialization(generation)) {
      await _disposeReceivePort();
      return;
    }
    await platform.initializeRemoteNotifications(debug: diagnosticsEnabled);
    if (!_isActiveInitialization(generation)) {
      await _disposeReceivePort();
      return;
    }
    await _initializeIsolateReceivePort();
    if (!_isActiveInitialization(generation)) {
      await _disposeReceivePort();
      return;
    }
    await platform.startListeningNotificationEvents();
    if (!_isActiveInitialization(generation)) {
      await _disposeReceivePort();
      return;
    }
    await _routeInitialNotificationAction(
      await platform.getInitialNotificationAction(),
    );
    if (!_isActiveInitialization(generation)) {
      await _disposeReceivePort();
    }
  }

  bool _isActiveInitialization(int generation) =>
      generation == _lifecycleGeneration && _router != null;

  Future<bool> _abortInitialization(int generation) async {
    if (generation != _lifecycleGeneration) {
      await _disposeReceivePort();
      return false;
    }
    await _disposeReceivePort();
    _router = null;
    _releaseOwnedResources();
    return false;
  }

  void _installOwnedUrlPolicy(NotificationUrlPolicy urlPolicy) {
    _previousUrlPolicy = NotificationController.urlPolicy;
    _ownedUrlPolicy = urlPolicy;
    NotificationController.urlPolicy = urlPolicy;
  }

  void _restoreOwnedUrlPolicy() {
    final owned = _ownedUrlPolicy;
    if (owned != null && identical(NotificationController.urlPolicy, owned)) {
      NotificationController.urlPolicy =
          _previousUrlPolicy ?? NotificationUrlPolicy.secureDefault;
    }
    _ownedUrlPolicy = null;
    _previousUrlPolicy = null;
  }

  void _releaseOwnedResources() {
    _restoreOwnedUrlPolicy();
    _clearOwnedFcmTokenCallback();
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

  Future<void> _routeInitialNotificationAction(
    ReceivedAction? receivedAction,
  ) async {
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
    _lifecycleGeneration++;
    await _disposeReceivePort();
    _router = null;
    _initialized = false;
    _releaseOwnedResources();
  }

  void _clearOwnedFcmTokenCallback() {
    if (identical(NotificationController.onFcmToken, _ownedFcmTokenCallback)) {
      NotificationController.onFcmToken = null;
    }
    _ownedFcmTokenCallback = null;
  }

  Future<void> _disposeReceivePort() async {
    IsolateNameServer.removePortNameMapping(_isolatePortName);
    _receivePort?.close();
    _receivePort = null;
  }
}
