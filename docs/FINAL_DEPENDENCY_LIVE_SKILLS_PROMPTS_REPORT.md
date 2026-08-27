# Final dependency, live-runtime, skills and prompt-system report

Date: 2026-08-27

## Readiness verdict

**Conditionally production-ready and suitable to freeze as the reusable
baseline.** All safe local work in this phase is complete. The Clean
Architecture/BLoC/GetIt/Injectable/router identity, canonical widget surface,
compatibility paths and optional-package isolation remain intact.

The classification cannot become Production-ready for a derived product until
that product supplies and verifies real API/TLS configuration, signing,
Firebase/APNs/Maps as applicable, store/privacy metadata, a physical iOS device
matrix and unlocked physical-Android end-to-end journeys.

## Important runtime regression found and fixed

The new full-base device smoke found a real first-route crash that isolated
widget tests did not expose. `bootstrap.dart` imported
`FadeAnimationOptions` through an uppercase URI while the router imported the
same file through a lowercase URI. On a case-insensitive filesystem Dart loaded
two incompatible library identities and threw a runtime type cast.

The bootstrap import now uses the canonical lowercase identity. A source-level
architecture regression test rejects noncanonical navigation import segments,
and the complete bootstrap/unknown-route smoke now passes on Android and iOS.
The pre-fix bootstrap file is recoverable at:

`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/navigation-case-fix-20260827-152023`

## Toolchain and dependency result

The toolchain remained Flutter 3.47.1 stable / Dart 3.13.1 because it was
already the newest verified stable compatible baseline. Java 17, Gradle 9.1.0,
AGP 9.0.1, Kotlin plugin 2.3.20, compile/target SDK 36, minimum SDK 24, Xcode
26.6, Swift 6.3.3 and iOS 15 remain mutually buildable.

Forty-eight compatible resolved Pub packages were upgraded. Six dev-only
Flutter-driver packages entered through the new SDK `integration_test`
dependency. Three production pins remain deliberate:

- `dio_cache_interceptor 3.5.1`: 4.x has a breaking cache/hit API.
- `image_cropper 11.0.0`: 12.x conflicts with the current SwiftPM/TOCrop graph.
- `flutter_secure_storage 10.3.1`: 11.x changes Android requirements and needs
  a persisted-storage migration exercise.

Build Runner 2.15.1 and Hive CE Generator 1.11.2 are the latest versions the
current generator graph can resolve. There is no dependency override. The
complete per-direct-dependency table is in
`docs/DEPENDENCY_COMPATIBILITY_AUDIT.md`.

OSV `querybatch` checked all **222 resolved hosted packages** and returned
**zero known advisories** at the audit time. Root production licenses remain
permissive BSD-style/MIT/Apache-2.0. This is point-in-time evidence, not a
guarantee; derived-project CI must repeat vulnerability and license review.

The remaining tool warning is Flutter's future AGP built-in-Kotlin migration.
A partial conversion was rejected: app and plugins still apply the Kotlin
Gradle Plugin. The migration must be done atomically and re-run through this
same Android/device matrix.

## Code generation

- Injectable now owns `TokenStorage` through a module provider; static and DI
  identity tests pass and the unregistered-dependency warning is gone.
- The obsolete `--delete-conflicting-outputs` flag was removed because Build
  Runner 2.15 no longer accepts/needs it.
- `tool/generate_locale_keys.dart` deterministically generates the 83 camelCase
  AR/EN translated getters expected by this base. The generic
  Easy Localization generator was not retained because it produced an
  incompatible API and broke 141 references.
- `scripts/check_codegen_reproducibility.sh` rebuilds in a temporary copy and
  checksum-compares Injectable, Hive CE, FlutterGen and locale output. It
  passed without changing the source tree.

## Live widget and complete-base evidence

| Target | Harness | Result | What is actually proven |
|---|---|---|---|
| Android 16 emulator | Widget gallery | 1/1 pass | Real taps, repeated submission, theme/locale switch, RTL, text focus/Tab, dropdown, dialog, sheet, snackbar, overlay, media failure and Back |
| Android 16 clean temporary emulator | Full-base bootstrap | 1/1 pass | Real startup, secure-storage anonymous restore, stable session route, unknown route, return without black screen or uncaught Flutter error |
| iOS 26.5 Simulator | Widget gallery | 1/1 pass | Same canonical interaction journey on the iOS runtime |
| iOS 26.5 Simulator | Full-base bootstrap | 1/1 pass | Startup/session/unknown-route journey on the iOS runtime |
| Android 16 emulator | Release-compiled smoke | Pass | Temporarily QA-signed copy cold-started, displayed controlled bilingual missing-production-config state, survived HOME/resume and double Retry; zero fatal markers |
| Samsung SM-A235F/API 34 | Full-base integration attempt | Blocked | Device was connected but keyguard/NotificationShade locked; secure storage timed out and the test was stopped rather than called a pass |

