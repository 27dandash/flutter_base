import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/extensions/base_state.dart';
import '../../network/error/failures.dart';
import 'paginated_data.dart';
import 'paginated_state.dart';

/// Base cubit for paginated lists.
///
/// Subclasses implement [fetchPage] — "given a page number (and optional
/// filter key), hit the API and return a [PaginatedData] with the items
/// and the meta". This class wires:
///   - first-page load → `BaseStatus.loading`
///   - subsequent pages → `BaseStatus.loadingMore` (list stays visible)
///   - pull-to-refresh → resets the page counter, preserves filter
///   - failure during load-more → keeps the items, marks state as error
///     so the UI can show an inline retry tile
///   - silent cancellation → ignores [CancelledFailure]
///   - filter key support → e.g. order status, category tab. Stored
///     across loadMore so we don't fetch the wrong slice mid-scroll.
///
/// Usage
///   ```dart
///   @injectable
///   class ProductsListCubit extends PaginatedAsyncCubit<ProductEntity> {
///     ProductsListCubit(this._repo);
///     final ProductsRepository _repo;
///
///     @override
///     Future<Either<Failure, PaginatedData<ProductEntity>>> fetchPage(
///       int page, {
///       String? filterKey,
///     }) {
///       return _repo.getProductsPaginated(page: page, status: filterKey);
///     }
///   }
///   ```
abstract class PaginatedAsyncCubit<T> extends Cubit<PaginatedState<T>> {
  PaginatedAsyncCubit() : super(PaginatedState<T>.initial());

  String? _filterKey;
  bool _isFetching = false;
  int _operation = 0;

  // ── Read-only sugar ───────────────────────────────────────────────

  String? get filterKey => _filterKey;
  int get currentPage => state.data.meta.currentPage;
  bool get hasMore => !state.data.meta.isLastPage;
  bool get canLoadMore =>
      hasMore && !state.isLoadingMore && !state.isFirstLoad && !_isFetching;

  // ── Subclass contract ─────────────────────────────────────────────

  /// Fetch a single page. Must return the items for that page plus the
  /// pagination meta so the cubit knows whether to allow [loadMore].
  Future<Either<Failure, PaginatedData<T>>> fetchPage(
    int page, {
    String? filterKey,
  });

  // ── Public API ────────────────────────────────────────────────────

  /// Initial fetch or full reset.
  Future<void> fetchInitialData({String? filterKey}) async {
    if (isClosed) return;
    final operation = ++_operation;
    _isFetching = true;
    _filterKey = filterKey;

    emit(
      state.copyWith(
        status: BaseStatus.loading,
        data: PaginatedData<T>.initial(),
        clearFailure: true,
      ),
    );

    late final Either<Failure, PaginatedData<T>> result;
    try {
      result = await fetchPage(1, filterKey: _filterKey);
    } catch (error) {
      result = Left(
        UnknownFailure(technical: 'Unexpected ${error.runtimeType}'),
      );
    }
    if (isClosed || operation != _operation) return;
    _isFetching = false;

    result.fold(
      (failure) {
        if (failure is CancelledFailure) {
          emit(
            state.copyWith(
              status: state.data.items.isEmpty
                  ? BaseStatus.initial
                  : BaseStatus.success,
              clearFailure: true,
            ),
          );
          return;
        }
        emit(state.copyWith(status: BaseStatus.error, failure: failure));
      },
      (page) => emit(PaginatedState<T>(data: page, status: BaseStatus.success)),
    );
  }

  /// Append the next page. No-op when:
  ///   - the API said there are no more pages,
  ///   - or another fetch is already in flight.
  Future<void> loadMore() async {
    if (!canLoadMore) return;
    if (isClosed) return;
    final operation = ++_operation;
    _isFetching = true;

    emit(state.copyWith(status: BaseStatus.loadingMore, clearFailure: true));

    final nextPage = state.data.meta.currentPage + 1;
    late final Either<Failure, PaginatedData<T>> result;
    try {
      result = await fetchPage(nextPage, filterKey: _filterKey);
    } catch (error) {
      result = Left(
        UnknownFailure(technical: 'Unexpected ${error.runtimeType}'),
      );
    }
    if (isClosed || operation != _operation) return;
    _isFetching = false;

    result.fold(
      (failure) {
        if (failure is CancelledFailure) {
          emit(state.copyWith(status: BaseStatus.success));
          return;
        }
        // Keep the list visible — the UI shows a footer error tile so the
        // user can retry without losing scroll position.
        emit(state.copyWith(status: BaseStatus.error, failure: failure));
      },
      (page) => emit(
        state.copyWith(
          data: state.data.addItems(page.items, page.meta),
          status: BaseStatus.success,
        ),
      ),
    );
  }

  /// Pull-to-refresh — reload from page 1, preserving the filter key.
  Future<void> refresh() => fetchInitialData(filterKey: _filterKey);

  // ── Local list mutations (optimistic flows) ───────────────────────

  void insertLocal(T item, {int at = 0}) {
    if (isClosed) return;
    _operation++;
    _isFetching = false;
    final items = [...state.data.items]..insert(at, item);
    emit(state.copyWith(data: state.data.copyWith(items: items)));
  }

  void updateLocal(bool Function(T) where, T Function(T) update) {
    if (isClosed) return;
    _operation++;
    _isFetching = false;
    final items = state.data.items
        .map((e) => where(e) ? update(e) : e)
        .toList();
    emit(state.copyWith(data: state.data.copyWith(items: items)));
  }

  void removeLocal(bool Function(T) where) {
    if (isClosed) return;
    _operation++;
    _isFetching = false;
    final items = state.data.items.where((e) => !where(e)).toList();
    emit(state.copyWith(data: state.data.copyWith(items: items)));
  }
}
