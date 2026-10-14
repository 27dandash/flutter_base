import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../shared/extensions/base_state.dart';
import '../../widgets/handling_views/app_error_handler.dart';
import 'paginated_async_cubit.dart';
import 'paginated_list_config.dart';
import 'paginated_state.dart';

/// Production-grade paginated list widget.
///
/// One widget, three view types (list / separated list / grid), with
/// built-in pull-to-refresh, infinite scroll, skeleton loading, and
/// error states. Pair it with any [PaginatedAsyncCubit] subclass.
///
/// Example
///   ```dart
///   PaginatedListWidget<ProductsListCubit, ProductEntity>(
///     itemBuilder: (_, product, i) => ProductCard(product: product),
///     skeletonBuilder: (_) => const ProductCardSkeleton(),
///     emptyWidget: const EmptyWidget(title: '...', desc: '...'),
///     config: const PaginatedListConfig(
///       padding: EdgeInsets.all(12),
///       useSeparator: true,
///       separator: SizedBox(height: 8),
///     ),
///   )
///   ```
class PaginatedListWidget<C extends PaginatedAsyncCubit<T>, T>
    extends StatefulWidget {
  /// Build a single list item — receives the data, the index, and the
  /// build context.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// All layout knobs (view type, padding, refresh control, etc.).
  final PaginatedListConfig config;

  /// Builder for one skeleton row — repeated [skeletonItemCount] times
  /// during the initial load. When null, a centred [CircularProgressIndicator]
  /// is shown instead.
  final Widget Function(BuildContext context)? skeletonBuilder;

  /// Override for the full-screen error widget. Falls back to
  /// [AppErrorHandler] with a retry button wired to `cubit.refresh`.
  final Widget Function(BuildContext context, Object? failure)? errorBuilder;

  /// Override for the empty-state widget. Falls back to a centred text.
  final Widget? emptyWidget;

  /// Override for the footer spinner shown while loading more.
  final Widget? loadMoreIndicator;

  /// Fraction of `maxScrollExtent` that triggers `loadMore`. Default 0.8
  /// (i.e. start fetching when the user is 20% from the bottom).
  final double loadMoreThreshold;

  /// How many skeleton rows to render during the initial load.
  final int skeletonItemCount;

  const PaginatedListWidget({
    super.key,
    required this.itemBuilder,
    this.config = const PaginatedListConfig(),
    this.skeletonBuilder,
    this.errorBuilder,
    this.emptyWidget,
    this.loadMoreIndicator,
    this.loadMoreThreshold = 0.8,
    this.skeletonItemCount = 6,
  });

  @override
  State<PaginatedListWidget<C, T>> createState() =>
      _PaginatedListWidgetState<C, T>();
}

