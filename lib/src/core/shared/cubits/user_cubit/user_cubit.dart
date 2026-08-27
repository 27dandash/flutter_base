import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../config/res/config_imports.dart';
import '../../../network/cache/cache_config.dart';
import '../../helpers/cache_service.dart';
import '../../../network/auth/token_storage.dart';
import '../../../network/offline/offline_queue_manager.dart';
import '../../../session/session_cleanup.dart';
import '../../models/user_model.dart';

part 'user_state.dart';
part 'user_utils.dart';

/// Owns the logged-in user object + the "is signed in" state.
///
/// Tokens are NOT stored here — they live in [TokenStorage], which is
/// the source of truth queried by [AuthInterceptor] on every request.
/// `UserCubit` only delegates token writes to it.
///
/// Persistence
///   - User payload → encrypted disk via [SecureStorage].
///   - Tokens       → encrypted disk via [TokenStorage] (which itself
///     uses [SecureStorage]).
@lazySingleton
class UserCubit extends Cubit<UserState> with UserUtils {
  UserCubit(this._tokenStorage) : super(UserState.initial());

  final TokenStorage _tokenStorage;
  Future<void>? _terminationInFlight;
  Future<bool>? _restoreInFlight;

  /// Static shortcut for places where DI access is awkward (e.g. global
  /// helpers). Prefer constructor injection in production code.
  static UserCubit get instance => injector<UserCubit>();

  // ── Public API ──────────────────────────────────────────────────

  /// Persist the user payload + tokens and flip the state to logged-in.
  Future<void> setUserLoggedIn({
    required UserModel user,
    required String token,
    String? refreshToken,
  }) async {
    await _tokenStorage.save(access: token, refresh: refreshToken);
    await _saveUser(user);
    OfflineQueueManager().activateOwnerScope(_ownerScopeFor(user));
    emit(UserState(userModel: user, userStatus: UserStatus.loggedIn));
  }

  Future<void> switchAccount({
    required UserModel user,
    required String token,
    String? refreshToken,
  }) async {
    await _terminate(SessionTerminationReason.accountSwitch);
    await setUserLoggedIn(user: user, token: token, refreshToken: refreshToken);
  }

  /// Wipe credentials and all session-scoped state. The unauthenticated state
  /// is emitted before cleanup starts, so a storage/plugin failure can never
  /// leave protected UI looking authenticated.
  Future<void> logout() => _terminate(SessionTerminationReason.logout);

  Future<void> accountDeleted() =>
      _terminate(SessionTerminationReason.accountDeleted);

  Future<void> sessionRevoked() => _terminate(SessionTerminationReason.revoked);

  Future<void> markBlocked({String? message}) => _terminate(
    SessionTerminationReason.blocked,
    status: UserStatus.blocked,
    message: message,
  );

  Future<void> markNeedsActivation({String? message, Object? activationData}) =>
      _terminate(
        SessionTerminationReason.needsActivation,
        status: UserStatus.needsActivation,
        message: message,
        activationData: activationData,
      );

  /// Rotate the access (and optionally the refresh) token without
  /// changing the user payload — used by the silent-refresh flow.
  Future<void> updateToken(String token, {String? refreshToken}) {
    return _tokenStorage.save(access: token, refresh: refreshToken);
  }

  /// Update the cached user payload (e.g. after the user edits their profile).
  Future<void> updateUser(UserModel user) async {
    await _saveUser(user);
    emit(state.copyWith(userModel: user));
  }

  /// Restore previous session from encrypted storage. Returns true when
  /// a valid (token + user) pair was found.
  ///
  /// Call this once during bootstrap, after `setUpServiceLocator()`.
  Future<bool> init({Duration timeout = const Duration(seconds: 6)}) {
    return _restoreInFlight ??= _restore(timeout).whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<bool> _restore(Duration timeout) async {
    try {
      await _tokenStorage.init().timeout(timeout);
      final userJson = await SecureStorage.read(_userKey).timeout(timeout);

      if (!_tokenStorage.hasAccessToken || userJson == null) {
        emit(UserState.loggedOut());
        return false;
      }

      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      OfflineQueueManager().activateOwnerScope(_ownerScopeFor(user));
      emit(UserState(userModel: user, userStatus: UserStatus.loggedIn));
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('UserCubit.init: session restore failed — $error');
      }
      emit(UserState.loggedOut());
      await _terminate(SessionTerminationReason.revoked);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'session restore',
        ),
      );
      return false;
    }
  }

  Future<void> _terminate(
    SessionTerminationReason reason, {
    UserStatus status = UserStatus.loggedOut,
    String? message,
    Object? activationData,
  }) {
    final inFlight = _terminationInFlight;
    if (inFlight != null) return inFlight;

    final future = _performTermination(
      reason,
      status: status,
      message: message,
      activationData: activationData,
    );
    _terminationInFlight = future;
    return future.whenComplete(() => _terminationInFlight = null);
  }

  Future<void> _performTermination(
    SessionTerminationReason reason, {
    required UserStatus status,
    String? message,
    Object? activationData,
  }) async {
    OfflineQueueManager().activateOwnerScope(null);
    emit(
      UserState(
        userModel: UserModel.initial(),
        userStatus: status,
        terminationReason: reason,
        message: message,
        activationData: activationData,
      ),
    );

    final failedSteps = <String>[];

    Future<void> capture(String id, Future<void> Function() action) async {
      try {
        await action().timeout(const Duration(seconds: 6));
      } catch (_) {
        failedSteps.add(id);
      }
    }

    await capture('tokens', _tokenStorage.clear);
    await capture('user_payload', () => SecureStorage.delete(_userKey));
    await capture('http_cache', CacheConfig.clearAll);
    await capture('offline_queue', OfflineQueueManager().clearPending);

    final hookFailures = await SessionCleanupRegistry.instance.run(reason);
    failedSteps.addAll(hookFailures.map((failure) => failure.hookId));

    emit(
      UserState(
        userModel: UserModel.initial(),
        userStatus: status,
        terminationReason: reason,
        message: message,
        activationData: activationData,
        cleanupFailures: List<String>.unmodifiable(failedSteps),
      ),
    );
  }

  // ── Sugar ───────────────────────────────────────────────────────

  UserModel get user => state.userModel;
  bool get isUserLoggedIn => state.isAuthenticated;

  String _ownerScopeFor(UserModel user) =>
      sha256.convert(utf8.encode(user.id)).toString();
}
