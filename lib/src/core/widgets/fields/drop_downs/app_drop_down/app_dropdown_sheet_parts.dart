part of 'app_dropdown.dart';

extension _DropdownSheetParts<T> on _AppDropdownState<T> {
  // ════════════════════════════════════════════════════════════════
  // Paginated sheet contents
  // ════════════════════════════════════════════════════════════════

  Widget _buildPaginatedSingleSelectSheet(
    BuildContext modalContext,
    PaginatedAsyncCubit<T> cubit,
    ScrollController scrollCtrl,
  ) {
    return BlocBuilder<PaginatedAsyncCubit<T>, PaginatedState<T>>(
      bloc: cubit,
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
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (_, _, _) {
                  _fillShortList(scrollCtrl, cubit, state);
                  return _buildSingleSelectList(
                    _filterLoaded(state.data.items),
                    scrollController: scrollCtrl,
                    isLoadingMore: state.isLoadingMore,
                  );
                },
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
    return BlocBuilder<PaginatedAsyncCubit<T>, PaginatedState<T>>(
      bloc: cubit,
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
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (_, _, _) {
                  _fillShortList(scrollCtrl, cubit, state);
                  return _buildMultiSelectList(
                    _filterLoaded(state.data.items),
                    scrollController: scrollCtrl,
                    isLoadingMore: state.isLoadingMore,
                  );
                },
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
