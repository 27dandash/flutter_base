import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/res/config_imports.dart';

/// Loading affordances used across the app.
///
/// Inline spinner is **adaptive**: shows a Material
/// [CircularProgressIndicator] on Android and a
/// [CupertinoActivityIndicator] on iOS, matching each platform's
/// native feel. Pass [forceMaterial] / [forceCupertino] to override
/// when a specific look is required (e.g. brand-coloured spinner that
/// the Cupertino indicator can't render).
class CustomLoading {
  CustomLoading._();

  /// Inline spinner — drop into any layout that has a parent constraint.
  static Widget inline({
    double? size,
    Color? color,
    bool forceMaterial = false,
    bool forceCupertino = false,
  }) {
    final useCupertino = forceCupertino || (!forceMaterial && Platform.isIOS);
    final dimension = size ?? AppSize.sH40;
    final effectiveColor = color ?? AppColors.main;

    return Center(
      child: SizedBox.square(
        dimension: dimension,
        child: useCupertino
            ? CupertinoActivityIndicator(
                color: effectiveColor,
                radius: dimension / 2,
              )
            : CircularProgressIndicator(color: effectiveColor, strokeWidth: 3),
      ),
    );
  }

  /// Backwards-compatible alias — older callers still use this name.
  static Widget showLoadingView() => inline(size: AppSize.sH50);
}
