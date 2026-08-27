import 'package:flutter/material.dart';

import '../../../config/res/assets.gen.dart';
import '../../shared/extensions/context_extension.dart';
import 'app_state_view.dart';

@Deprecated('Use AppStateView.error with safe localized copy.')
class ErrorView extends StatelessWidget {
  final String error;
  final double? width, height;
  const ErrorView({super.key, required this.error, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? context.width,
      height: height ?? context.height,
      child: AppStateView.error(
        message: error,
        semanticLabel: error,
        visual: AppAssets.lottie.error1.lottie(
          width: width ?? context.width * .8,
          height: height != null ? (height! * .8) : context.height * .3,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
