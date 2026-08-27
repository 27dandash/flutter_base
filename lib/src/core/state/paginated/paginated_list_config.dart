import 'package:flutter/material.dart';

import '../../../config/res/config_imports.dart';

/// List vs grid rendering mode for [PaginatedListWidget].
enum PaginatedListViewType { list, grid }

/// All scroll / layout / refresh knobs for [PaginatedListWidget] in one
/// object. Pass an instance to the widget instead of polluting the
/// widget's own constructor with 15+ params.
///
/// Sensible defaults:
///   - vertical [ListViewType.list] view
///   - pull-to-refresh **on**
///   - no separator, no padding — caller picks
///   - 2-column grid when [viewType] = grid
class PaginatedListConfig {
  // ── Layout ──────────────────────────────────────────────────────
  final PaginatedListViewType viewType;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? itemMargin;
  final bool shrinkWrap;
  final bool reverse;
  final bool? primary;
  final ScrollController? controller;

  // ── List-specific ──────────────────────────────────────────────
  final bool useSeparator;
  final Widget? separator;

  // ── Grid-specific ──────────────────────────────────────────────
  final SliverGridDelegate? gridDelegate;

  // ── Refresh ────────────────────────────────────────────────────
  final bool enableRefresh;
  final Color? refreshIndicatorColor;
  final Color? refreshIndicatorBackgroundColor;
  final double refreshIndicatorDisplacement;

  const PaginatedListConfig({
    this.viewType = PaginatedListViewType.list,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.padding,
    this.itemMargin,
    this.shrinkWrap = false,
    this.reverse = false,
    this.primary,
    this.controller,
    this.useSeparator = false,
    this.separator,
    this.gridDelegate,
    this.enableRefresh = true,
    this.refreshIndicatorColor,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorDisplacement = 40,
  });

  PaginatedListConfig copyWith({
    PaginatedListViewType? viewType,
    Axis? scrollDirection,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? itemMargin,
    bool? useSeparator,
    Widget? separator,
    SliverGridDelegate? gridDelegate,
    bool? shrinkWrap,
    bool? reverse,
    bool? primary,
    ScrollController? controller,
    bool? enableRefresh,
    Color? refreshIndicatorColor,
    Color? refreshIndicatorBackgroundColor,
    double? refreshIndicatorDisplacement,
  }) {
    return PaginatedListConfig(
      viewType: viewType ?? this.viewType,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      physics: physics ?? this.physics,
      padding: padding ?? this.padding,
      itemMargin: itemMargin ?? this.itemMargin,
      useSeparator: useSeparator ?? this.useSeparator,
      separator: separator ?? this.separator,
      gridDelegate: gridDelegate ?? this.gridDelegate,
      shrinkWrap: shrinkWrap ?? this.shrinkWrap,
      reverse: reverse ?? this.reverse,
      primary: primary ?? this.primary,
      controller: controller ?? this.controller,
      enableRefresh: enableRefresh ?? this.enableRefresh,
      refreshIndicatorColor:
          refreshIndicatorColor ?? this.refreshIndicatorColor,
      refreshIndicatorBackgroundColor:
          refreshIndicatorBackgroundColor ??
          this.refreshIndicatorBackgroundColor,
      refreshIndicatorDisplacement:
          refreshIndicatorDisplacement ?? this.refreshIndicatorDisplacement,
    );
  }

  /// Default 2-column grid delegate when none is supplied.
  static SliverGridDelegate get defaultGridDelegate =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppPadding.pH8,
        mainAxisSpacing: AppPadding.pH8,
      );
}
