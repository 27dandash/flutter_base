import '../shared/cubits/user_cubit/user_cubit.dart';

final class SessionRouteTarget {
  const SessionRouteTarget({
    required this.routeName,
    this.message,
    this.arguments,
  });

  final String routeName;
  final String? message;
  final Object? arguments;
}

/// Keeps business-specific destinations configurable while providing safe
/// defaults for the reusable base.
final class SessionRoutingPolicy {
  const SessionRoutingPolicy({
    this.authenticatedRoute = '/',
    this.loginRoute = '/login',
    this.activationRoute = '/activation',
    this.blockedRoute,
  });

  final String authenticatedRoute;
  final String loginRoute;
  final String activationRoute;
  final String? blockedRoute;

  SessionRouteTarget? resolve(UserState state) {
    return switch (state.userStatus) {
      UserStatus.restoring => null,
      UserStatus.loggedIn => SessionRouteTarget(routeName: authenticatedRoute),
      UserStatus.loggedOut => SessionRouteTarget(
        routeName: loginRoute,
        message: state.message,
      ),
      UserStatus.blocked => SessionRouteTarget(
        routeName: blockedRoute ?? loginRoute,
        message: state.message,
      ),
      UserStatus.needsActivation => SessionRouteTarget(
        routeName: activationRoute,
        message: state.message,
        arguments: state.activationData,
      ),
    };
  }
}
