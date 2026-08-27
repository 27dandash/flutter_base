import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/res/config_imports.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.icon,
    required this.text,
    required this.active,
    required this.onPressed,
    required this.color,
  });

  final String icon;
  final Text text;
  final bool active;
  final VoidCallback onPressed;
  final Color? color;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late bool _wasActive;

  @override
  void initState() {
    super.initState();
    _wasActive = widget.active;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.active ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != _wasActive) {
      _wasActive = widget.active;
      widget.active ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildContent(double curveValue) {
    final iconWidget = SvgPicture.asset(
      widget.icon,
      width: AppSize.sH22,
      height: AppSize.sH22,
      // ignore: deprecated_member_use
      color: widget.active ? AppColors.white : const Color(0xff999999),
    );
    final hasText = widget.text.data?.isNotEmpty ?? false;
    if (!hasText) return iconWidget;
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            iconWidget,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              widthFactor: curveValue,
              child: Opacity(
                opacity: _textOpacity,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: _leftPadding,
                    end: _rightPadding,
                  ),
                  child: widget.text,
                ),
              ),
            ),
          ],
        ),
        Align(alignment: AlignmentDirectional.centerStart, child: iconWidget),
      ],
    );
  }

  double get _textOpacity {
    if (!widget.active) {
      return pow(_controller.value, 13).toDouble();
    }
    return Curves.easeIn.transform(_controller.value);
  }

  double get _leftPadding {
    final easeOutValue = Curves.easeOutSine.transform(_controller.value);
    final gap = 8;
    return gap + 8 - (8 * easeOutValue);
  }

  double get _rightPadding {
    return 8 * Curves.easeOutSine.transform(_controller.value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curve = Curves.easeInCubic;
        final curveValue = widget.active
            ? curve.transform(_controller.value)
            : curve.flipped.transform(_controller.value);
        return AnimatedContainer(
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: AppPadding.pH6,
            horizontal: AppPadding.pW12,
          ),
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.color ?? Colors.transparent
                : (widget.color ?? Colors.transparent).withValues(alpha: 0),
            borderRadius: BorderRadius.circular(AppCircular.infinity),
          ),
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: _buildContent(curveValue),
          ),
        ).onClick(onTap: widget.onPressed);
      },
    );
  }
}
