import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'queued_operation.dart';

/// One-time import of the old (unowned) queue box into the owned, encrypted one.
abstract final class OfflineQueueLegacyMigration {
  static Future<void> migrate({
    required String legacyBoxName,
    required List<int> key,
    required String? legacyOwnerScope,
    required Future<void> Function(QueuedOperation operation) write,
  }) async {
    if (!await Hive.boxExists(legacyBoxName)) return;
    final scope = legacyOwnerScope?.trim();
    if (scope == null || scope.isEmpty) {
      // Old records have no user ownership metadata. Replaying them under a
      // guessed account is unsafe, so fail closed and remove them.
      await Hive.deleteBoxFromDisk(legacyBoxName);
      return;
    }
    final legacy = await Hive.openBox<QueuedOperation>(
      legacyBoxName,
      encryptionCipher: HiveAesCipher(key),
    );
    try {
      for (final operation in legacy.values) {
        await write(
          QueuedOperation(
            id: operation.id,
            endpoint: operation.endpoint,
            method: operation.method,
            body: operation.body,
            headers: operation.headers,
            createdAt: operation.createdAt,
            retryCount: operation.retryCount,
            localId: operation.localId,
            ownerScope: scope,
          ),
        );
      }
    } finally {
      await legacy.close();
      await Hive.deleteBoxFromDisk(legacyBoxName);
    }
  }
}
