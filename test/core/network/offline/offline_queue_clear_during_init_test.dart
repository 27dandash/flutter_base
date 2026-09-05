// OfflineQueueManager — clear requested DURING initialization.
//
// clearPending() invoked after init() has started but before it finishes
// opening the store must still be honoured: the queued clear intent is applied
// the moment the box is available, before the pending count is published or any
// replay can start.
//
// Runs in its own file so the OfflineQueueManager singleton starts fresh
// (uninitialized) in this isolate.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_base/src/core/network/offline/offline_queue_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const boxName = 'offline_queue_gcm_v2';
  final key = List<int>.generate(32, (i) => i);

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => call.method == 'check' ? <String>['none'] : null,
    );
    messenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) {}),
    );
    final dir = await Directory.systemTemp.createTemp('hive_clear_during');
    Hive.init(dir.path);
  });

  test('a clear requested while init is opening the store still wipes the '
      'pre-existing records', () async {
    final seeded = await Hive.openBox<String>(boxName);
    await seeded.put('ghost-op', 'stale-owner-record');
    await seeded.close();

    final manager = OfflineQueueManager();

    // init() runs synchronously up to the first `await Hive.openBox(...)` and
    // then suspends; _initialized is still false here.
    final initFuture = manager.init(encryptionKey: key);
    await manager.clearPending(); // requested mid-initialization

    await initFuture;

    expect(
      manager.pendingCount,
      0,
      reason: 'the mid-init clear was applied before publishing',
    );
    final box = await Hive.openBox<String>(boxName);
    expect(
      box.isEmpty,
      isTrue,
      reason: 'no stale owner record survived a clear-during-init',
    );
  });
}
