import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/shared/extensions/base_state.dart';
import 'package:flutter_base/src/core/state/paginated/paginated.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'localized_widget_harness.dart';

final class _ListCubit extends PaginatedAsyncCubit<int> {
  int calls = 0;
  Either<Failure, PaginatedData<int>> response = Right(_data([], page: 1));

  void seed(PaginatedState<int> value) => emit(value);

  @override
  Future<Either<Failure, PaginatedData<int>>> fetchPage(
    int page, {
    String? filterKey,
  }) async {
    calls++;
    return response;
  }
}

PaginatedData<int> _data(
  List<int> items, {
  required int page,
  int totalPages = 2,
}) => PaginatedData(
  items: items,
  meta: PaginationMeta(
    totalItems: 100,
    countItems: items.length,
    perPage: items.length,
    totalPages: totalPages,
    currentPage: page,
  ),
);

Widget _host(_ListCubit cubit) => MaterialApp(
  home: BlocProvider<_ListCubit>.value(
    value: cubit,
    child: Scaffold(
      body: PaginatedListWidget<_ListCubit, int>(
        itemBuilder: (_, item, _) =>
            SizedBox(height: 60, child: Text('item:$item')),
        emptyWidget: const Text('empty'),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders loading, empty and refresh behavior', (tester) async {
    final cubit = _ListCubit();
    addTearDown(cubit.close);
    cubit.seed(
      PaginatedState<int>(
        data: PaginatedData<int>.initial(),
        status: BaseStatus.loading,
      ),
    );
    await tester.pumpWidget(_host(cubit));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    cubit.seed(
      PaginatedState<int>(
        data: PaginatedData<int>.initial(),
        status: BaseStatus.success,
      ),
    );
    await tester.pump();
    expect(find.text('empty'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(cubit.calls, 1);
  });

  testWidgets('scroll loads the next page only once', (tester) async {
    final cubit = _ListCubit();
    addTearDown(cubit.close);
    cubit.seed(
      PaginatedState<int>(
        data: _data(List.generate(30, (index) => index), page: 1),
        status: BaseStatus.success,
      ),
    );
    cubit.response = Right(_data([30, 31], page: 2, totalPages: 2));
    await tester.pumpWidget(_host(cubit));
    await tester.fling(find.byType(ListView), const Offset(0, -3000), 3000);
    await tester.pumpAndSettle();
    expect(cubit.calls, 1);
    expect(find.text('item:30'), findsOneWidget);
  });

  testWidgets('inline failure keeps content and retries in place', (
    tester,
  ) async {
    final cubit = _ListCubit();
    addTearDown(cubit.close);
    cubit.seed(
      PaginatedState<int>(
        data: _data([1], page: 1),
        status: BaseStatus.error,
        failure: const NetworkFailure(technical: 'private endpoint'),
      ),
    );
    cubit.response = Right(_data([2], page: 2, totalPages: 2));
    await tester.pumpWidget(_host(cubit));
    expect(find.text('item:1'), findsOneWidget);
    expect(find.textContaining('private endpoint'), findsNothing);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(cubit.calls, 1);
    expect(find.text('item:2'), findsOneWidget);
  });

  testWidgets('default empty state uses dedicated localized copy', (
    tester,
  ) async {
    await ensureLocalizedTests();
    final cubit = _ListCubit();
    addTearDown(cubit.close);
    cubit.seed(
      PaginatedState<int>(
        data: PaginatedData<int>.initial(),
        status: BaseStatus.success,
      ),
    );
    await pumpLocalized(
      tester,
      BlocProvider<_ListCubit>.value(
        value: cubit,
        child: Scaffold(
          body: PaginatedListWidget<_ListCubit, int>(
            itemBuilder: (_, item, _) => Text('item:$item'),
          ),
        ),
      ),
      locale: const Locale('en'),
    );
    expect(find.text('No items to display'), findsOneWidget);
    expect(find.text('No data found'), findsNothing);
  });
}
