import 'dart:async';

import 'package:flutter/widgets.dart';

import 'notification_refresh_bus.dart';

/// Re-runs [onRefresh] when a notification that concerns THIS page arrives.
///
/// Wrap a page (or its body):
///
/// ```dart
/// NotificationRefreshListener(
///   scopes: const {'order'},
///   entityId: orderId.toString(),
///   onRefresh: (_) => context.read<OrderDetailsCubit>().refresh(silent: true),
///   child: const OrderDetailsView(),
/// )
/// ```
///
/// - Only events whose scope (and entity id, when both are known) match fire,
///   so a notification about ANOTHER order never touches this page.
/// - It never navigates, never opens a duplicate page, and never calls
///   `setState`: the callback is expected to drive a Cubit that keeps the old
///   data visible until the new data arrives (silent refresh).
/// - A failing callback is swallowed so a refresh problem cannot crash the app.
class NotificationRefreshListener extends StatefulWidget {
  const NotificationRefreshListener({
    required this.scopes,
    required this.onRefresh,
    required this.child,
    this.entityId,
    this.bus,
    super.key,
  });

  final Set<String> scopes;
  final String? entityId;
  final FutureOr<void> Function(NotificationRefresh event) onRefresh;
  final Widget child;

  /// Overrides the global bus (tests).
  final NotificationRefreshBus? bus;

  @override
  State<NotificationRefreshListener> createState() =>
      _NotificationRefreshListenerState();
}

class _NotificationRefreshListenerState
    extends State<NotificationRefreshListener> {
  StreamSubscription<NotificationRefresh>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant NotificationRefreshListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bus != widget.bus) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    final bus = widget.bus ?? NotificationRefreshBus.instance;
    _subscription = bus.stream.listen(_onEvent);
  }

  void _onEvent(NotificationRefresh event) {
    // Read the CURRENT widget so a changed entityId is honoured.
    if (!mounted) return;
    if (!event.matches(widget.scopes, watchedEntityId: widget.entityId)) {
      return;
    }
    try {
      final result = widget.onRefresh(event);
      if (result is Future) unawaited(result.catchError((_) {}));
    } catch (_) {
      // A refresh failure must never crash the app.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
