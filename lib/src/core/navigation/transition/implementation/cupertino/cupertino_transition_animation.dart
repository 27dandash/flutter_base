import 'package:flutter/cupertino.dart';

import '../../factory/transition_creator.dart';
import 'options/cupertino_animation_option.dart';

class CupertinoTransitionAnimation implements TransitionCreator {
  final CupertinoAnimationOptions options;

  const CupertinoTransitionAnimation({required this.options});

  @override
  Widget animate(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return options.isFullscreenDialog
        ? CupertinoFullscreenDialogTransition(
            primaryRouteAnimation: animation,
            secondaryRouteAnimation: secondaryAnimation,
            linearTransition: options.isLinearTransition,
            child: child,
          )
        : CupertinoPageTransition(
            primaryRouteAnimation: animation,
            secondaryRouteAnimation: secondaryAnimation,
            linearTransition: options.isLinearTransition,
            child: child,
          );
  }
}
