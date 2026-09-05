import 'dart:ui' as ui;

import 'package:flutter_base/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/state/paginated/paginated.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'localized_widget_harness.dart';

Widget _host(Widget child, {ThemeData? theme}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
    ),
  );
}

class _DropdownCubit extends PaginatedAsyncCubit<String> {
  int calls = 0;
  bool fail = true;

  @override
  Future<Either<Failure, PaginatedData<String>>> fetchPage(
    int page, {
    String? filterKey,
  }) async {
    calls++;
    if (fail) return const Left(NetworkFailure());
    return const Right(
      PaginatedData(
        items: ['Cairo'],
        meta: PaginationMeta(
          totalItems: 1,
          countItems: 1,
          perPage: 20,
          totalPages: 1,
          currentPage: 1,
        ),
      ),
    );
  }
}

void main() {
  testWidgets('dismissal never applies a pending single selection', (
    tester,
  ) async {
    String? selected = 'A';
    var callbacks = 0;
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const ['A', 'B'],
          value: selected,
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (value) {
            callbacks++;
            selected = value;
          },
        ),
      ),
    );

    await tester.tap(find.text('A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(selected, 'A');
    expect(callbacks, 0);
  });

  testWidgets('Confirm applies exactly one pending selection', (tester) async {
    String? selected = 'A';
    var callbacks = 0;
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const ['A', 'B'],
          value: selected,
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (value) {
            callbacks++;
            selected = value;
          },
        ),
      ),
    );

    await tester.tap(find.text('A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(selected, 'B');
    expect(callbacks, 1);
  });

  testWidgets('rapid trigger taps open only one modal sheet', (tester) async {
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const ['A', 'B'],
          value: 'A',
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (_) {},
        ),
      ),
    );

    final trigger = find.text('A').first;
    await tester.tap(trigger);
    await tester.tap(trigger, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('error state calls retry instead of opening a selector', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const [],
          itemAsString: (item) => item,
          isFailer: true,
          onRetry: () => retries++,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    expect(retries, 1);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('paginated initial error is retryable inside the sheet', (
    tester,
  ) async {
    final cubit = _DropdownCubit();
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

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(cubit.calls, 1);
    expect(find.byType(TextButton), findsOneWidget);

    cubit.fail = false;
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(cubit.calls, 2);
    expect(find.text('Cairo'), findsOneWidget);
  });

  testWidgets('rapid confirmation applies once and does not pop the page', (
    tester,
  ) async {
    var callbacks = 0;
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const ['A', 'B'],
          value: 'A',
          itemAsString: (item) => item,
          showSearchBox: false,
          onChanged: (_) => callbacks++,
        ),
      ),
    );

    await tester.tap(find.text('A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    final confirm = find.byType(ElevatedButton);
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(callbacks, 1);
    expect(find.byType(AppDropdown<String>), findsOneWidget);
  });

  testWidgets('multi-select applies only confirmed values', (tester) async {
    var selected = <String>[];
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const ['Cairo', 'Giza', 'Alexandria'],
          itemAsString: (item) => item,
          isMultiSelect: true,
          selectedValues: selected,
          onMultiChanged: (value) => selected = value,
          onChanged: (_) {},
          showSearchBox: false,
          semanticLabel: 'Cities',
        ),
      ),
    );
    final trigger = find.byType(InkWell).first;
    expect(tester.getSemantics(trigger).label, contains('Cities'));
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').last);
    await tester.pump();
    await tester.tap(find.text('Giza').last);
    await tester.pump();
    expect(selected, isEmpty);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(selected, ['Cairo', 'Giza']);
  });

  testWidgets('large dataset is lazy, searchable and scroll safe', (
    tester,
  ) async {
    final items = List.generate(500, (index) => 'Item $index');
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: items,
          itemAsString: (item) => item,
          onChanged: (_) {},
          semanticLabel: 'Large selector',
        ),
      ),
    );
    final trigger = find.byType(InkWell).first;
    expect(tester.getSemantics(trigger).label, contains('Large selector'));
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Item 499');
    await tester.pump();
    expect(find.text('Item 499'), findsNWidgets(2));
    expect(find.text('Item 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard activates a focused trigger', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _host(
        AppDropdown<String>(
          items: const ['A', 'B'],
          value: 'A',
          itemAsString: (item) => item,
          onChanged: (_) {},
          showSearchBox: false,
          focusNode: focus,
          autofocus: true,
          semanticLabel: 'Keyboard selector',
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('select all defaults to localized copy', (tester) async {
    await ensureLocalizedTests();
    final selected = <String>[];
    await pumpLocalized(
      tester,
      AppDropdown<String>(
        items: const ['Cairo', 'Giza'],
        itemAsString: (item) => item,
        isMultiSelect: true,
        selectedValues: selected,
        onMultiChanged: (_) {},
        onChanged: (_) {},
        showSearchBox: false,
        showSelectAll: true,
      ),
      locale: const Locale('en'),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('Select All'), findsOneWidget);
  });

  testWidgets('select all explicit override is preserved under RTL', (
    tester,
  ) async {
    await ensureLocalizedTests();
    var selected = <String>[];
    await pumpLocalized(
      tester,
      AppDropdown<String>(
        items: const ['Cairo', 'Giza'],
        itemAsString: (item) => item,
        isMultiSelect: true,
        selectedValues: selected,
        onMultiChanged: (value) => selected = value,
        onChanged: (_) {},
        showSearchBox: false,
        showSelectAll: true,
        selectAllText: 'Pick everything',
      ),
      locale: const Locale('ar'),
      direction: ui.TextDirection.rtl,
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('Pick everything'), findsOneWidget);
    await tester.tap(find.text('Pick everything'));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(selected, ['Cairo', 'Giza']);
  });

  testWidgets(
    'trigger and rows use dark-theme surface colors and 48dp target',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final theme = ThemeData.dark();
      await tester.pumpWidget(
        _host(
          AppDropdown<String>(
            items: const ['A', 'B'],
            value: 'A',
            itemAsString: (item) => item,
            showSearchBox: false,
            label: 'Choice',
            onChanged: (_) {},
          ),
          theme: theme,
        ),
      );

      final trigger = find.byType(InkWell).first;
      expect(tester.getSize(trigger).height, greaterThanOrEqualTo(48));
      expect(
        tester.widget<Text>(find.text('A').first).style?.color,
        theme.colorScheme.onSurface,
      );

      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('B').last).style?.color,
        theme.colorScheme.onSurface,
      );
    },
  );
}
