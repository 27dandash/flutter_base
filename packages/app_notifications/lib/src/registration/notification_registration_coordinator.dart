import 'dart:async';

import 'device_registration.dart';

enum RegistrationStatus {
  registered,
  duplicate,
  permissionDenied,
  tokenUnavailable,
  timedOut,
  backendFailure,
}

final class RegistrationResult {
  const RegistrationResult(this.status, {this.error});

  final RegistrationStatus status;
  final Object? error;
}

/// Keeps installation identity, FCM identity, and authenticated user identity
/// separate and updates the backend on token refresh/account changes.
final class NotificationRegistrationCoordinator {
  NotificationRegistrationCoordinator({
    required this.installationIds,
    required this.tokens,
    required this.permissions,
    required this.backend,
    required this.platform,
    required this.appVersion,
    required this.flavor,
    this.tokenTimeout = const Duration(seconds: 8),
  });

  final InstallationIdProvider installationIds;
  final FcmTokenProvider tokens;
  final NotificationPermissionProvider permissions;
  final DeviceRegistrationBackend backend;
  final String platform;
  final String appVersion;
  final String flavor;
  final Duration tokenTimeout;

  StreamSubscription<String>? _refreshSubscription;
  DeviceRegistration? _lastRegistration;
  String? _userId;
  Future<RegistrationResult>? _registrationInFlight;
  int _sessionGeneration = 0;

  Future<RegistrationResult> start({
    String? userId,
    bool requestPermission = false,
  }) {
    _userId = userId;
    _listenForRefresh();
    return _registrationInFlight ??= _registerCurrentToken(
      requestPermission: requestPermission,
      generation: _sessionGeneration,
    ).whenComplete(() => _registrationInFlight = null);
  }

  void _listenForRefresh() {
    _refreshSubscription ??= tokens.onTokenRefresh.listen(
      (token) => _registerRefreshedToken(token, _sessionGeneration),
      onError: (_) {},
    );
  }

  Future<RegistrationResult> _registerCurrentToken({
    required bool requestPermission,
    required int generation,
  }) async {
    try {
      var permission = await permissions.currentStatus().timeout(tokenTimeout);
      if (permission == NotificationPermissionState.notDetermined &&
          requestPermission) {
        permission = await permissions.requestPermission().timeout(
          tokenTimeout,
        );
      }
      if (permission == NotificationPermissionState.denied ||
          permission == NotificationPermissionState.permanentlyDenied ||
          permission == NotificationPermissionState.notDetermined) {
        return const RegistrationResult(RegistrationStatus.permissionDenied);
      }

      final values = await Future.wait<Object?>([
        installationIds.getOrCreate(),
        tokens.getToken(),
      ]).timeout(tokenTimeout);
      final installationId = (values[0]! as String).trim();
      final token = (values[1] as String?)?.trim();
      if (token == null || token.isEmpty || generation != _sessionGeneration) {
        return const RegistrationResult(RegistrationStatus.tokenUnavailable);
      }
      return await _upsert(
        installationId: installationId,
        token: token,
        generation: generation,
      );
    } on TimeoutException catch (error) {
      return RegistrationResult(RegistrationStatus.timedOut, error: error);
    } catch (error) {
      return RegistrationResult(
        RegistrationStatus.backendFailure,
        error: error,
      );
    }
  }

  Future<void> _registerRefreshedToken(String token, int generation) async {
    final value = token.trim();
    if (value.isEmpty || generation != _sessionGeneration) return;
    try {
      final installationId = await installationIds.getOrCreate().timeout(
        tokenTimeout,
      );
      await _upsert(
        installationId: installationId,
        token: value,
        generation: generation,
      );
    } catch (_) {
      // Refresh registration is best effort and must never crash the app.
      // Products can wrap the backend with their own bounded retry policy.
    }
  }

  Future<RegistrationResult> _upsert({
    required String installationId,
    required String token,
    required int generation,
  }) async {
    if (generation != _sessionGeneration) {
      return const RegistrationResult(RegistrationStatus.tokenUnavailable);
    }
    final registration = DeviceRegistration(
      installationId: installationId,
      fcmToken: token,
      platform: platform,
      appVersion: appVersion,
      flavor: flavor,
      userId: _userId,
    );
    if (_lastRegistration?.fingerprint == registration.fingerprint) {
      return const RegistrationResult(RegistrationStatus.duplicate);
    }
    try {
      await backend.upsert(registration).timeout(tokenTimeout);
      if (generation != _sessionGeneration) {
        // Logout or an account/generation change landed while this upsert was
        // in flight. The backend now holds a registration that the concurrent
        // logout could not see (it had no cached registration to remove yet),
        // so compensate with a bounded backend remove. The stale registration
        // is never cached and never reported as registered.
        await _compensateStaleRegistration(registration);
        return const RegistrationResult(RegistrationStatus.tokenUnavailable);
      }
      _lastRegistration = registration;
      return const RegistrationResult(RegistrationStatus.registered);
    } on TimeoutException catch (error) {
      return RegistrationResult(RegistrationStatus.timedOut, error: error);
    } catch (error) {
      return RegistrationResult(
        RegistrationStatus.backendFailure,
        error: error,
      );
    }
  }

  /// Removes a registration that was committed to the backend after its session
  /// had already ended. Idempotent and best effort: the local logout has
  /// already won, so a failure here is swallowed (a product may reconcile
  /// server-side). Never logs the token/installation identifiers.
  Future<void> _compensateStaleRegistration(
    DeviceRegistration registration,
  ) async {
    try {
      await backend.remove(registration).timeout(tokenTimeout);
    } catch (_) {
      // Best-effort compensation; the terminated session must not be reported
      // as registered regardless of whether the remove succeeds.
    }
  }

  Future<void> logout() async {
    _sessionGeneration++;
    _registrationInFlight = null;
    final registration = _lastRegistration;
    _lastRegistration = null;
    _userId = null;
    if (registration == null) return;
    try {
      await backend.remove(registration).timeout(tokenTimeout);
    } catch (_) {
      // Local session transition wins. A product may queue this server cleanup
      // under the old user identity if its backend contract supports that.
    }
  }

  Future<RegistrationResult> switchAccount(String newUserId) async {
    await logout();
    return start(userId: newUserId);
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }
}
