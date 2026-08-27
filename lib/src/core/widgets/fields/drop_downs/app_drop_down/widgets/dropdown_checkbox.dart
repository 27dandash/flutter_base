import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../config/res/config_imports.dart';
import '../dropdown_layout.dart';

/// Checkbox used in multi-select dropdowns.
class DropdownCheckbox extends StatelessWidget {
  const DropdownCheckbox({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DropdownLayout.selectionWidgetSize.w,
      height: DropdownLayout.selectionWidgetSize.w,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(
          DropdownLayout.checkboxBorderRadius.r,
        ),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.grey1,
          width: DropdownLayout.radioBorderWidth.w,
        ),
        color: selected ? AppColors.primary : Colors.transparent,
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: DropdownLayout.checkboxIconSize.w,
              color: AppColors.white,
            )
          : null,
    );
  }
}
