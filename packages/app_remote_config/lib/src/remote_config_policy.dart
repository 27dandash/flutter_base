enum RemoteConfigEnvironment { development, staging, production }

final class RemoteConfigPolicy {
  const RemoteConfigPolicy({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
    this.operationTimeout,
  });

  factory RemoteConfigPolicy.forEnvironment(RemoteConfigEnvironment value) =>
      switch (value) {
        RemoteConfigEnvironment.development => const RemoteConfigPolicy(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
        RemoteConfigEnvironment.staging => const RemoteConfigPolicy(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration(minutes: 15),
        ),
        RemoteConfigEnvironment.production => const RemoteConfigPolicy(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration(hours: 1),
        ),
      };

  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  final Duration? operationTimeout;

  Duration get effectiveOperationTimeout =>
      operationTimeout ?? fetchTimeout + const Duration(seconds: 2);
}
