import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_router.dart';
import 'notification_url_policy.dart';

/// Shared, test-friendly state and pure helpers used by `NotificationManager`.
///
/// Nothing here touches a native plugin.
class NotificationController {
  static FutureOr<void> Function(String token)? onFcmToken;
  static NotificationUrlPolicy urlPolicy = NotificationUrlPolicy.secureDefault;

  /// Parses the generic `action_type` contract used when a message does not
  /// match a registered notification type.
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

  static NotificationAction _parseOpenUrl(
    String? raw, {
    required NotificationUrlPolicy policy,
  }) {
    final uri = policy.parseAllowedUrl(raw);
    if (uri == null) return const DismissAction();
    return OpenUrl(uri);
  }

  /// Routes a flattened payload through the generic `action_type` contract.
  static Future<void> routeGeneric(
    Map<String, dynamic> payload,
    NotificationRouter router,
  ) {
    final stringData = <String, String?>{
      for (final entry in payload.entries) entry.key: entry.value?.toString(),
    };
    return router.route(parseAction(stringData, policy: urlPolicy));
  }

  static void logNotification(String event, Map<String, dynamic> fields) {
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
