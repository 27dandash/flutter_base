import 'package:flutter/material.dart';

import '../media/app_media_models.dart';
import '../media/app_media_viewer_page.dart';
import '../media/app_video_controller.dart';

enum MediaType { image, video }

enum MediaSource { network, asset }

/// Compatibility page for callers that still use the former media enums.
///
/// New code should use [AppMediaViewerPage] and [AppMediaRequest] directly.
@Deprecated('Use AppMediaViewerPage with AppMediaRequest instead.')
class ImageView extends StatelessWidget {
  const ImageView({
    super.key,
    required this.mediaPath,
    required this.mediaType,
    required this.mediaSource,
    this.minScale = 0.8,
    this.maxScale = 4,
    this.autoPlayVideo = true,
    this.loopVideo = true,
    this.semanticLabel,
    this.videoControllerFactory = createPlatformVideoController,
  }) : assert(minScale > 0),
       assert(maxScale >= minScale);

  final String mediaPath;
  final MediaType mediaType;
  final MediaSource mediaSource;
  final double minScale;
  final double maxScale;
  final bool autoPlayVideo;
  final bool loopVideo;
  final String? semanticLabel;
  final AppVideoControllerFactory videoControllerFactory;

  @override
  Widget build(BuildContext context) {
    return AppMediaViewerPage(
      request: AppMediaRequest(
        path: mediaPath,
        kind: mediaType == MediaType.video
            ? AppMediaKind.video
            : AppMediaKind.image,
        source: mediaSource == MediaSource.network
            ? AppMediaSource.network
            : AppMediaSource.asset,
      ),
      semanticLabel: semanticLabel,
      minScale: minScale,
      maxScale: maxScale,
      autoPlayVideo: autoPlayVideo,
      loopVideo: loopVideo,
      videoControllerFactory: videoControllerFactory,
    );
  }
}
