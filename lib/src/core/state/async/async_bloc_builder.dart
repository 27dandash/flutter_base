import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../network/error/failures.dart';
import '../../widgets/handling_views/app_error_handler.dart';
import 'async_cubit.dart';
import 'async_state.dart';

/// Renders an [AsyncCubit] state with one builder per branch.
/// Defaults: a centered spinner on loading and an [AppErrorHandler]
/// on failure.
class AsyncBlocBuilder<C extends AsyncCubit<T>, T> extends StatelessWidget {
  const AsyncBlocBuilder({
    super.key,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.initialBuilder,
    this.onRetry,
  });

  final Widget Function(BuildContext, T data) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Failure)? errorBuilder;
  final Widget Function(BuildContext)? initialBuilder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, AsyncState<T>>(
      builder: (context, state) => switch (state) {
        AsyncInitial<T>() =>
          initialBuilder?.call(context) ?? const SizedBox.shrink(),
        AsyncLoading<T>(:final previous) =>
          previous != null
              ? builder(context, previous)
              : loadingBuilder?.call(context) ??
                    const Center(child: CircularProgressIndicator()),
        AsyncSuccess<T>(:final data) => builder(context, data),
        AsyncFailure<T>(:final failure, :final previous) =>
          previous != null
              ? builder(context, previous)
              : errorBuilder?.call(context, failure) ??
                    AppErrorHandler(failure: failure, onRetry: onRetry),
      },
    );
  }
}
