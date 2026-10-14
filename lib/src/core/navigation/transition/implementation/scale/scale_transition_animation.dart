import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/imports_constants.dart';
import '../../factory/transition_creator.dart';
import 'animator/scale_animator.dart';
import 'options/scale_animation_option.dart';

class ScaleTransitionAnimation implements TransitionCreator {
  final ScaleAnimationOptions options;
  const ScaleTransitionAnimation({
    this.options = const ScaleAnimationOptions(),
  });

  @override
  Widget animate(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: ScaleAnimator(options).animator(animation),
      child: child,
    ).buildSecondaryTransition(
      animation: animation,
      applySecondaryTransition: options.secondaryTransition,
    );
  }
}
