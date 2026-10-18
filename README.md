# Flutter Base

> Replace `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}`, and the remaining placeholders before publishing a derived application.

![Project logo]({{PROJECT_LOGO}})

[![CI]({{CI_BADGE_URL}})]({{SUPPORT_URL}})
[![Coverage]({{COVERAGE_BADGE_URL}})]({{SUPPORT_URL}})

## 1. Project purpose

`flutter_base` is a reusable Clean Architecture foundation for production Flutter applications. It provides tested network, session, storage, localization, startup, routing, design-system, release, and QA foundations while keeping heavy integrations optional. Derived project summary: `{{PROJECT_DESCRIPTION}}`.

## 2. Architecture

Business features follow `presentation -> domain <- data`. Domain has no Flutter, Dio, storage, plugin, or data-model imports. Dependency registration belongs at composition roots; business behavior remains feature-owned. See `docs/ARCHITECTURE.md`.

## 3. Folder structure

```text
lib/src/core/                 reusable infrastructure and design system
lib/src/features/             feature-owned presentation/domain/data
packages/                     opt-in integrations
test/                         unit, widget, boundary, and configuration tests
integration_test/             critical runtime smoke flows
scripts/                      deterministic quality/release checks
tool/                         generators and widget gallery
docs/                         architecture, release, catalog, prompts, reports
```

## 4. Requirements and toolchain

- Flutter `>=3.47.1`
- Dart `>=3.13.1 <4.0.0`
- Android SDK/NDK and JDK 17 compatible with the checked Gradle files
- Xcode on macOS for iOS and macOS builds
- Swift Package Manager for the root Apple targets; CocoaPods only for optional
  integrations that do not support SwiftPM

Use the Flutter SDK configured in `android/local.properties` or a compatible Flutter executable on `PATH`.

## 5. Setup

```bash
flutter pub get
for package in packages/app_notifications packages/app_remote_config packages/app_socket packages/app_webview packages/app_maps; do
  (cd "$package" && flutter pub get)
done
(cd packages/app_webview/example && flutter pub get)
(cd packages/app_maps/example && flutter pub get)
(cd packages/app_remote_config/example && flutter pub get)
scripts/flutter_quality_gate.sh quick
```

Do not commit local endpoints, credentials, signing data, Maps keys, Firebase files, or developer-team identifiers.

## 6. Environments

Document the derived environments as `{{ENVIRONMENTS}}`. Endpoint configuration comes from validated `--dart-define` values. Remote Config is not a secrets store and must not silently replace a compile-time production endpoint.

## 7. Flavors

The template includes `development`, `staging`, and `production`. Describe derived variants in `{{APP_VARIANTS}}` and user roles in `{{USER_ROLES}}`.

## 8. Android/iOS flavor mapping

| Flavor | Android application ID | iOS bundle ID | Display name |
| --- | --- | --- | --- |
| development | `com.flutter.newproject.dev` | `com.flutter.newproject.dev` | Flutter Base Dev |
| staging | `com.flutter.newproject.staging` | `com.flutter.newproject.staging` | Flutter Base Staging |
| production | `com.flutter.newproject` | `com.flutter.newproject` | Flutter Base |

Derived IDs: Android `{{ANDROID_APPLICATION_ID}}`; iOS `{{IOS_BUNDLE_IDENTIFIER}}`. Keep suffixes and store registrations one-to-one.

## 9. Single-app and multi-app usage

One product may use the environment flavors above. A multi-app product should add a second flavor dimension only after defining unique IDs, signing, Firebase apps, deep links, Maps restrictions, icons, and store records for every combination.

## 10. Run commands

```bash
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor production -t lib/main_production.dart
```

Production startup rejects missing endpoints or certificate pins instead of falling back to development.

Pin formats, error reporting and other inherited behaviour: `docs/HARDENING_NOTES.md`.

## 11. Testing

```bash
flutter test
flutter test --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart
flutter test --coverage
flutter test integration_test
```

Tests protect behavior, security, architecture boundaries, assets, localization parity, accessibility, lifecycle, cancellation, and regressions.

## 12. Quality gate

```bash
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
scripts/flutter_quality_gate.sh release
scripts/flutter_quality_gate.sh release --build
```

`quick` is routine. `full` adds coverage, generation reproduction, and all optional packages/examples. `release --build` intentionally runs expensive Android/iOS matrices and artifact budgets. The gate never runs Git.

## 13. Code generation

```bash
dart run build_runner build
dart run tool/generate_locale_keys.dart
dart format lib/src/config/language/locale_keys.g.dart
```

Use `scripts/check_codegen_reproducibility.sh` to prove generated output.

## 14. Android builds

```bash
flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --release --flavor production -t lib/main_production.dart --split-debug-info=build/symbols/production
flutter build apk --release --flavor production --split-per-abi -t lib/main_production.dart --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart --split-debug-info=build/symbols/production
```

