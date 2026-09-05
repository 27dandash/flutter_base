import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../config/res/config_imports.dart';
import '../../../network/cache/cache_config.dart';
import '../../../network/cancel/request_cancellation_manager.dart';
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
///
/// Lifecycle coordination
///   Login, restore, logout, account deletion, blocked/needs-activation
///   termination, and account switching are serialized through a single
///   transition queue and stamped with a monotonic [_lifecycleEpoch]. A step
///   only publishes its terminal state (or activates an owner scope) while its
///   epoch is still current, so a slow restore or a delayed login can never
///   emit after — or interleave credentials/user/state with — a newer explicit
///   transition. This keeps session transitions deterministic without any
///   global mutable state or a retained `BuildContext`.
@lazySingleton
class UserCubit extends Cubit<UserState> with UserUtils {
  UserCubit(this._tokenStorage) : super(UserState.initial());

  final TokenStorage _tokenStorage;

  /// Serializes every lifecycle transition so credentials, the user payload,
  /// the offline owner scope, and the emitted state can never interleave into
  /// a mixed session.
  Future<void> _transitionTail = Future<void>.value();

  /// Incremented synchronously the moment an explicit transition is requested
  /// (before it is enqueued). A restore or login captures the epoch active when
  /// it began and refuses to emit once a newer transition has bumped it.
  int _lifecycleEpoch = 0;

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
  }) {
    return _beginTransition(
      (epoch) => _login(
        user: user,
        token: token,
        refreshToken: refreshToken,
        epoch: epoch,
      ),
    );
  }

  Future<void> switchAccount({
    required UserModel user,
    required String token,
    String? refreshToken,
  }) {
    // A switch is a single indivisible transition: the old session is torn down
    // and the new one is committed under one epoch, so no other transition can
    // interleave between them and no stale restore/login can win.
    return _beginTransition((epoch) async {
      await _performTermination(
        SessionTerminationReason.accountSwitch,
        status: UserStatus.loggedOut,
        epoch: epoch,
      );
      await _login(
        user: user,
        token: token,
        refreshToken: refreshToken,
        epoch: epoch,
      );
    });
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
  Future<void> updateToken(String token, {String? refreshToken}) async {
    final generation = _tokenStorage.sessionGeneration;
    await _tokenStorage.saveIfCurrent(
      expectedGeneration: generation,
      access: token,
      refresh: refreshToken,
    );
  }

  /// Update the cached user payload (e.g. after the user edits their profile).
  ///
  /// Serialized behind any in-flight transition and guarded by the lifecycle
  /// epoch + authentication state so a delayed profile write can never
  /// resurrect a user payload that a concurrent logout has already deleted.
  Future<void> updateUser(UserModel user) {
    final epoch = _lifecycleEpoch;
    return _enqueue(() async {
      if (!_isCurrentEpoch(epoch) || !state.isAuthenticated) return;
      await _saveUser(user);
      if (!_isCurrentEpoch(epoch) || !state.isAuthenticated) return;
      emit(state.copyWith(userModel: user));
    });
  }

  /// Restore previous session from encrypted storage. Returns true when
  /// a valid (token + user) pair was found.
  ///
  /// Call this once during bootstrap, after `setUpServiceLocator()`.
  Future<bool> init({Duration timeout = const Duration(seconds: 6)}) {
    return _restoreInFlight ??=
        _beginTransition((epoch) => _restore(timeout, epoch)).whenComplete(() {
          _restoreInFlight = null;
        });
  }

  Future<bool> _login({
    required UserModel user,
    required String token,
    String? refreshToken,
    required int epoch,
  }) async {
    try {
      await _tokenStorage.save(access: token, refresh: refreshToken);
      await _saveUser(user);
    } catch (error, stackTrace) {
      // Credentials and the user payload form one logical session. If either
      // persistence step fails, remove both before surfacing the original
      // failure so no authenticated transport can observe a partial login.
      await _performTermination(
        SessionTerminationReason.revoked,
        status: UserStatus.loggedOut,
        epoch: epoch,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
    // A newer explicit transition (logout/switch/another login) may have been
    // requested while credentials were being written. If so, do not activate
    // this user's owner scope or announce them as signed in — the newer
    // transition owns the terminal state.
    if (!_isCurrentEpoch(epoch)) return false;
    OfflineQueueManager().activateOwnerScope(_ownerScopeFor(user));
    emit(UserState(userModel: user, userStatus: UserStatus.loggedIn));
    return true;
  }

  Future<bool> _restore(Duration timeout, int epoch) async {
    try {
      await _tokenStorage.init().timeout(timeout);
      final userJson = await SecureStorage.read(_userKey).timeout(timeout);

      final hasToken = _tokenStorage.hasAccessToken;
      if (!hasToken || userJson == null) {
        if (hasToken || userJson != null) {
          // A session is valid only as a complete token + user pair. Clear the
          // surviving half so unauthenticated requests cannot carry an orphan
          // token and a later startup cannot resurrect stale user state.
          await _performTermination(
            SessionTerminationReason.revoked,
            status: UserStatus.loggedOut,
            epoch: epoch,
          );
        } else if (_isCurrentEpoch(epoch)) {
          emit(UserState.loggedOut());
        }
        return false;
      }

      // A logout/login requested while storage was being read supersedes this
      // restore. Never resurrect a session that an explicit transition ended.
      if (!_isCurrentEpoch(epoch)) return false;

      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      if (!_isCurrentEpoch(epoch)) return false;
      OfflineQueueManager().activateOwnerScope(_ownerScopeFor(user));
      emit(UserState(userModel: user, userStatus: UserStatus.loggedIn));
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('UserCubit.init: session restore failed');
      }
      // Already inside the transition queue: tear the session down inline so we
      // never re-enter (and deadlock on) the tail we are currently holding.
      await _performTermination(
        SessionTerminationReason.revoked,
        status: UserStatus.loggedOut,
        epoch: epoch,
      );
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
    return _beginTransition(
      (epoch) => _performTermination(
        reason,
        status: status,
        message: message,
        activationData: activationData,
        epoch: epoch,
      ),
    );
  }

  Future<void> _performTermination(
    SessionTerminationReason reason, {
    required UserStatus status,
    required int epoch,
    String? message,
    Object? activationData,
  }) async {
    OfflineQueueManager().activateOwnerScope(null);
    RequestCancellationManager().cancelAll('session_terminated');
    // Emit the unauthenticated state up front so protected UI can never look
    // authenticated while cleanup runs — unless a newer transition (e.g. an
    // immediate re-login) has already superseded this one.
    if (_isCurrentEpoch(epoch)) {
      emit(
        UserState(
          userModel: UserModel.initial(),
          userStatus: status,
          terminationReason: reason,
          message: message,
          activationData: activationData,
        ),
      );
    }

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

    if (!_isCurrentEpoch(epoch)) return;
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

  // ── Lifecycle coordinator ───────────────────────────────────────

  /// Enqueues an explicit transition, stamping it with a fresh epoch that
  /// supersedes any restore/login still awaiting storage.
  Future<T> _beginTransition<T>(Future<T> Function(int epoch) action) {
    final epoch = ++_lifecycleEpoch;
    return _enqueue(() => action(epoch));
  }

  /// Serializes [action] after every previously enqueued lifecycle step.
  /// Failures are isolated so one transition can never wedge the queue.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _transitionTail = _transitionTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  bool _isCurrentEpoch(int epoch) => epoch == _lifecycleEpoch;

  // ── Sugar ───────────────────────────────────────────────────────

  UserModel get user => state.userModel;
  bool get isUserLoggedIn => state.isAuthenticated;

  String _ownerScopeFor(UserModel user) =>
      sha256.convert(utf8.encode(user.id)).toString();
}
