part of '../imports/products_imports.dart';

/// View-level state that doesn't belong in a cubit:
///   - search text controller (lifecycle tied to the widget)
///   - selected status filter
///   - scroll controller
///
/// Pattern
///   - Create in `initState`.
///   - Always call `dispose()` from the screen's `dispose`.
///   - Expose state via `ValueNotifier`s so widgets can listen via
///     `ValueListenableBuilder` instead of rebuilding the whole screen.
class ProductsViewController {
  ProductsViewController({required this.onSearch});

  /// Called whenever the search term changes (already debounced).
  final ValueChanged<String> onSearch;

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<ProductStatus?> statusFilter = ValueNotifier(null);

  void setStatusFilter(ProductStatus? status) {
    statusFilter.value = status;
  }

  /// Opens the status-filter sheet and applies the picked value. Lives here
  /// (not in the screen) so the screen stays a pure compose-only widget.
  Future<void> openFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ProductStatus?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductsFilterSheet(current: statusFilter.value),
    );
    if (selected != null) setStatusFilter(selected);
  }

  void clearSearch() {
    searchController.clear();
    onSearch('');
  }

  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    statusFilter.dispose();
  }
}
