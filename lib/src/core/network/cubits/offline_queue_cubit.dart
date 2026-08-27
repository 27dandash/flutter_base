import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../offline/offline_queue_manager.dart';

class OfflineQueueState extends Equatable {
  final int pending;
  final SyncStatus status;

  const OfflineQueueState({required this.pending, required this.status});

  bool get isSyncing => status == SyncStatus.syncing;

  OfflineQueueState copyWith({int? pending, SyncStatus? status}) =>
      OfflineQueueState(
        pending: pending ?? this.pending,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [pending, status];
}

class OfflineQueueCubit extends Cubit<OfflineQueueState> {
  OfflineQueueCubit()
    : super(
        OfflineQueueState(
          pending: OfflineQueueManager().pendingCount,
          status: SyncStatus.idle,
        ),
      ) {
    _pendingSub = OfflineQueueManager().pendingStream.listen(
      (n) => emit(state.copyWith(pending: n)),
    );
    _statusSub = OfflineQueueManager().statusStream.listen(
      (s) => emit(state.copyWith(status: s)),
    );
  }

  late final StreamSubscription<int> _pendingSub;
  late final StreamSubscription<SyncStatus> _statusSub;

  @override
  Future<void> close() {
    _pendingSub.cancel();
    _statusSub.cancel();
    return super.close();
  }
}
