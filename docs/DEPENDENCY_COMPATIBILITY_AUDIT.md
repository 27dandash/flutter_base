# Dependency and toolchain compatibility audit

Audit date: 2026-08-27; Apple build integration revalidated 2026-10-02.
`Latest` is the stable Pub result observed on the original audit date. A
matching `Current / latest / compatible` value is abbreviated as `same`. SDK
packages follow Flutter 3.47.1. This is point-in-time evidence; resolution alone
was not accepted as compatibility proof.

## Toolchain

| Tool | Before | After / selected | Decision |
|---|---:|---:|---|
| Flutter | 3.47.1 stable | 3.47.1 stable | Already the latest stable verified through the official archive/release sources |
| Dart / DevTools | 3.13.1 / 2.60.0 | Same | Bundled with selected Flutter |
| Java | 17.0.15 shell; 17.0.12 Gradle daemon | Same | Supported by the current Android graph |
| Gradle / AGP | 9.1.0 / 9.0.1 | Same | Current project-compatible release pair |
| Kotlin plugin | 2.3.20 | Same | Retained until the app and every plugin can migrate together to AGP built-in Kotlin |
| Android SDK | compile 36, target 36, minimum 24 | Same | Current local/store-facing baseline |
| Android NDK | 28.2.13676358 | Same | Resolved native-plugin baseline |
| Xcode / Swift | 26.6 (17F113) / 6.3.3 | Same | Current installed stable toolchain |
| CocoaPods | 1.16.2 | Same, unused by the root targets | iOS and macOS use Flutter Swift Package Manager; no root Podfiles |
| iOS minimum | 15.0 | Same | Current reusable-base deployment floor |
| macOS minimum | 10.15 | 12.0 | Flutter 3.47 migration baseline; debug and release builds verified with SwiftPM |

The only unresolved toolchain warning is Flutter's future built-in-Kotlin
migration notice. Enabling it now would be a speculative partial migration:
the app and plugin build graph still apply the Kotlin Gradle Plugin. The safe
future plan is to migrate the app following Flutter/AGP guidance, verify every
plugin under the embedded Kotlin version, then run the complete Android build
and device matrix before removing the plugin declaration.

## Root production dependencies

| Dependency | Current | Latest | Compatible | Selected | Scope | Native | Decision / reason |
|---|---:|---:|---:|---:|---|---|---|
| dio | 5.11.0 | same | same | 5.11.0 | root | No | Retain; typed HTTP stack and live-socket tests pass |
| crypto | 3.0.7 | same | same | 3.0.7 | root | No | Retain; SHA-256 pin fingerprints |
| cryptography | 2.9.0 | same | same | 2.9.0 | root | No | Retain; maintained AES-256-GCM primitive |
| dio_cache_interceptor | 3.5.1 | 4.0.7 | 4.0.7 | 3.5.1 | root | No | Blocked by breaking hit/cache API; requires a dedicated cache-behavior migration |
| hive_ce | 2.19.3 | same | same | 2.19.3 | root | No | Retain; storage/offline queue |
| hive_ce_flutter | 2.3.4 | same | same | 2.3.4 | root | Yes | Retain with Hive initialization |
| connectivity_plus | 7.3.1 | same | same | 7.3.1 | root | Yes | Retain as reachability signal, never Internet proof |
| intl | 0.20.3 | same | same | 0.20.3 | root | No | Retain; Flutter localization-compatible pin |
| easy_localization | 3.0.8 | same | same | 3.0.8 | root | No | Retain; runtime AR/EN switching |
| image_picker | 1.2.3 | same | same | 1.2.3 | root | Yes | Retain behind injectable picker contract |
| file_picker | 12.1.1 | same | same | 12.1.1 | root | Yes | Retain reusable document selection |
| image_cropper | 11.0.0 | 12.2.1 | 12.2.1 | 11.0.0 | root | Yes | Compatibility pin; 12.x conflicts with the current SwiftPM/TOCrop graph |
| flutter_html | 3.0.0 | same | same | 3.0.0 | root | No | Retain while the sanitized rich-text widget is public |
| video_player | 2.14.0 | same | same | 2.14.0 | root | Yes | Retain for canonical optional-video media contract |
| cached_network_image | 3.4.1 | same | same | 3.4.1 | root | Yes | Retain for canonical image cache/loading contract |
| flutter_screenutil | 5.9.3 | same | same | 5.9.3 | root | No | Compatibility surface; deliberate migration only |
| flutter_secure_storage | 10.3.1 | 11.0.0 | 11.0.0 | 10.3.1 | root | Yes | Security migration deferred: 11.x raises Android requirements and persisted-data migration risk |
| equatable | 2.1.0 | same | same | 2.1.0 | root | No | Retain state/value equality |
| flutter_bloc | 9.1.1 | same | same | 9.1.1 | root | No | Architecture standard |
| get_it | 9.2.1 | same | same | 9.2.1 | root | No | Composition boundary only |
| injectable | 3.0.0 | same | same | 3.0.0 | root | No | Reproducible DI graph |
| flutter_svg | 2.3.0 | same | same | 2.3.0 | root | No | Trusted bundled vectors |
| lottie | 3.5.1 | same | same | 3.5.1 | root | No | Retained reachable shared animation capability |
| flutter_animate | 4.5.2 | same | same | 4.5.2 | root | No | Bounded shared transitions |
| skeletonizer | 2.1.3 | same | same | 2.1.3 | root | No | Canonical skeleton state |
| share_plus | 13.3.0 | same | same | 13.3.0 | root | Yes | System share adapter |
| url_launcher | 6.3.2 | same | same | 6.3.2 | root | Yes | Validated external-link adapter |
| rxdart | 0.28.0 | same | same | 0.28.0 | root | No | Existing debounce/stream contracts |
| uuid | 4.6.0 | same | same | 4.6.0 | root | No | Idempotency/queue identifiers |
| dartz | 0.10.1 | same | same | 0.10.1 | root | No | Retain public typed-result compatibility; migrate only as a breaking change |

