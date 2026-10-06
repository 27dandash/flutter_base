import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
}) => SvgPicture.file(
  File(path),
  fit: fit,
  width: width,
  height: height,
  semanticsLabel: semanticsLabel,
  placeholderBuilder: placeholderBuilder,
  errorBuilder: errorBuilder,
);
