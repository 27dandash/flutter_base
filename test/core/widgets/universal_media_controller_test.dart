import 'dart:async';

import 'package:flutter_base/src/core/widgets/universal_media/controller.dart';
import 'package:flutter_base/src/core/widgets/universal_media/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class _FakePlayer extends VideoPlayerController {
  _FakePlayer({this.fail = false, this.gate}) : super.networkUrl(Uri());

  final bool fail;
  final Completer<void>? gate;
  bool disposedFlag = false;
  bool played = false;

  @override
  Future<void> initialize() async {
    await gate?.future;
    if (fail) throw StateError('boom');
  }

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> play() async => played = true;

  @override
  // ignore: must_call_super
  Future<void> dispose() async => disposedFlag = true;
}

void main() {
  group('source and type detection', () {
    UniversalMediaController make(String path) => UniversalMediaController(
      path: path,
      videoControllerFactory: (_, _) => _FakePlayer(),
    );

    test('only http and https are network sources', () {
      expect(make('https://a.com/x.png').mediaSource, MediaSource.network);
      expect(make('HTTP://a.com/x.png').mediaSource, MediaSource.network);
      expect(make('assets/httpbin.png').mediaSource, MediaSource.asset);
      expect(make('httpfoo.png').mediaSource, MediaSource.asset);
    });

    test('a query string does not hide the extension', () {
      expect(make('https://a.com/c.mp4?t=1').mediaType, MediaType.video);
      expect(make('https://a.com/i.svg#x').mediaType, MediaType.svg);
      expect(make('https://a.com/i.png?x=a.mp4').mediaType, MediaType.image);
    });
  });

  test('a failed load discards the player and reports the error', () async {
    final player = _FakePlayer(fail: true);
    final controller = UniversalMediaController(
      path: 'https://a.com/c.mp4',
      videoControllerFactory: (_, _) => player,
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.error, 'media_load_failed');
    expect(controller.videoController, isNull);
    expect(player.disposedFlag, isTrue);
    controller.dispose();
  });

  test('disposing while loading releases the player and never plays', () async {
    final gate = Completer<void>();
    final player = _FakePlayer(gate: gate);
    final controller = UniversalMediaController(
      path: 'https://a.com/c.mp4',
      autoPlay: true,
      videoControllerFactory: (_, _) => player,
    );
    controller.dispose();
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(player.disposedFlag, isTrue);
    expect(player.played, isFalse);
  });

  test('reload replaces the player and disposes the old one', () async {
    final players = <_FakePlayer>[];
    final controller = UniversalMediaController(
      path: 'https://a.com/c.mp4',
      videoControllerFactory: (_, _) {
        final p = _FakePlayer();
        players.add(p);
        return p;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.isInitialized, isTrue);
    await controller.reload();
    expect(players, hasLength(2));
    expect(players.first.disposedFlag, isTrue);
    expect(controller.videoController, same(players.last));
    expect(controller.isInitialized, isTrue);
    controller.dispose();
  });
}
