import 'package:flutter/painting.dart';
import 'package:flutter_base/src/core/session/image_cache_cleanup.dart';
import 'package:flutter_base/src/core/session/session_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('logout empties the decoded-image cache and the disk cache', (
    tester,
  ) async {
    final image = (await tester.runAsync(createTestImage))!;
    final cache = PaintingBinding.instance.imageCache;
    cache.putIfAbsent(
      'avatar',
      () => OneFrameImageStreamCompleter(
        Future<ImageInfo>.value(ImageInfo(image: image)),
      ),
    );
    await tester.pump();
    expect(cache.currentSize, greaterThan(0));
    var diskCleared = 0;

    await clearImageCaches(
      SessionTerminationReason.logout,
      cleanDisk: () async => diskCleared++,
    );

    expect(cache.currentSize, 0);
    expect(diskCleared, 1);
  });

  test('a disk failure is reported to the cleanup registry', () async {
    SessionCleanupRegistry.instance
      ..clearForTesting()
      ..register(
        SessionCleanupHook(
          id: 'image_cache',
          action: (reason) => clearImageCaches(
            reason,
            cleanDisk: () async => throw StateError('disk busy'),
          ),
        ),
      );
    addTearDown(SessionCleanupRegistry.instance.clearForTesting);

    final failures = await SessionCleanupRegistry.instance.run(
      SessionTerminationReason.revoked,
    );

    expect(failures.map((f) => f.hookId), ['image_cache']);
  });
}
