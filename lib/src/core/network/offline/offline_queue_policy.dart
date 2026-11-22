/// Retry rules of the offline queue.
abstract final class OfflineQueuePolicy {
  /// A write that failed this many times is dropped and reported.
  static const int maxRetries = 5;

  /// 4xx responses that will not succeed on replay. 408 (timeout), 425 (too
  /// early) and 429 (rate limited) describe the moment, not the request, so
  /// the user's offline write must be kept and retried instead of lost.
  static bool isPermanentClientError(int code) =>
      code >= 400 && code < 500 && code != 408 && code != 425 && code != 429;
}