## Optional production packages

| Dependency | Current/latest/compatible/selected | Scope | Native | Decision |
|---|---:|---|---|---|
| geolocator | 14.0.3 | app_maps | Yes | Latest; optional only |
| google_maps_flutter | 2.18.0 | app_maps | Yes | Latest; optional only |
| firebase_messaging | 16.7.0 | app_notifications | Yes | Replaces Awesome Notifications; SwiftPM-capable; optional only |
| flutter_local_notifications | 19.5.0 | app_notifications | Yes | Foreground display; SwiftPM-capable; optional only |
| firebase_core | 4.15.0 | app_notifications | Yes | Required by firebase_messaging; optional only |
| firebase_core | 4.14.0 | app_remote_config | Yes | Latest; optional only |
| firebase_remote_config | 6.6.0 | app_remote_config | Yes | Latest; optional only |
| socket_io_client | 3.1.6 | app_socket | No | Latest; optional only |
| webview_flutter | 4.14.1 | app_webview | Yes | Latest; optional only |

Every optional package also uses the selected Flutter SDK and
`flutter_lints 6.0.0`/`flutter_test` for development. Root Pub, registrant,
Gradle, APK, DEX and AAB isolation checks remain the authority for zero-byte
absence.

## Development and generation dependencies

| Dependency | Current | Latest | Compatible | Selected | Decision / reason |
|---|---:|---:|---:|---:|---|
| flutter_test | SDK | SDK | SDK | SDK | Tooling-only |
| integration_test | SDK | SDK | SDK | SDK | Added for device/simulator harnesses; tooling-only |
| image_picker_platform_interface | 2.11.1 | same | same | 2.11.1 | Picker service fakes/tests only |
| mocktail | 1.0.4 | same | same | 1.0.4 | Tests only |
| bloc_test | 10.0.0 | same | same | 10.0.0 | Tests only |
| build_runner | 2.15.1 | 2.16.0 | 2.15.1 | 2.15.1 | Current generator/analyzer graph cannot resolve 2.16.0 |
| flutter_gen_runner | 5.15.0 | same | same | 5.15.0 | Generation only; upgraded |
| injectable_generator | 3.1.3 | same | same | 3.1.3 | Generation only; upgraded |
| hive_ce_generator | 1.11.2 | 1.11.3 | 1.11.2 | 1.11.2 | Current graph cannot resolve 1.11.3 |
| flutter_lints | 6.0.0 | same | same | 6.0.0 | Analysis only |
| http_mock_adapter | 0.6.1 | same | same | 0.6.1 | Tests only |

## Resolution changes and security/license result

`flutter pub upgrade` changed 48 compatible resolved versions and the new
integration harness added six Flutter-driver transitive packages. No root
production constraint was broadened blindly. Notable generator upgrades were
Analyzer 10.0.1→12.1.0, FlutterGen 5.14.1→5.15.0 and Injectable Generator
3.0.2→3.1.3; generated output is checked in an isolated temporary directory.

An OSV `querybatch` covered all 222 resolved hosted packages and returned zero
known vulnerability records. This is not a guarantee of absence and must be
repeated in CI. Resolved production licenses remain permissive
(BSD-style/MIT/Apache-2.0); optional packages retain their upstream licenses
and are application opt-ins whose store/privacy/license review belongs to the
consuming app. No dependency override is present and no credential or private
registry is required.

## Migrations performed

- Re-generated Injectable with `TokenStorage` owned by a module provider,
  eliminating the unregistered-dependency warning while preserving singleton
  identity.
- Replaced the obsolete build-runner flag with the supported build command.
- Added deterministic project-local AR/EN locale-key generation and a clean
  checksum-based reproducibility gate.
- Retained the three breaking production pins rather than treating compilation
  as migration proof.
