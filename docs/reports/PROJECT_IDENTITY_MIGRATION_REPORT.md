# Flutter Base identity, branding, and native-parity report

Date: 2026-08-27
Toolchain: Flutter 3.47.1, Dart 3.13.1, macOS ARM64, Java 17
Scope: final project identity, neutral branding, Android/iOS parity, native
splash/icons, optional Maps and Remote Config examples, reusable README and
project-local agent guidance.

## 1. Readiness classification

**Conditionally production-ready as a reusable baseline.** The reusable and
locally verifiable identity work is complete. Product IDs, signing, restricted
Maps keys, per-flavor Firebase projects, APNs, backend configuration, store
records, privacy declarations and full physical-device journeys remain derived-
project release gates.

The complete post-identity release matrix now passes. The final run of
`scripts/flutter_quality_gate.sh release --build` completed 59 checks with zero
skips, produced fresh APK/AAB and symbol evidence, and was followed by release
launch verification on Samsung API 34, Android Emulator API 36 and iOS
Simulator. The reusable-baseline verdict is **Reusable baseline frozen**. The
overall production classification remains **Conditionally production-ready**.

## 2. Paths, backup, and recovery

| Item | Value |
| --- | --- |
| Old path | `/Users/abdelrahamndandash/StudioProjects/flutter_clean_arch_base-main` |
| Final path | `/Users/abdelrahamndandash/StudioProjects/flutter_base` |
| Operation | Verified source/destination, archived source, then one authorized directory `mv`; no copied second project |
| Backup | `/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter_clean_arch_base-main-pre-identity-20260827-162517.tar.gz` |
| Backup bytes | 1.7 MiB compressed |
| Backup SHA-256 | `24740f6a2005d32b2d7f9122c8e7033a9b656d539b82f6994c51995594945f42` |
| Verification | `tar -tzf` succeeded before the rename |

The archive excludes only reproducible build/cache output (`build`, `.dart_tool`,
Pods, ephemeral, Gradle and OS metadata). It contains the source, native project,
assets, configuration, tests, documentation and the removed root launch catalog.

## 3. Neutral identity and flavor parity

The originally suggested mixed-case `com.flutter.newProject` was deliberately
normalized to the portable lowercase `com.flutter.newproject` everywhere.

| Flavor | Android ID | iOS bundle ID | Display name |
| --- | --- | --- | --- |
| Development | `com.flutter.newproject.dev` | `com.flutter.newproject.dev` | Flutter Base Dev |
| Staging | `com.flutter.newproject.staging` | `com.flutter.newproject.staging` | Flutter Base Staging |
| Production | `com.flutter.newproject` | `com.flutter.newproject` | Flutter Base |

The Dart package is `flutter_base`; package imports, generated registrars, tests,
the widget gallery and integration harness use that identity. MainActivity is
`android/app/src/main/kotlin/com/flutter/newproject/MainActivity.kt`. Runner and
RunnerTests have flavor-correct iOS identifiers. Linux, macOS, Windows and web
metadata were neutralized as well.

## 4. Branding audit, removals, and retentions

The automated audit searches, case-insensitively, for:

- Arabic Awamer variants including `أوامر الشبكة`;
- Awamer/Awaamer English transliterations;
- I Craft/ICraft/iCraft variants;
- `flutter_clean_arch_base-main` and the old package path;
- `com.example.clean_arch_base`, `com.example.cleanArchBase` and old package
  imports;
- personal paths and Apple `DEVELOPMENT_TEAM` values in active guidance/native
  templates.

No old Awamer or I Craft product artwork/text was present in the pre-migration
source. The active launcher art was Flutter's stock logo; it was classified as
obsolete template identity and replaced, not mistaken for user artwork. Generic
network/connectivity terminology and translations were retained.

Removed from the original root after backup and reference checks:

