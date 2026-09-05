import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/material.dart' hide DismissAction;

import 'models/notification_enums.dart' as app_enums;
import 'models/notification_payload.dart';
import 'notification_manager.dart';
import 'notification_router.dart';
import 'notification_url_policy.dart';

class NotificationController {
  static const String _isolatePortName = 'notification_action_port';
  static FutureOr<void> Function(String token)? onFcmToken;
  static NotificationUrlPolicy urlPolicy = NotificationUrlPolicy.secureDefault;

  // ── 1. Initialize Local ─────────────────────────────────────────
  static Future<void> initializeLocalNotifications({bool debug = false}) async {
    await AwesomeNotifications().initialize('resource://mipmap/ic_launcher', [
      NotificationChannel(
        channelKey: app_enums.NotificationChannel.messaging.name,
        channelName: 'Messaging',
        channelDescription: 'Chat and message notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: app_enums.NotificationChannel.general.name,
        channelName: 'General',
        channelDescription: 'General notifications',
        importance: NotificationImportance.Default,
      ),
      NotificationChannel(
        channelKey: app_enums.NotificationChannel.system.name,
        channelName: 'System',
        channelDescription: 'System alerts',
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'high_importance_channel',
        channelName: 'High Importance',
        channelDescription: 'High importance notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        playSound: true,
        enableVibration: true,
      ),
    ], debug: debug);
  }

  // ── 2. Initialize Remote (FCM) ──────────────────────────────────
  static Future<void> initializeRemoteNotifications({
    bool debug = false,
  }) async {
    await AwesomeNotificationsFcm().initialize(
      onFcmTokenHandle: myFcmTokenHandle,
      onNativeTokenHandle: myNativeTokenHandle,
      onFcmSilentDataHandle: mySilentDataHandle,
      // licenseKeys removed — no longer required since awesome_notifications_fcm 0.11
      debug: debug,
    );
  }

