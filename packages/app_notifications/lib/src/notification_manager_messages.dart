part of 'notification_manager.dart';

/// Foreground delivery, taps and routing of [NotificationManager].
extension _NotificationMessages on NotificationManager {
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
      if (!_sessionDedupe.markHandled(_eventKey(message))) return;
      await _show(message);
      await _endSession();
      return;
    }
    if (!await _canHandle(payload)) return;

    if (spec != null) {
      _emitRefresh(spec, payload, fromTap: false);
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

  /// Stable identity of one push, so a foreground delivery and the tap on the
  /// same notification count as one event.
  String _eventKey(RemoteMessage message) {
    final id = message.messageId;
    if (id != null && id.isNotEmpty) return id;
    final data = message.data;
    final keys = data.keys.toList()..sort();
    return keys.map((k) => '$k=${data[k]}').join('&');
  }

  /// Tells open pages that something changed. Pages decide (scope + entity id)
  /// whether they are affected; duplicates inside the dedupe window collapse.
  void _emitRefresh(
    NotificationTypeSpec spec,
    Map<String, dynamic> payload, {
    required bool fromTap,
  }) {
    final scope = spec.refreshScope;
    if (scope == null) return;
    final rawId = payload[spec.entityIdKey]?.toString();
    NotificationRefreshBus.instance.emit(
      NotificationRefresh(
        scope: scope,
        entityId: rawId == null || rawId.isEmpty ? null : rawId,
        type: spec.key,
        fromTap: fromTap,
      ),
    );
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
    _notificationId = _notificationId >= NotificationManager._maxNotificationId
        ? 1
        : _notificationId + 1;
    try {
      await platform.showNotification(
        id: _notificationId,
        title: text.title,
        body: text.body,
        message: message,
        presentation: _presentation,
        badgeNumber: _pendingBadge,
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
    if (spec != null &&
        spec.endsSession &&
        !_sessionDedupe.markHandled(_eventKey(message))) {
      _log('TAP IGNORED', {'reason': 'session-end already handled'});
      return;
    }
    try {
      if (spec != null) _emitRefresh(spec, payload, fromTap: true);
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
}
