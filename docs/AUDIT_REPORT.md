# Final production-base audit

Audit reproduced and extended: 2026-08-27. Base: supplied local tree corresponding to upstream
`main` at the start of the work. No Git repository was initialized and no
commit/push was made. The `rahoul` and `herajone` reference projects were not
modified.

## Verdict

**Conditionally production-ready.** The root and all optional packages resolve,
analyze, test, and build under the pinned Flutter 3.47.1 / Dart 3.13.1 toolchain.
The binary-size anomaly is explained byte-for-byte and materially reduced. This
is still a reusable template, not a signed store product.

| Area | Result |
| --- | --- |
| Size | ARM64 distribution APK 18,816,110; AAB 50,618,227; representative Play download 9,247,946 bytes |
| Optimization | -2,725,888 ARM64 APK and -4,496,394 AAB versus supplied baseline, with functionality retained |
| Optional isolation | Firebase/notifications, Remote Config, WebView, Maps and Socket contribute zero to root artifacts |
| Architecture | Domain/optional boundaries are now executable tests; startup/session/security policies remain intact |
| Assets | Explicit 16-file manifest, 2,037,307 source bytes, no duplicate hash, missing/key-parity tests |
| Android | R8/resource shrinking, non-debuggable production, ABI splits, AAB and external symbols verified |
| iOS | Simulator flavor builds are valid compile checks; signed archive/thinning/download size is blocked |
| Product release | Blocked by real IDs/signing/backend/TLS rotation/Firebase/APNs/Maps/deep links/privacy/store/device QA |

## Findings fixed

- Upgraded `file_picker` from 10.3.10 to 12.1.1 and migrated its API, removing
  Apache Tika from Android DEX/resources and resolving the optional Maps
  package's `win32` constraint.
- Upgraded `share_plus` to 13.3.0 for the current built-in-Kotlin-compatible
  plugin line.
- Replaced directory-wide assets with explicit runtime files; removed 28
  verified-unused/duplicate files and regenerated `AppAssets`.
- Added executable root/domain/optional boundary checks, missing-asset and
  Arabic/English translation-key parity checks.
- Added root-plus-each-optional resolution checks, measured size budgets,
  ABI-split distribution builds, and CI retention of Dart/R8/native symbols.
- Added the detailed size report, missing-standards ownership map, ADRs, and
  product customization/upgrade/removal instructions.
- Added redacted network/Bloc diagnostics, latest-result-wins async state,
  hardened pagination and retryable paginated dropdown behavior.
- Added `AppButton`, scoped blocking overlay state, tests for accessibility,
  duplicate submission, cancellation, concurrency, thrown calls and disposal.
- Added the recurrence inventory, reusable catalog, exact test reconciliation,
  dependency/license/OSV audit and a validated repository-local Codex skill.

No security or maintained dependency was removed solely for size. Lottie is the
largest reachable non-framework Dart package at 362,490 decompressed AOT bytes,
but it powers intentional shared state UI and was retained. Secure storage,
authenticated cryptography, networking, session cleanup, media acquisition and
optional source packages were retained.

## Evidence map

- `SIZE_AUDIT.md`: matched minimal control, exact artifact/components,
  dependency-by-dependency attribution, optional increments, bundletool device
  estimate, budgets, commands, symbol policy and iOS limitation.
- `STANDARDS_AUDIT.md`: every requested architecture, release, security,
  reliability, performance, accessibility, localization, design, testing,
  observability and platform capability classified by owner/status.
- `RELEASE_CHECKLIST.md`: reproducible commands, release/symbol/rollback and
  blocked inputs.
- `QA_MATRIX.md`: automated and manual/device requirements traceability.
- `CHANGE_MANIFEST.md`: edited, added and removed paths.
- `CROSS_PROJECT_RECURRENCE.md`, `REUSABLE_COMPONENT_CATALOG.md`,
  `TEST_COUNT_RECONCILIATION.md`, `DEPENDENCY_AUDIT.md` and
  `CODEX_INSTRUCTIONS_AUDIT.md`: reuse/discovery/test/dependency evidence.

## Remaining warnings and blocks

Flutter reports that the app plus `image_picker_android`,
`shared_preferences_android`, and `url_launcher_android` still apply the Kotlin
Gradle Plugin. It is not suppressed: this exact stack builds, but a coordinated
Built-in Kotlin migration remains future work as upstream plugins permit.

Production needs approved identifiers, signing stored outside source, real
backend and overlapping TLS pins, privacy/data-safety declarations, Firebase/
APNs and Maps configuration if enabled, deep-link association, crash-provider
consent and symbol upload, store exports, and representative physical-device
journeys. The controlled startup failure with placeholder production config is
expected behavior, not a release-ready product launch.
