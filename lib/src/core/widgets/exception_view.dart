import 'package:flutter/material.dart';

import '../../config/language/locale_keys.g.dart';
import '../../config/res/assets.gen.dart';
import '../../config/res/config_imports.dart';
import '../shared/extensions/context_extension.dart';
import '../shared/extensions/text_style_extensions.dart';

/// Full-screen fallback used as the global `ErrorWidget.builder` in release
/// builds (see `main.dart`). Distinct from the data-state views under
/// `handling_views/` — this catches widget *build* failures, not API errors.
class ExceptionView extends StatelessWidget {
  const ExceptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppMargin.mH10,
          children: [
            AppAssets.lottie.error1.lottie(
              width: context.width * .7,
              height: context.height * .3,
            ),
            Text(
              LocaleKeys.exceptionError,
              style: const TextStyle().setPrimaryColor.s13.medium,
            ),
          ],
        ),
      ),
    );
  }
}
