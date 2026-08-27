# Optional Google Maps

`app_maps` is not referenced by the root application. Add the path dependency
only when a product needs maps; otherwise it contributes zero Dart, plugin, and
native bytes to the root artifact.

## Safe contract

- The product passes `AppMapConfig`, localized labels, and optional services.
- Missing native configuration is represented by `apiKeyConfigured: false` and
  displays a controlled accessible state without creating `GoogleMap`.
- GPS and permission prompts happen only after the user asks for current
  location.
- Address lookup is injected; the package chooses no paid provider.
- Raw native/plugin errors are never user-facing copy.

## Android keys

The example reads non-committed `android/maps.properties`:

```properties
MAPS_API_KEY_DEVELOPMENT={{ANDROID_MAPS_DEVELOPMENT_KEY}}
MAPS_API_KEY_STAGING={{ANDROID_MAPS_STAGING_KEY}}
MAPS_API_KEY_PRODUCTION={{ANDROID_MAPS_PRODUCTION_KEY}}
```

Copy `android/maps.properties.example`, replace one key per flavor, and run with
`--dart-define=MAPS_API_KEY_CONFIGURED=true` only after the matching native key
exists. Restrict each key by the effective package ID and the exact debug or
release certificate SHA-1/SHA-256.

## iOS keys

Copy the matching file under `example/ios/Flutter/`:

- `MapsDevelopment.local.xcconfig.example`
- `MapsStaging.local.xcconfig.example`
- `MapsProduction.local.xcconfig.example`

Remove `.example`, set `GOOGLE_MAPS_API_KEY`, and keep the local file
uncommitted. Xcode injects it into `Info.plist`; `AppDelegate` calls
`GMSServices.provideAPIKey` only for a non-empty, non-placeholder value.
Restrict each key by the exact bundle ID.

| Flavor | Android ID | Android source | iOS bundle ID | iOS source | Missing behavior |
| --- | --- | --- | --- | --- | --- |
| development | `com.flutter.newproject.maps.dev` | `MAPS_API_KEY_DEVELOPMENT` | `com.flutter.newproject.maps.dev` | `MapsDevelopment.local.xcconfig` | controlled state |
| staging | `com.flutter.newproject.maps.staging` | `MAPS_API_KEY_STAGING` | `com.flutter.newproject.maps.staging` | `MapsStaging.local.xcconfig` | controlled state |
| production | `com.flutter.newproject.maps` | `MAPS_API_KEY_PRODUCTION` | `com.flutter.newproject.maps` | `MapsProduction.local.xcconfig` | controlled state |

Development/staging must never reuse the production key. No real key is stored
in Dart, manifests, plist, AppDelegate, xcconfig templates, docs, or reports.

## Example verification

```bash
cd packages/app_maps/example
flutter analyze
flutter test
flutter build apk --debug --flavor production
flutter build ios --simulator --flavor production
```

The default example is intentionally key-free. Real rendering remains blocked
until an authorized key is supplied and restrictions are verified on devices.
