import 'package:flutter_base/src/core/session/session_cleanup.dart';
import 'package:flutter_base/src/core/session/session_routing_policy.dart';
import 'package:flutter_base/src/core/shared/cubits/user_cubit/user_cubit.dart';
import 'package:flutter_base/src/core/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = SessionRoutingPolicy();

  test('restoring does not compete with startup navigation', () {
    expect(policy.resolve(UserState.initial()), isNull);
  });

  test('logout clears history into login', () {
    final target = policy.resolve(
      UserState.loggedOut(reason: SessionTerminationReason.logout),
    );

    expect(target?.routeName, '/login');
  });

  test('authenticated session routes to the product root', () {
    final target = policy.resolve(
      UserState(
        userModel: UserModel.initial(),
        userStatus: UserStatus.loggedIn,
      ),
    );

    expect(target?.routeName, '/');
  });

  test('blocked defaults to login with a controlled message', () {
    final target = policy.resolve(
      UserState(
        userModel: UserModel.initial(),
        userStatus: UserStatus.blocked,
        message: 'blocked',
      ),
    );

    expect(target?.routeName, '/login');
    expect(target?.message, 'blocked');
  });

  test('activation data is preserved for a configurable activation route', () {
    final target = policy.resolve(
      UserState(
        userModel: UserModel.initial(),
        userStatus: UserStatus.needsActivation,
        activationData: const {'phone': 'masked'},
      ),
    );

    expect(target?.routeName, '/activation');
    expect(target?.arguments, const {'phone': 'masked'});
  });
}