- `android/app/src/main/kotlin/com/example/clean_arch_base/MainActivity.kt`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`.

The LaunchImage files were the obsolete stock catalog, were no longer referenced
after the native LaunchScreen migration, and are recoverable from the archive.
No reusable widget, product asset, font or behavior was deleted. Reproducible
empty package directories, generated IDE files, `.DS_Store` files and Flutter
crash logs were removed without treating them as source assets. Optional-example
stock LaunchImage catalogs created by scaffolding were also replaced before the
examples became deliverables.

## 5. Neutral icon and logo system

Authoritative replaceable sources:

- `tool/branding/neutral_app_icon.svg`;
- `tool/branding/neutral_launch_mark.svg`;
- `tool/branding/generate_native_branding.sh`.

The deterministic generator produces Android legacy/adaptive/monochrome and
notification assets, iOS AppIcon and launch assets, and the equivalent optional-
example assets. Web, macOS and Windows stock Flutter icons were replaced too.

| Evidence | Result |
| --- | --- |
| Root iOS 1024 icon | 1024×1024, RGB, no alpha, 37,839 bytes |
| Root/Maps/Remote Config 1024 SHA-256 | `20af2447c2b90b79e019f374f7d74ac00979786b210e778be5740b7616a6836d` for all three |
| Neutral icon SVG SHA-256 | `0032e5c8169a07111a98f8672f9f6d78a9c1f61788e1a9c9c19520f54ab99dfb` |
| Neutral launch SVG SHA-256 | `1764776ce4b7cda6333bf2771b89e91cdd90cf634e7e8e252dd3aa6c9ad5fe1a` |
| Active LaunchImage catalogs | none |

## 6. Native splash parity

| Flavor | Android | iOS | Light/dark resources | Old brand absent |
| --- | --- | --- | --- | --- |
| Development | `LaunchTheme`, pre-12 layer-list and Android 12+ theme | native `LaunchScreen.storyboard` | yes | audit passed |
| Staging | same neutral resource contract | native `LaunchScreen.storyboard` | yes | audit passed |
| Production | same neutral resource contract | native `LaunchScreen.storyboard` | yes | audit passed |

Android uses `values`, `values-night`, `values-v31` and `values-night-v31`, a
neutral vector mark and the normal Flutter theme transition. It does not depend
on a Dart splash. iOS uses a centered `LaunchMark`, a light/dark
`LaunchBackground` colorset and `scaleAspectFit`; no runtime/network dependency
or obsolete LaunchImage remains.

Compilation proves resource validity for all root flavors. Fresh light/dark
native-launch captures on Samsung API 34 and iOS Simulator show the centered
neutral mark, correct background variants and no old stock/product artwork.

## 7. Optional Google Maps parity

Maps remains isolated in `packages/app_maps`; the root dependency graph and root
artifact contract contain no Google Maps plugin.

| Flavor | Android ID | Android key source | iOS bundle ID | iOS key source | Missing-key behavior |
| --- | --- | --- | --- | --- | --- |
| Development | `com.flutter.newproject.maps.dev` | ignored `android/maps.properties` → `MAPS_API_KEY_DEVELOPMENT` | `com.flutter.newproject.maps.dev` | ignored `MapsDevelopment.local.xcconfig` | controlled accessible page; no platform map |
| Staging | `com.flutter.newproject.maps.staging` | `MAPS_API_KEY_STAGING` | `com.flutter.newproject.maps.staging` | `MapsStaging.local.xcconfig` | controlled accessible page; no platform map |
| Production | `com.flutter.newproject.maps` | `MAPS_API_KEY_PRODUCTION` | `com.flutter.newproject.maps` | `MapsProduction.local.xcconfig` | controlled accessible page; no platform map |

Tracked `.example` files contain placeholders only; real files are ignored.
Android injects a manifest placeholder. iOS reads `GOOGLE_MAPS_API_KEY` from the
selected build setting and calls `GMSServices.provideAPIKey` only for a nonempty,
non-placeholder value. Development/staging cannot silently read the production
setting.

Restriction guidance requires Android package ID plus debug/release signing
certificate SHA-1/SHA-256, and exact iOS bundle ID, with separate environment
keys, billing/quota ownership and rotation. No real key was read, copied or
logged. Android production debug and iOS production simulator examples built;
real rendering is correctly blocked until authorized restricted keys exist.

## 8. Optional Firebase and Remote Config parity

Remote Config remains isolated in `packages/app_remote_config`; Firebase Core
and Firebase Remote Config are absent from the root Dart dependency and plugin-
registration graph.

| Flavor | Android example ID and file | iOS example ID and file | Policy | Missing configuration |
| --- | --- | --- | --- | --- |
| Development | `com.flutter.newproject.remoteconfig.dev`, `app/src/development/google-services.json` | `com.flutter.newproject.remoteconfig.dev`, `Runner/Firebase/development/GoogleService-Info.plist` | fetch timeout 10s, minimum interval zero | plugin/config copy safely skipped; disabled/default state works |
| Staging | `com.flutter.newproject.remoteconfig.staging`, staging file | matching staging bundle/file | fetch timeout 10s, minimum interval 15m | same controlled behavior |
| Production | `com.flutter.newproject.remoteconfig`, production file | matching production bundle/file | fetch timeout 10s, minimum interval 1h | same controlled behavior |

All committed Firebase files end in `.example`. The iOS copy script selects by
configuration, rejects literal template markers and skips absent configuration.
The Android Google Services plugin is applied only when a real file exists.
Root Android/iOS also contain neutral flavor templates, but no Firebase Dart
package or runtime initialization.

## 9. Base versus Rahoul Remote Config comparison

Rahoul was inspected read-only only for relevant source patterns and config-file
placement. No Firebase file, key, ID, endpoint or product-specific parameter was
read into or copied to this base.

| Concern | Current base | Rahoul pattern | Better approach/action |
| --- | --- | --- | --- |
| Initialization | injectable initializer/backend, lazy when disabled | direct `FirebaseRemoteConfig.instance` in a product Cubit | retain base |
| Timeout/interval | explicit bounded policies: 10s; 0/15m/1h | 10s and 1h | retain base; adds safe environment policy |
| Fetch/activate | separate operations plus shared concurrent `fetchAndActivate` | direct fetch-and-activate | retain base |
| Defaults | available before network, typed fallbacks | product URL fallback flow | retain generic base; do not copy URLs |
| Failure/retry | safe status/error codes, timeout, retryable init, no raw exception | retry loop then product endpoint fallback | retain bounded base |
| DI/testability | basic and advanced backend contracts | concrete Firebase dependency | retain base |
| Typed access | string/bool/int/double/JSON with malformed fallback | product-specific values | retain base |
| Startup | optional and independently bounded | product startup/Cubit owned | retain non-blocking base |
| Native files | flavor `.example` templates on Android/iOS | real files at platform app/Runner locations | document placement only; copied no data |

Backward compatibility is preserved for the original constructor/backend,
`initialize`, `fetchRequiredString`, and original timeout/minimum-interval
semantics. Advanced behavior is additive. Firebase cached/last-known values
remain owned by the native SDK.

## 10. Remote Config behavior and tests

Implemented behavior includes explicit DI, lazy disablement, defaults before
network, environment policy, bounded initialization/fetch/activation,
fetch-and-activate, safe typed access, JSON fallback, missing/malformed fallback,
offline-safe errors, retry after failed initialization, shared concurrent work,
disposal/lifecycle protection and no raw Firebase exception/user value logging.

The package has **16 passing behavior tests** covering the old compatibility API,
disabled provider, missing config, defaults, policies, success/no-change,
concurrency, fetch/offline/activation failure, malformed typed/JSON values,
repeated initialization/retry, timeout and disposal. The optional example adds
one widget test proving default behavior without Firebase startup. These are
mock/controlled tests, not live Firebase verification.

## 11. README and local-agent guidance

Rahoul README structure was inspected read-only at heading/link-placement level.

| Rahoul pattern | Suitable | Neutral adaptation |
| --- | --- | --- |
| overview, apps, features, technologies | yes | reusable-base purpose and optional integrations |
| requirements/setup/environment | yes | portable root-relative setup and flavor matrix |
| run/build commands | yes | verified development/staging/production commands |
| Figma/API/store/support links | yes | explicit `{{...}}` placeholders |
| product names, roles, credentials and links | no | not copied |

The root README now has exactly **47 H2 sections** and **29 unique neutral
placeholders**, including project metadata, design/API/docs links, store/privacy/
support links, IDs, Maps/Firebase sources, Remote Config defaults, splash/icon
sources, roles/variants/environments and screenshots. It contains a derived-
project replacement checklist and no personal path or real-looking credential.

Active Codex, Claude and Cursor instructions and the prompt library require
Android/iOS parity for identity, flavors, Maps, Firebase, Remote Config, native
splash, icons, signing, links, APNs and stores. The executable project-local
quality gate now includes identity validation and resolves the configured SDK.

## 12. Exact source delta and generated files

Because Git was prohibited, the exact delta is defined against the checksum-
verified archive rather than a Git diff. The following dry-run produces the
file-by-file manifest while excluding only reproducible state:

```bash
rsync -rcn --delete --itemize-changes \
  --exclude='.dart_tool/' --exclude='build/' --exclude='.gradle/' \
  --exclude='Pods/' --exclude='ephemeral/' --exclude='coverage/' \
  --exclude='.idea/' --exclude='*.iml' --exclude='local.properties' \
  --exclude='Generated.xcconfig' --exclude='flutter_export_environment.sh' \
  /path/to/extracted-backup/flutter_clean_arch_base-main/ ./
