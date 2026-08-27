import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/res/assets.gen.dart';
import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';

enum SelectArrowStyleEnum { showMore, arrowBack, arrowRight }

@Deprecated('Use BackButton or AppPageShell leading actions.')
class ArrowWidget extends StatelessWidget {
  final double? width, height;
  final void Function()? onTap;
  final MainAxisAlignment? mainAxisAlignment;

  const ArrowWidget({
    super.key,
    this.height,
    this.width,
    this.onTap,
    this.mainAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      children: [
        IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onTap ?? () => Navigator.of(context).maybePop(),
          icon: Transform(
            alignment: Alignment.center,
            transform: context.isRight
                ? Matrix4.rotationY(math.pi)
                : Matrix4.identity(),
            child: AppAssets.svg.baseSvg.arrowBack.svg(
              width: width ?? AppSize.sH35,
              height: height ?? AppSize.sH35,
            ),
          ),
        ),
      ],
    );
  }
}

@Deprecated('Compose text with a directional IconButton instead.')
class TitleWithArrowWidget extends StatelessWidget {
  final SelectArrowStyleEnum selectArrowStyleEnum;
  final void Function()? onTap;
  final String tiltle;
  final TextStyle? style;
  final MainAxisAlignment mainAxisAlignment;
  final double? width, height, spacing;

  const TitleWithArrowWidget({
    super.key,
    required this.tiltle,
    this.selectArrowStyleEnum = SelectArrowStyleEnum.arrowBack,
    this.style,
    this.height,
    this.spacing,
    this.width,
    this.onTap,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: spacing ?? AppMargin.mH6,
      children: [
        Text(
          tiltle,
          style: style ?? const TextStyle().setPrimaryColor.s12.regular,
        ),
        ArrowWidget(width: width, height: height),
      ],
    ).onClick(onTap: onTap);
  }
}
