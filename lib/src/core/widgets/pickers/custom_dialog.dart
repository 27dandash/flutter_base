import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';

/// Wraps Flutter's [showGeneralDialog] so feature code only worries about
/// the body — sizing, rounded surface, scrim, and animation are handled
/// here for visual consistency.
///
/// For OK/Cancel prompts prefer [showAdaptiveDialog] directly so iOS
/// users get the Cupertino style automatically; this helper is for
/// custom-body dialogs (forms, pickers, illustrations, …).
Future<T?> showCustomDialog<T>(
  BuildContext context, {
  required Widget child,
  BorderRadiusGeometry? borderRadius,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  bool barrierDismissible = true,
  Color? color,
  Color? barrierColor,
  Duration transitionDuration = const Duration(milliseconds: 250),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.5),
    transitionDuration: transitionDuration,
    pageBuilder: (dialogContext, _, _) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: margin ?? EdgeInsets.symmetric(horizontal: AppPadding.pH20),
            padding: padding ?? EdgeInsets.all(AppPadding.pH20),
            decoration: BoxDecoration(
              color: color ?? Theme.of(dialogContext).colorScheme.surface,
              borderRadius: borderRadius ?? BorderRadius.circular(AppSize.sH25),
            ),
            child: child,
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, _, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}
