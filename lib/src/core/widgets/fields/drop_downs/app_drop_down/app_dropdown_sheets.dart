part of 'app_dropdown.dart';

extension _DropdownSheets<T> on _AppDropdownState<T> {
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
        // The field may have left the tree while its sheet was open (the page
        // was replaced, the session ended): its notifiers are disposed then.
        if (!mounted) return;
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
        if (!mounted) return;
        if (result != null) {
          _singleSelectedNotifier.value = result;
          widget.onChanged?.call(result);
          state
            ..didChange(result)
            ..validate();
        }
      }
    } finally {
      // Plain fields only: nothing to reset on a disposed State.
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
}
