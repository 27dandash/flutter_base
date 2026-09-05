import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../config/res/config_imports.dart';
import '../../../../../shared/extensions/context_extension.dart';
import '../../../../../shared/extensions/text_style_extensions.dart';
import '../dropdown_layout.dart';

/// One selectable row inside a dropdown sheet. Used for both single and
/// multi-select — the selection indicator (radio or checkbox) is passed
/// via [trailing] so this tile stays generic.
class DropdownItemTile extends StatelessWidget {
  const DropdownItemTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.trailing,
    required this.itemHeight,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget trailing;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(
              DropdownLayout.itemBorderRadius.r,
            ),
            child: Container(
              height: itemHeight,
              padding: EdgeInsets.symmetric(
                vertical: DropdownLayout.itemVerticalPadding.h,
                horizontal: DropdownLayout.itemHorizontalPadding.w,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  DropdownLayout.itemBorderRadius.r,
                ),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.grey2.withValues(alpha: 0.3),
                  width: selected
                      ? DropdownLayout.itemSelectedBorder
                      : DropdownLayout.itemUnselectedBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: selected
                          ? context.textStyle.s16.medium.setColor(
                              AppColors.primary,
                            )
                          : context.textStyle.s16.regular.setColor(
                              Theme.of(context).colorScheme.onSurface,
                            ),
                    ),
                  ),
                  SizedBox(width: DropdownLayout.itemSelectionWidgetGap.w),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
