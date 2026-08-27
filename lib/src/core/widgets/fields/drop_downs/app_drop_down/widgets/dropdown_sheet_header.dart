import 'package:flutter/material.dart';

import '../../../../../../config/res/config_imports.dart';
import '../../../../../shared/extensions/context_extension.dart';
import '../../../../../shared/extensions/text_style_extensions.dart';

/// Header row inside a dropdown sheet: title + optional trailing widget
/// + close button.
class DropdownSheetHeader extends StatelessWidget {
  const DropdownSheetHeader({
    super.key,
    required this.title,
    this.titleStyle,
    this.trailing,
  });

  final String title;
  final TextStyle? titleStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.pH16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: titleStyle ?? context.textStyle.s16.bold.setMainTextColor,
            ),
          ),
          ?trailing,
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
