import 'package:flutter/material.dart';

import '../shared/cubits/user_cubit/user_cubit.dart';
import 'session_routing_policy.dart';

/// Converts session state into one stack-clearing navigation operation.
/// It owns no BuildContext and therefore remains safe across disposed screens.
final class SessionNavigationCoordinator {
  SessionNavigationCoordinator({
    required this.navigatorKey,
    this.policy = const SessionRoutingPolicy(),
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final SessionRoutingPolicy policy;

  String? _lastRoute;
  bool _scheduled = false;

  void handle(UserState state) {
    final target = policy.resolve(state);
    if (target == null || target.routeName == _lastRoute || _scheduled) return;

    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      _lastRoute = target.routeName;
      navigator.pushNamedAndRemoveUntil(
        target.routeName,
        (_) => false,
        arguments: target.arguments ?? target.message,
      );
    });
  }

  void resetForTesting() {
    _lastRoute = null;
    _scheduled = false;
  }
}
