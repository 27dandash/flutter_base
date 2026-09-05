import 'package:flutter/material.dart';

import '../../../config/res/assets.gen.dart';
import '../../network/error/failures.dart';
import '../../shared/extensions/context_extension.dart';
import 'app_state_view.dart';

/// Compatibility-only error presentation adapter.
///
/// Prefer [AppStateView.error] with localized safe copy. The [error] parameter
/// must already be user-safe; for typed failures use [ErrorView.fromFailure].
@Deprecated('Use AppStateView.error with safe localized copy.')
class ErrorView extends StatelessWidget {
  final String error;
  final double? width, height;

  const ErrorView({super.key, required this.error, this.width, this.height});

  /// Builds a safe error view from a typed [Failure] without exposing raw
  /// backend or plugin exception text.
  factory ErrorView.fromFailure({
    Key? key,
    required Failure failure,
    double? width,
    double? height,
  }) {
    return ErrorView(
      key: key,
      error: failure.userMessage,
      width: width,
      height: height,
    );
  }

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
