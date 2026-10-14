import 'dart:async';

import 'package:app_notifications/app_notifications.dart';
import 'package:app_notifications/src/notification_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_notification_platform.dart';

final class _RecordingRouter implements NotificationRouter {
  final actions = <NotificationAction>[];

  @override
  Future<void> route(NotificationAction action) async => actions.add(action);
}

RemoteMessage _message(
  Map<String, dynamic> data, {
  RemoteNotification? notification,
}) => RemoteMessage(data: data, notification: notification);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationPlatform platform;
  late _RecordingRouter router;
  late List<String> events;

  NotificationTypeRegistry registry() => NotificationTypeRegistry(
    types: [
      NotificationTypeSpec(
        'order_created',
        navigate: (data) => events.add('order:${data['order_id']}'),
      ),
      NotificationTypeSpec(
        'new_message',
        navigate: (data) => events.add('chat:${data['room_id']}'),
      ),
      const NotificationTypeSpec('admin_notify'),
      const NotificationTypeSpec('blocked', endsSession: true),
    ],
    resolveType: (type, payload) =>
        type == 'text' && payload['sender_id'] != null ? 'new_message' : type,
  );

  Future<void> start({
    NotificationGate? gate,
    Future<void> Function()? onSessionEnd,
    FakeNotificationPlatform? custom,
  }) async {
    platform = custom ?? platform;
    final ok = await NotificationManager.instance.initialize(
      router: router,
      platform: platform,
      typeRegistry: registry(),
      canHandle: gate,
      onSessionEnd: onSessionEnd ?? () async => events.add('session-end'),
      sessionEndCooldown: Duration.zero,
      tokenRetryDelay: const Duration(milliseconds: 10),
    );
    expect(ok, isTrue);
    await settle();
  }

  setUp(() {
    platform = FakeNotificationPlatform();
    router = _RecordingRouter();
    events = [];
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    NotificationController.onFcmToken = null;
    await NotificationManager.instance.dispose();
    await platform.close();
  });

  group('foreground messages', () {
    test('are shown as local notifications with a counter id', () async {
      await start();

      platform.messages.add(
        _message({'type': 'admin_notify', 'title': 'Hello', 'message': 'Body'}),
      );
      platform.messages.add(_message({'title': 'Second'}));
      await settle();

      expect(platform.shown, hasLength(2));
      expect(platform.shown.first.title, 'Hello');
      expect(platform.shown.first.body, 'Body');
      expect(platform.shown.map((n) => n.id), [1, 2]);
      expect(platform.shown.last.body, isEmpty);
    });

    test('use the configured presentation and fallback title', () async {
      await start();

      platform.messages.add(_message({}));
      await settle();

      expect(platform.shown.single.title, 'إشعار جديد');
      expect(platform.presentation?.channelId, 'high_importance_channel');
    });

    test('are dropped when the gate disallows them', () async {
      await start(gate: (_) => false);

      platform.messages.add(_message({'type': 'admin_notify', 'title': 'X'}));
      await settle();

      expect(platform.shown, isEmpty);
    });

    test('a throwing gate allows the notification', () async {
      await start(gate: (_) => throw StateError('preference unavailable'));

      platform.messages.add(_message({'title': 'X'}));
      await settle();

      expect(platform.shown, hasLength(1));
    });

    test('registered listeners observe matching types only', () async {
      await start();
      final received = <Map<String, dynamic>>[];
      NotificationManager.instance.addListener(
        NotificationActionListener(
          types: {'order_created'},
          onMessage: received.add,
        ),
      );
      NotificationManager.instance.addListener(
        NotificationActionListener(
          types: {'order_created'},
          onMessage: (_) => throw StateError('faulty observer'),
        ),
      );

      platform.messages.add(
        _message({'type': 'order_created', 'order_id': '9', 'title': 'T'}),
      );
      platform.messages.add(_message({'type': 'unknown_type', 'title': 'U'}));
      await settle();

      expect(received, hasLength(1));
      expect(received.single['order_id'], '9');
      expect(platform.shown, hasLength(2));
    });

    test('nested data is flattened before type detection', () async {
      await start();
      final received = <Map<String, dynamic>>[];
      NotificationManager.instance.addListener(
        NotificationActionListener(
          types: {'order_created'},
          onMessage: received.add,
        ),
      );

      platform.messages.add(
        _message({
          'id': '77',
          'data': '{"type":"order_created","order_id":"5"}',
        }),
      );
      await settle();

      expect(received.single['order_id'], '5');
      expect(received.single['notification_id'], '77');
    });

    test('a failing display never throws into the stream', () async {
      await start();
      platform.showFails = true;

      platform.messages.add(_message({'title': 'X'}));
      await settle();

      expect(platform.shown, isEmpty);
    });
  });

  group('session ending types', () {
    test('show the notification then end the session once', () async {
      await start(gate: (_) => false);

      platform.messages.add(_message({'type': 'blocked', 'title': 'Blocked'}));
      await settle();

      expect(platform.shown.single.title, 'Blocked');
      expect(events, ['session-end']);
    });

    test('concurrent session-end messages run the callback once', () async {
      final gate = Completer<void>();
      await start(
        onSessionEnd: () async {
          events.add('session-end');
          await gate.future;
        },
      );

      platform.messages.add(_message({'type': 'blocked', 'title': 'A'}));
      platform.messages.add(_message({'type': 'blocked', 'title': 'B'}));
      await settle();
      gate.complete();
      await settle();

      expect(events, ['session-end']);
      expect(platform.shown, hasLength(2));
    });

    test(
      'a tap ends the session even when notifications are disabled',
      () async {
        await start(gate: (_) => false);

        platform.opened.add(_message({'type': 'blocked'}));
        await settle();

        expect(events, ['session-end']);
      },
    );

    test('a failing session-end callback is contained', () async {
      await start(onSessionEnd: () async => throw StateError('logout failed'));

      platform.messages.add(_message({'type': 'blocked', 'title': 'B'}));
      await settle();

      expect(platform.shown, hasLength(1));
    });
  });

  group('taps', () {
    test('a system-tray tap routes by registered type', () async {
      await start();

      platform.opened.add(
        _message({'type': 'order_created', 'order_id': '12'}),
      );
      await settle();

      expect(events, ['order:12']);
    });

    test('a local-notification tap routes the original message', () async {
      await start();

      platform.onTap!(_message({'type': 'order_created', 'order_id': '3'}));
      await settle();

      expect(events, ['order:3']);
    });

    test('the type resolver aliases legacy transport types', () async {
      await start();

      platform.opened.add(
        _message({'type': 'text', 'sender_id': '4', 'room_id': 'r1'}),
      );
      await settle();

      expect(events, ['chat:r1']);
    });

    test('a type object with a value key is understood', () async {
      await start();

      platform.opened.add(
        _message({
          'type': {'value': 'order_created'},
          'order_id': '8',
        }),
      );
      await settle();

      expect(events, ['order:8']);
    });

    test('taps are dropped when the gate disallows them', () async {
      await start(gate: (_) => false);

      platform.opened.add(_message({'type': 'order_created', 'order_id': '1'}));
      await settle();

      expect(events, isEmpty);
    });

    test('a type without navigation does nothing', () async {
      await start();

      platform.opened.add(_message({'type': 'admin_notify'}));
      await settle();

      expect(events, isEmpty);
      expect(router.actions, isEmpty);
    });

    test(
      'an unregistered type falls back to the generic action contract',
      () async {
        await start();

        platform.opened.add(
          _message({
            'type': 'promo',
            'action_type': 'navigate_screen',
            'route': '/offers',
          }),
        );
        await settle();

        expect(router.actions.single, isA<NavigateToScreen>());
        expect((router.actions.single as NavigateToScreen).route, '/offers');
      },
    );

    test('generic open_url honours the url policy', () async {
      await start();

      platform.opened.add(
        _message({'action_type': 'open_url', 'url': 'http://insecure.test'}),
      );
      platform.opened.add(
        _message({'action_type': 'open_url', 'url': 'https://safe.test/x'}),
      );
      await settle();

      expect(router.actions[0], isA<DismissAction>());
      expect(router.actions[1], isA<OpenUrl>());
    });

    test('the launch notification is routed once at startup', () async {
      await start(
        custom: FakeNotificationPlatform(
          initialMessage: _message({'type': 'order_created', 'order_id': '21'}),
        ),
      );

      expect(events, ['order:21']);
    });

    test('a throwing navigator is contained', () async {
      final custom = FakeNotificationPlatform();
      platform = custom;
      await NotificationManager.instance.initialize(
        router: router,
        platform: custom,
        typeRegistry: NotificationTypeRegistry(
          types: [
            NotificationTypeSpec(
              'order_created',
              navigate: (_) => throw StateError('navigator not ready'),
            ),
          ],
        ),
      );
      await settle();

      custom.opened.add(_message({'type': 'order_created'}));
      await settle();
    });

    test('messages after dispose are ignored', () async {
      await start();
      await NotificationManager.instance.dispose();

      platform.onTap!(_message({'type': 'order_created', 'order_id': '1'}));
      await settle();

      expect(events, isEmpty);
    });
  });

  group('token', () {
    test('is delivered to the owner callback and refresh stream', () async {
      final tokens = <String>[];
      await NotificationManager.instance.initialize(
        router: router,
        platform: platform,
        onFcmToken: tokens.add,
      );
      await settle();
      final refreshed = <String>[];
      final sub = NotificationManager.instance.tokenRefreshes.listen(
        refreshed.add,
      );

      platform.refreshes.add('token-2');
      await settle();

      expect(tokens, ['token-1', 'token-2']);
      expect(refreshed, ['token-2']);
      expect(NotificationManager.instance.deviceToken, 'token-2');
      await sub.cancel();
    });

    test('is retried with a bounded schedule after failures', () async {
      final custom = FakeNotificationPlatform(tokenFailures: 2);
      final tokens = <String>[];
      platform = custom;
      await NotificationManager.instance.initialize(
        router: router,
        platform: custom,
        onFcmToken: tokens.add,
        tokenRetryDelay: const Duration(milliseconds: 5),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(custom.tokenCalls, 3);
      expect(tokens, ['token-1']);
    });

    test('retrying stops after the attempt limit', () async {
      final custom = FakeNotificationPlatform(tokenFailures: 100);
      platform = custom;
      await NotificationManager.instance.initialize(
        router: router,
        platform: custom,
        tokenRetryDelay: const Duration(milliseconds: 1),
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(custom.tokenCalls, 5);
      expect(NotificationManager.instance.isInitialized, isTrue);
    });

    test('requestToken returns null for an empty token', () async {
      final custom = FakeNotificationPlatform(token: '  ');
      platform = custom;
      await NotificationManager.instance.initialize(
        router: router,
        platform: custom,
      );

      expect(await NotificationManager.instance.requestToken(), isNull);
    });
  });

  group('resolveNotificationText', () {
    test('Android prefers data over the notification block', () {
      final text = resolveNotificationText(
        data: {'title': 'D', 'message': 'dm', 'body': 'db'},
        notificationTitle: 'N',
        notificationBody: 'nb',
        isIOS: false,
        fallbackTitle: 'F',
      );
      expect(text, (title: 'D', body: 'dm'));
    });

    test('iOS prefers the notification block over data', () {
      final text = resolveNotificationText(
        data: {'title': 'D', 'message': 'dm'},
        notificationTitle: 'N',
        notificationBody: 'nb',
        isIOS: true,
        fallbackTitle: 'F',
      );
      expect(text, (title: 'N', body: 'nb'));
    });

    test('falls back through alternative keys and the fallback title', () {
      expect(
        resolveNotificationText(
          data: {'Title': 'T', 'body_ar': 'ar', 'body_en': 'en'},
          notificationTitle: null,
          notificationBody: null,
          isIOS: false,
          fallbackTitle: 'F',
        ),
        (title: 'T', body: 'ar'),
      );
      expect(
        resolveNotificationText(
          data: const {},
          notificationTitle: null,
          notificationBody: 'nb',
          isIOS: false,
          fallbackTitle: 'F',
        ),
        (title: 'F', body: 'nb'),
      );
    });

    test('the manager resolves text with the iOS rules on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await NotificationManager.instance.initialize(
        router: router,
        platform: platform,
      );
      await settle();

      platform.messages.add(
        _message(
          {'title': 'data title'},
          notification: const RemoteNotification(
            title: 'system title',
            body: 'system body',
          ),
        ),
      );
      await settle();

      expect(platform.shown.single.title, 'system title');
      expect(platform.shown.single.body, 'system body');
    });
  });
}
