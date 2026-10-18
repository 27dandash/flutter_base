import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/painting.dart';

import 'session_cleanup.dart';

/// Empties the decoded-image memory cache and the on-disk network image cache.
///
/// Registered as a `SessionCleanupHook` at startup. Images downloaded for one
/// account (avatars, attachments) must not stay readable after logout, account
/// switching or a revoked session. [cleanDisk] is injectable for tests.
Future<void> clearImageCaches(
  SessionTerminationReason reason, {
  Future<void> Function()? cleanDisk,
}) async {
  final cache = PaintingBinding.instance.imageCache;
  cache
    ..clear()
    ..clearLiveImages();
  await (cleanDisk ?? DefaultCacheManager().emptyCache)();
}
