import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';
import 'custom_animated_button.dart';

@Deprecated('Use AppButton. Keep this only for legacy gradient/progress UI.')
class LoadingButton extends StatelessWidget {
  final String title;
  final Future<void> Function() onTap;
  final Color? textColor;
  final Color? color;
  final BorderSide borderSide;
  final double? borderRadius;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double? fontSize;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final ValueNotifier<double>? onSendProgress;
  final bool isDisabled;
  const LoadingButton({
    super.key,
    required this.title,
    required this.onTap,
    this.color,
    this.isDisabled = false,
    this.textColor,
    this.borderRadius,
    this.margin,
    this.borderSide = BorderSide.none,
    this.fontFamily,
    this.fontSize,
    this.width,
    this.height,
    this.fontWeight,
    this.onSendProgress,
    this.titleAsWidget,
  });
  final Widget? titleAsWidget;
  const LoadingButton.withWidget({
    super.key,
    this.title = "",
    required this.onTap,
    required this.titleAsWidget,
    this.isDisabled = false,
    this.color,
    this.textColor,
    this.borderRadius,
    this.margin,
    this.borderSide = BorderSide.none,
    this.fontFamily,
    this.fontSize,
    this.width,
    this.height,
    this.fontWeight,
    this.onSendProgress,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: CustomAnimatedButton(
        gradient: isDisabled
            ? AppColors.disableGradient
            : color != null
            ? LinearGradient(colors: [color!, color!])
            : AppColors.gradient,
        onTap: isDisabled ? null : onTap,
        enabled: !isDisabled,
        semanticLabel: title,
        elevation: 0,
        padding: EdgeInsets.zero,
        width: width ?? MediaQuery.sizeOf(context).width,
        minWidth: 46.h,
        height: height ?? 46.h,
        borderRadius: borderRadius ?? AppSize.sH12,
        disabledColor: color ?? AppColors.primary,
        borderSide: borderSide,
        loader: onSendProgress == null
            ? Center(
                child: CupertinoActivityIndicator(
                  color: (color ?? AppColors.primary).isDark
                      ? AppColors.white
                      : AppColors.black,
                ),
              )
            : ValueListenableBuilder(
                valueListenable: onSendProgress!,
                builder: (context, value, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60.w,
                        child: Text(
                          "${(value * 100).toStringAsFixed(1)} %",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: (color ?? AppColors.primary).isDark
                                ? AppColors.white
                                : AppColors.black,
                            fontSize: fontSize ?? FontSizeManager.s14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        child:
            titleAsWidget ??
            Text(
              title,
              style: TextStyle(
                color: isDisabled ? AppColors.black : textColor ?? Colors.white,
                fontSize: fontSize ?? FontSizeManager.s14,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}

@Deprecated('Use AppButton with its leading parameter.')
class LoadingButtonWithIcon extends StatefulWidget {
  const LoadingButtonWithIcon({
    super.key,
    required this.onTap,
    required this.title,
    required this.icon,
  });
  final Future<void> Function() onTap;
  final String title;
  final String icon;
  @override
  State<LoadingButtonWithIcon> createState() => _LoadingButtonWithIconState();
}

// Private state retained only for the deprecated compatibility adapter.
// ignore: deprecated_member_use_from_same_package
class _LoadingButtonWithIconState extends State<LoadingButtonWithIcon> {
  bool isLoading = false;

  void toggleIsLoading() {
    if (!mounted) return;
    setState(() {
      isLoading = !isLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isLoading,
      label: widget.title,
      child: InkWell(
        onTap: isLoading
            ? null
            : () async {
                try {
                  if (mounted) toggleIsLoading();
                  await widget.onTap();
                } finally {
                  toggleIsLoading();
                }
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: isLoading
                ? SizedBox(
                    height: 23.h,
                    child: const Center(
                      child: CupertinoActivityIndicator(color: AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(widget.icon),
                      8.w.szW,
                      Text(
                        widget.title,
                        style: context.textStyle.s16.semiBold.setWhiteColor,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
