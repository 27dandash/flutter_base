import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../../config/res/assets.gen.dart';
import '../../shared/extensions/context_extension.dart';
import 'app_state_view.dart';

@Deprecated('Use AppStateView.empty with an optional visual.')
class EmptyWidget extends StatelessWidget {
  final String? path;
  final String title;
  final String desc;
  const EmptyWidget({
    super.key,
    this.path,
    required this.desc,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppStateView.empty(
      title: title,
      message: desc,
      semanticLabel: '$title. $desc',
      visual: SizedBox(
        width: context.width * .6,
        height: context.height * .25,
        child: FittedBox(fit: BoxFit.contain, child: _buildMedia()),
      ),
    );
  }

  Widget _buildMedia() {
    final String effectivePath = (path == null || path!.isEmpty)
        ? AppAssets.lottie.notFound2.path
        : path!;

    final lower = effectivePath.toLowerCase();

    if (lower.endsWith('.json')) {
      // Lottie animation
      return Lottie.asset(effectivePath);
    } else if (lower.endsWith('.svg')) {
      // SVG asset
      return SvgPicture.asset(effectivePath);
    } else {
      // Fallback to normal image (png, jpg, etc.)
      return Image.asset(effectivePath);
    }
  }
}