```

Material changed/new groups (the command above expands every file exactly):

- root identity: `pubspec.yaml`, all `package:flutter_base` import consumers,
  generated registrars/config, root tests and integration/gallery harnesses;
- root Android: `android/app/build.gradle.kts`, flavor templates/resources,
  MainActivity, all launcher/notification/splash resources;
- root iOS: `ios/Runner.xcodeproj/project.pbxproj`, AppIcon set,
  LaunchScreen/LaunchBackground/LaunchMark, Firebase templates/copy script;
- secondary platforms: Linux, macOS, Windows and web identity/icon files;
- Maps: package README and the complete neutral native example under
  `packages/app_maps/example/{android,ios}` plus controlled Dart state/test;
- Remote Config: package API/README/tests and the complete neutral native example
  under `packages/app_remote_config/example/{android,ios}`;
- tooling: `tool/branding/*`, `tool/configure_optional_ios_flavors.rb`,
  `scripts/check_project_identity.sh`, quality/instruction/prompt validators;
- documentation/guidance: root README, active AGENTS/Claude/Cursor skills/rules,
  QA/release docs, authoritative prompt spec and prompt README;
- this report: `docs/reports/PROJECT_IDENTITY_MIGRATION_REPORT.md`.

Generated/reproducible files include optional-example Gradle wrappers, Xcode
workspaces/schemes, plugin registrants, lockfiles, icon rasters and splash
rasters/vectors. Native branding is reproducible with
`tool/branding/generate_native_branding.sh`; optional iOS flavor projects are
reproducible/idempotent with `tool/configure_optional_ios_flavors.rb`.

## 13. Final post-identity quality gate

| Check | Final result |
| --- | --- |
| `scripts/flutter_quality_gate.sh release --build` | passed: 59 checks, 0 skips |
| Identity/branding/native parity | passed |
| Agent instructions and prompt library | passed |
| Format | 304 files, 0 changed |
| Root analyzer | no issues |
| Root tests | 226 passed, 2 intentional conditional skips |
| Focused widget tests | 61; subset of the 226, not additional |
| Root coverage | 2,470/4,069 lines, 60.70% |
| PHP inverse | 15 passed, 3 opposite-branch skips |
| Code generation | 16 outputs and 83 locale keys reproduced |
| Optional package analyzers | all five passed |
| Optional package tests | 44: notifications 9, Remote Config 16, WebView 6, Maps 7, Socket 6 |
| Optional example tests | 3: WebView 1, Maps 1, Remote Config 1 |
| Root optional dependency graph | isolated; passed |
| Universal APK entry/DEX isolation | passed; zero forbidden optional packages |
| Android debug flavors | development, staging and production ARM64 passed |
| Android production | Universal, ARM32, ARM64, x86_64 and AAB passed |
| Root iOS Simulator | development, staging and production passed |
| Maps example build | Android production ARM64 debug and iOS production Simulator passed |
| Remote Config example build | Android production ARM64 debug and iOS production Simulator passed |
| Size budgets | passed |

Android reports Flutter's future Built-in Kotlin migration warning. Maps iOS
reports that `google_maps_flutter_ios` still requires CocoaPods instead of Swift
Package Manager. Both are upstream future-toolchain warnings, not current build
failures.

## 14. Authoritative post-identity artifacts

All paths below are relative to the project root. Timestamps use Cairo time.

| Artifact | Timestamp | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-development-debug.apk` | 2026-08-27 22:16:42 | 101,568,642 | `d632ddd7456b10e7ffebd88de116e2a5d0a54b3a6400c5910377e9a7f573dc70` |
| `build/app/outputs/flutter-apk/app-staging-debug.apk` | 2026-08-27 22:17:04 | 101,568,526 | `c445f85f208d8e9ff7848a26019b17e71abd993d367893d9ba0fd81921da31ff` |
| `build/app/outputs/flutter-apk/app-production-debug.apk` | 2026-08-27 22:17:26 | 101,568,646 | `fb9d68dd7eeffb06ce11a15b3886418f63a32c1d5d7187bd440955106c665674` |
| `build/app/outputs/flutter-apk/app-production-release.apk` | 2026-08-27 22:18:04 | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| `build/app/outputs/flutter-apk/app-production-universal-release.apk` | 2026-08-27 22:18:05 | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk` | 2026-08-27 22:18:34 | 15,846,674 | `7df5fcf2d56f9189199765cccd6b17f8456d013438fdd36aa81e3f15287f9d14` |
| `build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk` | 2026-08-27 22:18:33 | 18,601,894 | `e97b63ee6f2e9949e915a6014d31c95c90995a7acdbd04395295d7736616aede` |
| `build/app/outputs/flutter-apk/app-x86_64-production-release.apk` | 2026-08-27 22:18:34 | 20,020,086 | `059ec12a3513461ff8229943168d1eef102df7fe6a4e4aef0f06566461fca8f3` |
| `build/app/outputs/bundle/productionRelease/app-production-release.aab` | 2026-08-27 22:19:06 | **50,659,286** | `6f4f6ae7540ac9b80868ba98be9dfc1c6725db5e2bb5400a6f3e56aca1cb1636` |

The final post-identity AAB value above supersedes the earlier phase values
50,618,821 and 50,618,560 bytes. The last comparable retained pre-identity
dependency-hardening artifacts were Universal 49,913,424 and AAB 50,651,242
bytes. Identity/native-resource work therefore added 8,072 bytes (0.01617%) to
Universal and 8,044 bytes (0.01588%) to AAB. Against the historical 52,046,296-
byte Universal, the final artifact is 2,124,800 bytes smaller (4.08252%), but
that historical comparison uses different Dart-symbol packaging and is not
presented as a pure widget/identity saving.

Release APKs are `com.flutter.newproject`, `Flutter Base`, target API 36,
minimum API 24 and non-debuggable. The AAB manifest has the same package,
`com.flutter.newproject.MainActivity`, `LaunchTheme`, `@mipmap/ic_launcher` and
no debuggable attribute. The Universal APK contains ARM32, ARM64 and x86_64.
R8/resource shrinking is configured and the release mapping is nonempty.

## 15. Symbols, mappings and packaging

| Evidence | Bytes | SHA-256 |
| --- | ---: | --- |
| `build/app/outputs/mapping/productionRelease/mapping.txt` | 25,724,248 | `162acbd8207144f8c7c2f6b7ba4e3ea52953712bb8d220c34f33555c51185f18` |
| `build/app/outputs/native-debug-symbols/productionRelease/native-debug-symbols.zip` | 133,759,971 | `de2f195823e0c8d3eb39a0d1c4e7191236be05880fe0ebebe8bece8dc2e8d69a` |
| `build/symbols/production/app.android-arm.symbols` | 1,907,728 | `7779fcc6673242e80082c2b477c999c4441a08f939868a57f93b76dc91dd717f` |
| `build/symbols/production/app.android-arm64.symbols` | 2,237,016 | `b6cc38bb5d3713fdcf6a22ad73c355a397a450c1f06b6484cf573a1ed7738a9e` |
| `build/symbols/production/app.android-x64.symbols` | 2,237,720 | `ba2ba8cff2950ac5c43319aa49eb5bfc5f4020310b1385f1bea07c0c845134e3` |

The external native archive contains 14 unstripped `.so` files under ABI-
qualified `lib/` paths. The AAB separately contains nine compressed native
symbol-table entries in `BUNDLE-METADATA`; those entries are genuinely inside
the AAB. The full native archive, external Dart `.symbols` files and external
R8 mapping remain separate files beside the store artifact.

## 16. Identity, isolation and credential inspection

- APK/AAB entry scans, Universal DEX package inspection and the root dependency
  graph found no Firebase, Maps, WebView, Socket, notifications or Remote Config
  concrete integration in Root.
- APK/AAB decompressed-string scans found no old Awamer/I Craft identity, old
  package IDs/imports, Google API-key pattern, Firebase app-ID pattern or private
  key marker.
- Release resource tables contain neutral launcher resources and Launch/Normal
  themes; visual captures confirm the neutral light/dark launch mark.
- Every retained iOS app has the expected bundle ID/display name, compiled
  `LaunchScreen.storyboardc`, two compiled AppIcon files, no LaunchImage, no real
  Firebase file, no Maps-key pattern and no old identity.
- Source/native templates contain no Apple Team assignment or real optional-
  service configuration.

## 17. Android and iOS launch evidence

The unsigned reusable release artifact was not altered. A separate debug-key-
signed smoke copy was created outside the project and verified with APK v2/v3.

| Runtime | Result |
| --- | --- |
| Samsung SM-A235F, API 34, unlocked | cold release launch passed; light and dark native visuals captured; controlled startup error shown; double Retry, background/resume and Back passed; zero fatal lines |
| Android ARM64 Emulator, API 36 | cold release launch passed; controlled startup error shown; double Retry passed; zero fatal lines |
| iPhone 16 Pro Simulator, iOS 18.4 | all three flavors installed/launched; development showed controlled authentication-required state; staging/production showed controlled startup state; zero Runner fatal/crash events |
| iOS production light/dark | native LaunchScreen captured with centered neutral mark and correct light/dark background |

Evidence is stored outside the project under the task work directory, including
Samsung light/dark videos/frames, Samsung and API-36 first-route screenshots,
iOS flavor screenshots and production light/dark launch videos/frames. No claim
is made for signed physical iOS or App Store execution.

## 18. Disk recovery and quality-gate hardening

The initial read-only check found 17.34 GiB free, so no deletion was initially
required. The first full matrix expanded root Android/iOS intermediates and
Gradle caches until iOS failed with 240 MiB free. Project-local cleanup was then
proven insufficient. Removed items were reproducible only: root `build`, root
`.dart_tool/flutter_build`/`hooks_runner`, optional-example build output,
target-related Runner DerivedData, incomplete release staging directories and
the Gradle 9.3.1 version cache generated by optional-example builds. The unique
pre-rename archive, source, reports, final screenshots, final APK/AAB, Dart
symbols, native symbols and R8 mapping are preserved.

Temporary failed-attempt evidence directories were removed only after their
contents were superseded by a later clean build; they are not authoritative
artifacts. The final artifacts above are checksum-backed. Disk after the
successful gate was 4.1 GiB free; a later non-authoritative optional runtime
rebuild attempt recreated Gradle cache and was stopped/cleaned, leaving about
1.7 GiB. The successful optional builds/tests from the gate remain authoritative;
no live Maps/Firebase service success is claimed.

Exact reproducible paths removed during recovery (some were recreated and
removed more than once between failed attempts) were:

- `/Users/abdelrahamndandash/StudioProjects/flutter_base/build` (only incomplete
  attempts; the final checksum-backed `build` evidence was restored and kept);
- `/Users/abdelrahamndandash/StudioProjects/flutter_base/.dart_tool/flutter_build`;
- `/Users/abdelrahamndandash/StudioProjects/flutter_base/.dart_tool/hooks_runner`;
- `packages/app_maps/example/build` and its generated `android/.gradle/9.3.1`;
- `packages/app_remote_config/example/build`;
- `packages/app_webview/example/build`;
- `/Users/abdelrahamndandash/Library/Developer/Xcode/DerivedData/Runner-ecgbggnutcwtlqarkbhbavlusgtp`;
- `/Users/abdelrahamndandash/.gradle/caches/9.3.1` after local cleanup was
  measured and proved insufficient; this version cache is reproducible;
- `/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/first_failed_release_evidence-20260827`;
- incomplete `flutter-base-release-stage.9tLNuy`, `.Mb8YTP`, `.GI9e66` and
  `.CoWnOO` directories under the task-specific macOS temporary directory.

No source, unique recovery archive, final report, final artifact, final symbol,
R8 mapping or final visual evidence was deleted. The required pre-rename archive
and its SHA-256 remain unchanged.

The gate now stages each Android artifact immediately, clears only allowlisted
reproducible intermediates between flavors/platforms, preserves each iOS app,
forces fresh Dart symbol generation, creates an external native-symbol archive,
and uses ARM64-only debug build checks while retaining all release ABIs. This
eliminates the verified peak-disk regression without changing product behavior.

## 19. Commands executed in the final verification

Material commands included:

```bash
flutter pub get                         # root, optional packages and examples
dart run build_runner build
dart run tool/generate_locale_keys.dart
scripts/check_project_identity.sh
scripts/flutter_quality_gate.sh release --build
apkanalyzer manifest ...
apkanalyzer resources ...
apkanalyzer dex packages ...
bundletool dump manifest --bundle=... --module=base
shasum -a 256 <each artifact/symbol file>
apksigner verify ...
apksigner sign ... --out <external-smoke-copy> <ARM64-release>
adb install / am start / screencap / screenrecord / logcat / uimode
xcrun simctl boot / install / launch / screenshot / recordVideo / log show
```

All Flutter commands used the SDK selected by `android/local.properties`
(Flutter 3.47.1, Dart 3.13.1). No dependency upgrade command was run. The only
intentional project-file changes in this final verification are
`scripts/flutter_quality_gate.sh` and this report. A temporary native-symbol
Gradle experiment was reverted byte-for-byte; `android/app/build.gradle.kts`
matches its pre-experiment SHA-256
`5636ca48e971d7a8074a0a09ba1f28678820e87938ef1392be0f4d7fda10534f`.

## 20. Remaining application-specific gates

- Replace neutral identity/design/store records for the real product.
- Configure protected Android/iOS signing and CI secret injection.
- Supply authorized backend environments and real test accounts.
- Create per-flavor Firebase/APNs projects and restricted Maps keys.
- Complete live Maps, Firebase, notification, backend and deep-link testing.
- Complete physical iOS release/archive/App Store verification.
- Complete product privacy, Data Safety, licenses, accessibility and store review.
- Track Flutter's Built-in Kotlin migration and Maps iOS SwiftPM support before
  the future toolchain versions make those warnings errors.

## 21. Reference-project, Git and freeze confirmation

Rahoul and every project other than `flutter_base` remained read-only. No build,
format, generation, migration or configuration command was executed in them.
No secret/config content was copied. **No Git command was performed and no Git
state was created or modified.**

Final reusable-baseline verdict: **Reusable baseline frozen**.
Overall production classification: **Conditionally production-ready**.
