import 'package:flutter/material.dart';

import '../../../../../../config/res/config_imports.dart';
import '../dropdown_layout.dart';

/// Material-style drag handle drawn at the top of a dropdown sheet.
class DropdownDragHandle extends StatelessWidget {
  const DropdownDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DropdownLayout.dragHandleTopGap),
      child: Container(
        width: DropdownLayout.dragHandleWidth,
        height: DropdownLayout.dragHandleHeight,
        decoration: BoxDecoration(
          color: AppColors.grey1,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
