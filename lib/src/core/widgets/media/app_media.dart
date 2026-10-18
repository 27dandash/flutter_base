import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/language/locale_keys.g.dart';
import 'app_media_file_svg.dart';
import 'app_media_models.dart';
import 'app_media_viewer_page.dart';
import 'app_video_controller.dart';

typedef AppMediaStateBuilder = Widget Function(BuildContext context);

/// Canonical media renderer for asset, file and network images/SVGs and
/// optional video. Failures are converted to a safe localized state and raw
/// plugin exceptions are never rendered.
class AppMedia extends StatelessWidget {
  const AppMedia({
    super.key,
    required this.request,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.semanticLabel,
    this.openBehavior = AppMediaOpenBehavior.none,
    this.loadingBuilder,
    this.errorBuilder,
    this.videoControllerFactory = createPlatformVideoController,
    this.autoPlay = false,
    this.loopVideo = false,
    this.interactive = false,
    this.interactiveMinScale = 0.8,
    this.interactiveMaxScale = 4,
  }) : assert(interactiveMinScale > 0),
       assert(interactiveMaxScale >= interactiveMinScale);

  factory AppMedia.networkImage({
    Key? key,
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    String? semanticLabel,
    AppMediaOpenBehavior openBehavior = AppMediaOpenBehavior.none,
    AppMediaStateBuilder? loadingBuilder,
    AppMediaStateBuilder? errorBuilder,
  }) => AppMedia(
    key: key,
    request: AppMediaRequest(
      path: url,
      kind: AppMediaKind.image,
      source: AppMediaSource.network,
    ),
    fit: fit,
    width: width,
    height: height,
    semanticLabel: semanticLabel,
    openBehavior: openBehavior,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );

  factory AppMedia.assetImage({
    Key? key,
    required String path,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    String? semanticLabel,
  }) => AppMedia(
    key: key,
    request: AppMediaRequest(
      path: path,
      kind: AppMediaKind.image,
      source: AppMediaSource.asset,
    ),
    fit: fit,
    width: width,
    height: height,
    semanticLabel: semanticLabel,
  );

  factory AppMedia.fileImage({
    Key? key,
    required File file,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    String? semanticLabel,
  }) => AppMedia(
    key: key,
    request: AppMediaRequest(
      path: file.path,
      kind: AppMediaKind.image,
      source: AppMediaSource.file,
    ),
    fit: fit,
    width: width,
    height: height,
    semanticLabel: semanticLabel,
  );

