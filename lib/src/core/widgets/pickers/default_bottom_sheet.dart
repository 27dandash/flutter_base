import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';

/// Standard modal bottom sheet used across the app.
///
/// Uses Flutter's built-in `showDragHandle: true` (Flutter 3.10+) instead
/// of hand-drawing the grab bar — keeps us aligned with Material 3 specs
/// for free.
///
/// Pass [scrollControlled: true] (default) when the body might be tall
/// enough to need the full sheet area; the sheet auto-resizes with the
/// keyboard via `viewInsets`.
Future<T?> showDefaultBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool scrollControlled = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  EdgeInsetsGeometry? padding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
    shape:
        shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppCircular.r20),
          ),
        ),
    builder: (ctx) => _SheetBody(padding: padding, child: child),
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        // Lift body above the keyboard.
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SingleChildScrollView(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: AppPadding.pH16,
                vertical: AppPadding.pH8,
              ),
          child: child,
        ),
      ),
    );
  }
}
