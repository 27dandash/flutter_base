// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter_base/src/core/widgets/image_widgets/image_view.dart';
import 'package:flutter_base/src/core/widgets/media/media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

class _FakeVideoController implements AppVideoController {
  _FakeVideoController({this.initialization, this.fail = false});

  final Completer<void>? initialization;
  final bool fail;
  bool disposed = false;
  bool initialized = false;
  bool playing = false;

  @override
  double get aspectRatio => 16 / 9;
  @override
  bool get isInitialized => initialized;
  @override
  bool get isPlaying => playing;
  @override
  Widget buildPlayer() =>
      const ColoredBox(key: ValueKey('fake-video'), color: Colors.black);
  @override
  Future<void> initialize() async {
    if (fail) throw StateError('private decoder details');
    await initialization?.future;
    initialized = true;
  }

  @override
  Future<void> pause() async => playing = false;
  @override
  Future<void> play() async => playing = true;
  @override
  Future<void> setLooping(bool looping) async {}
  @override
  Future<void> dispose() async => disposed = true;
}

const _video = AppMediaRequest(
  path: 'asset.mp4',
  kind: AppMediaKind.video,
  source: AppMediaSource.asset,
);

void main() {
  test('detect ignores URL queries and distinguishes secure network media', () {
    final request = AppMediaRequest.detect(
      'https://example.test/media/clip.mp4?token=redacted',
    );
    expect(request.kind, AppMediaKind.video);
    expect(request.source, AppMediaSource.network);
  });

  testWidgets('video failure renders a safe fallback without raw exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        AppMedia(
          request: _video,
          videoControllerFactory: (_) => _FakeVideoController(fail: true),
          errorBuilder: (_) => const Text('safe failure'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('safe failure'), findsOneWidget);
    expect(find.textContaining('private decoder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'controller completing after widget disposal is disposed safely',
    (tester) async {
      final pending = Completer<void>();
      final controller = _FakeVideoController(initialization: pending);
      await tester.pumpWidget(
        _host(
          AppMedia(request: _video, videoControllerFactory: (_) => controller),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(_host(const SizedBox.shrink()));
      pending.complete();
      await tester.pump();
      await tester.pump();
      expect(controller.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('viewer opens only when fullscreen policy is enabled', (
    tester,
  ) async {
    const request = AppMediaRequest(
      path: 'missing.png',
      kind: AppMediaKind.image,
      source: AppMediaSource.asset,
    );
    await tester.pumpWidget(
      _host(
        const AppMedia(
          request: request,
          width: 120,
          height: 120,
          semanticLabel: 'Receipt',
          openBehavior: AppMediaOpenBehavior.none,
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);

    await tester.pumpWidget(
      _host(
        const AppMedia(
          request: request,
          width: 120,
          height: 120,
          semanticLabel: 'Receipt',
          openBehavior: AppMediaOpenBehavior.fullscreen,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Receipt'));
    await tester.pumpAndSettle();
    expect(find.byType(AppMediaViewerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('media semantics work in RTL', (tester) async {
    await tester.pumpWidget(
      _host(
        AppMedia.assetImage(path: 'missing.png', semanticLabel: 'صورة'),
        direction: TextDirection.rtl,
      ),
    );
    expect(find.bySemanticsLabel('صورة'), findsOneWidget);
  });

  testWidgets('legacy ImageView delegates to the canonical viewer contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ImageView(
          mediaPath: 'missing.png',
          mediaType: MediaType.image,
          mediaSource: MediaSource.asset,
          minScale: 1,
          maxScale: 3,
          semanticLabel: 'Legacy receipt',
        ),
      ),
    );
    expect(find.byType(AppMediaViewerPage), findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 3);
    expect(find.bySemanticsLabel('Legacy receipt'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy video viewer is safe when disposed while initializing', (
    tester,
  ) async {
    final pending = Completer<void>();
    final controller = _FakeVideoController(initialization: pending);
    await tester.pumpWidget(
      _host(
        ImageView(
          mediaPath: 'legacy.mp4',
          mediaType: MediaType.video,
          mediaSource: MediaSource.asset,
          videoControllerFactory: (_) => controller,
        ),
      ),
    );
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    pending.complete();
    await tester.pump();
    await tester.pump();
    expect(controller.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
