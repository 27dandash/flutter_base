import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../config/language/locale_keys.g.dart';
import 'app_media.dart';
import 'app_media_models.dart';
import 'app_video_controller.dart';

class AppMediaVideoView extends StatefulWidget {
  const AppMediaVideoView({
    super.key,
    required this.request,
    required this.fit,
    required this.autoPlay,
    required this.loop,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.controllerFactory,
    required this.semanticLabel,
  });

  final AppMediaRequest request;
  final BoxFit fit;
  final bool autoPlay;
  final bool loop;
  final AppMediaStateBuilder? loadingBuilder;
  final AppMediaStateBuilder? errorBuilder;
  final AppVideoControllerFactory controllerFactory;
  final String? semanticLabel;

  @override
  State<AppMediaVideoView> createState() => AppMediaVideoViewState();
}

class AppMediaVideoViewState extends State<AppMediaVideoView> {
  AppVideoController? _controller;
  int _generation = 0;
  bool _loading = true;
  bool _failed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant AppMediaVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request != widget.request ||
        oldWidget.controllerFactory != widget.controllerFactory) {
      unawaited(_initialize());
    }
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    final previous = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    if (previous != null) await previous.dispose();

    AppVideoController? next;
    try {
      next = widget.controllerFactory(widget.request);
      await next.initialize();
      await next.setLooping(widget.loop);
      if (widget.autoPlay) await next.play();
      if (_disposed || generation != _generation) {
        await next.dispose();
        return;
      }
      _controller = next;
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (next != null) await next.dispose();
      if (_disposed || generation != _generation) return;
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingBuilder?.call(context) ??
          appMediaDefaultLoading(context);
    }
    final controller = _controller;
    if (_failed || controller == null || !controller.isInitialized) {
      return widget.errorBuilder?.call(context) ??
          appMediaDefaultError(context);
    }
    final ratio = controller.aspectRatio > 0 ? controller.aspectRatio : 16 / 9;
    return Semantics(
      label: widget.semanticLabel,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: ratio * 100,
              height: 100,
              child: controller.buildPlayer(),
            ),
          ),
          IconButton.filledTonal(
            tooltip: controller.isPlaying
                ? LocaleKeys.mediaPause
                : LocaleKeys.mediaPlay,
            onPressed: () async {
              controller.isPlaying
                  ? await controller.pause()
                  : await controller.play();
              if (mounted) setState(() {});
            },
            icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}
