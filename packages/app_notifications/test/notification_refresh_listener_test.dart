import 'package:app_notifications/app_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NotificationRefreshBus bus;
  late List<NotificationRefresh> refreshed;

  setUp(() {
    bus = NotificationRefreshBus();
    refreshed = [];
  });

  Widget page({String? entityId, Set<String> scopes = const {'order'}}) =>
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationRefreshListener(
          scopes: scopes,
          entityId: entityId,
          bus: bus,
          onRefresh: refreshed.add,
          child: const SizedBox(),
        ),
      );

  testWidgets('refreshes when the scope and entity match', (tester) async {
    await tester.pumpWidget(page(entityId: '7'));
    bus.emit(const NotificationRefresh(scope: 'order', entityId: '7'));
    expect(refreshed, hasLength(1));
  });

  testWidgets('ignores another order and another scope', (tester) async {
    await tester.pumpWidget(page(entityId: '7'));
    bus.emit(const NotificationRefresh(scope: 'order', entityId: '8'));
    bus.emit(const NotificationRefresh(scope: 'wallet', entityId: '7'));
    expect(refreshed, isEmpty);
  });

  testWidgets('a scope-wide event refreshes every page of that scope', (
    tester,
  ) async {
    await tester.pumpWidget(page(entityId: '7'));
    bus.emit(const NotificationRefresh(scope: 'order'));
    expect(refreshed, hasLength(1));
  });

  testWidgets('duplicates inside the window refresh once', (tester) async {
    await tester.pumpWidget(page());
    final first = DateTime(2026);
    expect(
      bus.emit(const NotificationRefresh(scope: 'order'), now: first),
      isTrue,
    );
    expect(
      bus.emit(
        const NotificationRefresh(scope: 'order', fromTap: true),
        now: first.add(const Duration(milliseconds: 500)),
      ),
      isFalse,
    );
    expect(refreshed, hasLength(1));
    // After the window the same event refreshes again.
    expect(
      bus.emit(
        const NotificationRefresh(scope: 'order'),
        now: first.add(const Duration(seconds: 5)),
      ),
      isTrue,
    );
    expect(refreshed, hasLength(2));
  });

  testWidgets('stops listening when the page is removed', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpWidget(const SizedBox());
    bus.emit(const NotificationRefresh(scope: 'order'));
    expect(refreshed, isEmpty);
  });

  testWidgets('a throwing callback never crashes', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationRefreshListener(
          scopes: const {'order'},
          bus: bus,
          onRefresh: (_) => throw StateError('boom'),
          child: const SizedBox(),
        ),
      ),
    );
    bus.emit(const NotificationRefresh(scope: 'order'));
    expect(tester.takeException(), isNull);
  });
}
