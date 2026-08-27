import 'package:equatable/equatable.dart';

import 'pagination_meta.dart';

/// One page of items + the meta the API returned with it.
///
/// Used as the success payload of a paginated repository call:
/// `Future<Either<Failure, PaginatedData<T>>>`. The cubit accumulates
/// pages via [addItems] as the user scrolls.
class PaginatedData<T> extends Equatable {
  final List<T> items;
  final PaginationMeta meta;

  const PaginatedData({required this.items, required this.meta});

  /// Empty placeholder shown before the first fetch returns. The meta is
  /// `currentPage: 1, totalPages: 1` so `isLastPage` is `true` and the
  /// list widget doesn't prematurely call `loadMore`.
  factory PaginatedData.initial() {
    return PaginatedData<T>(
      items: const [],
      meta: const PaginationMeta.empty(),
    );
  }

  PaginatedData<T> copyWith({List<T>? items, PaginationMeta? meta}) {
    return PaginatedData<T>(
      items: items ?? this.items,
      meta: meta ?? this.meta,
    );
  }

  /// Append [newItems] (typically the next page) and replace [meta] with
  /// the latest server response. Returns a new instance — never mutates.
  PaginatedData<T> addItems(List<T> newItems, PaginationMeta newMeta) {
    return PaginatedData<T>(items: [...items, ...newItems], meta: newMeta);
  }

  @override
  List<Object?> get props => [items, meta];
}
