import 'package:flutter/material.dart';

import '../../../config/language/locale_keys.g.dart';
import 'app_media.dart';
import 'app_media_models.dart';
import 'app_video_controller.dart';

class AppMediaViewerPage extends StatelessWidget {
  const AppMediaViewerPage({
    super.key,
    required this.request,
    this.semanticLabel,
    this.videoControllerFactory = createPlatformVideoController,
    this.minScale = 0.8,
    this.maxScale = 4,
    this.autoPlayVideo = true,
    this.loopVideo = false,
  }) : assert(minScale > 0),
       assert(maxScale >= minScale);

  final AppMediaRequest request;
  final String? semanticLabel;
  final AppVideoControllerFactory videoControllerFactory;
  final double minScale;
  final double maxScale;
  final bool autoPlayVideo;
  final bool loopVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: semanticLabel == null ? null : Text(semanticLabel!),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Center(
          child: AppMedia(
            request: request,
            semanticLabel: semanticLabel ?? LocaleKeys.mediaOpen,
            openBehavior: AppMediaOpenBehavior.none,
            videoControllerFactory: videoControllerFactory,
            interactive: request.kind != AppMediaKind.video,
            interactiveMinScale: minScale,
            interactiveMaxScale: maxScale,
            autoPlay: request.kind == AppMediaKind.video && autoPlayVideo,
            loopVideo: loopVideo,
          ),
        ),
      ),
    );
  }
}
