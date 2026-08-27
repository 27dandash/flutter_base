import 'package:flutter_base/src/core/session/session_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final registry = SessionCleanupRegistry.instance;

  setUp(registry.clearForTesting);
  tearDown(registry.clearForTesting);

  test('runs every cleanup hook even when one fails', () async {
    final calls = <String>[];
    registry.register(
      SessionCleanupHook(
        id: 'socket',
        action: (_) async => calls.add('socket'),
      ),
    );
    registry.register(
      SessionCleanupHook(
        id: 'notification-token',
        action: (_) async {
          calls.add('notification-token');
          throw StateError('backend offline');
        },
      ),
    );
    registry.register(
      SessionCleanupHook(
        id: 'profile',
        action: (_) async => calls.add('profile'),
      ),
    );

    final failures = await registry.run(SessionTerminationReason.logout);

    expect(calls, ['socket', 'notification-token', 'profile']);
    expect(failures.map((failure) => failure.hookId), ['notification-token']);
  });

  test('re-registering an id replaces the old hook', () async {
    var value = 0;
    registry.register(
      SessionCleanupHook(id: 'socket', action: (_) async => value = 1),
    );
    registry.register(
      SessionCleanupHook(id: 'socket', action: (_) async => value = 2),
    );

    await registry.run(SessionTerminationReason.accountSwitch);

    expect(value, 2);
  });
}
