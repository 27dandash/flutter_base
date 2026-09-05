import 'dart:async';
import 'dart:ui';

import 'package:app_notifications/app_notifications.dart';
import 'package:app_notifications/src/notification_controller.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingRouter implements NotificationRouter {
  @override
  Future<void> route(NotificationAction action) async {}
}

final class _FakePlatform implements NotificationManagerPlatform {
  _FakePlatform({this.blockOn, this.blockGate});

  final String? blockOn;
  final Completer<void>? blockGate;
  var localCalls = 0;
  var remoteCalls = 0;
  var listenCalls = 0;
  var initialActionCalls = 0;

  @override
  Future<void> initializeLocalNotifications({bool debug = false}) async {
    localCalls++;
    if (blockOn == 'local') await blockGate!.future;
  }

  @override
  Future<void> initializeRemoteNotifications({bool debug = false}) async {
    remoteCalls++;
    if (blockOn == 'remote') await blockGate!.future;
  }

  @override
  Future<void> startListeningNotificationEvents() async {
    listenCalls++;
    if (blockOn == 'listen') await blockGate!.future;
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction() async {
    initialActionCalls++;
    if (blockOn == 'initial') await blockGate!.future;
    return null;
  }
}

Future<void> _resetManager() async {
  NotificationController.onFcmToken = null;
  NotificationController.urlPolicy = NotificationUrlPolicy.secureDefault;
  await NotificationManager.instance.dispose();
  IsolateNameServer.removePortNameMapping('notification_action_port');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(_resetManager);

  test(
    'successful initialization registers callback and isolate port',
    () async {
      final platform = _FakePlatform();
      final router = _RecordingRouter();

      final initialized = await NotificationManager.instance.initialize(
        router: router,
        platform: platform,
      );

      expect(initialized, isTrue);
      expect(NotificationManager.instance.isInitialized, isTrue);
      expect(platform.localCalls, 1);
      expect(platform.remoteCalls, 1);
      expect(platform.listenCalls, 1);
      expect(NotificationController.onFcmToken, isNotNull);
      expect(
        IsolateNameServer.lookupPortByName('notification_action_port'),
        isNotNull,
      );
    },
  );

  test(
    'dispose clears only owned callback and port while keeping token stream',
    () async {
      final platform = _FakePlatform();
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

      await ownedCallback('token-1');
      expect(deliveries, 1);

      await NotificationManager.instance.dispose();

      expect(NotificationController.onFcmToken, isNull);
      expect(
        IsolateNameServer.lookupPortByName('notification_action_port'),
        isNull,
      );
      expect(NotificationManager.instance.isInitialized, isFalse);

      await ownedCallback('stale-token');
      expect(deliveries, 1);

      await NotificationManager.instance.initialize(
        router: router,
        platform: platform,
      );
      expect(NotificationController.onFcmToken, isNot(same(ownedCallback)));
      expect(
        NotificationManager.instance.tokenRefreshes,
        isA<Stream<String>>(),
      );

      await subscription.cancel();
    },
  );

  test('failed initialization cannot resurrect owned resources', () async {
    final gate = Completer<void>();
    final platform = _FakePlatform(blockOn: 'remote', blockGate: gate);

    final result = await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: platform,
      timeout: Duration.zero,
    );

    expect(result, isFalse);
    expect(NotificationManager.instance.isInitialized, isFalse);
    expect(NotificationController.onFcmToken, isNull);
    expect(
      IsolateNameServer.lookupPortByName('notification_action_port'),
      isNull,
    );

    gate.complete();
    await Future<void>.delayed(Duration.zero);

    expect(NotificationManager.instance.isInitialized, isFalse);
    expect(NotificationController.onFcmToken, isNull);
    expect(
      IsolateNameServer.lookupPortByName('notification_action_port'),
      isNull,
    );
  });

  test(
    'dispose during in-flight initialization cannot resurrect state',
    () async {
      final gate = Completer<void>();
      final platform = _FakePlatform(blockOn: 'remote', blockGate: gate);
      final router = _RecordingRouter();

      final initialization = NotificationManager.instance.initialize(
        router: router,
        platform: platform,
      );
      await Future<void>.delayed(Duration.zero);
      expect(platform.localCalls, 1);
      expect(platform.remoteCalls, 1);

      await NotificationManager.instance.dispose();
      gate.complete();

      expect(await initialization, isFalse);
      expect(NotificationManager.instance.isInitialized, isFalse);
      expect(NotificationController.onFcmToken, isNull);
      expect(
        IsolateNameServer.lookupPortByName('notification_action_port'),
        isNull,
      );
    },
  );

  test(
    'initialize owns url policy and restores secure default on dispose',
    () async {
      const external = NotificationUrlPolicy(
        allowedHttpsHosts: {'external.example.test'},
      );
      const owned = NotificationUrlPolicy(
        allowedHttpsHosts: {'owned.example.test'},
      );
      NotificationController.urlPolicy = external;

      await NotificationManager.instance.initialize(
        router: _RecordingRouter(),
        platform: _FakePlatform(),
        urlPolicy: owned,
      );
      expect(NotificationController.urlPolicy, owned);

      await NotificationManager.instance.dispose();
      expect(NotificationController.urlPolicy, external);
    },
  );

  test('dispose does not overwrite a newer url policy owner', () async {
    const owned = NotificationUrlPolicy(
      allowedHttpsHosts: {'owned.example.test'},
    );
    const newer = NotificationUrlPolicy(
      allowedHttpsHosts: {'newer.example.test'},
    );

    await NotificationManager.instance.initialize(
      router: _RecordingRouter(),
      platform: _FakePlatform(),
      urlPolicy: owned,
    );
    NotificationController.urlPolicy = newer;

    await NotificationManager.instance.dispose();
    expect(NotificationController.urlPolicy, newer);
  });
}