Archive Dart/native symbols and the R8 mapping with the release.

## 15. iOS builds

```bash
flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart
```

Real archives require product signing, entitlements, privacy review, and App Store Connect registration.

## 16. Android IDs

The root ID is `com.flutter.newproject`; development/staging use `.dev`/`.staging`. Replace every effective ID, provider authority, custom permission, deep-link host, Firebase app, and Maps restriction together.

## 17. iOS bundle IDs

Runner and RunnerTests use matching flavor IDs. Replace bundle IDs, keychain/app groups, associated domains, URL schemes, APNs, provisioning, Firebase apps, and Maps restrictions together.

## 18. Android native splash

`LaunchTheme` covers pre-Android 12 and Android 12+ with light/dark colors and a neutral vector mark. Source: `{{ANDROID_SPLASH_ASSET}}` (template: `tool/branding/neutral_launch_mark.svg`). It ends when Flutter draws its first frame.

## 19. iOS native splash

`LaunchScreen.storyboard` uses centered `LaunchMark` and light/dark `LaunchBackground`. Source: `{{IOS_SPLASH_ASSET}}`. No Dart/runtime dependency is involved.

## 20. Android icons

The template has legacy, adaptive, monochrome, notification, and splash resources. Source: `{{ANDROID_ICON_SOURCE}}` (template: `tool/branding/neutral_app_icon.svg`).

## 21. iOS AppIcon

`AppIcon.appiconset` contains iPhone, iPad, and 1024px marketing sizes; the marketing PNG has no alpha. Source: `{{IOS_ICON_SOURCE}}`. Replace the neutral placeholder before stores.

## 22. Android Maps

Maps remains in `packages/app_maps`. The example reads per-flavor keys from non-committed `android/maps.properties`; template source: `{{ANDROID_MAPS_KEY_SOURCE}}`. Missing keys produce a controlled state.

## 23. iOS Maps

The example injects `GOOGLE_MAPS_API_KEY` through per-flavor local xcconfig files and calls `GMSServices.provideAPIKey` only for a non-empty, non-placeholder value. Source: `{{IOS_MAPS_KEY_SOURCE}}`.

## 24. Maps restrictions

Restrict Android keys by package ID plus SHA-1/SHA-256 certificate fingerprints, separating debug/release. Restrict iOS keys by exact bundle ID. Never share production keys with another flavor.

## 25. Android Firebase configuration

Firebase stays optional. Put downloaded files at `android/app/src/<flavor>/google-services.json`; example source: `{{ANDROID_FIREBASE_CONFIG_SOURCE}}`. Google Services is applied only when a file exists.

## 26. iOS Firebase configuration

Put files at `ios/Runner/Firebase/<flavor>/GoogleService-Info.plist`; source: `{{IOS_FIREBASE_CONFIG_SOURCE}}`. The script selects the matching file, skips safely when absent, and rejects template placeholders.

## 27. Remote Config setup and defaults

Opt in with `packages/app_remote_config`. Define non-sensitive defaults before fetch: `{{REMOTE_CONFIG_DEFAULTS}}`. Inject the backend in tests. Development uses zero minimum interval, staging 15 minutes, and production one hour by default.

## 28. Remote Config fetch, activation, and fallback

Initialization is lazy/time-bounded. Defaults exist before network success. Fetch-and-activate is concurrency-protected and returns safe typed status. String/bool/int/double/JSON accessors fall back for missing/malformed values. Cached values remain owned by Firebase. No raw exception becomes UI, and startup never waits indefinitely.

## 29. Firebase and APNs

Register one Android/iOS Firebase app per flavor. Supply configs outside source control, configure APNs for the product, and verify foreground/background/terminated behavior on devices. No live claim exists without authorized projects and files.

## 30. Optional integrations

Notifications, Remote Config, Maps, WebView, and sockets live under `packages/` and stay absent from the root dependency graph. Crash reporting/analytics should use provider-independent contracts and remain opt-in.

## 31. WebView

Use `packages/app_webview` for allowlisted HTTPS origins. Block dangerous schemes, externalize unsupported navigation safely, hide raw web errors, and test loading/error/back/lifecycle states.

## 32. Socket

Use `packages/app_socket` with an injected transport. Define authentication, reconnect/backoff, lifecycle, cancellation, event ownership, redaction, and logout cleanup in the product.

## 33. Deep Links and Universal Links

Replace hosts, configure Android App Links/iOS Associated Domains together, publish association files, validate guards, and test cold/warm/authenticated/unauthenticated launches.

## 34. Signing

No production signing credential is committed. Keep Android keystores, Apple teams, certificates, profiles, and CI secrets outside source. Verify flavor-to-signing separation.

## 35. Store preparation

Replace name, icon, splash, screenshots, descriptions, support/privacy links, permission copy, Data Safety/privacy manifests, versioning, and release notes. Use Play internal testing and TestFlight.

## 36. Figma