  final AppMediaRequest request;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final AppMediaOpenBehavior openBehavior;
  final AppMediaStateBuilder? loadingBuilder;
  final AppMediaStateBuilder? errorBuilder;
  final AppVideoControllerFactory videoControllerFactory;
  final bool autoPlay;
  final bool loopVideo;
  final bool interactive;
  final double interactiveMinScale;
  final double interactiveMaxScale;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: width,
      height: height,
      child: switch (request.kind) {
        AppMediaKind.image => _buildImage(context),
        AppMediaKind.svg => _buildSvg(context),
        AppMediaKind.video => _AppVideoView(
          request: request,
          fit: fit,
          autoPlay: autoPlay,
          loop: loopVideo,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          controllerFactory: videoControllerFactory,
          semanticLabel: semanticLabel,
        ),
      },
    );

    final accessible = Semantics(
      image: request.kind != AppMediaKind.video,
      label: semanticLabel,
      button: openBehavior == AppMediaOpenBehavior.fullscreen,
      child: ExcludeSemantics(
        child: interactive && request.kind != AppMediaKind.video
            ? InteractiveViewer(
                minScale: interactiveMinScale,
                maxScale: interactiveMaxScale,
                child: content,
              )
            : content,
      ),
    );

    if (openBehavior == AppMediaOpenBehavior.none) return accessible;
    return Tooltip(
      message: LocaleKeys.mediaOpen,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AppMediaViewerPage(
              request: request,
              semanticLabel: semanticLabel,
              videoControllerFactory: videoControllerFactory,
            ),
          ),
        ),
        child: accessible,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    Widget error(
      BuildContext errorContext,
      Object error,
      StackTrace? stackTrace,
    ) => _error(errorContext);
    final image = switch (request.source) {
      // Disk-cached and decoded at display size. `Image.network` keeps no disk
      // cache and decodes the full-resolution bitmap, which exhausts memory in
      // an image-heavy list.
      AppMediaSource.network => CachedNetworkImage(
        imageUrl: request.path,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: _decodeWidth(context),
        memCacheHeight: _decodeWidth(context) == null
            ? _decodeHeight(context)
            : null,
        placeholder: (context, _) =>
            loadingBuilder?.call(context) ?? _defaultLoading(context),
        errorWidget: (context, _, _) => _error(context),
      ),
      AppMediaSource.asset => Image.asset(
        request.path,
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
        errorBuilder: error,
      ),
      AppMediaSource.file when kIsWeb => _error(context),
      AppMediaSource.file => Image.file(
        File(request.path),
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
        errorBuilder: error,
      ),
    };
    return image;
  }

  static const int _maxDecodePixels = 2048;

  /// Pixel size to decode a network image at, capped so a huge layout hint
  /// cannot request a huge bitmap. Only one dimension is given: Flutter then
  /// keeps the aspect ratio (both would distort it).
  int? _decodeWidth(BuildContext context) => _decodePixels(context, width);

  int? _decodeHeight(BuildContext context) => _decodePixels(context, height);

  int? _decodePixels(BuildContext context, double? logical) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final pixels = (logical * MediaQuery.devicePixelRatioOf(context)).round();
    return pixels.clamp(1, _maxDecodePixels);
  }

  Widget _buildSvg(BuildContext context) {
    final placeholder =
        loadingBuilder?.call(context) ?? _defaultLoading(context);
    Widget error(BuildContext context, Object _, StackTrace? stackTrace) =>
        errorBuilder?.call(context) ?? _defaultError(context);
    return switch (request.source) {
      AppMediaSource.network => SvgPicture.network(
        request.path,
        fit: fit,
        width: width,
        height: height,
        semanticsLabel: semanticLabel,
        placeholderBuilder: (_) => placeholder,
        errorBuilder: error,
      ),
      AppMediaSource.asset => SvgPicture.asset(
        request.path,
        fit: fit,
        width: width,
        height: height,
        semanticsLabel: semanticLabel,
        placeholderBuilder: (_) => placeholder,
        errorBuilder: error,
      ),
      AppMediaSource.file => buildAppMediaFileSvg(
        context: context,
        path: request.path,
        fit: fit,
        width: width,
        height: height,
        semanticsLabel: semanticLabel,
        placeholderBuilder: (_) => placeholder,
        errorBuilder: error,
      ),
    };
  }

  Widget _error(BuildContext context) =>
      errorBuilder?.call(context) ?? _defaultError(context);
}

Widget _defaultLoading(BuildContext context) => Semantics(
  liveRegion: true,
  label: LocaleKeys.loading,
  child: const Center(child: CircularProgressIndicator()),
);

Widget _defaultError(BuildContext context) => Semantics(
  liveRegion: true,
  label: LocaleKeys.mediaLoadFailed,
  child: Center(
    child: Icon(
      Icons.broken_image_outlined,
      color: Theme.of(context).colorScheme.error,
    ),
  ),
);

class _AppVideoView extends StatefulWidget {
  const _AppVideoView({
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
  State<_AppVideoView> createState() => _AppVideoViewState();
}

class _AppVideoViewState extends State<_AppVideoView> {
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
  void didUpdateWidget(covariant _AppVideoView oldWidget) {
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
      return widget.loadingBuilder?.call(context) ?? _defaultLoading(context);
    }
    final controller = _controller;
    if (_failed || controller == null || !controller.isInitialized) {
      return widget.errorBuilder?.call(context) ?? _defaultError(context);
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
