import 'package:flutter/material.dart';

import '../media/media.dart';

/// Compatibility wrapper. New code should use [AppMedia] directly.
@Deprecated('Use AppMedia from widgets/media/media.dart.')
class UniversalMediaWidget extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool autoPlay;

  const UniversalMediaWidget({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.autoPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppMedia(
      request: AppMediaRequest.detect(path),
      fit: fit,
      width: width,
      height: height,
      autoPlay: autoPlay,
    );
  }
}
