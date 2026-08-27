# Release commands, smoke tests, and gates

Run commands from the repository root. The project-local gate resolves the SDK
from `android/local.properties`; documentation uses portable `flutter`/`dart`
commands so CI and other machines do not depend on a personal path.

## Resolve, format, analyze, and test

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --dart-define=PHP_RESPONSE_MODE=false \
  test/core/network/php/php_envelope_test.dart
flutter pub outdated --no-dev-dependencies
flutter pub deps --style=compact
for package in app_notifications app_remote_config app_webview app_maps app_socket; do
  scripts/check_optional_resolution.sh "$package"
done
```

For each directory under `packages/`:

```bash
cd packages/app_notifications && flutter pub get && flutter analyze && flutter test
cd packages/app_remote_config && flutter pub get && flutter analyze && flutter test
cd packages/app_webview && flutter pub get && flutter analyze && flutter test
cd packages/app_maps && flutter pub get && flutter analyze && flutter test
cd packages/app_socket && flutter pub get && flutter analyze && flutter test
```

## Run/build every flavor

Create ignored `config/development.json`, `config/staging.json`, and
`config/production.json`. Production needs a real HTTPS URL and two real pins.

```bash
flutter run --flavor development -t lib/main_development.dart \
  --dart-define-from-file=config/development.json
flutter run --flavor staging -t lib/main_staging.dart \
  --dart-define-from-file=config/staging.json
flutter run --flavor production -t lib/main_production.dart \
  --dart-define-from-file=config/production.json

flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart \
  --target-platform=android-arm64 --analyze-size
flutter build appbundle --release --flavor production \
  -t lib/main_production.dart --analyze-size

# Distribution builds: retain build/symbols/production outside the app.
flutter build apk --release --flavor production -t lib/main_production.dart \
  --target-platform=android-arm64 \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production \
  -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
scripts/check_size_budget.sh \
  build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk \
  build/app/outputs/bundle/productionRelease/app-production-release.aab

flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart
```

The project-local consistency gate wraps the verified routine commands:

```bash
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
scripts/flutter_quality_gate.sh release
# Explicitly opt into the expensive Android/iOS build matrix:
scripts/flutter_quality_gate.sh release --build
```

`release` checks size budgets and Universal-APK optional isolation only when
the required audited artifacts are present; it reports an explicit skip
otherwise. `--build` recreates them. The gate uses `--no-pub`, so dependency
resolution remains an explicit environment-setup action.

Production examples above omit the define file only when verifying compilation.
A real smoke launch must use `config/production.json`; placeholder production
configuration intentionally renders controlled startup failure.

## Native inspection

```bash
cd android
./gradlew app:dependencies --configuration productionReleaseRuntimeClasspath
cd ..
xcodebuild -list -project ios/Runner.xcodeproj
xcodebuild -showBuildSettings -project ios/Runner.xcodeproj \
  -scheme production -configuration Release-production
```

Inspect `build/app/outputs/logs/manifest-merger-*-report.txt` and merged manifests
for every flavor. Confirm IDs, app names, permissions, exported components,
cleartext policy, deep links, Firebase providers, and Maps metadata. Do not
silence the Built-in Kotlin warnings; schedule coordinated migration.

`--analyze-size` cannot be combined with `--split-debug-info`; use separate
analysis and distribution builds. Preserve all of these under the exact version,
build and ABI in restricted release storage:

- `build/symbols/production/*.symbols`;
- `build/app/outputs/mapping/productionRelease/`;
- `build/app/outputs/native-debug-symbols/productionRelease/`;
- the signed APK/AAB delivered to the store.

CI retention is 90 days and is only a transfer window. Symbolicate Dart crashes
with `flutter symbolize -i crash.txt -d <matching-abi.symbols>`. Google Play gets
the AAB; direct distribution gets the matching ABI APK, never the universal APK
by default. See `SIZE_AUDIT.md` for bundletool commands and exact budgets.

## Release smoke checklist

- [ ] Analyzer and all root/optional tests pass; both PHP branches executed.
- [ ] Production config rejects placeholder/dev URL, bad/missing pins, and
      debug-only configuration; valid primary and backup pins hit the real API.
- [ ] Install all flavors side-by-side; name/icon/ID/endpoint/Firebase/deep links
      are captured and correct.
- [ ] Cold/warm/offline/resume/process-death launch reaches content or a
      controlled recovery destination, never indefinite splash/black screen.
- [ ] Login/session restore/logout/account deletion/revocation/blocked/activation/
      account switch work; Back never reopens protected UI; cleanup failures are
      observable and old-user cache/queue/data cannot appear.
- [ ] Android Photo Picker/gallery/camera/crop covers allow/deny/permanent deny,
      cancel, activity recreation, missing/unsupported/oversized file, rapid
      requests, minified release install, and minimum/current API levels.
- [ ] Arabic/English cold and runtime switching updates nested/retained routes,
      tabs, dialogs, sheets, validation, mixed-direction fields, light/dark,
      large text, screen reader, and reduced motion.
- [ ] If notifications are enabled: prompt states, real FCM/APNs token/refresh,
      backend fields, dedupe/retry, all delivery states, tap routes, logout and
      account-switch association removal pass without startup waits/token logs.
- [ ] If WebView is enabled: real HTTPS/SSL/offline/error/retry/back/callback/
      external schemes/download policy and duplicate/disposed callbacks pass.
- [ ] If Maps is enabled: restricted per-platform/flavor keys, billing/quota,
      map render, GPS permissions/services, selection/confirm/cancel/address
      failure, RTL controls, lifecycle pass.
- [ ] If socket is enabled: real endpoint auth/refresh, bounded reconnect,
      radio/proxy loss, background/resume, duplicate listeners, logout/switch,
      and payload redaction pass.
- [ ] Signed Android APK/AAB and iOS archive install from release channels; R8,
      resources, symbols, privacy declarations, crash reporting and symbol upload
      are verified. Store download/installed sizes are recorded from real tools.
- [ ] Version is `major.minor.patch+monotonicBuild`; the prior signed artifact,
      config, mappings and symbols are retained; internal testing and staged
      rollout owners can execute and reverse the promotion.
- [ ] iOS privacy manifest/required-reason APIs, Android Data Safety, third-party
      SDK licenses, PII/retention/account deletion, screenshots/clipboard, and
      user consent reflect the integrations actually enabled by the product.

## Blocked items and required inputs

| Blocked gate | Required to unblock |
| --- | --- |
| real backend journeys and session states | approved dev/stage/prod contracts, endpoints, credentials/test users, expected blocked/activation routes |
| production TLS | real host, current primary/backup certificate/SPKI policy, rotation/rollback owner, network access |
| Android signing/store | product application IDs, upload key in CI secret storage, Play app/channel, store declarations |
| iOS signing/archive/store | product bundle IDs, Apple team, profiles/certificates, capabilities/entitlements, App Store Connect app |
| Firebase/notifications | separate flavor projects/config files, APNs key/certificate, backend registration endpoint, physical devices |
| Google Maps | separately restricted Android/iOS keys per environment, billing/quota/privacy owner, devices |
| deep links | approved domains/schemes, association files, route matrix |
| crash/analytics | approved provider, DSN/config via secret/public config policy, privacy consent, symbol upload credentials |
| WebView/socket live checks | approved hosts/callbacks/schemes/downloads and real socket endpoint/events/auth test plan |
| physical QA | representative Android/iOS devices, minimum/current OS matrix, accessibility and poor-network lab |

Until every applicable gate passes, the allowed status is **Conditionally
production-ready**, never Production-ready.
