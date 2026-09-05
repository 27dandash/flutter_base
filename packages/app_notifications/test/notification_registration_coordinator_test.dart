import 'dart:async';

import 'package:app_notifications/app_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Installations implements InstallationIdProvider {
  _Installations(this.value);
  final String value;
  @override
  Future<String> getOrCreate() async => value;
}

final class _Tokens implements FcmTokenProvider {
  _Tokens(this.value);
  String? value;
  Future<String?>? pending;
  final controller = StreamController<String>.broadcast();

  @override
  Future<String?> getToken() => pending ?? Future.value(value);

  @override
  Stream<String> get onTokenRefresh => controller.stream;
}

final class _Permissions implements NotificationPermissionProvider {
  _Permissions(this.status);
  NotificationPermissionState status;
  var requestCalls = 0;

  @override
  Future<NotificationPermissionState> currentStatus() async => status;

  @override
  Future<NotificationPermissionState> requestPermission() async {
    requestCalls++;
    return status;
  }
}

final class _Backend implements DeviceRegistrationBackend {
  final upserts = <DeviceRegistration>[];
  final removals = <DeviceRegistration>[];
  Object? upsertError;

  /// Gates ONLY the first upsert so a stale in-flight completion can be
  /// deterministically pinned while a logout/account switch races ahead.
  Completer<void>? upsertGate;
  Completer<void>? upsertStarted;

  @override
  Future<void> upsert(DeviceRegistration registration) async {
    final gate = upsertGate;
    if (gate != null && !gate.isCompleted) {
      upsertGate = null;
      upsertStarted?.complete();
      upsertStarted = null;
      await gate.future;
    }
    if (upsertError != null) throw upsertError!;
    upserts.add(registration);
  }

  @override
  Future<void> remove(DeviceRegistration registration) async {
    removals.add(registration);
  }
}

NotificationRegistrationCoordinator _coordinator({
  required _Tokens tokens,
  required _Permissions permissions,
  required _Backend backend,
  Duration timeout = const Duration(milliseconds: 100),
}) {
  return NotificationRegistrationCoordinator(
    installationIds: _Installations('installation-1'),
    tokens: tokens,
    permissions: permissions,
    backend: backend,
    platform: 'android',
    appVersion: '1.0.0',
    flavor: 'staging',
    tokenTimeout: timeout,
  );
}