class _PaginatedListWidgetState<C extends PaginatedAsyncCubit<T>, T>
    extends State<PaginatedListWidget<C, T>> {
  late final C _cubit;
  late final ScrollController _scrollController;
  late final PageStorageKey<String> _pageStorageKey;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<C>();
    if (widget.config.controller != null) {
      _scrollController = widget.config.controller!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _scrollController.addListener(_onScroll);
    _pageStorageKey = PageStorageKey<String>('paginated_list_${C.toString()}');
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.loadMoreThreshold;
    if (currentScroll >= threshold && _cubit.canLoadMore) {
      _cubit.loadMore();
    }
  }

  Future<void> _onRefresh() => _cubit.refresh();

  /// Scrolling is the only thing that triggers [_onScroll]. When a page is too
  /// short to scroll (a tall screen, a small page size) there are no scroll
  /// events, so the remaining pages would never load. After the frame, keep
  /// loading while the content does not yet fill the viewport.
  ///
  /// Only a settled `success` state qualifies: after a failed load-more the
  /// user retries explicitly from the inline error tile, otherwise this would
  /// retry in a loop.
  void _scheduleViewportFill(PaginatedState<T> state) {
    if (!state.status.isSuccess || !_cubit.canLoadMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent > 0) return;
      if (_cubit.state.status.isSuccess && _cubit.canLoadMore) {
        _cubit.loadMore();
      }
    });
  }

  // ════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, PaginatedState<T>>(
      builder: (context, state) {
        // First-page loading → full skeleton if available, else spinner.
        if (state.isFirstLoad) {
          return widget.skeletonBuilder != null
              ? Skeletonizer(enabled: true, child: _buildSkeletonView())
              : const Center(child: CircularProgressIndicator());
        }

        // Full-screen error (no items ever loaded).
        if (state.isInitialError) {
          final fallback = AppErrorHandler(
            failure: state.failure!,
            onRetry: _onRefresh,
          );
          return _wrapRefresh(
            widget.errorBuilder?.call(context, state.failure) ?? fallback,
            needsScrollable: true,
          );
        }

        // Empty success.
        if (state.data.items.isEmpty) {
          return _wrapRefresh(
            widget.emptyWidget ?? Center(child: Text(LocaleKeys.listEmpty)),
            needsScrollable: true,
          );
        }

        // Populated list.
        _scheduleViewportFill(state);
        return _wrapRefresh(_buildListView(state));
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // List builders
  // ════════════════════════════════════════════════════════════════

  Widget _buildListView(PaginatedState<T> state) {
    final isLoadingMore = state.isLoadingMore;
    final itemCount =
        state.data.items.length +
        (isLoadingMore ? 1 : 0) +
        (state.hasInlineError ? 1 : 0);

    switch (widget.config.viewType) {
      case PaginatedListViewType.grid:
        return _buildGridView(state, itemCount);
      case PaginatedListViewType.list:
        return widget.config.useSeparator
            ? _buildSeparatedListView(state, itemCount)
            : _buildRegularListView(state, itemCount);
    }
  }

  Widget _buildRegularListView(PaginatedState<T> state, int itemCount) {
    return ListView.builder(
      key: _pageStorageKey,
      controller: _scrollController,
      scrollDirection: widget.config.scrollDirection,
      physics: _scrollPhysics,
      padding: widget.config.padding,
      shrinkWrap: widget.config.shrinkWrap,
      reverse: widget.config.reverse,
      primary: widget.config.primary,
      itemCount: itemCount,
      itemBuilder: (ctx, i) => _row(ctx, state, i),
    );
  }

  Widget _buildSeparatedListView(PaginatedState<T> state, int itemCount) {
    return ListView.separated(
      key: _pageStorageKey,
      controller: _scrollController,
      scrollDirection: widget.config.scrollDirection,
      physics: _scrollPhysics,
      padding: widget.config.padding,
      shrinkWrap: widget.config.shrinkWrap,
      reverse: widget.config.reverse,
      primary: widget.config.primary,
      itemCount: itemCount,
      separatorBuilder: (_, i) {
        // No separator before the footer.
        if (i >= state.data.items.length - 1) return const SizedBox.shrink();
        return widget.config.separator ?? const Divider();
      },
      itemBuilder: (ctx, i) => _row(ctx, state, i),
    );
  }

  Widget _buildGridView(PaginatedState<T> state, int itemCount) {
    return GridView.builder(
      key: _pageStorageKey,
      controller: _scrollController,
      scrollDirection: widget.config.scrollDirection,
      physics: _scrollPhysics,
      padding: widget.config.padding,
      shrinkWrap: widget.config.shrinkWrap,
      reverse: widget.config.reverse,
      primary: widget.config.primary,
      gridDelegate:
          widget.config.gridDelegate ?? PaginatedListConfig.defaultGridDelegate,
      itemCount: itemCount,
      itemBuilder: (ctx, i) => _row(ctx, state, i),
    );
  }

  Widget _row(BuildContext context, PaginatedState<T> state, int i) {
    if (i >= state.data.items.length) {
      // Footer slot — either spinner or inline-error tile.
      if (state.isLoadingMore) return _buildLoadMoreIndicator();
      if (state.hasInlineError) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: AppErrorHandler(
            failure: state.failure!,
            onRetry: _cubit.loadMore,
            compact: true,
          ),
        );
      }
      return const SizedBox.shrink();
    }
    final item = state.data.items[i];
    final tile = widget.itemBuilder(context, item, i);
    return widget.config.itemMargin != null
        ? Padding(padding: widget.config.itemMargin!, child: tile)
        : tile;
  }

  // ════════════════════════════════════════════════════════════════
  // Skeleton + refresh + helpers
  // ════════════════════════════════════════════════════════════════

  Widget _buildSkeletonView() {
    if (widget.config.viewType == PaginatedListViewType.grid) {
      return GridView.builder(
        scrollDirection: widget.config.scrollDirection,
        physics: const NeverScrollableScrollPhysics(),
        padding: widget.config.padding,
        shrinkWrap: widget.config.shrinkWrap,
        reverse: widget.config.reverse,
        primary: widget.config.primary,
        gridDelegate:
            widget.config.gridDelegate ??
            PaginatedListConfig.defaultGridDelegate,
        itemCount: widget.skeletonItemCount,
        itemBuilder: (ctx, _) => widget.skeletonBuilder!(ctx),
      );
    }
    if (widget.config.useSeparator) {
      return ListView.separated(
        scrollDirection: widget.config.scrollDirection,
        physics: const NeverScrollableScrollPhysics(),
        padding: widget.config.padding,
        shrinkWrap: widget.config.shrinkWrap,
        reverse: widget.config.reverse,
        primary: widget.config.primary,
        itemCount: widget.skeletonItemCount,
        separatorBuilder: (_, _) => widget.config.separator ?? const Divider(),
        itemBuilder: (ctx, _) => widget.skeletonBuilder!(ctx),
      );
    }
    return ListView.builder(
      scrollDirection: widget.config.scrollDirection,
      physics: const NeverScrollableScrollPhysics(),
      padding: widget.config.padding,
      shrinkWrap: widget.config.shrinkWrap,
      reverse: widget.config.reverse,
      primary: widget.config.primary,
      itemCount: widget.skeletonItemCount,
      itemBuilder: (ctx, _) => widget.skeletonBuilder!(ctx),
    );
  }

  Widget _wrapRefresh(Widget child, {bool needsScrollable = false}) {
    if (!widget.config.enableRefresh) return child;

    // Non-scrollable bodies (empty/error) need a scrollable parent for
    // the pull-to-refresh gesture to register.
    final scrollableChild = needsScrollable
        ? CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
          )
        : child;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: widget.config.refreshIndicatorColor,
      backgroundColor: widget.config.refreshIndicatorBackgroundColor,
      displacement: widget.config.refreshIndicatorDisplacement,
      child: scrollableChild,
    );
  }

  Widget _buildLoadMoreIndicator() {
    return widget.loadMoreIndicator ??
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
  }

  ScrollPhysics? get _scrollPhysics {
    // Force AlwaysScrollableScrollPhysics when refresh is on so the
    // pull-to-refresh gesture works even for short lists.
    if (widget.config.enableRefresh) {
      return const AlwaysScrollableScrollPhysics();
    }
    return widget.config.physics;
  }
}
