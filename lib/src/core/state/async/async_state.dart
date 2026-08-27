import 'package:equatable/equatable.dart';

import '../../network/error/failures.dart';

/// Sealed state used by every async screen (GET list, GET single, mutation…).
/// Exhaustive pattern matching means the UI cannot forget a branch.
sealed class AsyncState<T> extends Equatable {
  const AsyncState();

  @override
  List<Object?> get props => [];

  bool get isInitial => this is AsyncInitial<T>;
  bool get isLoading => this is AsyncLoading<T>;
  bool get isSuccess => this is AsyncSuccess<T>;
  bool get isFailure => this is AsyncFailure<T>;
}

final class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

final class AsyncLoading<T> extends AsyncState<T> {
  /// The last known data (e.g. while refreshing a populated list).
  final T? previous;
  const AsyncLoading({this.previous});

  @override
  List<Object?> get props => [previous];
}

final class AsyncSuccess<T> extends AsyncState<T> {
  final T data;
  const AsyncSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

final class AsyncFailure<T> extends AsyncState<T> {
  final Failure failure;

  /// The last known data so the screen can keep rendering it under an
  /// error banner.
  final T? previous;
  const AsyncFailure(this.failure, {this.previous});

  @override
  List<Object?> get props => [failure, previous];
}
