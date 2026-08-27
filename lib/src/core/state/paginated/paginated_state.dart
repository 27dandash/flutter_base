import 'package:equatable/equatable.dart';

import '../../shared/extensions/base_state.dart';
import '../../network/error/failures.dart';
import 'paginated_data.dart';

/// State emitted by [PaginatedAsyncCubit].
///
/// Uses [BaseStatus] (initial/loading/loadingMore/success/error) so a
/// first-page load and a load-more can be distinguished in the UI — the
/// first shows a skeleton, the second shows a footer spinner without
/// dropping the list the user is already reading.
class PaginatedState<T> extends Equatable {
  final PaginatedData<T> data;
  final BaseStatus status;
  final Failure? failure;

  const PaginatedState({
    required this.data,
    this.status = BaseStatus.initial,
    this.failure,
  });

  factory PaginatedState.initial() {
    return PaginatedState<T>(data: PaginatedData<T>.initial());
  }

  // ── Convenience selectors used by widgets ─────────────────────────

  /// First fetch on a fresh screen — show the full-screen skeleton.
  bool get isFirstLoad => status.isLoading && data.items.isEmpty;

  /// Pagination tail loader — show a spinner under the list.
  bool get isLoadingMore => status.isLoadingMore;

  /// Error AND we never managed to load anything → full-screen error.
  bool get isInitialError => status.isError && data.items.isEmpty;

  /// Error AFTER we already have items → inline footer/snackbar.
  bool get hasInlineError => status.isError && data.items.isNotEmpty;

  PaginatedState<T> copyWith({
    PaginatedData<T>? data,
    BaseStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return PaginatedState<T>(
      data: data ?? this.data,
      status: status ?? this.status,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [data, status, failure];
}
