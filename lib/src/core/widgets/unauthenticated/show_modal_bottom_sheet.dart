// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';

Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double? borderRadius,
  bool isDismissible = true,
  bool enableDrag = true,
  bool scrollable = true,
  String? title,
  String? subTitle,
  TextStyle? subTitleStyle,
  bool hasTopInductor = true,
  RouteSettings? routeSettings,
  EdgeInsets? padding,
}) async {
  if (FocusManager.instance.primaryFocus?.hasPrimaryFocus == true) {
    FocusScope.of(context).requestFocus(FocusNode());
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
  return await showModalBottomSheet<T?>(
    context: context,
    isScrollControlled: true,
    enableDrag: enableDrag,
    useRootNavigator: true,
    isDismissible: isDismissible,
    routeSettings: routeSettings,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
    ),
    builder: (BuildContext context) {
      return Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        padding:
            padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12).r,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: (scrollable)
                  ? SingleChildScrollView(
                      physics: scrollable
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (title != null)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Icon(Icons.close, size: 28.sp),
                                ),
                                8.w.szW,
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: context
                                      .textStyle
                                      .s14
                                      .bold
                                      .setPrimaryColor,
                                ),
                              ],
                            ),
                          if (subTitle != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                subTitle,
                                textAlign: TextAlign.center,
                                style:
                                    subTitleStyle ??
                                    context.textStyle.s20.bold.setHintColor,
                              ),
                            ),
                          const SizedBox(height: 12),
                          child,
                          SizedBox(
                            height: MediaQuery.of(context).viewInsets.bottom,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Flexible(child: child),
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}

Future<T?> showAppTopModalSheet<T>({
  required BuildContext context,
  required List<Widget> children,
  double? borderRadius,
  bool isDismissible = true,
  bool hasInductor = true,
  String? routeSettingsName,
  EdgeInsets? padding,
  Widget Function(BuildContext context)? header,
  Widget Function(BuildContext context)? footer,
}) async {
  if (FocusManager.instance.primaryFocus?.hasPrimaryFocus == true) {
    FocusScope.of(context).requestFocus(FocusNode());
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
  return await showGeneralDialog<T?>(
    context: context,
    barrierDismissible: isDismissible,
    useRootNavigator: true,
    barrierLabel: routeSettingsName ?? "showAppTopModalSheet",
    routeSettings: RouteSettings(name: routeSettingsName),
    pageBuilder:
        (
          BuildContext buildContext,
          Animation animation,
          Animation secondaryAnimation,
        ) {
          return Align(
            alignment: Alignment.topCenter,
            child: Material(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              elevation: .7,
              child: Container(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                width: MediaQuery.of(context).size.width,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .92,
                ),
                decoration: const BoxDecoration(color: Colors.white),
                padding:
                    padding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12).r,
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (header != null) header(context),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(children: children),
                        ),
                      ),
                      if (footer != null) footer(context),
                      const SizedBox(height: 20),
                      if (hasInductor)
                        Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width * .25,
                          height: 5,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xffD6D6D6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1), // Slide from top
          end: const Offset(0, 0),
        ).animate(anim1),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