The temporary Android AVD was created from the already-installed API 36 image
because the two existing AVDs had insufficient free data space for the 128 MB
debug integration APK. It was deleted after the successful smoke. No existing
AVD/app data was erased. The production APK remains unsigned and unmodified;
the ephemeral QA key and signed copy were deleted.

The gallery is external at `tool/widget_gallery/main.dart`; it is not reachable
from any production entry point. Maps and WebView have key/network-free example
applications inside their optional packages. Picker cancellation uses an
injectable fake in the gallery, so native camera/crop/lost-activity behavior is
not falsely reported as live.

## Live networking evidence

Six behavior-focused tests use a real local `HttpServer`, actual TCP sockets
and Dio's IO adapter—no production backend and no mocked transport. They cover:

- JSON, empty, text content type and redirect responses.
- 400, 401, 403, 404, 409, 422, 429, 500, 502 and 503 typed mapping.
- malformed JSON, a 256 KiB response and slow streaming.
- timeout, connection refusal and cancellation.
- idempotent GET retry versus no unsafe POST replay.
- concurrent requests and multipart upload.

Raw server text is retained only as technical metadata; localized safe failure
keys are the user-facing output. Concurrent-401 single refresh, refresh
success/failure, logout/account switch, encrypted queue/replay/corruption,
redaction, PHP on/off and session routing remain strongly covered by existing
unit/integration-policy tests, but are not mislabeled as live real-backend
journeys.

## Exact test and quality-gate totals

| Suite | Passed | Skipped | Counting note |
|---|---:|---:|---|
| Root/default | 226 | 2 | Includes the six local-socket tests and 61 focused widget tests |
| Focused reusable-widget subset | 61 | 0 | Subset of the 226, not additional |
| PHP inverse configuration | 15 | 3 | Opposite compile-time branch; reported separately, not added to root count |
| Optional packages | 32 | 0 | Notifications 9, Remote Config 4, WebView 6, Maps 7, Socket 6 |
| Optional Maps/WebView examples | 2 | 0 | 1 each; package-owned safe-state examples |
| Device/simulator integration | 4 | 0 | Gallery + full base on Android and iOS; not part of root 226 |

Root line coverage is **2470/4069 = 60.70%**. The prior 61-widget-test number
remains a subset. Coverage is behavior evidence, not a production-readiness
claim by itself.

Quality gate results:

- `quick`: passed 8 checks, 0 skipped.
- `full`: passed 24 checks, 0 skipped.
- `release --build`: passed 36 checks, 0 skipped, complete build matrix.

## Build and artifact matrix

Android development, staging and production debug APKs passed. The production
Universal APK, all three ABI splits and AAB passed with external Dart symbols.
iOS development, staging and production Simulator builds passed. R8 mapping
was produced, `debuggable=false`, there is one `classes.dex`, Material Icons
were 99.9% tree-shaken and Universal entry isolation passed.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Universal production APK | 49,913,424 | `cc308d0aadbdcab4723a991fa660c3640708ea1d496da97e54221d0bc79492b2` |
| ARM32 split | 15,838,606 | `814b77496a181404f0ac00e288b982045440c274db9b2f31471f93e07f5725eb` |
| ARM64 split | 18,593,822 | `41e924320dd6488926eba4d6c290fcb89df53950dfa331288eee5b80d323c37f` |
| x86_64 split | 20,012,014 | `6f13514752d3b2539ebce192616b67c9adf79e77e39613160382fcaaee865e33` |
| Production AAB | 50,651,242 | `5232545e2ae7cb223aa1635f38374331d9fc90f74e80485125ef8751d5c538b9` |

The comparable post-widget artifacts used the same external-symbol packaging.
The Universal changed +29,484 bytes (+0.0591%) and AAB +32,421 (+0.0641%) after
dependency/source hardening. The earlier 50,618,821-byte AAB remains the
authoritative post-widget baseline; 50,651,242 is the authoritative artifact
after this phase. The unsupported 50,618,560 value remains superseded.

ARM64 (18,593,822 < 19,340,398), AAB (50,651,242 < 51,666,803) and source assets
(2,056,847 < 2,100,000) pass their existing evidence-based budgets. Root Pub,
registrant and APK-entry searches show zero Firebase/notifications/Maps/WebView/
Socket concrete integration.

## Skills and instructions

Every former project-local skill/rule was audited individually. The 29 Claude
skills and 29 Cursor rules were highly duplicated and contained stale SDK,
widget, notification-root and nonexistent-script claims. None was deleted:
they were moved to dated inactive reference directories and backed up outside
the project.

