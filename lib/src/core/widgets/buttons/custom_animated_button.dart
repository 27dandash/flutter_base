import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';

enum ButtonStatus { loading, idle }

/// Legacy animated action retained for gradient/progress compatibility.
///
/// Prefer `AppButton` for new actions. This implementation still guarantees a
/// real disabled state, keyboard focus, accessible targets, duplicate-submit
/// prevention and safe completion after disposal.
@Deprecated('Use AppButton unless the legacy width animation is required.')
class CustomAnimatedButton extends StatefulWidget {
  const CustomAnimatedButton({
    required this.height,
    required this.width,
    this.minWidth = 0,
    this.loader,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutCirc,
    this.reverseCurve = Curves.easeInOutCirc,
    required this.child,
    required this.onTap,
    this.color,
    this.gradient,
    this.colorBrightness,
    this.elevation,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 0,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.materialTapTargetSize,
    this.roundLoadingShape = true,
    this.borderSide = BorderSide.none,
    this.disabledElevation,
    this.disabledColor,
    this.disabledTextColor,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
    super.key,
  }) : assert(elevation == null || elevation >= 0),
       assert(disabledElevation == null || disabledElevation >= 0),
       assert(
         color == null || gradient == null,
         'Cannot provide both color and gradient',
       );

  final double height;
  final double width;
  final double minWidth;
  final Widget? loader;
  final Duration animationDuration;
  final Curve curve;
  final Curve reverseCurve;
  final Widget child;
  final FutureOr<void> Function()? onTap;
  final Color? color;
  final Gradient? gradient;
  final Brightness? colorBrightness;
  final double? elevation;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;
  final FocusNode? focusNode;
  final MaterialTapTargetSize? materialTapTargetSize;
  final bool roundLoadingShape;
  final double borderRadius;
  final BorderSide borderSide;
  final double? disabledElevation;
  final Color? disabledColor;
  final Color? disabledTextColor;
  final bool enabled;
  final bool autofocus;
  final String? semanticLabel;

  @override
  CustomButtonState createState() => CustomButtonState();
}

// Compatibility state is intentionally coupled to the deprecated public
// adapter until downstream callers finish migrating.
// ignore: deprecated_member_use_from_same_package
class CustomButtonState extends State<CustomAnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late double _minWidth;
  ButtonStatus buttonStatus = ButtonStatus.idle;

  @override
  void initState() {
    super.initState();
    _minWidth = widget.minWidth == 0 ? widget.height : widget.minWidth;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation =
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
          reverseCurve: widget.reverseCurve,
        )..addStatusListener((status) {
          if (status == AnimationStatus.dismissed && mounted) {
            setState(() => buttonStatus = ButtonStatus.idle);
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startLoading() {
    if (!mounted || !widget.enabled || widget.onTap == null) return;
    setState(() => buttonStatus = ButtonStatus.loading);
    _controller.forward();
  }

  void stopLoading() {
    if (!mounted) return;
    _controller.reverse();
  }

  Future<void> doWhileLoading() async {
    if (!mounted ||
        !widget.enabled ||
        widget.onTap == null ||
        buttonStatus != ButtonStatus.idle) {
      return;
    }
    try {
      startLoading();
      await widget.onTap!();
    } finally {
      stopLoading();
    }
  }

  double? _lerpWidth() {
    if (widget.width == 0 || _minWidth == 0) return null;
    return widget.width + (_minWidth - widget.width) * _animation.value;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => _buildButton(),
    );
  }

  Widget _buildButton() {
    final canSubmit =
        widget.enabled &&
        widget.onTap != null &&
        buttonStatus == ButtonStatus.idle;
    final radius = widget.roundLoadingShape
        ? lerpDouble(widget.borderRadius, widget.height / 2, _animation.value)!
        : widget.borderRadius;

    return Semantics(
      button: true,
      enabled: canSubmit,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: SizedBox(
          height: widget.height,
          width: _lerpWidth(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canSubmit ? doWhileLoading : null,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              splashColor: AppColors.secondary,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                clipBehavior: widget.clipBehavior,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  color: widget.gradient == null
                      ? (widget.enabled
                            ? widget.color
                            : widget.disabledColor ?? widget.color)
                      : null,
                  borderRadius: BorderRadius.circular(radius),
                  border: widget.borderSide == BorderSide.none
                      ? null
                      : Border.fromBorderSide(widget.borderSide),
                ),
                padding: widget.padding,
                alignment: Alignment.center,
                child: buttonStatus == ButtonStatus.idle
                    ? widget.child
                    : widget.loader,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
