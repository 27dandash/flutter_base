import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';
import '../../shared/extensions/text_style_extensions.dart';
import 'arrow_widget.dart';

@Deprecated('Use AppPageShell for normal and sliver pages.')
class DefaultScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final void Function()? onTap;
  final Widget? trailing;
  final Widget? headLineWidget;
  final bool showArrow;

  const DefaultScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showArrow = true,
    this.onTap,
    this.headLineWidget,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: AppPadding.pH12,
                horizontal: AppPadding.pH12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showArrow) ...[
                    ArrowWidget(onTap: onTap),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                  if (headLineWidget == null) ...[
                    Text(
                      title,
                      style: const TextStyle().setMainTextColor.s13.medium,
                    ),
                  ] else ...[
                    headLineWidget!,
                  ],
                  if (trailing != null) ...[
                    trailing!,
                  ] else ...[
                    SizedBox(height: AppSize.sH30, width: AppSize.sH30),
                  ],
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
