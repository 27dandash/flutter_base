import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base/src/core/network/cubits/connectivity_cubit.dart';
import 'package:flutter_base/src/core/network/cubits/offline_queue_cubit.dart';
import 'package:flutter_base/src/core/network/offline/offline_queue_manager.dart';
import 'package:flutter_base/src/core/widgets/offline_sync_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'localized_widget_harness.dart';

class _MockConnectivity extends MockCubit<bool> implements ConnectivityCubit {}

class _MockQueue extends MockCubit<OfflineQueueState>
    implements OfflineQueueCubit {}

Widget _banner(bool online, OfflineQueueState queue) {
  final connectivity = _MockConnectivity();
  final queueCubit = _MockQueue();
  whenListen(connectivity, const Stream<bool>.empty(), initialState: online);
  whenListen(
    queueCubit,
    const Stream<OfflineQueueState>.empty(),
    initialState: queue,
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<ConnectivityCubit>.value(value: connectivity),
      BlocProvider<OfflineQueueCubit>.value(value: queueCubit),
    ],
    child: const OfflineSyncBanner(),
  );
}

void main() {
  setUpAll(ensureLocalizedTests);

  const idle = OfflineQueueState(pending: 0, status: SyncStatus.idle);
  const queued = OfflineQueueState(pending: 3, status: SyncStatus.idle);

  test('every translation keeps its {} placeholders', () {
    Map<String, dynamic> load(String l) =>
        jsonDecode(File('assets/translations/$l.json').readAsStringSync())
            as Map<String, dynamic>;
    final en = load('en');
    final ar = load('ar');
    for (final key in en.keys.where((k) => k.startsWith('offline_banner_'))) {
      expect(
        '{}'.allMatches(ar[key] as String).length,
        '{}'.allMatches(en[key] as String).length,
        reason: key,
      );
    }
  });

  // EasyLocalization state leaks between testWidgets in one file, so every
  // scenario runs as a step of a single test.
  testWidgets('banner states, localization and theme colors', (tester) async {
    await pumpLocalized(tester, _banner(true, idle));
    expect(find.byType(Icon), findsNothing);

    await pumpLocalized(tester, _banner(false, queued));
    expect(find.text('No connection — 3 pending'), findsOneWidget);

    final theme = ThemeData(colorScheme: const ColorScheme.dark());
    await pumpLocalized(tester, _banner(false, idle), theme: theme);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(OfflineSyncBanner),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.error);

    await pumpLocalized(
      tester,
      _banner(
        true,
        const OfflineQueueState(pending: 2, status: SyncStatus.syncing),
      ),
    );
    expect(find.text('Syncing… (2)'), findsOneWidget);

    await pumpLocalized(
      tester,
      _banner(
        true,
        const OfflineQueueState(pending: 2, status: SyncStatus.idle),
      ),
    );
    expect(find.text('Waiting to sync (2)'), findsOneWidget);
  });
}
