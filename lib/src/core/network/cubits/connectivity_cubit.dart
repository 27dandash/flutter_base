import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../network_info.dart';

/// Streams connectivity changes as a single boolean (`true` = online).
/// Exposes the value through `flutter_bloc` so UI uses BlocBuilder/Selector
/// instead of raw StreamBuilders.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(NetworkInfo().isOnline) {
    _sub = NetworkInfo().onStatusChange.listen(emit);
    // Re-check on creation so the first frame reflects the real state.
    NetworkInfo().check().then(emit);
  }

  late final StreamSubscription<bool> _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
