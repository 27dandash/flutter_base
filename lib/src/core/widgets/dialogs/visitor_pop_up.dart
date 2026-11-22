import 'package:material_ui/material_ui.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../../config/res/assets.gen.dart';
import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';
import '../buttons/app_button.dart';
import '../pickers/default_bottom_sheet.dart';

/// Asks a guest to sign in. The buttons only exist when the app supplies the
/// action: a visible button must never be dead.
Future<dynamic> visitorDialog(
  BuildContext context,
  String desc, {
  VoidCallback? onLogin,
  VoidCallback? onRegister,
}) {
  return showDefaultBottomSheet(
    context: context,
    child: VisitorBody(desc: desc, onLogin: onLogin, onRegister: onRegister),
  );
}

class VisitorBody extends StatefulWidget {
  final String desc;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  const VisitorBody({
    super.key,
    required this.desc,
    this.onLogin,
    this.onRegister,
  });

  @override
  State<VisitorBody> createState() => VisitorBodyState();
}

class VisitorBodyState extends State<VisitorBody> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: AppMargin.mH10,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAssets.svg.baseSvg.dropDownClose
                .svg(width: AppSize.sH30, height: AppSize.sH30)
                .onClick(onTap: () => Navigator.of(context).maybePop()),
          ],
        ),
        SizedBox(
          width: context.width * .2,
          height: context.height * .12,
          child: Center(
            child: AppAssets.lottie.visit.lottie(
              width: context.width * .15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Text(
          LocaleKeys.oops,
          textAlign: TextAlign.center,
          style: const TextStyle().setMainTextColor.s14.medium,
        ),
        Text(
          widget.desc,
          textAlign: TextAlign.center,
          style: const TextStyle().setSecondryColor.s12.regular,
        ),
        AppSize.sH10.szH,
        if (widget.onLogin != null || widget.onRegister != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: AppMargin.mH10,
            children: [
              if (widget.onLogin != null)
                Expanded(
                  child: AppButton(
                    label: LocaleKeys.login,
                    onPressed: () async {
                      Navigator.of(context).maybePop();
                      widget.onLogin!();
                    },
                  ),
                ),
              if (widget.onRegister != null)
                Expanded(
                  child: AppButton(
                    label: LocaleKeys.register,
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      Navigator.of(context).maybePop();
                      widget.onRegister!();
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