Design source: `{{FIGMA_URL}}`. Verify tokens, component states, Arabic/English, RTL/LTR, light/dark, text scaling, and accessibility—not screenshots alone.

## 37. API collection

API collection: `{{API_COLLECTION_URL}}`. Backend docs: `{{BACKEND_DOCUMENTATION_URL}}`. Confirm contracts with authorized live services; never hide failures with fake data.

## 38. Documentation

Current architecture, catalog, release, QA, size, and prompts are under `docs/`.
The cross-project evidence ledger and recurring-failure adoption decisions are
in `docs/CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31.md`.
The identity/native-parity closeout is
`docs/reports/PROJECT_IDENTITY_MIGRATION_REPORT.md`. Historical reports retain
original measurements/paths when clearly labeled as evidence.

## 39. Canonical widgets

Reuse `AppButton`, `DefaultTextField`, `AppDropdown`, `AppStateView`, `AppMedia`, `AppImagePickerField`, `AppPageShell`, async/pagination builders, dialogs, and feedback utilities. See `docs/REUSABLE_COMPONENT_CATALOG.md`.

## 40. Prompt system

Workflow prompts live under `docs/prompts/`. Select the smallest adapter, keep reference projects read-only unless authorized, and run `scripts/validate_prompt_library.sh`.

## 41. Skills

Project-local Codex/Claude/Cursor guidance lives in `AGENTS.md`, `.codex/skills/flutter-base-production/`, `.claude/skills/flutter-base-production/`, and `.cursor/rules/00-flutter-base-production.mdc`. It requires Android/iOS parity and evidence.

## 42. Release gates

Local gates cover format, analysis, tests, boundaries, assets, localization, identity, optional isolation, size, and builds. Real backend/Firebase/Maps/APNs, signing, stores, and device journeys remain product gates.

## 43. Screenshots and store links

Screenshots: `{{SCREENSHOTS}}`

- Android: `{{ANDROID_STORE_URL}}`
- iOS: `{{IOS_STORE_URL}}`

## 44. Privacy and terms

- Privacy: `{{PRIVACY_POLICY_URL}}`
- Terms: `{{TERMS_URL}}`

Review retention, deletion, consent, logs, analytics, notifications, clipboard/screenshot policy, Android Data Safety, and iOS privacy declarations.

## 45. Support

- Portal: `{{SUPPORT_URL}}`
- Email: `{{SUPPORT_EMAIL}}`

Do not place credentials or private operational links here.

## 46. License

Add the derived product license and attribution policy. Audit dependency licenses and create SBOM/license inventory where required.

## 47. Derived-project checklist

- [ ] Set `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}`, and `{{PROJECT_LOGO}}`.
- [ ] Rename folder/Dart package and package imports.
- [ ] Replace `{{ANDROID_APPLICATION_ID}}` and `{{IOS_BUNDLE_IDENTIFIER}}`; verify flavor/test-target parity.
- [ ] Replace display names, colors, typography, Android/iOS icons and splash.
- [ ] Set `{{ANDROID_ICON_SOURCE}}`, `{{IOS_ICON_SOURCE}}`, `{{ANDROID_SPLASH_ASSET}}`, and `{{IOS_SPLASH_ASSET}}`.
- [ ] Configure `{{ANDROID_MAPS_KEY_SOURCE}}` and `{{IOS_MAPS_KEY_SOURCE}}`; restrict keys.
- [ ] Register flavor Firebase apps and set `{{ANDROID_FIREBASE_CONFIG_SOURCE}}` and `{{IOS_FIREBASE_CONFIG_SOURCE}}`.
- [ ] Define `{{REMOTE_CONFIG_DEFAULTS}}`; review intervals; test success/failure/malformed/offline/default behavior.
- [ ] Replace `{{ENVIRONMENTS}}`, `{{APP_VARIANTS}}`, `{{USER_ROLES}}`, links, screenshots, and store metadata.
- [ ] Configure signing, APNs, deep links, privacy/Data Safety, crash reporting, and CI symbol retention.
- [ ] Search stale identity:

```bash
rg -i 'flutter_base|com\.flutter\.newproject|Flutter Base'
find android ios -iname '*icon*' -o -iname '*launch*' -o -iname '*splash*'
scripts/check_project_identity.sh
```

- [ ] Run tests, live design/API verification, quality gates, release builds, and final readiness verification.

Mandatory customization links: `{{FIGMA_URL}}`, `{{API_COLLECTION_URL}}`, `{{BACKEND_DOCUMENTATION_URL}}`, `{{ANDROID_STORE_URL}}`, `{{IOS_STORE_URL}}`, `{{PRIVACY_POLICY_URL}}`, `{{TERMS_URL}}`, `{{SUPPORT_URL}}`, `{{SUPPORT_EMAIL}}`, `{{CI_BADGE_URL}}`, and `{{COVERAGE_BADGE_URL}}`.
