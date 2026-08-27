import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension SeparatorExtension on List<Widget> {
  List<Widget> joinWith(Widget separator) {
    if (isEmpty) return [];
    if (length == 1) return toList();
    return expand((element) => [element, separator]).toList()..removeLast();
  }
}

extension OnClick on Widget {
  Widget onClick({void Function()? onTap}) {
    return GestureDetector(onTap: onTap, child: this);
  }
}

extension SizedBoxHelper on num {
  SizedBox get szH => SizedBox(height: toDouble().h);
  SizedBox get szW => SizedBox(width: toDouble().w);
}

extension SliverExtension on Widget {
  SliverToBoxAdapter toSliver() => SliverToBoxAdapter(child: this);
}
