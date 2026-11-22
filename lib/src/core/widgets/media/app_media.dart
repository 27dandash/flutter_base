import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/language/locale_keys.g.dart';
import 'app_media_file_svg.dart';
import 'app_media_models.dart';
import 'app_media_video_view.dart';
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
        AppMediaKind.video => AppMediaVideoView(
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
            loadingBuilder?.call(context) ?? appMediaDefaultLoading(context),
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
        loadingBuilder?.call(context) ?? appMediaDefaultLoading(context);
    Widget error(BuildContext context, Object _, StackTrace? stackTrace) =>
        errorBuilder?.call(context) ?? appMediaDefaultError(context);
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
      errorBuilder?.call(context) ?? appMediaDefaultError(context);
}

Widget appMediaDefaultLoading(BuildContext context) => Semantics(
  liveRegion: true,
  label: LocaleKeys.loading,
  child: const Center(child: CircularProgressIndicator()),
);

Widget appMediaDefaultError(BuildContext context) => Semantics(
  liveRegion: true,
  label: LocaleKeys.mediaLoadFailed,
  child: Center(
    child: Icon(
      Icons.broken_image_outlined,
      color: Theme.of(context).colorScheme.error,
    ),
  ),
);
