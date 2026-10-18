import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'enums.dart';

class UniversalMediaController extends ChangeNotifier {
  final String path;
  final bool autoPlay;

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;
  int _generation = 0;

  /// Builds the player. Overridable so tests can run without a platform
  /// video plugin.
  final VideoPlayerController Function(String path, MediaSource source)?
  videoControllerFactory;

  UniversalMediaController({
    required this.path,
    this.autoPlay = false,
    @visibleForTesting this.videoControllerFactory,
  }) {
    _initialize();
  }

  MediaType get mediaType => _detectMediaType();
  MediaSource get mediaSource => _detectMediaSource();
  VideoPlayerController? get videoController => _videoController;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPlaying => _videoController?.value.isPlaying ?? false;

  MediaType _detectMediaType() {
    // Ignore the query string and fragment of a URL (`clip.mp4?token=1`).
    final clean = path.split(RegExp(r'[?#]')).first;
    final ext = clean.split('.').last.toLowerCase();

    if (['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', 'webm'].contains(ext)) {
      return MediaType.video;
    } else if (ext == 'svg') {
      return MediaType.svg;
    } else {
      return MediaType.image;
    }
  }

  MediaSource _detectMediaSource() {
    final scheme = Uri.tryParse(path)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https'
        ? MediaSource.network
        : MediaSource.asset;
  }

  Future<void> _initialize() async {
    if (mediaType == MediaType.video) {
      await _loadVideo();
    } else {
      _isInitialized = true;
      _notify();
    }
  }

  Future<void> _loadVideo() async {
    final generation = ++_generation;
    _isLoading = true;
    _error = null;
    _notify();

    VideoPlayerController? controller;
    try {
      controller =
          videoControllerFactory?.call(path, mediaSource) ??
          (mediaSource == MediaSource.network
              ? VideoPlayerController.networkUrl(Uri.parse(path))
              : VideoPlayerController.asset(path));
      _videoController = controller;

      await controller.initialize();
      await controller.setLooping(true);

      if (_disposed || generation != _generation) {
        if (identical(_videoController, controller)) _videoController = null;
        await controller.dispose();
        return;
      }
      if (autoPlay) await controller.play();

      _isInitialized = true;
      _isLoading = false;
      _notify();
    } catch (_) {
      if (identical(_videoController, controller)) _videoController = null;
      try {
        await controller?.dispose();
      } catch (_) {}
      if (_disposed || generation != _generation) return;
      _error = 'media_load_failed';
      _isLoading = false;
      _isInitialized = false;
      _notify();
    }
  }

  Future<void> play() async {
    if (_isInitialized && _videoController != null) {
      await _videoController!.play();
      _notify();
    }
  }

  Future<void> pause() async {
    if (_isInitialized && _videoController != null) {
      await _videoController!.pause();
      _notify();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_isInitialized && _videoController != null) {
      await _videoController!.seekTo(position);
    }
  }

  Future<void> reload() async {
    if (mediaType == MediaType.video) {
      final old = _videoController;
      _videoController = null;
      _isInitialized = false;
      _error = null;
      _notify();
      try {
        await old?.dispose();
      } catch (_) {}
      if (_disposed) return;
      await _loadVideo();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
