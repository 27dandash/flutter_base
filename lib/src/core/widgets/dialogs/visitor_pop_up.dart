import 'package:flutter/material.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../../config/res/assets.gen.dart';
import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';
import '../buttons/app_button.dart';
import '../pickers/default_bottom_sheet.dart';

Future<dynamic> visitorDialog(BuildContext context, String desc) {
  return showDefaultBottomSheet(
    context: context,
    child: VisitorBody(desc: desc),
  );
}

class VisitorBody extends StatefulWidget {
  final String desc;
  const VisitorBody({super.key, required this.desc});

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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppMargin.mH10,
          children: [
            Expanded(
              child: AppButton(
                label: LocaleKeys.login,
                onPressed: () async =>
                    {}, //async => Go.offAll(const LoginScreen()),
              ),
            ),
            Expanded(
              child: AppButton(
                label: LocaleKeys.register,
                variant: AppButtonVariant.secondary,
                onPressed: () async => {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
