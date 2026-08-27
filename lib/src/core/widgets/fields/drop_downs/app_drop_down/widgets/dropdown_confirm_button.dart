import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../config/res/config_imports.dart';
import '../../../../../shared/extensions/context_extension.dart';
import '../../../../../shared/extensions/text_style_extensions.dart';
import '../dropdown_layout.dart';

/// Confirm button at the bottom of every dropdown sheet. Disabled
/// (greyed out) until the caller flips [enabled] to true.
class DropdownConfirmButton extends StatelessWidget {
  const DropdownConfirmButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppPadding.pH16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? AppColors.primary : AppColors.grey2,
            padding: EdgeInsets.symmetric(
              vertical: DropdownLayout.confirmButtonVerticalPadding.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                DropdownLayout.confirmButtonRadius.r,
              ),
            ),
          ),
          onPressed: enabled ? onPressed : null,
          child: Text(
            label,
            style: context.textStyle.s18.medium.setColor(
              enabled ? AppColors.white : AppColors.grey1,
            ),
          ),
        ),
      ),
    );
  }
}
