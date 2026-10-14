import 'dart:async';

import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/shared/extensions/base_state.dart';
import 'package:flutter_base/src/core/state/paginated/paginated.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestPaginationCubit extends PaginatedAsyncCubit<int> {
  final List<
    Future<Either<Failure, PaginatedData<int>>> Function(
      int page,
      String? filterKey,
    )
  >
  responses = [];
  final calls = <(int, String?)>[];

  @override
  Future<Either<Failure, PaginatedData<int>>> fetchPage(
    int page, {
    String? filterKey,
  }) {
    calls.add((page, filterKey));
    return responses.removeAt(0)(page, filterKey);
  }
}

PaginatedData<int> _page(int page, List<int> items, {int totalPages = 2}) {
  return PaginatedData(
    items: items,
    meta: PaginationMeta(
      totalItems: items.length * totalPages,
      countItems: items.length,
      perPage: items.length,
      totalPages: totalPages,
      currentPage: page,
    ),
  );
}

void main() {
  group('PaginatedAsyncCubit', () {
    test('loads the first page and forwards the filter', () async {
      final cubit = _TestPaginationCubit()
        ..responses.add((page, _) async => Right(_page(page, [1, 2])));

      await cubit.fetchInitialData(filterKey: 'active');

      expect(cubit.calls, [(1, 'active')]);
      expect(cubit.state.status, BaseStatus.success);
      expect(cubit.state.data.items, [1, 2]);
      await cubit.close();
    });

    test(
      'appends a page and prevents duplicate concurrent load more',
      () async {
        final pending = Completer<Either<Failure, PaginatedData<int>>>();
        final cubit = _TestPaginationCubit()
          ..responses.add((page, _) async => Right(_page(page, [1])))
          ..responses.add((_, _) => pending.future);
        await cubit.fetchInitialData();

        final first = cubit.loadMore();
        final duplicate = cubit.loadMore();
        expect(cubit.calls, [(1, null), (2, null)]);
        pending.complete(Right(_page(2, [2])));
        await Future.wait([first, duplicate]);

        expect(cubit.state.data.items, [1, 2]);
        expect(cubit.hasMore, isFalse);
        await cubit.close();
      },
    );

    test('load-more failure retains items and supports retry', () async {
      final cubit = _TestPaginationCubit()
        ..responses.add((page, _) async => Right(_page(page, [1])))
        ..responses.add((_, _) async => const Left(NetworkFailure()))
        ..responses.add((page, _) async => Right(_page(page, [2])));
      await cubit.fetchInitialData();

      await cubit.loadMore();
      expect(cubit.state.hasInlineError, isTrue);
      expect(cubit.state.data.items, [1]);
      await cubit.loadMore();
      expect(cubit.state.data.items, [1, 2]);
      await cubit.close();
    });

    test(
      'unexpected throw becomes typed error and does not lock retries',
      () async {
        final cubit = _TestPaginationCubit()
          ..responses.add((_, _) async => throw StateError('private payload'))
          ..responses.add((page, _) async => Right(_page(page, [1])));

        await cubit.fetchInitialData();
        expect(cubit.state.failure, isA<UnknownFailure>());
        expect(cubit.state.failure?.technical, 'Unexpected StateError');
        await cubit.fetchInitialData();
        expect(cubit.state.data.items, [1]);
        await cubit.close();
      },
    );

    test('a newer filtered request supersedes an older response', () async {
      final old = Completer<Either<Failure, PaginatedData<int>>>();
      final cubit = _TestPaginationCubit()
        ..responses.add((_, _) => old.future)
        ..responses.add((page, _) async => Right(_page(page, [2])));

      final oldRun = cubit.fetchInitialData(filterKey: 'old');
      await cubit.fetchInitialData(filterKey: 'new');
      old.complete(Right(_page(1, [1])));
      await oldRun;

      expect(cubit.filterKey, 'new');
      expect(cubit.state.data.items, [2]);
      await cubit.close();
    });

    test('cancellation restores a stable non-loading state', () async {
      final cubit = _TestPaginationCubit()
        ..responses.add((_, _) async => const Left(CancelledFailure()));

      await cubit.fetchInitialData();

      expect(cubit.state.status, BaseStatus.initial);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('completion after disposal is ignored', () async {
      final pending = Completer<Either<Failure, PaginatedData<int>>>();
      final cubit = _TestPaginationCubit()
        ..responses.add((_, _) => pending.future);
      final run = cubit.fetchInitialData();
      await cubit.close();
      pending.complete(Right(_page(1, [1])));
      await run;
      expect(cubit.isClosed, isTrue);
    });

    group('local mutations while a fetch is in flight', () {
      test(
        'removeLocal during load-more does not leave the footer loading',
        () async {
          final pending = Completer<Either<Failure, PaginatedData<int>>>();
          final cubit = _TestPaginationCubit()
            ..responses.add((page, _) async => Right(_page(page, [1, 2])))
            ..responses.add((_, _) => pending.future);
          await cubit.fetchInitialData();

          final loadMore = cubit.loadMore();
          expect(cubit.state.status, BaseStatus.loadingMore);
          cubit.removeLocal((item) => item == 1);
          pending.complete(Right(_page(2, [3, 4])));
          await loadMore;

          expect(cubit.state.status, BaseStatus.success);
          expect(cubit.state.data.items, [2]);
          await cubit.close();
        },
      );

      test('insertLocal during the first load settles to success', () async {
        final pending = Completer<Either<Failure, PaginatedData<int>>>();
        final cubit = _TestPaginationCubit()
          ..responses.add((_, _) => pending.future);

        final load = cubit.fetchInitialData();
        cubit.insertLocal(7);
        pending.complete(Right(_page(1, [1, 2])));
        await load;

        expect(cubit.state.status, BaseStatus.success);
        expect(cubit.state.data.items, [7]);
        await cubit.close();
      });

      test('removeLocal on an empty list does not keep the skeleton', () async {
        final pending = Completer<Either<Failure, PaginatedData<int>>>();
        final cubit = _TestPaginationCubit()
          ..responses.add((_, _) => pending.future);

        final load = cubit.fetchInitialData();
        cubit.removeLocal((_) => true);
        pending.complete(Right(_page(1, [1])));
        await load;

        expect(cubit.state.status, BaseStatus.success);
        expect(cubit.state.isFirstLoad, isFalse);
        await cubit.close();
      });

      test('pagination works again after a local mutation', () async {
        final pending = Completer<Either<Failure, PaginatedData<int>>>();
        final cubit = _TestPaginationCubit()
          ..responses.add((page, _) async => Right(_page(page, [1, 2])))
          ..responses.add((_, _) => pending.future)
          ..responses.add((page, _) async => Right(_page(page, [5, 6])));
        await cubit.fetchInitialData();

        final stale = cubit.loadMore();
        cubit.updateLocal((item) => item == 2, (item) => 20);
        pending.complete(Right(_page(2, [3, 4])));
        await stale;
        expect(cubit.canLoadMore, isTrue);

        await cubit.loadMore();
        expect(cubit.state.data.items, [1, 20, 5, 6]);
        await cubit.close();
      });

      test('an error status is preserved by a local mutation', () async {
        final cubit = _TestPaginationCubit()
          ..responses.add((page, _) async => Right(_page(page, [1, 2])))
          ..responses.add((_, _) async => const Left(NetworkFailure()));
        await cubit.fetchInitialData();
        await cubit.loadMore();
        expect(cubit.state.status, BaseStatus.error);

        cubit.insertLocal(9);

        expect(cubit.state.status, BaseStatus.error);
        expect(cubit.state.data.items.first, 9);
        await cubit.close();
      });
    });
  });
}
