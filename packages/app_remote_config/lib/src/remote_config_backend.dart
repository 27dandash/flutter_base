import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

typedef FirebaseInitializer = Future<void> Function(FirebaseOptions? options);

abstract interface class RemoteConfigBackend {
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  });

  Future<bool> fetchAndActivate();
  String getString(String key);
}

/// Richer optional contract. Existing lightweight backends remain compatible
/// with [RemoteConfigBackend].
abstract interface class AdvancedRemoteConfigBackend
    implements RemoteConfigBackend {
  Future<void> setDefaults(Map<String, Object> defaults);
  Future<void> fetch();
  Future<bool> activate();
  bool getBool(String key);
  int getInt(String key);
  double getDouble(String key);
}

final class FirebaseRemoteConfigBackend implements AdvancedRemoteConfigBackend {
  FirebaseRemoteConfigBackend(this.remoteConfig);

  final FirebaseRemoteConfig remoteConfig;

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) => remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: fetchTimeout,
      minimumFetchInterval: minimumFetchInterval,
    ),
  );

  @override
  Future<void> setDefaults(Map<String, Object> defaults) =>
      remoteConfig.setDefaults(defaults);
  @override
  Future<void> fetch() => remoteConfig.fetch();
  @override
  Future<bool> activate() => remoteConfig.activate();
  @override
  Future<bool> fetchAndActivate() => remoteConfig.fetchAndActivate();
  @override
  String getString(String key) => remoteConfig.getString(key);
  @override
  bool getBool(String key) => remoteConfig.getBool(key);
  @override
  int getInt(String key) => remoteConfig.getInt(key);
  @override
  double getDouble(String key) => remoteConfig.getDouble(key);
}
