import 'package:flutter/widgets.dart';

typedef AppMediaFileSvgErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

Widget buildAppMediaFileSvg({
  required BuildContext context,
  required String path,
  required BoxFit fit,
  required double? width,
  required double? height,
  required String? semanticsLabel,
  required WidgetBuilder placeholderBuilder,
  required AppMediaFileSvgErrorBuilder errorBuilder,
}) => errorBuilder(
  context,
  UnsupportedError('Local SVG files are unavailable on this platform.'),
  null,
);
