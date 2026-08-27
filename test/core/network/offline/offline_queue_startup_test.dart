import 'package:flutter_base/src/core/network/cubits/offline_queue_cubit.dart';
import 'package:flutter_base/src/core/network/offline/offline_queue_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('optional queue persistence is safe before initialization', () async {
    final manager = OfflineQueueManager();

    expect(manager.pendingCount, greaterThanOrEqualTo(0));

    final cubit = OfflineQueueCubit();
    expect(cubit.state.pending, manager.pendingCount);
    await cubit.close();
  });
}