  // ── 3. Start Listening ──────────────────────────────────────────
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  // ── BG / Terminated Handler ─────────────────────────────────────
  @pragma('vm:entry-point')
  static Future<void> mySilentDataHandle(FcmSilentData silentData) async {
    try {
      final data = silentData.data;
      if (data == null || data.isEmpty) return;

      _logNotification('📥 FCM DATA RECEIVED', {
        'startedByForeground': silentData.createdLifeCycle?.name,
        'data': data,
      });

      final payload = NotificationPayload.fromMap(
        Map<String, dynamic>.from(data),
        languageCode: _detectLangCode(),
      );
      final content = _buildContent(payload);

      await AwesomeNotifications().createNotification(
        content: content,
        actionButtons: _buildActionButtons(payload),
      );
    } catch (_) {
      if (kDebugMode) debugPrint('Notification data handler failed');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> myFcmTokenHandle(String token) async {
    if (kDebugMode) debugPrint('FCM Token refreshed');
    await Future<void>.sync(() => onFcmToken?.call(token));
  }

  @pragma('vm:entry-point')
  static Future<void> myNativeTokenHandle(String token) async {
    if (kDebugMode) debugPrint('Native notification token refreshed');
  }

  // ── Click Handler ───────────────────────────────────────────────
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    try {
      if (receivedAction.actionType == ActionType.SilentAction ||
          receivedAction.actionType == ActionType.SilentBackgroundAction) {
        _logNotification('🔇 SILENT ACTION', {
          'buttonKeyPressed': receivedAction.buttonKeyPressed,
          'id': receivedAction.id,
        });
        await _handleSilentAction(receivedAction);
        return;
      }

      _logNotification('👆 ACTION RECEIVED', {
        'id': receivedAction.id,
        'title': receivedAction.title,
        'buttonKeyPressed': receivedAction.buttonKeyPressed,
        'payload': receivedAction.payload,
      });

      final sendPort = IsolateNameServer.lookupPortByName(_isolatePortName);
      if (sendPort != null) {
        sendPort.send(receivedAction);
        return;
      }

      await routeAction(receivedAction);
    } catch (_) {
      if (kDebugMode) debugPrint('Notification action handler failed');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification n,
  ) async {
    _logNotification('🔔 NOTIFICATION CREATED', {'id': n.id, 'title': n.title});
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification n,
  ) async {
    _logNotification('✅ NOTIFICATION DISPLAYED', {
      'id': n.id,
      'title': n.title,
    });
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction action,
  ) async {
    _logNotification('🗑️ NOTIFICATION DISMISSED', {'id': action.id});
  }

  // ── Build NotificationContent ───────────────────────────────────
  static NotificationContent _buildContent(NotificationPayload payload) {
    return NotificationContent(
      id: payload.id.hashCode,
      channelKey: payload.channel.name,
      title: payload.title,
      body: payload.body,
      notificationLayout: NotificationLayout.Default,
      category: switch (payload.type) {
        app_enums.NotificationType.message => NotificationCategory.Message,
        app_enums.NotificationType.call => NotificationCategory.Call,
        _ => NotificationCategory.Social,
      },
      payload: Map<String, String>.from(
        payload.data.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
  }

  // ── Build Action Buttons ────────────────────────────────────────
  static List<NotificationActionButton>? _buildActionButtons(
    NotificationPayload payload,
  ) {
    final labels = actionLabelsForLanguage(_detectLangCode());
    return switch (payload.type) {
      app_enums.NotificationType.call => [
        NotificationActionButton(
          key: 'ACCEPT',
          label: labels.$1,
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'REJECT',
          label: labels.$2,
          color: Colors.red,
          actionType: ActionType.DismissAction,
        ),
      ],
      _ => null,
    };
  }

  // ── Parse Action from data map ──────────────────────────────────
  @visibleForTesting
  static NotificationAction parseAction(
    Map<String, String?> data, {
    NotificationUrlPolicy policy = NotificationUrlPolicy.secureDefault,
  }) {
    return switch (data['action_type']) {
      'navigate_chat' => NavigateToChat(data['chat_id'] ?? ''),
      'navigate_screen' => NavigateToScreen(data['route'] ?? '/'),
      'open_url' => _parseOpenUrl(data['url'], policy: policy),
      _ => const DismissAction(),
    };
  }

  static NotificationAction _parseAction(Map<String, String?> data) =>
      parseAction(data, policy: urlPolicy);

  static NotificationAction _parseOpenUrl(
    String? raw, {
    required NotificationUrlPolicy policy,
  }) {
    final uri = policy.parseAllowedUrl(raw);
    if (uri == null) return const DismissAction();
    return OpenUrl(uri);
  }

  // ── Route Action ────────────────────────────────────────────────
  static Future<void> routeAction(ReceivedAction receivedAction) async {
    final action = _parseAction(receivedAction.payload ?? {});
    await NotificationManager.instance.route(action);
  }

  static Future<void> _handleSilentAction(ReceivedAction receivedAction) async {
    if (kDebugMode) debugPrint('Silent notification action received');
  }

  // ── Helpers ─────────────────────────────────────────────────────
  static String _detectLangCode() {
    return PlatformDispatcher.instance.locale.languageCode;
  }

  /// Localized background-safe action labels without a BuildContext.
  @visibleForTesting
  static (String, String) actionLabelsForLanguage(String languageCode) =>
      languageCode.toLowerCase() == 'ar'
      ? ('قبول', 'رفض')
      : ('Accept', 'Reject');

  static void _logNotification(String event, Map<String, dynamic> fields) {
    if (!kDebugMode) return;
    debugPrint(formatDebugLog(event, fields));
  }

  /// Formats structural diagnostics while redacting notification content,
  /// identifiers, routes, payloads and errors by field name.
  @visibleForTesting
  static String formatDebugLog(String event, Map<String, dynamic> fields) {
    final buffer = StringBuffer()
      ..writeln('┌─────────────────────────────────────────')
      ..writeln('│ [Notifications] $event')
      ..writeln('├─────────────────────────────────────────');
    for (final entry in fields.entries) {
      final key = entry.key.toLowerCase();
      if (_isSensitiveLogField(key)) {
        buffer.writeln('│  ${entry.key}: <redacted>');
        continue;
      }
      final value = entry.value;
      if (value == null) continue;
      if (value is Map && value.isEmpty) continue;
      buffer.writeln('│  ${entry.key}: $value');
    }
    buffer.write('└─────────────────────────────────────────');
    return buffer.toString();
  }

  static bool _isSensitiveLogField(String key) =>
      key.contains('token') ||
      key.contains('payload') ||
      key.contains('title') ||
      key.contains('body') ||
      key.contains('message') ||
      key.contains('content') ||
      key.contains('sender') ||
      key.contains('user') ||
      key.contains('account') ||
      key.contains('chat') ||
      key.contains('route') ||
      key.contains('url') ||
      key.contains('error') ||
      key == 'data' ||
      key == 'id';
}
