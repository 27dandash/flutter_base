/// Visual constants for [AppDropdown]. Every magic number used by the
/// dropdown lives here so the design system is one tweak away.
class DropdownLayout {
  DropdownLayout._();

  // ── Sheet chrome ────────────────────────────────────────────────
  static const double dragHandleWidth = 85;
  static const double dragHandleHeight = 4;
  static const double dragHandleTopGap = 12;
  static const double headerHeight = 50;
  static const double customHeaderHeight = 80;
  static const double searchBoxHeight = 56 + 16; // field + vertical paddings
  static const double confirmButtonHeight = 70;
  static const double topHandleAndPadding = 28;
  static const double itemExtraSpacing = 12;
  static const double sheetMaxHeightFactor = 0.75;
  static const double sheetTopRadius = 12;

  // ── Item card ───────────────────────────────────────────────────
  static const double itemBorderRadius = 12;
  static const double itemSelectedBorder = 1.5;
  static const double itemUnselectedBorder = 0.5;
  static const double itemHorizontalPadding = 20;
  static const double itemVerticalPadding = 16;
  static const double itemSelectionWidgetGap = 16;

  // ── Selection indicator ─────────────────────────────────────────
  static const double selectionWidgetSize = 20;
  static const double radioInnerSize = 10;
  static const double radioBorderWidth = 2;
  static const double checkboxBorderRadius = 4;
  static const double checkboxIconSize = 14;

  // ── Confirm button ──────────────────────────────────────────────
  static const double confirmButtonVerticalPadding = 14;
  static const double confirmButtonRadius = 10;

  // ── Trigger field ───────────────────────────────────────────────
  static const double loadingIndicatorStroke = 2;
  static const double errorIconSize = 20;
  static const double labelGap = 6;
  static const double fieldBorderRadius = 12;
  static const double errorTopGap = 6;
  static const double errorStartGap = 16;
}
