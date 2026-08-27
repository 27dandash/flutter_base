import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'app_media_models.dart';

abstract interface class AppVideoController {
  Future<void> initialize();
  bool get isInitialized;
  bool get isPlaying;
  double get aspectRatio;
  Widget buildPlayer();
  Future<void> play();
  Future<void> pause();
  Future<void> setLooping(bool looping);
  Future<void> dispose();
}

typedef AppVideoControllerFactory = AppVideoController Function(
  AppMediaRequest request,
);

AppVideoController createPlatformVideoController(AppMediaRequest request) {
  return PlatformAppVideoController(request);
}

final class PlatformAppVideoController implements AppVideoController {
  PlatformAppVideoController(AppMediaRequest request)
    : _controller = switch (request.source) {
        AppMediaSource.network => VideoPlayerController.networkUrl(
          Uri.parse(request.path),
        ),
        AppMediaSource.asset => VideoPlayerController.asset(request.path),
        AppMediaSource.file => VideoPlayerController.file(File(request.path)),
      };

  final VideoPlayerController _controller;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  Widget buildPlayer() => VideoPlayer(_controller);

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> setLooping(bool looping) => _controller.setLooping(looping);

  @override
  Future<void> dispose() => _controller.dispose();
}
