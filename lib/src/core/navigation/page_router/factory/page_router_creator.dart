import 'package:flutter/material.dart';

import '../../constants/imports_constants.dart';
import '../../helper/interfaces/helper_imports.dart';

abstract class PageRouterCreator {
  Route<T> create<T>(
    Widget page, {
    RouteSettings? settings,
    TransitionType? transition,
    AnimationOption? animationOptions,
  });
}
