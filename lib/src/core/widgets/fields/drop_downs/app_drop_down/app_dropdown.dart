import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../config/language/locale_keys.g.dart';
import '../../../../../config/res/assets.gen.dart';
import '../../../../../config/res/config_imports.dart';
import '../../../../shared/extensions/context_extension.dart';
import '../../../../shared/extensions/text_style_extensions.dart';
import '../../../../shared/helpers/validators.dart';
import '../../../../shared/extensions/base_state.dart';
import '../../../../state/paginated/paginated_async_cubit.dart';
import '../../../../state/paginated/paginated_state.dart';
import '../../text_fields/default_text_field.dart';
import 'dropdown_layout.dart';
import 'widgets/widgets.dart';

part 'app_dropdown_trigger.dart';
part 'app_dropdown_sheets.dart';
part 'app_dropdown_sheet_parts.dart';

/// Production-grade dropdown supporting:
///   - single & multi-select modes (toggled via [isMultiSelect])
///   - optional searchable list (client-side filtering)
///   - optional "select all" tile (multi-select only)
///   - loading / error states (driven by [isLoading] / [isFailer])
///   - **paginated lazy-loading** (driven by [paginatedCubit])
///   - readonly mode
///   - dynamic sheet height (capped at 75 % of screen, never covered by
///     the on-screen keyboard)
///
/// All visual constants live in `DropdownLayout` (see `_internals.dart`)
/// so the dropdown follows the design system end-to-end.
///
/// ### Paginated usage (no AsyncBlocBuilder wrapper needed)
/// ```dart
/// AppDropdown<CityEntity>(
///   paginatedCubit: context.read<CitiesCubit>(),
///   paginationFilterKey: selectedCountryId,   // optional — for dependent lookups
///   itemAsString: (c) => c.name,
///   label: LocaleKeys.city.tr(),
///   onChanged: (c) => vc.city.value = c,
///   validator: Validators.validateDropDown,
/// )
/// ```
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.onChanged,
    this.items = const [],
    required this.itemAsString,
    this.value,
    this.hint,
    this.label,
    this.validator,
    this.formKey,
    this.autovalidateMode,
    // Visual
    this.style,
    this.labelTextStyle,
    this.hintTextStyle,
    this.fillColor,
    this.suffixIconColor,
    this.borderRadius,
    this.contentPadding,
    this.height,
    this.maxHeight,
    this.isBordered = true,
    this.isOptional = false,
    // Sheet behaviour
    this.showSearchBox = true,
    this.showHeader = false,
    this.itemHeight = 56,
    this.minBottomSheetHeight = 200,
    // State flags
    this.isFailer = false,
    this.isLoading = false,
    this.onRetry,
    this.readonly = false,
    this.itemId,
    // Multi-select
    this.isMultiSelect = false,
    this.selectedValues,
    this.onMultiChanged,
    this.maxSelectableItems,
    this.selectAllText,
    this.showSelectAll = false,
    // Custom header message
    this.showCustomHeaderMessage = false,
    this.customHeaderMessage,
    // Paginated lookup
    this.paginatedCubit,
    this.paginationFilterKey,
    this.loadMoreThreshold = 0.85,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         !isMultiSelect || (selectedValues != null && onMultiChanged != null),
         'selectedValues and onMultiChanged must be provided when isMultiSelect is true',
       );

  // ── Public API ───────────────────────────────────────────────────
  final List<T> items;
  final T? value;
  final String? hint;
  final String? label;
  final String Function(T) itemAsString;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final GlobalKey<FormState>? formKey;
  final AutovalidateMode? autovalidateMode;

  // Visual
  final TextStyle? style;
  final TextStyle? labelTextStyle;
  final TextStyle? hintTextStyle;
  final Color? fillColor;
  final Color? suffixIconColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;
  final double? maxHeight;
  final bool isBordered;
  final bool isOptional;

  // Sheet behaviour
  final bool showSearchBox;
  final bool showHeader;
  final double itemHeight;
  final double minBottomSheetHeight;

  // State flags (ignored when [paginatedCubit] is set)
  final bool isFailer;
  final bool isLoading;
  final VoidCallback? onRetry;
  final bool readonly;

  /// Stable identity for DTOs/entities that do not implement value equality.
  final Object? Function(T item)? itemId;

  // Multi-select
  final bool isMultiSelect;
  final List<T>? selectedValues;
  final ValueChanged<List<T>>? onMultiChanged;
  final int? maxSelectableItems;
  final String? selectAllText;
  final bool showSelectAll;

  // Custom header message
  final bool showCustomHeaderMessage;
  final String? customHeaderMessage;

  // ── Pagination ──────────────────────────────────────────────────

  /// When provided the dropdown fetches items lazily via [PaginatedAsyncCubit].
  /// The static [items] list is ignored in this mode.
  final PaginatedAsyncCubit<T>? paginatedCubit;

  /// Forwarded to [PaginatedAsyncCubit.fetchInitialData] as `filterKey`
  /// when the sheet opens — use for dependent dropdowns (e.g. cities by country).
  final String? paginationFilterKey;

  /// Fraction of list scroll extent at which the next page loads (0–1).
  final double loadMoreThreshold;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  // ── State holders (ValueNotifier so the sheet rebuilds only the
  //    affected sub-tree, not the whole sheet on every selection). ─
  late final ValueNotifier<T?> _singleSelectedNotifier;
  late final ValueNotifier<List<T>> _multiSelectedNotifier;

  /// Used in static mode — filtered from [AppDropdown.items].
  late final ValueNotifier<List<T>> _filteredItemsNotifier;

  final TextEditingController _searchController = TextEditingController();
  bool _sheetOpen = false;
  bool _confirmationPending = false;

  // ════════════════════════════════════════════════════════════════
  // Lifecycle
  // ════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _singleSelectedNotifier = ValueNotifier<T?>(widget.value);
    _multiSelectedNotifier = ValueNotifier<List<T>>(
      widget.selectedValues ?? [],
    );
    _filteredItemsNotifier = ValueNotifier<List<T>>(widget.items);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _singleSelectedNotifier.value = widget.value;
    }
    if (widget.selectedValues != oldWidget.selectedValues) {
      _multiSelectedNotifier.value = widget.selectedValues ?? [];
    }
    if (widget.items != oldWidget.items) {
      _filteredItemsNotifier.value = widget.items;
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _singleSelectedNotifier.dispose();
    _multiSelectedNotifier.dispose();
    _filteredItemsNotifier.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // Internal helpers
  // ════════════════════════════════════════════════════════════════

  void _onSearchChanged() {
    // Paginated mode filters while building (see [_filterLoaded]); only the
    // static list keeps a filtered copy.
    if (widget.paginatedCubit != null) return;
    final q = _searchController.text.toLowerCase();
    _filteredItemsNotifier.value = q.isEmpty
        ? widget.items
        : widget.items
              .where((e) => widget.itemAsString(e).toLowerCase().contains(q))
              .toList();
  }

  /// Applies the current search query to the pages loaded so far.
  ///
  /// Computed from the cubit state while building rather than copied into a
  /// notifier from a listener: a listener only sees *changes*, so a page that
  /// finished loading before the sheet's first frame (a fast or cached
  /// response) would never have reached it and the sheet would stay empty.
  List<T> _filterLoaded(List<T> loadedItems) {
    final q = _searchController.text.toLowerCase();
    return q.isEmpty
        ? loadedItems
        : loadedItems
              .where((e) => widget.itemAsString(e).toLowerCase().contains(q))
              .toList();
  }

  void _attachPaginationListener(
    ScrollController controller,
    PaginatedAsyncCubit<T> cubit,
  ) {
    controller.addListener(() {
      if (!controller.hasClients) return;
      final max = controller.position.maxScrollExtent;
      if (max > 0 &&
          controller.offset >= max * widget.loadMoreThreshold &&
          cubit.canLoadMore) {
        cubit.loadMore();
      }
    });
  }

  /// A page that does not fill the sheet cannot scroll, so the scroll listener
  /// never fires and the remaining pages would never load. Keep loading while
  /// the list is shorter than the sheet. Not while searching: the search runs
  /// over the loaded pages only, and fetching every page to look for a rare
  /// term would be an unbounded number of requests.
  void _fillShortList(
    ScrollController controller,
    PaginatedAsyncCubit<T> cubit,
    PaginatedState<T> state,
  ) {
    if (!state.status.isSuccess ||
        _searchController.text.isNotEmpty ||
        !cubit.canLoadMore) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      if (controller.position.maxScrollExtent > 0) return;
      if (_searchController.text.isEmpty &&
          cubit.state.status.isSuccess &&
          cubit.canLoadMore) {
        cubit.loadMore();
      }
    });
  }

  /// Dynamic sheet height — sized to content, capped at [maxHeight]
  /// (or 75% of screen), and shrunk further if the keyboard would
  /// otherwise cover the bottom of the sheet.
  double _calculateSheetHeight(BuildContext context, int itemCount) {
    final screen = MediaQuery.of(context).size.height;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final available = screen - keyboard;

    final double headerH = widget.showHeader ? DropdownLayout.headerHeight : 0;
    final double customH =
        widget.showCustomHeaderMessage && widget.customHeaderMessage != null
        ? DropdownLayout.customHeaderHeight
        : 0;
    final double searchH = widget.showSearchBox
        ? DropdownLayout.searchBoxHeight
        : 0;
    final double itemH = widget.itemHeight + DropdownLayout.itemExtraSpacing;
    final double itemsTotal = itemCount * itemH;

    final double content =
        DropdownLayout.topHandleAndPadding +
        headerH +
        customH +
        searchH +
        itemsTotal +
        DropdownLayout.confirmButtonHeight;

    final double maxAllowed =
        widget.maxHeight ?? (screen * DropdownLayout.sheetMaxHeightFactor);
    final double clamped = content.clamp(
      widget.minBottomSheetHeight,
      maxAllowed,
    );

    return clamped > available ? available : clamped;
  }

  bool _isValueEmpty(dynamic value) {
    if (widget.isMultiSelect) {
      return value == null || (value as List<T>).isEmpty;
    }
    return value == null;
  }

  bool _sameItem(T first, T second) {
    final id = widget.itemId;
    return id == null ? first == second : id(first) == id(second);
  }

  bool _containsItem(List<T> values, T item) =>
      values.any((value) => _sameItem(value, item));

  // ════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<dynamic>(
      valueListenable: widget.isMultiSelect
          ? _multiSelectedNotifier
          : _singleSelectedNotifier,
      builder: (context, value, _) {
        return FormField<dynamic>(
          key: widget.formKey,
          autovalidateMode:
              widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
          enabled: !widget.readonly,
          initialValue: value,
          validator: (v) {
            if (widget.validator == null) return null;
            if (widget.isMultiSelect) {
              final selected = value as List<T>? ?? [];
              return widget.validator!(
                selected.isEmpty ? null : selected.first,
              );
            }
            return widget.validator!(value);
          },
          builder: (state) => _buildFieldChrome(context, state, value),
        );
      },
    );
  }
}
