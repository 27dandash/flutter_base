import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../config/res/config_imports.dart';
import '../dropdown_layout.dart';

/// Radio circle used in single-select dropdowns.
class DropdownRadio extends StatelessWidget {
  const DropdownRadio({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DropdownLayout.selectionWidgetSize.w,
      height: DropdownLayout.selectionWidgetSize.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.grey1,
          width: DropdownLayout.radioBorderWidth,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: DropdownLayout.radioInnerSize.w,
                height: DropdownLayout.radioInnerSize.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}
