import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../../config/res/config_imports.dart';
import '../image_widgets/cached_image.dart';
import 'controller.dart';
import 'enums.dart';

class MediaVideoPlayer extends StatelessWidget {
  final UniversalMediaController controller;
  final BoxFit fit;

  const MediaVideoPlayer({
    super.key,
    required this.controller,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const LoadingIndicator();
    }

    final videoController = controller.videoController;
    if (controller.error != null ||
        !controller.isInitialized ||
        videoController == null) {
      return Semantics(
        liveRegion: true,
        label: LocaleKeys.mediaLoadFailed,
        child: const Center(
          child: Icon(CupertinoIcons.exclamationmark_triangle),
        ),
      );
    }

    return FittedBox(
      fit: fit,
      child: SizedBox(
        width: videoController.value.size.width,
        height: videoController.value.size.height * 1.1,
        child: VideoPlayer(videoController),
      ),
    );
  }
}

class MediaSvgViewer extends StatelessWidget {
  final String path;
  final MediaSource source;
  final BoxFit fit;

  const MediaSvgViewer({
    super.key,
    required this.path,
    required this.source,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (source == MediaSource.network) {
      return SvgPicture.network(
        path,
        fit: fit,
        placeholderBuilder: (context) => const LoadingIndicator(),
      );
    } else {
      return SvgPicture.asset(path, fit: fit);
    }
  }
}

class MediaImageViewer extends StatelessWidget {
  final String path;
  final MediaSource source;
  final BoxFit fit;
  final double? width;
  final double? height;

  const MediaImageViewer({
    super.key,
    required this.path,
    required this.source,
    required this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (source == MediaSource.network) {
      return CachedImage(url: path, fit: fit, width: width, height: height);
    } else {
      return Image.asset(path, fit: fit, width: width, height: height);
    }
  }
}

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  const LoadingIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(color: color ?? AppColors.white),
    );
  }
}
