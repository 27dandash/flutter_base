import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/state/paginated/paginated.dart';
import 'package:flutter_base/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
);

/// Serves [perPage] items per page for [totalPages] pages.
class _PagedCubit extends PaginatedAsyncCubit<String> {
  _PagedCubit({this.perPage = 2, this.totalPages = 6});

  final int perPage;
  final int totalPages;
  final requestedPages = <int>[];

  @override
  Future<Either<Failure, PaginatedData<String>>> fetchPage(
    int page, {
    String? filterKey,
  }) async {
    requestedPages.add(page);
    return Right(
      PaginatedData(
        items: [for (var i = 0; i < perPage; i++) 'P$page-$i'],
        meta: PaginationMeta(
          totalItems: perPage * totalPages,
          countItems: perPage,
          perPage: perPage,
          totalPages: totalPages,
          currentPage: page,
        ),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(InkWell).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a first page too short for the sheet keeps loading pages', (
    tester,
  ) async {
    final cubit = _PagedCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          paginatedCubit: cubit,
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (_) {},
        ),
      ),
    );

    await _open(tester);

    expect(
      cubit.requestedPages.length,
      greaterThan(1),
      reason: 'two 56px rows cannot scroll in a 450px sheet',
    );
    expect(
      cubit.requestedPages,
      [1, 2, 3, 4, 5, 6].take(cubit.requestedPages.length),
    );
    expect(find.text('P1-0'), findsOneWidget);
  });

  testWidgets('loading stops once the list can scroll', (tester) async {
    final cubit = _PagedCubit(perPage: 12, totalPages: 9);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          paginatedCubit: cubit,
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (_) {},
        ),
      ),
    );

    await _open(tester);

    expect(cubit.requestedPages, [1], reason: '12 rows already overflow');
  });

  testWidgets('a short list is not auto-extended while searching', (
    tester,
  ) async {
    final cubit = _PagedCubit(perPage: 12, totalPages: 9);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          paginatedCubit: cubit,
          itemAsString: (item) => item,
          onChanged: (_) {},
        ),
      ),
    );
    await _open(tester);
    expect(cubit.requestedPages, [1]);

    await tester.enterText(find.byType(TextFormField), 'P1-3');
    await tester.pumpAndSettle();

    expect(find.text('P1-3'), findsWidgets);
    expect(cubit.requestedPages, [1], reason: 'search must not fetch pages');
  });

  testWidgets('confirming a paginated selection leaves no framework error', (
    tester,
  ) async {
    final cubit = _PagedCubit(perPage: 12, totalPages: 2);
    addTearDown(cubit.close);
    String? chosen;
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          paginatedCubit: cubit,
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (value) => chosen = value,
        ),
      ),
    );
    await _open(tester);

    await tester.tap(find.text('P1-1'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    // Step through the closing animation instead of settling at once: the
    // sheet is still on screen while its scroll controller is released.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    expect(chosen, 'P1-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a field removed while its sheet is open ignores the result', (
    tester,
  ) async {
    var changes = 0;
    final key = GlobalKey();
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          key: key,
          items: const ['A', 'B'],
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (_) => changes++,
        ),
      ),
    );
    await _open(tester);
    await tester.tap(find.text('B').last);
    await tester.pump();

    // The page behind the sheet is replaced: the dropdown is disposed.
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });
}
