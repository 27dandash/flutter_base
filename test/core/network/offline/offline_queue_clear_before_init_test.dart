// OfflineQueueManager — clear requested BEFORE initialization.
//
// A logout can call clearPending() before optional persistence has finished
// starting. The intent must be remembered and applied the instant the store
// opens, so records left on disk from a previous run/owner are never published
// or replayed under the new session.
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
    final dir = await Directory.systemTemp.createTemp('hive_clear_before');
    Hive.init(dir.path);
  });

  test('a clear requested before init wipes pre-existing records once the '
      'store opens', () async {
    // A previous run left a record on disk.
    final seeded = await Hive.openBox<String>(boxName);
    await seeded.put('ghost-op', 'stale-owner-record');
    await seeded.close();

    final manager = OfflineQueueManager();

    // Logout raced ahead of initialization.
    await manager.clearPending();
    expect(
      manager.pendingCount,
      0,
      reason: 'pendingCount is safe (0) before init',
    );

    await manager.init(encryptionKey: key);

    expect(
      manager.pendingCount,
      0,
      reason: 'the deferred clear removed the stale record at init',
    );
    final box = await Hive.openBox<String>(boxName);
    expect(box.isEmpty, isTrue, reason: 'no stale owner record survived init');
  });

  test('a repeated clear after init stays idempotent', () async {
    final manager = OfflineQueueManager();
    await manager.clearPending();
    await manager.clearPending();
    expect(manager.pendingCount, 0);
  });
}
