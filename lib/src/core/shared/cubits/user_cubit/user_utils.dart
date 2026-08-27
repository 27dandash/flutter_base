part of 'user_cubit.dart';

/// Storage keys used by [UserCubit]. Kept here so they live next to the
/// `_saveUser` helper that uses them — easier to keep in sync.
const String _userKey = 'auth_user_payload';

/// Tiny helpers shared by [UserCubit]. Stays in a mixin so they don't
/// leak into the public surface of the cubit.
mixin UserUtils {
  Future<void> _saveUser(UserModel user) {
    return SecureStorage.write(_userKey, jsonEncode(user.toJson()));
  }
}
