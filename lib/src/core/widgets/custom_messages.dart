import 'package:material_ui/material_ui.dart';

import '../../config/language/locale_keys.g.dart';
import '../../config/res/config_imports.dart';
import '../shared/extensions/base_state.dart';
import '../shared/extensions/text_style_extensions.dart';

class MessageUtils {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
  showSnackBar({
    required BuildContext context,
    required BaseStatus baseStatus,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    assert(duration > Duration.zero && duration <= const Duration(seconds: 4));
    final snackBar = SnackBar(
      duration: duration,
      content: Semantics(
        container: true,
        explicitChildNodes: true,
        liveRegion: true,
        label: message,
        child: ExcludeSemantics(
          child: Text(
            message,
            style: const TextStyle().setWhiteColor.s11.medium,
          ),
        ),
      ),
      action: SnackBarAction(
        label: LocaleKeys.dismiss,
        textColor: AppColors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).clearSnackBars();
        },
      ),
      // One look app-wide: green = success, red = error.
      backgroundColor: baseStatus == BaseStatus.error
          ? AppColors.error
          : AppColors.success,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    );
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    return messenger.showSnackBar(snackBar);
  }
}
