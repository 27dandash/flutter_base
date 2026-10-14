import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart'
    show BackgroundMessageHandler, RemoteMessage;
import 'package:flutter/foundation.dart';

import 'models/notification_payload_normalizer.dart';
import 'notification_controller.dart';
import 'notification_manager_platform.dart';
import 'notification_presentation.dart';
import 'notification_router.dart';
import 'notification_type_registry.dart';
import 'notification_url_policy.dart';

/// Decides whether the signed-in user wants this notification. Receives the
/// flattened payload. Return `false` to drop it (foreground display and tap
/// routing). An exception is treated as "allowed", so a faulty preference
/// read never hides a notification.
typedef NotificationGate = FutureOr<bool> Function(Map<String, dynamic> data);

/// Orchestrates FCM + local notifications.
///
/// Behavior (mirrors the reference product):
///  * Foreground messages are not presented by the OS; this manager shows them
///    as local notifications, after applying the optional [NotificationGate].
///  * Background/terminated `notification` messages are shown by the OS.
///  * A tap — on a local notification, a system-tray notification, or the
///    notification that launched the app — is routed through the
///    [NotificationTypeRegistry], falling back to the generic `action_type`
///    contract handled by the [NotificationRouter].
///  * Session-ending types (blocked or deleted account) bypass the gate and
///    invoke `onSessionEnd` once.
final class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  static const int _maxTokenAttempts = 5;
  static const int _maxNotificationId = 2147483647;

  NotificationManagerPlatform? _platform;
  NotificationRouter? _router;
  NotificationTypeRegistry _registry = NotificationTypeRegistry.empty;
  NotificationGate? _gate;
  FutureOr<void> Function()? _onSessionEnd;
  NotificationPresentation _presentation = const NotificationPresentation();
  Duration _sessionEndCooldown = const Duration(milliseconds: 800);
  Duration _tokenRetryDelay = const Duration(seconds: 3);
  bool _debug = false;

  Future<bool>? _initialization;
  bool _initialized = false;
  int _lifecycleGeneration = 0;
  int _notificationId = 0;
  String _deviceToken = '';
  bool _sessionEndInFlight = false;
  Timer? _sessionEndReset;
  Timer? _tokenRetryTimer;

  FutureOr<void> Function(String token)? _ownedFcmTokenCallback;
  NotificationUrlPolicy? _ownedUrlPolicy;
  NotificationUrlPolicy? _previousUrlPolicy;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<NotificationActionListener> _listeners = [];
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;
  bool get isInitialized => _initialized;

  /// The last FCM token this manager read, or an empty string.
  String get deviceToken => _deviceToken;

  Future<bool> initialize({
    required NotificationRouter router,
    FutureOr<void> Function(String token)? onFcmToken,
    bool debug = false,
    Duration timeout = const Duration(seconds: 10),
    NotificationUrlPolicy urlPolicy = NotificationUrlPolicy.secureDefault,
    NotificationManagerPlatform platform = defaultNotificationManagerPlatform,
    NotificationTypeRegistry? typeRegistry,
    NotificationGate? canHandle,
    FutureOr<void> Function()? onSessionEnd,
    NotificationPresentation presentation = const NotificationPresentation(),
    BackgroundMessageHandler backgroundHandler = notificationBackgroundHandler,
    bool requestPermissionsOnInitialize = true,
    Duration sessionEndCooldown = const Duration(milliseconds: 800),
    Duration tokenRetryDelay = const Duration(seconds: 3),
  }) {
    if (_initialized) return Future<bool>.value(true);
    return _initialization ??= _initialize(
      router: router,
      onFcmToken: onFcmToken,
      debug: debug,
      timeout: timeout,
      urlPolicy: urlPolicy,
      platform: platform,
      typeRegistry: typeRegistry ?? NotificationTypeRegistry.empty,
      canHandle: canHandle,
      onSessionEnd: onSessionEnd,
      presentation: presentation,
      backgroundHandler: backgroundHandler,
      requestPermissionsOnInitialize: requestPermissionsOnInitialize,
      sessionEndCooldown: sessionEndCooldown,
      tokenRetryDelay: tokenRetryDelay,
    ).whenComplete(() => _initialization = null);
  }

  Future<bool> _initialize({
    required NotificationRouter router,
    required FutureOr<void> Function(String token)? onFcmToken,
    required bool debug,
    required Duration timeout,
    required NotificationUrlPolicy urlPolicy,
    required NotificationManagerPlatform platform,
    required NotificationTypeRegistry typeRegistry,
    required NotificationGate? canHandle,
    required FutureOr<void> Function()? onSessionEnd,
    required NotificationPresentation presentation,
    required BackgroundMessageHandler backgroundHandler,
    required bool requestPermissionsOnInitialize,
    required Duration sessionEndCooldown,
    required Duration tokenRetryDelay,
  }) async {
    final generation = _lifecycleGeneration;
    _platform = platform;
    _router = router;
    _registry = typeRegistry;
    _gate = canHandle;
    _onSessionEnd = onSessionEnd;
    _presentation = presentation;
    _sessionEndCooldown = sessionEndCooldown;
    _tokenRetryDelay = tokenRetryDelay;
    _debug = debug && kDebugMode;
    _installOwnedUrlPolicy(urlPolicy);
    _ownedFcmTokenCallback = (token) async {
      if (generation != _lifecycleGeneration || _router == null) return;
      _tokenRefreshController.add(token);
      await Future<void>.sync(() => onFcmToken?.call(token));
    };
    NotificationController.onFcmToken = _ownedFcmTokenCallback;

    try {
      await _runPlatformBootstrap(
        generation: generation,
        platform: platform,
        backgroundHandler: backgroundHandler,
        requestPermissionsOnInitialize: requestPermissionsOnInitialize,
      ).timeout(timeout);
      if (!_isActive(generation)) {
        return await _abortInitialization(generation);
      }
      _initialized = true;
      return true;
    } on TimeoutException {
      return await _abortInitialization(generation);
    } catch (_) {
      return await _abortInitialization(generation);
    }
  }

  Future<void> _runPlatformBootstrap({
    required int generation,
    required NotificationManagerPlatform platform,
    required BackgroundMessageHandler backgroundHandler,
    required bool requestPermissionsOnInitialize,
  }) async {
    await platform.initializeLocalNotifications(
      presentation: _presentation,
      debug: _debug,
      onTap: (message) => unawaited(_handleTap(message, generation)),
    );
    if (!_isActive(generation)) return;

    // Non-critical steps: a refusal must not prevent message handling.
    await _tolerate(platform.setForegroundPresentationOptions);
    if (!_isActive(generation)) return;

    platform.registerBackgroundHandler(backgroundHandler);
    final subscriptions = <StreamSubscription<Object?>>[
      platform.onMessage.listen(
        (message) => unawaited(_handleForeground(message, generation)),
        onError: (_) {},
      ),
      platform.onMessageOpenedApp.listen(
        (message) => unawaited(_handleTap(message, generation)),
        onError: (_) {},
      ),
      platform.onTokenRefresh.listen(
        (token) => unawaited(_deliverToken(token, generation)),
        onError: (_) {},
      ),
    ];
    if (!_isActive(generation)) {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
      return;
    }
    _subscriptions.addAll(subscriptions);

    if (requestPermissionsOnInitialize) {
      await _tolerate(platform.requestPermissions);
      if (!_isActive(generation)) return;
    }

    RemoteMessage? initialMessage;
    await _tolerate(() async {
      initialMessage = await platform.getInitialMessage();
    });
    if (!_isActive(generation)) return;
    final launchMessage = initialMessage;
    if (launchMessage != null) {
      unawaited(_handleTap(launchMessage, generation));
    }

    // Not awaited: a slow Play Services/APNs registration must not fail
    // initialization. The token reaches the owner callback when available.
    unawaited(_loadToken(generation, attempt: 1));
  }

  Future<void> _tolerate(Future<void> Function() step) async {
    try {
      await step();
    } catch (error) {
      _log('STEP FAILED', {'errorType': error.runtimeType.toString()});
    }
  }

  bool _isActive(int generation) =>
      generation == _lifecycleGeneration && _router != null;

  Future<bool> _abortInitialization(int generation) async {
    if (generation != _lifecycleGeneration) return false;
    _lifecycleGeneration++;
    await _cancelSubscriptions();
    _router = null;
    _releaseOwnedResources();
    return false;
  }

  // ── Token ─────────────────────────────────────────────────────────

  Future<void> _loadToken(int generation, {required int attempt}) async {
    try {
      final token = await _platform?.getToken();
      if (!_isActive(generation)) return;
      await _deliverToken(token, generation);
    } catch (error) {
      _log('TOKEN FAILED', {'errorType': error.runtimeType.toString()});
      if (!_isActive(generation) || attempt >= _maxTokenAttempts) return;
      _tokenRetryTimer?.cancel();
      _tokenRetryTimer = Timer(
        _tokenRetryDelay,
        () => unawaited(_loadToken(generation, attempt: attempt + 1)),
      );
    }
  }

  Future<void> _deliverToken(String? token, int generation) async {
    if (!_isActive(generation)) return;
    final value = token?.trim() ?? '';
    _deviceToken = value;
    if (value.isEmpty) return;
    await _ownedFcmTokenCallback?.call(value);
  }

  /// Reads the FCM token on demand and delivers it to the owner callback.
  Future<String?> requestToken({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final platform = _platform ?? defaultNotificationManagerPlatform;
      final token = await platform.getToken().timeout(timeout);
      if (token == null || token.trim().isEmpty) return null;
      _deviceToken = token;
      await Future<void>.sync(
        () => NotificationController.onFcmToken?.call(token),
      );
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Asks for notification permission. Prefer calling this from an explicit
  /// user-facing flow when [initialize] ran with
  /// `requestPermissionsOnInitialize: false`.
  Future<bool> requestPermissions({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final platform = _platform ?? defaultNotificationManagerPlatform;
      return await platform.requestPermissions().timeout(timeout);
    } catch (_) {
      return false;
    }
  }

  // ── Foreground messages ───────────────────────────────────────────

  Future<void> _handleForeground(RemoteMessage message, int generation) async {
    if (!_isActive(generation)) return;
    final payload = normalizeNotificationPayload(message.data);
    final key = _registry.keyFor(payload);
    final spec = _registry.specFor(key);
    _log('FOREGROUND MESSAGE', {
      'type': key.isEmpty ? null : 'known',
      'keys': message.data.keys.toList(),
    });

    if (spec != null && spec.endsSession) {
      await _show(message);
      await _endSession();
      return;
    }
    if (!await _canHandle(payload)) return;

    if (spec != null) {
      for (final listener in List.of(_listeners)) {
        if (!listener.conditionCheck(key)) continue;
        try {
          listener.onMessage(payload);
        } catch (_) {
          // One faulty observer must not hide the notification.
        }
      }
    }
    await _show(message);
  }

  Future<void> _show(RemoteMessage message) async {
    final platform = _platform;
    if (platform == null) return;
    final text = resolveNotificationText(
      data: message.data,
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
      isIOS: defaultTargetPlatform == TargetPlatform.iOS,
      fallbackTitle: _presentation.fallbackTitle,
    );
    _notificationId = _notificationId >= _maxNotificationId
        ? 1
        : _notificationId + 1;
    try {
      await platform.showNotification(
        id: _notificationId,
        title: text.title,
        body: text.body,
        message: message,
        presentation: _presentation,
      );
    } catch (error) {
      _log('SHOW FAILED', {'errorType': error.runtimeType.toString()});
    }
  }

  // ── Taps ──────────────────────────────────────────────────────────

  Future<void> _handleTap(RemoteMessage message, int generation) async {
    if (!_isActive(generation)) return;
    final payload = normalizeNotificationPayload(message.data);
    final spec = _registry.specForPayload(payload);
    if (!(spec?.endsSession ?? false) && !await _canHandle(payload)) {
      _log('TAP IGNORED', {'reason': 'disabled'});
      return;
    }
    if (!_isActive(generation)) return;
    try {
      await _route(payload, spec);
    } catch (error) {
      _log('ROUTE FAILED', {'errorType': error.runtimeType.toString()});
    }
  }

  Future<void> _route(
    Map<String, dynamic> payload,
    NotificationTypeSpec? spec,
  ) async {
    if (spec != null) {
      if (spec.endsSession) {
        await _endSession();
      } else {
        await spec.navigate?.call(payload);
      }
      return;
    }
    final router = _router;
    if (router != null) {
      await NotificationController.routeGeneric(payload, router);
    }
  }

  Future<bool> _canHandle(Map<String, dynamic> payload) async {
    final gate = _gate;
    if (gate == null) return true;
    try {
      return await gate(payload);
    } catch (_) {
      return true;
    }
  }

  Future<void> _endSession() async {
    if (_sessionEndInFlight) return;
    _sessionEndInFlight = true;
    try {
      await _onSessionEnd?.call();
    } catch (error) {
      _log('SESSION END FAILED', {'errorType': error.runtimeType.toString()});
    } finally {
      _sessionEndReset?.cancel();
      _sessionEndReset = Timer(
        _sessionEndCooldown,
        () => _sessionEndInFlight = false,
      );
    }
  }

  // ── Public helpers ────────────────────────────────────────────────

  /// Observes foreground messages of the listener's types.
  void addListener(NotificationActionListener listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  void removeListener(NotificationActionListener listener) =>
      _listeners.remove(listener);

  Future<void> route(NotificationAction action) async {
    final router = _router;
    if (router != null) await router.route(action);
  }

  Future<void> dispose() async {
    _lifecycleGeneration++;
    await _cancelSubscriptions();
    _router = null;
    _initialized = false;
    _deviceToken = '';
    _sessionEndInFlight = false;
    _sessionEndReset?.cancel();
    _sessionEndReset = null;
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = null;
    _listeners.clear();
    _releaseOwnedResources();
  }

  // ── Ownership ─────────────────────────────────────────────────────

  Future<void> _cancelSubscriptions() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
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
    if (identical(NotificationController.onFcmToken, _ownedFcmTokenCallback)) {
      NotificationController.onFcmToken = null;
    }
    _ownedFcmTokenCallback = null;
  }

  void _log(String event, Map<String, dynamic> fields) {
    if (!_debug) return;
    NotificationController.logNotification(event, fields);
  }
}