void main() {
  test('registers explicitly named installation and FCM values', () async {
    final tokens = _Tokens('fcm-1');
    final backend = _Backend();
    final coordinator = _coordinator(
      tokens: tokens,
      permissions: _Permissions(NotificationPermissionState.authorized),
      backend: backend,
    );

    final result = await coordinator.start(userId: 'user-1');

    expect(result.status, RegistrationStatus.registered);
    expect(backend.upserts.single.toMap(), {
      'installationId': 'installation-1',
      'fcmToken': 'fcm-1',
      'platform': 'android',
      'appVersion': '1.0.0',
      'flavor': 'staging',
      'userId': 'user-1',
    });
    await coordinator.dispose();
    await tokens.controller.close();
  });

  test(
    'null token is controlled and never replaced by installation id',
    () async {
      final tokens = _Tokens(null);
      final backend = _Backend();
      final coordinator = _coordinator(
        tokens: tokens,
        permissions: _Permissions(NotificationPermissionState.authorized),
        backend: backend,
      );

      expect(
        (await coordinator.start()).status,
        RegistrationStatus.tokenUnavailable,
      );
      expect(backend.upserts, isEmpty);
      await coordinator.dispose();
      await tokens.controller.close();
    },
  );

  test(
    'token timeout is bounded and does not require startup to await it',
    () async {
      final tokens = _Tokens(null)..pending = Completer<String?>().future;
      final coordinator = _coordinator(
        tokens: tokens,
        permissions: _Permissions(NotificationPermissionState.authorized),
        backend: _Backend(),
        timeout: const Duration(milliseconds: 5),
      );

      expect((await coordinator.start()).status, RegistrationStatus.timedOut);
      await coordinator.dispose();
      await tokens.controller.close();
    },
  );

  test('permission denial does not prompt or register by default', () async {
    final permissions = _Permissions(NotificationPermissionState.denied);
    final tokens = _Tokens('fcm');
    final backend = _Backend();
    final coordinator = _coordinator(
      tokens: tokens,
      permissions: permissions,
      backend: backend,
    );

    expect(
      (await coordinator.start()).status,
      RegistrationStatus.permissionDenied,
    );
    expect(permissions.requestCalls, 0);
    expect(backend.upserts, isEmpty);
    await coordinator.dispose();
    await tokens.controller.close();
  });

  test('deduplicates registration and updates on token refresh', () async {
    final tokens = _Tokens('fcm-1');
    final backend = _Backend();
    final coordinator = _coordinator(
      tokens: tokens,
      permissions: _Permissions(NotificationPermissionState.authorized),
      backend: backend,
    );

    await coordinator.start(userId: 'user-1');
    expect(
      (await coordinator.start(userId: 'user-1')).status,
      RegistrationStatus.duplicate,
    );
    tokens.controller.add('fcm-2');
    await Future<void>.delayed(Duration.zero);

    expect(backend.upserts.map((item) => item.fcmToken), ['fcm-1', 'fcm-2']);
    await coordinator.dispose();
    await tokens.controller.close();
  });

  test('backend failure can be retried', () async {
    final tokens = _Tokens('fcm');
    final backend = _Backend()..upsertError = StateError('offline');
    final coordinator = _coordinator(
      tokens: tokens,
      permissions: _Permissions(NotificationPermissionState.authorized),
      backend: backend,
    );

    expect(
      (await coordinator.start()).status,
      RegistrationStatus.backendFailure,
    );
    backend.upsertError = null;
    expect((await coordinator.start()).status, RegistrationStatus.registered);
    await coordinator.dispose();
    await tokens.controller.close();
  });

  test('logout removes the old token association', () async {
    final tokens = _Tokens('fcm');
    final backend = _Backend();
    final coordinator = _coordinator(
      tokens: tokens,
      permissions: _Permissions(NotificationPermissionState.authorized),
      backend: backend,
    );
    await coordinator.start(userId: 'user-1');

    await coordinator.logout();

    expect(backend.removals.single.userId, 'user-1');
    await coordinator.dispose();
    await tokens.controller.close();
  });

  test(
    'an upsert that completes after logout is compensated and never reported '
    'as registered',
    () async {
      final tokens = _Tokens('fcm');
      final upsertGate = Completer<void>();
      final backend = _Backend()
        ..upsertGate = upsertGate
        ..upsertStarted = Completer<void>();
      final coordinator = _coordinator(
        tokens: tokens,
        permissions: _Permissions(NotificationPermissionState.authorized),
        backend: backend,
        timeout: const Duration(seconds: 2),
      );

      final start = coordinator.start(userId: 'user-1');
      await backend.upsertStarted!.future; // upsert is in flight
      // Logout lands while the upsert is still on the wire. It has no cached
      // registration to remove yet.
      await coordinator.logout();
      upsertGate.complete(); // the stale upsert now completes

      final result = await start;

      expect(
        result.status,
        isNot(RegistrationStatus.registered),
        reason: 'a registration for an ended session is not "registered"',
      );
      expect(backend.upserts.single.userId, 'user-1');
      expect(
        backend.removals.map((item) => item.userId),
        contains('user-1'),
        reason: 'the stale backend registration is compensated with a remove',
      );
      await coordinator.dispose();
      await tokens.controller.close();
    },
  );

  test(
    'an upsert that completes after an account switch is compensated for the '
    'old identity',
    () async {
      final tokens = _Tokens('fcm');
      final upsertGate = Completer<void>();
      final backend = _Backend()
        ..upsertGate = upsertGate
        ..upsertStarted = Completer<void>();
      final coordinator = _coordinator(
        tokens: tokens,
        permissions: _Permissions(NotificationPermissionState.authorized),
        backend: backend,
        timeout: const Duration(seconds: 2),
      );

      final oldStart = coordinator.start(userId: 'old');
      await backend.upsertStarted!.future; // old upsert is in flight (gated)

      // Switching bumps the generation; the new registration is not gated.
      final switchResult = await coordinator.switchAccount('new');
      upsertGate.complete(); // release the stale old upsert
      final oldResult = await oldStart;

      expect(switchResult.status, RegistrationStatus.registered);
      expect(
        oldResult.status,
        isNot(RegistrationStatus.registered),
        reason: 'the superseded old registration must not be reported ok',
      );
      expect(
        backend.upserts.map((item) => item.userId),
        containsAll(<String>['old', 'new']),
      );
      expect(
        backend.removals.map((item) => item.userId),
        contains('old'),
        reason: 'the stale old-identity registration is compensated',
      );
      expect(
        backend.removals.map((item) => item.userId),
        isNot(contains('new')),
        reason: 'the new identity is the live registration, not removed',
      );
      await coordinator.dispose();
      await tokens.controller.close();
    },
  );

  test(
    'account switching removes old association and registers the new user',
    () async {
      final tokens = _Tokens('fcm');
      final backend = _Backend();
      final coordinator = _coordinator(
        tokens: tokens,
        permissions: _Permissions(NotificationPermissionState.authorized),
        backend: backend,
      );
      await coordinator.start(userId: 'old');

      final result = await coordinator.switchAccount('new');

      expect(result.status, RegistrationStatus.registered);
      expect(backend.removals.single.userId, 'old');
      expect(backend.upserts.last.userId, 'new');
      await coordinator.dispose();
      await tokens.controller.close();
    },
  );
}
