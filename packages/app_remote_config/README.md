# Optional Firebase Remote Config

`app_remote_config` is not referenced by the root application. Add it only to a
product that needs Remote Config; otherwise Firebase contributes zero Dart,
plugin-registration, and native bytes to the root artifact.

Remote Config is suitable for non-sensitive presentation/operational values and
gradual feature exposure. It is not a secrets store, authorization boundary,
substitute for backend enforcement, or safe place for credentials.

## Behavior

- Explicit backend and Firebase-initializer injection.
- Lazy construction; disabled mode never touches Firebase.
- Time-bounded initialization and operations.
- Defaults available before initialization/network success.
- Environment policies: development zero interval, staging 15 minutes,
  production one hour; all retain the existing 10-second fetch timeout.
- Concurrency-protected fetch-and-activate.
- Separate fetch and activation for advanced backends.
- Typed string, bool, int, double, and JSON access with malformed/missing
  fallback.
- Safe status/error codes with no raw Firebase exception user copy.
- `tryInitialize` reports `initialized` when Firebase setup completes without
  fetching; fetch/activation statuses remain unchanged.
- Native Firebase caching/last-known values remain available through the SDK.
- Disposal prevents new lifecycle work.

Existing `RemoteConfigBackend`, constructor names, `initialize`, and
`fetchRequiredString` remain supported. Existing timeout and interval defaults
were not silently changed.

## Usage

```dart
final remoteConfig = AppRemoteConfig(enabled: true);
await remoteConfig.setDefaults(const <String, Object>{
  'welcome_message': 'Welcome',
  'new_navigation_enabled': false,
});

final initialization = await remoteConfig.tryInitialize();
if (initialization.isSuccess) {
  await remoteConfig.fetchAndActivate(
    policy: RemoteConfigPolicy.forEnvironment(
      RemoteConfigEnvironment.production,
    ),
  );
}
final enabled = remoteConfig.getBool('new_navigation_enabled');
```

Use lowercase snake_case generic parameter names. Keep product keys and their
values in the derived application. Define rollback/emergency-disable defaults
that are safe when Firebase is offline; security-critical authorization remains
server-side.

## Android Firebase apps

Download one real file per registered application:

| Flavor | App ID | Source |
| --- | --- | --- |
| development | `com.flutter.newproject.remoteconfig.dev` | `example/android/app/src/development/google-services.json` |
| staging | `com.flutter.newproject.remoteconfig.staging` | `example/android/app/src/staging/google-services.json` |
| production | `com.flutter.newproject.remoteconfig` | `example/android/app/src/production/google-services.json` |

Tracked `.example` files contain instructions only. The Google Services plugin
is applied only when a real file exists. Missing configuration does not prevent
the disabled example or root application from building.

## iOS Firebase apps

Download one real plist per registered bundle:

| Flavor | Bundle ID | Source |
| --- | --- | --- |
| development | `com.flutter.newproject.remoteconfig.dev` | `example/ios/Runner/Firebase/development/GoogleService-Info.plist` |
| staging | `com.flutter.newproject.remoteconfig.staging` | `example/ios/Runner/Firebase/staging/GoogleService-Info.plist` |
| production | `com.flutter.newproject.remoteconfig` | `example/ios/Runner/Firebase/production/GoogleService-Info.plist` |

The Xcode build phase selects the file from the active configuration, skips
when absent, and fails actionably if a placeholder file is renamed without
replacement.

## Tests and live verification

```bash
cd packages/app_remote_config
flutter analyze
flutter test
cd example
flutter analyze
flutter test
flutter build apk --debug --flavor production
flutter build ios --simulator --flavor production
```

Tests cover disabled/missing config, defaults, success, failure/offline,
timeout, activation/no-change, malformed/missing typed values, repeated
initialization, concurrent fetch, environment intervals, and disposal. They are
mock/local verification—not live Firebase proof. Live verification remains
blocked until authorized per-flavor Firebase projects and files are supplied.
