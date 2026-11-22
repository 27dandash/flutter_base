import 'package:material_ui/material_ui.dart';

abstract class TransitionCreator {
  Widget animate(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}
