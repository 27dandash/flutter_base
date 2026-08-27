import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';
import '../../shared/extensions/text_style_extensions.dart';
import 'animated_button.dart';
import 'navigation_bar_entity.dart';

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({
    super.key,
    required this.tabs,
    this.selectedIndex = 0,
    this.onTabChange,
  });

  final List<NavigationBarEntity> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabChange;

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late int _selectedIndex;
  bool _isClickable = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(CustomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  void _handleTabPress(int index) {
    if (!_isClickable) return;

    setState(() {
      _selectedIndex = index;
      _isClickable = false;
    });

    widget.onTabChange?.call(index);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isClickable = true);
      }
    });
  }

  Widget _buildTab(NavigationBarEntity tab, int index) {
    context.locale;
    final isActive = _selectedIndex == index;
    return Semantics(
      child: AnimatedButton(
        icon: tab.icon,
        text: Text(tab.text, style: const TextStyle().setWhiteColor.s13.medium),
        active: isActive,
        color: const Color(0xff5C40C2),
        onPressed: () => _handleTabPress(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return Container(
      height: AppSize.sH60,
      padding: EdgeInsets.all(AppPadding.pH8),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey1,
            blurRadius: 0,
            offset: Offset(1, -.5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.tabs
            .asMap()
            .entries
            .map((entry) => _buildTab(entry.value, entry.key))
            .toList(),
      ),
    );
  }
}
