import 'package:flutter/material.dart';
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

  /// Used in paginated mode — filtered from [PaginatedAsyncCubit.state.data.items].
  late final ValueNotifier<List<T>> _paginatedFilteredItemsNotifier;

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
    _paginatedFilteredItemsNotifier = ValueNotifier<List<T>>(
      widget.paginatedCubit?.state.data.items ?? [],
    );
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
    _paginatedFilteredItemsNotifier.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // Internal helpers
  // ════════════════════════════════════════════════════════════════

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    if (widget.paginatedCubit != null) {
      _syncPaginatedFilter(widget.paginatedCubit!.state.data.items);
    } else {
      _filteredItemsNotifier.value = q.isEmpty
          ? widget.items
          : widget.items
                .where((e) => widget.itemAsString(e).toLowerCase().contains(q))
                .toList();
    }
  }

  /// Re-applies the current search query against freshly loaded pages.
  void _syncPaginatedFilter(List<T> loadedItems) {
    final q = _searchController.text.toLowerCase();
    _paginatedFilteredItemsNotifier.value = q.isEmpty
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

  String _getDisplayText(
    dynamic value, {
    bool isLoading = false,
    bool isFailer = false,
  }) {
    if (isLoading) return LocaleKeys.loading;
    if (isFailer) return LocaleKeys.exceptionError;

    if (widget.isMultiSelect) {
      final selected = value as List<T>? ?? [];
      if (selected.isEmpty) return widget.hint ?? LocaleKeys.selectAnOption;
      return selected.map(widget.itemAsString).join(', ');
    }

    if (value == null) return widget.hint ?? LocaleKeys.selectAnOption;
    return widget.itemAsString(value);
  }

  Widget _buildSuffix(
    BuildContext context, {
    bool isLoading = false,
    bool isFailer = false,
  }) {
    if (isLoading) {
      return SizedBox(
        width: DropdownLayout.selectionWidgetSize.w,
        height: DropdownLayout.selectionWidgetSize.h,
        child: const CircularProgressIndicator(
          strokeWidth: DropdownLayout.loadingIndicatorStroke,
          color: AppColors.primary,
        ),
      );
    }
    if (isFailer) {
      return Icon(
        Icons.error_outline,
        color: AppColors.error,
        size: DropdownLayout.errorIconSize.h,
      );
    }
    if (widget.readonly) return const SizedBox.shrink();

    return AppAssets.svg.baseSvg.arrowDown.svg(
      colorFilter: ColorFilter.mode(
        widget.suffixIconColor ??
            Theme.of(context).colorScheme.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    );
  }

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

  Widget _buildFieldChrome(
    BuildContext context,
    FormFieldState<dynamic> state,
    dynamic value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          _buildLabel(context),
          SizedBox(height: AppSize.sH6),
        ],
        // When a paginated cubit is attached, react to its loading/error
        // state so the trigger shows a spinner / error icon automatically.
        if (widget.paginatedCubit != null)
          BlocBuilder<PaginatedAsyncCubit<T>, PaginatedState<T>>(
            bloc: widget.paginatedCubit,
            buildWhen: (prev, curr) => prev.status != curr.status,
            builder: (ctx, pState) => _buildTrigger(
              context,
              state,
              value,
              overrideIsLoading: pState.isFirstLoad,
              overrideIsFailer: pState.isInitialError,
            ),
          )
        else
          _buildTrigger(context, state, value),
        if (state.hasError && state.errorText != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: DropdownLayout.errorTopGap.h,
              start: DropdownLayout.errorStartGap.w,
            ),
            child: Text(
              state.errorText!,
              style: context.textStyle.s12.regular.setColor(AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.label,
            style:
                widget.labelTextStyle ??
                context.textStyle.s14.regular.setColor(
                  Theme.of(context).colorScheme.onSurface,
                ),
          ),
          if (widget.isOptional)
            TextSpan(
              text: ' (${LocaleKeys.optional})',
              style: context.textStyle.s12.regular.setColor(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrigger(
    BuildContext context,
    FormFieldState<dynamic> state,
    dynamic value, {
    bool overrideIsLoading = false,
    bool overrideIsFailer = false,
  }) {
    final effectiveIsLoading = overrideIsLoading || widget.isLoading;
    final effectiveIsFailer = overrideIsFailer || widget.isFailer;
    final borderRadius =
        widget.borderRadius ??
        BorderRadius.circular(DropdownLayout.fieldBorderRadius.r);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: state.hasError
            ? Border.all(
                width: 0.5,
                color: AppColors.error.withValues(alpha: 0.65),
              )
            : null,
      ),
      child: Semantics(
        button: true,
        enabled: !widget.readonly && !effectiveIsLoading,
        label:
            widget.semanticLabel ??
            widget.label ??
            _getDisplayText(
              value,
              isLoading: effectiveIsLoading,
              isFailer: effectiveIsFailer,
            ),
        child: InkWell(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          borderRadius: borderRadius,
          onTap: widget.readonly || effectiveIsLoading
              ? null
              : effectiveIsFailer && widget.onRetry != null
              ? widget.onRetry
              : () => _openSheet(state),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: widget.contentPadding ?? EdgeInsets.all(AppPadding.pH12),
            decoration: BoxDecoration(
              color: widget.readonly
                  ? Theme.of(context).disabledColor.withValues(alpha: 0.12)
                  : widget.fillColor ??
                        Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: borderRadius,
              border: Border.all(
                color: state.hasError
                    ? AppColors.error
                    : (widget.isBordered
                          ? AppColors.border
                          : Colors.transparent),
                width: state.hasError ? 1.0 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(
                      value,
                      isLoading: effectiveIsLoading,
                      isFailer: effectiveIsFailer,
                    ),
                    overflow: TextOverflow.ellipsis,
                    style:
                        widget.style ??
                        (_isValueEmpty(value)
                            ? (widget.hintTextStyle ??
                                  context.textStyle.s12.regular.setColor(
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ))
                            : context.textStyle.s14.regular.setColor(
                                widget.readonly
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              )),
                  ),
                ),
                _buildSuffix(
                  context,
                  isLoading: effectiveIsLoading,
                  isFailer: effectiveIsFailer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Open sheet (dispatch to single- or multi-select)
  // ════════════════════════════════════════════════════════════════

  Future<void> _openSheet(FormFieldState<dynamic> state) async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    _confirmationPending = false;
    try {
      if (widget.isMultiSelect) {
        final result = await _showMultiSelectSheet(
          _multiSelectedNotifier.value,
        );
        if (result != null) {
          _multiSelectedNotifier.value = result;
          widget.onMultiChanged?.call(result);
          state
            ..didChange(result)
            ..validate();
        }
      } else {
        final result = await _showSingleSelectSheet(
          _singleSelectedNotifier.value,
        );
        if (result != null) {
          _singleSelectedNotifier.value = result;
          widget.onChanged?.call(result);
          state
            ..didChange(result)
            ..validate();
        }
      }
    } finally {
      _sheetOpen = false;
      _confirmationPending = false;
    }
  }

  void _closeSheetOnce<R>(BuildContext sheetContext, R result) {
    if (_confirmationPending) return;
    _confirmationPending = true;
    Navigator.pop<R>(sheetContext, result);
  }

  // ════════════════════════════════════════════════════════════════
  // Single-select sheet
  // ════════════════════════════════════════════════════════════════

  Future<T?> _showSingleSelectSheet(T? current) async {
    if (widget.readonly) return null;

    _searchController.clear();
    _singleSelectedNotifier.value = current;

    // ── Paginated path ────────────────────────────────────────────
    if (widget.paginatedCubit != null) {
      final cubit = widget.paginatedCubit!;
      _paginatedFilteredItemsNotifier.value = cubit.state.data.items;
      // Fetch is started before the sheet opens so the cubit is already
      // in loading state when the BlocConsumer first builds.
      cubit.fetchInitialData(filterKey: widget.paginationFilterKey);

      final scrollCtrl = ScrollController();
      _attachPaginationListener(scrollCtrl, cubit);
      try {
        return await showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: DropdownSheetContainer(
              height:
                  MediaQuery.of(sheetCtx).size.height *
                  DropdownLayout.sheetMaxHeightFactor,
              child: Column(
                children: [
                  const DropdownDragHandle(),
                  if (widget.showHeader)
                    DropdownSheetHeader(
                      title: widget.label ?? LocaleKeys.selectAnOption,
                      titleStyle: widget.labelTextStyle,
                    ),
                  Expanded(
                    child: _buildPaginatedSingleSelectSheet(
                      sheetCtx,
                      cubit,
                      scrollCtrl,
                    ),
                  ),
                  ValueListenableBuilder<T?>(
                    valueListenable: _singleSelectedNotifier,
                    builder: (_, selected, _) => DropdownConfirmButton(
                      label: LocaleKeys.confirm,
                      enabled: selected != null,
                      onPressed: () => _closeSheetOnce<T?>(
                        sheetCtx,
                        _singleSelectedNotifier.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } finally {
        scrollCtrl.dispose();
      }
    }

    // ── Static path ───────────────────────────────────────────────
    if (widget.isLoading || widget.isFailer) return null;
    _filteredItemsNotifier.value = widget.items;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: ValueListenableBuilder<List<T>>(
          valueListenable: _filteredItemsNotifier,
          builder: (_, filteredItems, _) => DropdownSheetContainer(
            height: _calculateSheetHeight(sheetCtx, filteredItems.length),
            child: Column(
              children: [
                const DropdownDragHandle(),
                if (widget.showHeader)
                  DropdownSheetHeader(
                    title: widget.label ?? LocaleKeys.selectAnOption,
                    titleStyle: widget.labelTextStyle,
                  ),
                if (widget.showSearchBox) _buildSearchBox(),
                Expanded(child: _buildSingleSelectList(filteredItems)),
                ValueListenableBuilder<T?>(
                  valueListenable: _singleSelectedNotifier,
                  builder: (_, selected, _) => DropdownConfirmButton(
                    label: LocaleKeys.confirm,
                    enabled: selected != null,
                    onPressed: () => _closeSheetOnce<T?>(
                      sheetCtx,
                      _singleSelectedNotifier.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Multi-select sheet
  // ════════════════════════════════════════════════════════════════

  Future<List<T>?> _showMultiSelectSheet(List<T> current) async {
    if (widget.readonly) return null;

    _searchController.clear();
    _multiSelectedNotifier.value = List<T>.from(current);

    // ── Paginated path ────────────────────────────────────────────
    if (widget.paginatedCubit != null) {
      final cubit = widget.paginatedCubit!;
      _paginatedFilteredItemsNotifier.value = cubit.state.data.items;
      cubit.fetchInitialData(filterKey: widget.paginationFilterKey);

      final scrollCtrl = ScrollController();
      _attachPaginationListener(scrollCtrl, cubit);
      try {
        return await showModalBottomSheet<List<T>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: DropdownSheetContainer(
              height:
                  MediaQuery.of(sheetCtx).size.height *
                  DropdownLayout.sheetMaxHeightFactor,
              child: Column(
                children: [
                  const DropdownDragHandle(),
                  if (widget.showHeader)
                    DropdownSheetHeader(
                      title: widget.label ?? LocaleKeys.selectAnOption,
                      titleStyle: widget.labelTextStyle,
                      trailing: ValueListenableBuilder<List<T>>(
                        valueListenable: _multiSelectedNotifier,
                        builder: (_, selected, _) => Text(
                          '${selected.length} ',
                          style: context.textStyle.s14.regular.setHintColor,
                        ),
                      ),
                    ),
                  if (widget.showCustomHeaderMessage &&
                      widget.customHeaderMessage != null)
                    _buildCustomHeaderMessage(),
                  Expanded(
                    child: _buildPaginatedMultiSelectSheet(
                      sheetCtx,
                      cubit,
                      scrollCtrl,
                    ),
                  ),
                  ValueListenableBuilder<List<T>>(
                    valueListenable: _multiSelectedNotifier,
                    builder: (_, selected, _) => DropdownConfirmButton(
                      label: '${LocaleKeys.confirm} (${selected.length})',
                      enabled: true,
                      onPressed: () => _closeSheetOnce<List<T>>(
                        sheetCtx,
                        List<T>.from(_multiSelectedNotifier.value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } finally {
        scrollCtrl.dispose();
      }
    }

    // ── Static path ───────────────────────────────────────────────
    if (widget.isLoading || widget.isFailer) return null;
    _filteredItemsNotifier.value = widget.items;

    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: ValueListenableBuilder<List<T>>(
          valueListenable: _filteredItemsNotifier,
          builder: (_, filteredItems, _) {
            final totalItems =
                filteredItems.length + (widget.showSelectAll ? 1 : 0);
            return DropdownSheetContainer(
              height: _calculateSheetHeight(sheetCtx, totalItems),
              child: Column(
                children: [
                  const DropdownDragHandle(),
                  if (widget.showHeader)
                    DropdownSheetHeader(
                      title: widget.label ?? LocaleKeys.selectAnOption,
                      titleStyle: widget.labelTextStyle,
                      trailing: ValueListenableBuilder<List<T>>(
                        valueListenable: _multiSelectedNotifier,
                        builder: (_, selected, _) => Text(
                          '${selected.length} ',
                          style: context.textStyle.s14.regular.setHintColor,
                        ),
                      ),
                    ),
                  if (widget.showCustomHeaderMessage &&
                      widget.customHeaderMessage != null)
                    _buildCustomHeaderMessage(),
                  if (widget.showSearchBox) _buildSearchBox(),
                  Expanded(child: _buildMultiSelectList(filteredItems)),
                  ValueListenableBuilder<List<T>>(
                    valueListenable: _multiSelectedNotifier,
                    builder: (_, selected, _) => DropdownConfirmButton(
                      label: '${LocaleKeys.confirm} (${selected.length})',
                      enabled: true,
                      onPressed: () => _closeSheetOnce<List<T>>(
                        sheetCtx,
                        List<T>.from(_multiSelectedNotifier.value),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Paginated sheet contents
  // ════════════════════════════════════════════════════════════════

  Widget _buildPaginatedSingleSelectSheet(
    BuildContext modalContext,
    PaginatedAsyncCubit<T> cubit,
    ScrollController scrollCtrl,
  ) {
    return BlocConsumer<PaginatedAsyncCubit<T>, PaginatedState<T>>(
      bloc: cubit,
      listenWhen: (_, curr) => curr.status.isSuccess,
      listener: (_, state) => _syncPaginatedFilter(state.data.items),
      builder: (_, state) {
        if (state.isFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isInitialError) {
          return _buildPaginatedError(cubit, state);
        }
        return Column(
          children: [
            if (widget.showSearchBox) _buildSearchBox(),
            Expanded(
              child: ValueListenableBuilder<List<T>>(
                valueListenable: _paginatedFilteredItemsNotifier,
                builder: (_, filtered, _) => _buildSingleSelectList(
                  filtered,
                  scrollController: scrollCtrl,
                  isLoadingMore: state.isLoadingMore,
                ),
              ),
            ),
            if (state.hasInlineError) _buildInlinePaginationRetry(cubit),
          ],
        );
      },
    );
  }

  Widget _buildPaginatedMultiSelectSheet(
    BuildContext modalContext,
    PaginatedAsyncCubit<T> cubit,
    ScrollController scrollCtrl,
  ) {
    return BlocConsumer<PaginatedAsyncCubit<T>, PaginatedState<T>>(
      bloc: cubit,
      listenWhen: (_, curr) => curr.status.isSuccess,
      listener: (_, state) => _syncPaginatedFilter(state.data.items),
      builder: (_, state) {
        if (state.isFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isInitialError) {
          return _buildPaginatedError(cubit, state);
        }
        return Column(
          children: [
            if (widget.showSearchBox) _buildSearchBox(),
            Expanded(
              child: ValueListenableBuilder<List<T>>(
                valueListenable: _paginatedFilteredItemsNotifier,
                builder: (_, filtered, _) => _buildMultiSelectList(
                  filtered,
                  scrollController: scrollCtrl,
                  isLoadingMore: state.isLoadingMore,
                ),
              ),
            ),
            if (state.hasInlineError) _buildInlinePaginationRetry(cubit),
          ],
        );
      },
    );
  }

  Widget _buildPaginatedError(
    PaginatedAsyncCubit<T> cubit,
    PaginatedState<T> state,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppPadding.pH16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 40.h),
            SizedBox(height: AppPadding.pH8),
            Text(
              state.failure?.userMessage ?? LocaleKeys.exceptionError,
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () =>
                  cubit.fetchInitialData(filterKey: widget.paginationFilterKey),
              child: Text(LocaleKeys.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePaginationRetry(PaginatedAsyncCubit<T> cubit) {
    return SafeArea(
      top: false,
      child: TextButton.icon(
        onPressed: cubit.loadMore,
        icon: const Icon(Icons.refresh),
        label: Text(LocaleKeys.retry),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Sheet sub-widgets (kept inline so they share `widget._*` access)
  // ════════════════════════════════════════════════════════════════

  Widget _buildSearchBox() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.pH16,
        vertical: AppPadding.pH8,
      ),
      child: DefaultTextField(
        title: LocaleKeys.search,
        suffixIcon: AppAssets.svg.baseSvg.search.svg(),
        controller: _searchController,
        inputType: TextInputType.text,
        action: TextInputAction.search,
        validator: (value) => Validators.noValidate(value ?? ''),
      ),
    );
  }

  Widget _buildCustomHeaderMessage() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppPadding.pH16,
        vertical: AppPadding.pH8,
      ),
      padding: EdgeInsets.all(AppPadding.pH12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
      child: Column(
        children: [
          Text(
            widget.hint ?? '',
            style: context.textStyle.s16.bold.setColor(
              Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            widget.customHeaderMessage!,
            style: context.textStyle.s12.regular.setColor(
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSelectList(
    List<T> items, {
    ScrollController? scrollController,
    bool isLoadingMore = false,
  }) {
    if (items.isEmpty && !isLoadingMore) return _buildEmptyState();
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.pH16,
        vertical: 10.h,
      ),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (_, i) {
        if (isLoadingMore && i == items.length) {
          return Padding(
            padding: EdgeInsets.all(AppPadding.pH12),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder<T?>(
          valueListenable: _singleSelectedNotifier,
          builder: (_, selected, _) {
            final isSelected =
                selected != null && _sameItem(items[i], selected);
            return DropdownItemTile(
              label: widget.itemAsString(items[i]),
              selected: isSelected,
              itemHeight: widget.itemHeight,
              onTap: () => _singleSelectedNotifier.value = items[i],
              trailing: DropdownRadio(selected: isSelected),
            );
          },
        );
      },
    );
  }

  Widget _buildMultiSelectList(
    List<T> items, {
    ScrollController? scrollController,
    bool isLoadingMore = false,
  }) {
    if (items.isEmpty &&
        _searchController.text.isEmpty &&
        !widget.showSelectAll &&
        !isLoadingMore) {
      return _buildEmptyState();
    }
    final extraCount = (widget.showSelectAll ? 1 : 0) + (isLoadingMore ? 1 : 0);
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.pH16,
        vertical: 10.h,
      ),
      itemCount: items.length + extraCount,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (_, i) {
        if (widget.showSelectAll && i == 0) {
          return _buildSelectAllTile(items);
        }
        final itemIndex = widget.showSelectAll ? i - 1 : i;
        if (isLoadingMore && itemIndex == items.length) {
          return Padding(
            padding: EdgeInsets.all(AppPadding.pH12),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (itemIndex >= items.length) return const SizedBox.shrink();
        return _buildMultiSelectItemTile(items[itemIndex]);
      },
    );
  }

  Widget _buildSelectAllTile(List<T> filteredItems) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: _multiSelectedNotifier,
      builder: (_, selected, _) {
        final isAllSelected =
            filteredItems.isNotEmpty &&
            filteredItems.every((item) => _containsItem(selected, item));

        return DropdownItemTile(
          label: widget.selectAllText ?? LocaleKeys.selectAll,
          selected: isAllSelected,
          itemHeight: widget.itemHeight,
          trailing: DropdownCheckbox(selected: isAllSelected),
          onTap: () {
            final next = List<T>.from(_multiSelectedNotifier.value);
            if (isAllSelected) {
              next.removeWhere(
                (item) =>
                    filteredItems.any((filtered) => _sameItem(item, filtered)),
              );
            } else {
              for (final item in filteredItems) {
                if (_containsItem(next, item)) continue;
                if (widget.maxSelectableItems == null ||
                    next.length < widget.maxSelectableItems!) {
                  next.add(item);
                }
              }
            }
            _multiSelectedNotifier.value = next;
          },
        );
      },
    );
  }

  Widget _buildMultiSelectItemTile(T item) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: _multiSelectedNotifier,
      builder: (_, selected, _) {
        final isSelected = _containsItem(selected, item);
        final canSelect =
            widget.maxSelectableItems == null ||
            selected.length < widget.maxSelectableItems! ||
            isSelected;
        return DropdownItemTile(
          label: widget.itemAsString(item),
          selected: isSelected,
          enabled: canSelect,
          itemHeight: widget.itemHeight,
          trailing: DropdownCheckbox(selected: isSelected),
          onTap: () {
            final next = List<T>.from(selected);
            if (isSelected) {
              next.removeWhere((value) => _sameItem(value, item));
            } else {
              next.add(item);
            }
            _multiSelectedNotifier.value = next;
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _searchController.text.isNotEmpty
            ? LocaleKeys.noResultFound
            : LocaleKeys.noOptionsFound,
        style: context.textStyle.s14.regular.setHintColor,
      ),
    );
  }
}

// `DropdownSheetContainer` moved to `widgets/dropdown_sheet_container.dart`.
