import 'package:flutter/material.dart';

/// Canonical page chrome for normal and sliver-based screens.
///
/// Back navigation remains owned by Flutter unless [onBack] is supplied. This
/// preserves Android predictive-back while still allowing a page to provide a
/// genuinely contextual back action.
class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions = const [],
    this.onBack,
    this.backgroundColor,
    this.safeArea = true,
  }) : slivers = null,
       pinned = true,
       floating = false,
       expandedHeight = null;

  const AppPageShell.sliver({
    super.key,
    required this.title,
    required this.slivers,
    this.leading,
    this.actions = const [],
    this.onBack,
    this.backgroundColor,
    this.safeArea = false,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight,
  }) : body = null;

  final Widget title;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final bool safeArea;
  final bool pinned;
  final bool floating;
  final double? expandedHeight;

  @override
  Widget build(BuildContext context) {
    final customBack = onBack;
    final scaffold = slivers == null
        ? Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: title,
              leading:
                  leading ??
                  (customBack == null
                      ? null
                      : BackButton(onPressed: customBack)),
              actions: actions,
            ),
            body: safeArea ? SafeArea(child: body!) : body,
          )
        : Scaffold(
            backgroundColor: backgroundColor,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: title,
                  leading:
                      leading ??
                      (customBack == null
                          ? null
                          : BackButton(onPressed: customBack)),
                  actions: actions,
                  pinned: pinned,
                  floating: floating,
                  expandedHeight: expandedHeight,
                ),
                ...?slivers,
              ],
            ),
          );

    if (customBack == null) return scaffold;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) customBack();
      },
      child: scaffold,
    );
  }
}
