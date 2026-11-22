enum RemoteConfigOperationStatus {
  activated,
  fetchedNoChange,
  initialized,
  disabled,
  timedOut,
  failed,
}

final class RemoteConfigOperationResult {
  const RemoteConfigOperationResult(this.status, {this.errorCode});

  final RemoteConfigOperationStatus status;
  final String? errorCode;

  bool get isSuccess =>
      status == RemoteConfigOperationStatus.activated ||
      status == RemoteConfigOperationStatus.fetchedNoChange ||
      status == RemoteConfigOperationStatus.initialized;
}

final class RemoteConfigOperationException implements Exception {
  const RemoteConfigOperationException(this.code);

  final String code;

  @override
  String toString() => 'RemoteConfigOperationException($code)';
}

/// Optional, lifecycle-safe boundary around Firebase Remote Config.
///
/// Construction is lazy, so a disabled provider never touches Firebase.
/// Defaults are available before initialization or network work. Concurrent
/// fetch-and-activate calls share one bounded native operation.