Active discoverable surface now consists of:

- `AGENTS.md` and `.codex/skills/flutter-base-production/SKILL.md` for Codex.
- root `CLAUDE.md` and `.claude/skills/flutter-base-production/SKILL.md` for Claude.
- `.cursor/rules/00-flutter-base-production.mdc` for Cursor.

`scripts/validate_agent_instructions.sh` proves there is exactly one active
tool surface for each tool, 29+29 archived legacy files, real referenced
scripts, no personal path/credential/stale claim and a valid prompt library.
`docs/AGENT_INSTRUCTIONS_AUDIT.md` records all 29 individual decisions and
precedence.

## Reusable prompt system

`docs/prompts/` contains 29 files: one authoritative specification, index,
selection/variables/workflow guides, six topology examples and **18 adapters**
(six families × Codex/Cursor/Claude). All eight required placeholders occur in
every adapter. The validator passed.

The shared spec handles one app, multiple roles, arbitrary app/flavor counts,
white label, shared/separate backends, one/multiple Figma files/collections,
AR/EN, RTL/LTR, light/dark, Android/iOS and debug/release. The six families are
design creation, design review, pre-implementation collection review,
collection completeness proof, live Figma/API comparison and final production
readiness.

Tool differences are intentional:

- Codex adapters require `AGENTS.md`, repository skills, progress commentary,
  exact tool evidence and mandatory Figma skill loading before Figma calls.
- Cursor adapters require repository indexing, Agent mode, a plan before
  material edits, terminal evidence and manual checkpoints when external tools
  are unavailable.
- Claude adapters require `CLAUDE.md`, a persistent task ledger, concise
  checkpoints and strict separation of executed evidence from recommendations.

No adapter assumes exactly two apps/roles, fabricates APIs or claims unavailable
Figma/device/backend access.

## Target files changed

No widget redesign or architecture replacement was performed. The phase touched
only these target-owned surfaces:

- Dependency/generation: `pubspec.yaml`, `pubspec.lock`,
  `lib/src/core/shared/service_locators/setup_service_locators.dart`, its
  generated config, `lib/src/config/language/locale_keys.g.dart`, FlutterGen
  asset/font outputs, `tool/generate_locale_keys.dart`,
  `scripts/check_codegen_reproducibility.sh`.
- Runtime safety: `lib/bootstrap/bootstrap.dart`, network failure/exception
  mapping, `lib/src/core/session/session_failure_coordinator.dart`, their tests,
  `test/architecture/module_boundaries_test.dart`,
  `test/integration/live_http_stack_test.dart`.
- Live harnesses: `tool/widget_gallery/main.dart`, both files under
  `integration_test/`, Maps/WebView `example/` files and those package READMEs.
- Tooling: `Makefile`, `README.md`, `AGENTS.md`, `CLAUDE.md`, active Codex/
  Claude/Cursor skill/rule files, `md/CLAUDE.md`,
  `md/HOW_TO_USE_PROMPTS.md`, `scripts/flutter_quality_gate.sh`,
  `scripts/check_optional_resolution.sh`, both instruction/prompt validators.
- Documentation: `docs/DEPENDENCY_AUDIT.md`,
  `docs/DEPENDENCY_COMPATIBILITY_AUDIT.md`,
  `docs/AGENT_INSTRUCTIONS_AUDIT.md`, `docs/SIZE_AUDIT.md`, this report,
  command log, and all 29 files listed by `docs/prompts/README.md`.
- Historical moves: the exact old Claude/Cursor files listed row-by-row in
  `docs/AGENT_INSTRUCTIONS_AUDIT.md` now live under
  `.claude/reference/skills-legacy-2026-08/` and
  `.cursor/reference/{rules-legacy-2026-08,prompts-legacy-2026-08}/`.

Recoverable external backups were created for dependency/lockfiles, DI,
localization generation, integration harness setup, raw-message safety, agent
instructions, tooling consistency and the navigation case fix under:

`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/`

No source/widget/asset was deleted in this phase. Generated `build/` and
`.dart_tool/` were cleaned once to recover disk space and then completely
reproduced by the final matrix.

## Remaining external gates

- Production API URL, two real TLS pins and real auth/account-switch/block/
  activation/delete flows.
- Android/iOS production signing and store-delivered install.
- Firebase/APNs, Maps, WebView, Socket and Remote Config only when selected by
  a real product.
- Unlocked Samsung/physical-Android native picker/crop/media/background QA.
- Physical iOS device, archive/export, app thinning and notification delivery.
- App-specific privacy manifests/Data Safety, legal copy, accessibility audit,
  performance budgets, crash/symbol provider upload and store review.

No Git command was executed. No reference project was modified.
