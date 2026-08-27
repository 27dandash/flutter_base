import 'package:flutter/material.dart';

import '../../../../config/res/config_imports.dart';

extension PaddingExtension on Widget {
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }

  Widget paddingSymmetric({double? horizontal, double? vertical}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal ?? ConstantManager.zeroAsDouble,
        vertical: vertical ?? ConstantManager.zeroAsDouble,
      ),
      child: this,
    );
  }

  Widget paddingAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  @Deprecated('Use paddingStart for direction-aware layouts.')
  Widget paddingLeft(double padding) {
    return Padding(
      padding: EdgeInsets.only(left: padding),
      child: this,
    );
  }

  @Deprecated('Use paddingEnd for direction-aware layouts.')
  Widget paddingRight(double padding) {
    return Padding(
      padding: EdgeInsets.only(right: padding),
      child: this,
    );
  }

  Widget paddingTop(double padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: this,
    );
  }

  Widget paddingBottom(double padding) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: this,
    );
  }

  Widget paddingStart(double padding) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: padding),
      child: this,
    );
  }

  Widget paddingEnd(double padding) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: padding),
      child: this,
    );
  }

  @Deprecated('Use paddingOnlyDirectional for direction-aware layouts.')
  Widget paddingOnly({
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left ?? 0.0,
        right: right ?? 0.0,
        top: top ?? 0.0,
        bottom: bottom ?? 0.0,
      ),
      child: this,
    );
  }

  Widget paddingOnlyDirectional({
    double? start,
    double? end,
    double? top,
    double? bottom,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: start ?? 0.0,
        end: end ?? 0.0,
        top: top ?? 0.0,
        bottom: bottom ?? 0.0,
      ),
      child: this,
    );
  }
}
