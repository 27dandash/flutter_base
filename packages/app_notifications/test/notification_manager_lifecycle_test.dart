import 'dart:async';

import 'package:app_notifications/app_notifications.dart';
import 'package:app_notifications/src/notification_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_notification_platform.dart';

final class _RecordingRouter implements NotificationRouter {
  final actions = <NotificationAction>[];

  @override
  Future<void> route(NotificationAction action) async => actions.add(action);
}

Future<void> _resetManager() async {
  NotificationController.onFcmToken = null;
  NotificationController.urlPolicy = NotificationUrlPolicy.secureDefault;
  await NotificationManager.instance.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(_resetManager);

  test('successful initialization wires every platform step once', () async {
    final platform = FakeNotificationPlatform();

    final initialized = await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: platform,
    );
    await settle();

    expect(initialized, isTrue);
    expect(NotificationManager.instance.isInitialized, isTrue);
    expect(platform.localCalls, 1);
    expect(platform.optionCalls, 1);
    expect(platform.permissionCalls, 1);
    expect(platform.backgroundHandlerRegistrations, 1);
    expect(platform.messages.hasListener, isTrue);
    expect(platform.opened.hasListener, isTrue);
    expect(platform.refreshes.hasListener, isTrue);
    expect(NotificationController.onFcmToken, isNotNull);
    expect(NotificationManager.instance.deviceToken, 'token-1');
    await platform.close();
  });

  test('permission prompt can be deferred to an explicit flow', () async {
    final platform = FakeNotificationPlatform();

    await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: platform,
      requestPermissionsOnInitialize: false,
    );
    expect(platform.permissionCalls, 0);

    expect(await NotificationManager.instance.requestPermissions(), isTrue);
    expect(platform.permissionCalls, 1);
    await platform.close();
  });

  test('a failing non-critical step does not fail initialization', () async {
    final platform = FakeNotificationPlatform(
      failOn: {'options', 'permissions', 'initial'},
    );

    final initialized = await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: platform,
    );

    expect(initialized, isTrue);
    await platform.close();
  });

  test('a failing local initialization fails closed', () async {
    final platform = FakeNotificationPlatform(failOn: {'local'});

    final initialized = await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: platform,
    );

    expect(initialized, isFalse);
    expect(NotificationManager.instance.isInitialized, isFalse);
    expect(NotificationController.onFcmToken, isNull);
    expect(platform.messages.hasListener, isFalse);
    await platform.close();
  });

  test(
    'dispose clears only owned callback and listeners but keeps token stream',
    () async {
      final platform = FakeNotificationPlatform();
      final router = _RecordingRouter();
      await NotificationManager.instance.initialize(
        router: router,
        platform: platform,
      );

      final ownedCallback = NotificationController.onFcmToken!;
      var deliveries = 0;
      final subscription = NotificationManager.instance.tokenRefreshes.listen(
        (_) => deliveries++,
      );
      await settle();
      deliveries = 0;

      await ownedCallback('token-2');
      expect(deliveries, 1);

      await NotificationManager.instance.dispose();

      expect(NotificationController.onFcmToken, isNull);
      expect(platform.messages.hasListener, isFalse);
      expect(NotificationManager.instance.isInitialized, isFalse);
      expect(NotificationManager.instance.deviceToken, isEmpty);

      await ownedCallback('stale-token');
      expect(deliveries, 1);

      await NotificationManager.instance.initialize(
        router: router,
        platform: FakeNotificationPlatform(),
      );
      expect(NotificationController.onFcmToken, isNot(same(ownedCallback)));

      await subscription.cancel();
      await platform.close();
    },
  );

  test('failed initialization cannot resurrect owned resources', () async {
    final gate = Completer<void>();
    final platform = FakeNotificationPlatform(
      blockOn: 'options',
      blockGate: gate,
    );

    final result = await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: platform,
      timeout: Duration.zero,
    );

    expect(result, isFalse);
    expect(NotificationManager.instance.isInitialized, isFalse);
    expect(NotificationController.onFcmToken, isNull);

    gate.complete();
    await settle();

    expect(NotificationManager.instance.isInitialized, isFalse);
    expect(NotificationController.onFcmToken, isNull);
    expect(platform.messages.hasListener, isFalse);
    expect(platform.backgroundHandlerRegistrations, 0);
    await platform.close();
  });

  test('a timed-out attempt cannot subscribe after a newer attempt', () async {
    final gate = Completer<void>();
    final stale = FakeNotificationPlatform(blockOn: 'options', blockGate: gate);

    expect(
      await NotificationManager.instance.initialize(
        router: _RecordingRouter(),
        platform: stale,
        timeout: Duration.zero,
      ),
      isFalse,
    );

    final fresh = FakeNotificationPlatform();
    expect(
      await NotificationManager.instance.initialize(
        router: _RecordingRouter(),
        platform: fresh,
      ),
      isTrue,
    );

    gate.complete();
    await settle();

    expect(stale.messages.hasListener, isFalse);
    expect(fresh.messages.hasListener, isTrue);
    await stale.close();
    await fresh.close();
  });

  test(
    'dispose during in-flight initialization cannot resurrect state',
    () async {
      final gate = Completer<void>();
      final platform = FakeNotificationPlatform(
        blockOn: 'options',
        blockGate: gate,
      );

      final initialization = NotificationManager.instance.initialize(
        router: _RecordingRouter(),
        platform: platform,
      );
      await settle();
      expect(platform.localCalls, 1);
      expect(platform.optionCalls, 1);

      await NotificationManager.instance.dispose();
      gate.complete();

      expect(await initialization, isFalse);
      expect(NotificationManager.instance.isInitialized, isFalse);
      expect(NotificationController.onFcmToken, isNull);
      expect(platform.messages.hasListener, isFalse);
      await platform.close();
    },
  );

  test('initialize owns url policy and restores it on dispose', () async {
    const external = NotificationUrlPolicy(
      allowedHttpsHosts: {'external.example.test'},
    );
    const owned = NotificationUrlPolicy(
      allowedHttpsHosts: {'owned.example.test'},
    );
    NotificationController.urlPolicy = external;

    await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: FakeNotificationPlatform(),
      urlPolicy: owned,
    );
    expect(NotificationController.urlPolicy, owned);

    await NotificationManager.instance.dispose();
    expect(NotificationController.urlPolicy, external);
  });

  test('dispose does not overwrite a newer url policy owner', () async {
    const owned = NotificationUrlPolicy(
      allowedHttpsHosts: {'owned.example.test'},
    );
    const newer = NotificationUrlPolicy(
      allowedHttpsHosts: {'newer.example.test'},
    );

    await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: FakeNotificationPlatform(),
      urlPolicy: owned,
    );
    NotificationController.urlPolicy = newer;

    await NotificationManager.instance.dispose();
    expect(NotificationController.urlPolicy, newer);
  });
}
