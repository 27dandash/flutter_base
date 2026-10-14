import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../factory/transition_creator.dart';
import 'animator/fade_animator.dart';
import 'option/fade_animation_option.dart';

class FadeTransitionAnimation implements TransitionCreator {
  final FadeAnimationOptions options;

  const FadeTransitionAnimation({required this.options});

  @override
  Widget animate(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: FadeAnimator(options).animator(animation),
      child: child,
    );
  }
}
