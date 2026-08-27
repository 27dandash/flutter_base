import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';

@Deprecated('Use AppButton. This wrapper remains for legacy visual options.')
class DefaultButton extends StatelessWidget {
  final String? title;
  final Function()? onTap;
  final Color? textColor;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final double? width;
  final double? fontSize;
  final double? height;
  final double? elevation;
  final bool? disabled;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final Widget? customChild;
  final bool isFitted;

  const DefaultButton({
    super.key,
    this.title,
    this.onTap,
    this.color,
    this.disabled,
    this.textColor,
    this.borderRadius,
    this.margin,
    this.borderColor,
    this.fontFamily,
    this.fontSize,
    this.width,
    this.height,
    this.fontWeight,
    this.elevation,
    this.customChild,
    this.isFitted = true,
  });

  Widget get _defaultChild => Text(
    title ?? 'Click!',
    style: TextStyle(
      color: textColor ?? AppColors.buttonText,
      fontSize: fontSize ?? FontSizeManager.s13,
      fontFamily: fontFamily,
      fontWeight: fontWeight ?? FontWeightManager.medium,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? context.width * .9,
      height: height ?? AppSize.sH45,
      child: ElevatedButton(
        onPressed: disabled == true ? null : onTap,
        style: ElevatedButton.styleFrom(
          splashFactory: InkRipple.splashFactory,
          surfaceTintColor: color ?? AppColors.buttonColor,
          foregroundColor: color ?? AppColors.buttonColor,
          backgroundColor: color ?? AppColors.buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppCircular.r8),
            side: borderColor != null
                ? BorderSide(
                    color: borderColor ?? AppColors.buttonColor,
                    width: .5,
                  )
                : BorderSide.none,
          ),
          elevation: elevation ?? ConstantManager.zeroAsDouble,
        ),
        child: isFitted
            ? FittedBox(child: customChild ?? _defaultChild)
            : customChild ?? _defaultChild,
      ),
    );
  }
}
