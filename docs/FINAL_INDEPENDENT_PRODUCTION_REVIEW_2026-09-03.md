# Final independent production review

Evidence date: 2026-09-03. Target: `flutter_base` only. This report supersedes
test counts in older phase reports, but it does not relabel old artifacts as
current builds.

## 1. Executive summary

The base remains **Conditionally production-ready**. The independent review
found two release-gating account-boundary races and one persistence-consistency
gap. Codex reproduced the control-flow defects, implemented session-generation
guards, cancelled stale offline/network/socket work, made token-pair persistence
single-record and serialized, and added negative regression tests. Notification
debug output and bilingual action labels were also hardened.

The final non-build release gate passed all 29 checks with 237 root tests, 53
optional-package tests and three optional-example tests. Fresh Android debug,
Universal/split release APKs, AAB, all three root iOS Simulator flavors and the
required optional examples were built. The current ARM64 release-code path was
also smoke-tested on the connected Samsung API 34 device with successful cold
and warm launches and no fatal Flutter/Android log marker.

The monolithic `release --build` invocation is not reported as one successful
command: it initially stopped during optional Maps iOS because the data volume
filled. After safe build-cache cleanup, Maps iOS passed independently. Remote
Config iOS completed Xcode compilation and produced a valid universal
`Runner.app`, but Flutter's post-build `rsync` copy then failed for the same disk
reason. This is an environmental wrapper failure, not claimed as a fully passed
Flutter command. Subject to the application-specific gates listed below, this
base is suitable to freeze as the reusable baseline.

## 2. Delegation-skill evidence

The installed `cursor-delegate` and `claude-delegate` skills and every directly
required reference were read before invocation. Provider reviews used the
skill-owned relay, read-only mode and raw output under
`/tmp/flutter-base-final-audit.rw4aqL/`, outside the repository. Codex alone
edited the worktree. Authentication was checked without retaining private
account fields.

Cursor could not begin a review: the installed relay adds `--trust`, while the
installed Cursor Agent 2026.01.28 rejects it as an unknown option. One
deterministic attempt was sufficient; the other two Cursor model passes were
skipped rather than wasting quota. Claude Opus completed. Two distinct/smaller
Claude Sonnet instruction audits exhausted their turn limits without a final
report, so neither is counted as completed evidence.

## 3. Provider/model matrix

| Provider | Model | Scope | Authenticated | Started | Completed | Raw findings | Codex confirmed | False positives checked | Accepted |
| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| Cursor Agent | `composer-2.5` | Architecture/network | Yes | Yes | No: CLI flag incompatibility | 0 | 0 | 0 | 0 |
| Cursor Agent | `cursor-grok-4.6-low` | Widgets/prompts | Yes | Skipped after deterministic blocker | No | 0 | 0 | 0 | 0 |
| Cursor Agent | `auto` | Adversarial final pass | Yes | Skipped after deterministic blocker | No | 0 | 0 | 0 | 0 |
| Claude Code | Opus (resolved by provider as Opus 4.8) | Auth/session/offline architecture | Yes | Yes | Yes, 38 turns | 7 | 5 | 3 | 5 |
| Claude Code | Sonnet | Prompt/skill audit | Yes | Yes | No: max turns | 0 usable | 0 | 0 | 0 |
| Claude Code | Sonnet | Reduced prompt/skill retry | Yes | Yes | No: max turns | 0 usable | 0 | 0 | 0 |
| Codex | Current task model | Consolidation, reproduction, implementation, tests | Yes | Yes | Yes | 7 normalized | 5 | 3 | 5 |

Provider statistics: four calls attempted, one succeeded and three failed; three
conditional passes were skipped. Attempt wall time was about 22 minutes. There
was one usable reviewer report with seven normalized findings. There can be no
honest cross-provider voting or agreement statistic when Cursor never executed;
decisions were made from source evidence and Codex reproduction instead.

The first Sonnet relay marked already-dirty files as a possible read-only
violation. Its permitted tool surface was only Read/Glob/Grep and the same files
had already been changed by Codex. No delegated edit was found. The smaller
retry also reported no attributable violation.

## 4. Reviewer comparison

Claude uniquely identified the missing session-generation boundary. Codex
confirmed the refresh, offline replay and token persistence paths directly and
extended the same invariant to active requests and sockets. No Cursor comparison
was possible due to the deterministic CLI mismatch. The result is therefore a
multi-provider attempt with one completed external reviewer, not a fabricated
multi-provider consensus.

## 5. Verified findings

| ID | Severity | Finding | Decision / evidence |
| --- | --- | --- | --- |
| F1 | High | A delayed refresh could save old tokens and retry after logout/account switch | Confirmed and fixed with captured monotonic session generations, per-generation single-flight refresh and stale-request cancellation |
| F2 | High | An in-memory offline replay could continue old-owner writes with a new user's token | Confirmed and fixed with owner/generation checks around every await plus cancellation/invalidation |
| F3 | Medium | Two separately persisted tokens and memory-first mutation allowed partial state | Confirmed and fixed with one versioned encrypted record, serialized mutations, fail-closed memory and legacy migration |
| F4 | Medium | Negative race/storage tests were missing | Confirmed; nine root assertions plus four optional-package assertions were added |
| F5 | Low | Refresh did not inherit the request language despite a source comment | Confirmed; `Accept-Language` is explicitly forwarded to the isolated refresh client |
| F6 | Low | Navigation coalescing might discard a second different target in one frame | Not reproduced; current termination single-flight prevents the proposed normal path. No speculative state machine added |
| F7 | Info | Arbitrary one-shot request bodies are not generally replayable | True as a constraint, but current root request APIs produce replayable JSON/FormData. Kept documented rather than adding a broad cloning framework |

## 6. False positives

Three reviewer hypotheses were explicitly rejected: route state does not remain
stuck after re-login; the certificate validator still enforces pins for normally
trusted certificates; and logout without a different login does not replay an
old queue successfully. Startup ordering between persistence and session
restoration also converges through the existing guarded queue activation.

## 7. Implemented improvements

- `TokenStorage` now stores a versioned access/refresh pair in one encrypted
  record, serializes mutations, migrates legacy keys and exposes conditional
  generation-safe save/clear operations.
- `AuthInterceptor` records session ownership on every authenticated request,
  rejects stale results as cancellation, refreshes once per generation and
  cannot log out or overwrite a newer account.
- Session termination cancels active remote-source requests before cleanup.
- Offline synchronization reserves its worker before the reachability await,
  rechecks owner/generation at each asynchronous boundary and cancels stale work.
- Socket authentication/network/lifecycle changes detach in-flight connections;
  stale transports cannot publish state or schedule reconnects.
- Notification logs no longer expose raw exceptions or common payload/identity
  fields; call action labels have explicit Arabic and English parity.

## 8. Rejected recommendations

No architecture replacement, Router migration, generic request-body cloner,
new integration, dependency upgrade, widget redesign or additional wrapper was
accepted. Retry-After/jitter remains a product policy decision: current retries
are bounded and limited to idempotent reads, and no verified defect justified
changing timing semantics in this review.

## 9. Architecture result

Clean Architecture boundaries, BLoC/Cubit, GetIt/Injectable composition,
Navigator named routes and feature ownership remain intact. Root has no concrete
Firebase, notifications, Maps, WebView or Socket dependency. Session generation
is owned by credential storage and consumed at the network boundary, avoiding
global mutable user models or cross-feature imports.

Known deliberate debt remains: broad compatibility exports under `core/widgets`,
the small service-locator composition boundary and named-route placeholders.
None is a release defect for the reusable base.

## 10. Feature inventory

Root retains startup coordination, environment/flavor validation, typed Dio
errors, refresh tokens, retry/cancellation, encrypted owner-scoped offline queue,
secure token/user storage, runtime AR/EN localization and RTL, routing/session
cleanup, the canonical widget system, media/picker contracts and test tooling.

Notifications, Remote Config, WebView, Maps and Socket remain independent
packages. Analytics, crash reporting and real service wiring remain injectable
or product-owned. No existing generic capability or public widget was removed.

## 11. Widget and live-gallery result

The canonical surface remains `AppButton`, `DefaultTextField`, `AppDropdown`,
`AppStateView`, `AppMedia`, `AppImagePickerField`, `AppPageShell`, async and
pagination presenters, context-owned dialogs/sheets/messages and compatibility
adapters. The 62 focused widget tests are a subset of the 237 root tests.

No widget changed in this review. Historical Android/iOS gallery journeys remain
documented. A current root release-code smoke on the physical Samsung verified
the controlled bilingual missing-production-configuration state and Retry
action, with no black screen or infinite splash. This was not a complete gallery
or TalkBack/VoiceOver journey, and no virtual device was started.

## 12. Dio/network result

The root still has six real loopback-HTTP tests covering response types,
status mapping, malformed/large/slow bodies, timeout/refusal/cancellation,
idempotent retry, concurrency and multipart upload. These are included in the
root total. Production endpoints were not called. Raw backend strings remain
technical metadata rather than user-facing copy.

## 13. Refresh-token/session result

Refresh-token support is present and now session-bound. A request captures the
credential generation before transport; refresh save, retry, response delivery
and auth-failure cleanup all verify it. Logout/account switch synchronously
invalidates the generation and cancels active remote requests. Regression tests
prove delayed refresh and delayed success cannot cross the boundary.

Remaining product gates are real token rotation/revocation semantics, backend
idempotency, blocked/activation/account-deletion responses and real multi-account
journeys.

## 14. Optional-package result

All five packages analyzed and tested independently in the completed final gate:
Notifications 16, Remote Config 16, WebView 6, Maps 7 and Socket 8. WebView,
Maps and Remote Config examples each passed one test. Root Pub dependency
isolation passed. The current Universal APK entry check also passed: no concrete
Firebase, Notifications, Maps, WebView or Socket integration entered the root
artifact.

## 15. Prompt audit

The active library remains 18 adapters: six lifecycle families for each of
Codex, Cursor and Claude. Shared normative behavior lives in
`docs/prompts/AUTHORITATIVE_SPEC.md`; tool adapters intentionally differ in
their planning, checkpoint and tool-availability requirements. Validation
passed. No prompt was added, removed or changed in this review.

## 16. Skill audit

The discoverable project-local surface remains one production skill/rule per
tool: Codex, Claude and Cursor. Twenty-nine former Claude skills and 29 Cursor
rules are preserved under inactive dated references. The active files refer to
real scripts including `scripts/flutter_quality_gate.sh`; the instruction
validator passed. No global skill was modified.

## 17. Prompt-to-skill matrix

| Prompt family | Codex | Cursor | Claude | Intentionally excluded |
| --- | --- | --- | --- | --- |
| Design creation/review | Project skill + Figma prerequisite when used | Active project rule | Project skill | Device/release skills unless implementation begins |
| API collection/completeness | Project skill and contract-first checks | Active project rule | Project skill | Figma when no design evidence exists |
| Live implementation comparison | Project skill; Figma/device skills only when applicable | Active project rule + manual fallback | Project skill + explicit evidence ledger | Optional integrations not selected by product |
| Production readiness | Project skill + quality/device gate as applicable | Active project rule | Project skill | No skill is forced merely because it exists |

## 18. Test and coverage result

| Suite | Pass | Skip | Counting rule |
| --- | ---: | ---: | --- |
| Root/default | 237 | 2 | Includes 62 widget and six loopback-network tests |
| PHP inverse | 15 | 3 | Only two OFF-only assertions are distinct from root |
| Optional packages | 53 | 0 | 16 + 16 + 6 + 7 + 8 |
| Optional examples | 3 | 0 | WebView + Maps + Remote Config |
| Non-double-counted total | 295 | 2 default + 3 inverse-branch selectors | 237 + 2 inverse-only + 53 + 3 |

Root coverage is 2,609/4,228 lines = **61.71%**, the authoritative final
snapshot. Before this review the first quick gate had 228 root passes; the review
added nine root assertions. Optional Notifications and Socket each added two
behavior tests. No regression test was removed.

Completed verification: formatting (307 files, zero changes), root analyzer,
237-test full root run/coverage, PHP inverse, root isolation, reproducible
generation, five optional analyzers/tests, three optional-example
analyzers/tests, release size budgets and Universal APK optional-integration
isolation. The authoritative final non-build command reported:
`QUALITY GATE PASSED: mode=release checks=29 skipped=0 builds=0`.

## 19. Dependency and toolchain result

No dependency or lockfile changed. Direct packages requiring planned decisions
are `cached_network_image` 4.x, `dio_cache_interceptor` 4.x, `file_picker`
12.2, `image_cropper` 12.x and `flutter_secure_storage` 11.x. Breaking native,
cache and persisted-data changes were not mixed into this review.

Toolchain: Flutter 3.47.1 stable, Dart 3.13.1, Java 17.0.15 ARM64, AGP 9.0.1,
Gradle 9.1.0, Kotlin plugin 2.3.20, Xcode 26.6, Swift 6.3.3 and CocoaPods
1.16.2. Flutter 3.47 warns that legacy KGP support is temporary. An isolated
built-in-Kotlin migration was attempted according to the
[official Flutter guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers),
but both packaging and compile-only validation ran out of disk. It was reverted
without Git so the last fully proven Android configuration remains active.

## 20. Build/device matrix

| Target | Current-review result |
| --- | --- |
| Android development/staging/production debug | Passed for all three flavors |
| Universal/split APK/AAB | Universal, ARM32, ARM64, x86_64 and production AAB passed |
| iOS three root Simulator flavors | Passed; apps preserved as verified ZIP archives |
| Optional Maps Android/iOS | Passed independently |
| Optional Remote Config Android | Passed |
| Optional Remote Config iOS | Xcode compilation passed and produced a valid universal app; Flutter wrapper failed during post-build `rsync` because disk filled |
| Android physical Samsung ARM64/API 34 | Passed release-code cold/warm smoke; 1,397 ms cold and 222 ms hot launch |
| Android emulator / iOS Simulator boot | Not authorized in this task; none started |

The physical smoke used an unchanged copy of the unsigned ARM64 release APK,
locally QA-signed with the machine's debug key. It installed without deleting
app data; the process stayed alive and top-resumed, and PID-filtered logcat had
no `AndroidRuntime` or Flutter error marker. This does not replace production
signing or full real-service/device QA.

## 21. Artifact sizes and SHA-256

Fresh current artifacts are retained with the following exact sizes and hashes:

| Current artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Universal APK | 49,921,496 | `6aa42e0cb54087535e262189c163e3312094ee704e29f4ad69ff1f32425639a6` |
| ARM32 split | 15,846,674 | `4868c427e3fc9ef036220f58f61480767b509ced3873f558f5c9eddf1a222f5e` |
| ARM64 split | 18,601,894 | `21b52e1d5a90fbb5a74e8b0e01243bd7d404396b7c31332c678e3c2387adb0c9` |
| x86_64 split | 20,020,086 | `09dece176ff3240d8b099e8dedaf1b16b4e40630bdf4351559436327111a2277` |
| Production AAB | 50,694,841 | `42dd442d8d7d8974f2d810bccfc6a8f65b5d346a6bb5d8fe06c05056c9ad5543` |
| R8 mapping | 25,724,248 | `162acbd8207144f8c7c2f6b7ba4e3ea52953712bb8d220c34f33555c51185f18` |
| Native symbols ZIP | 133,788,125 | `51b4eda4016c9d5ea7bd3b21df3c5721023ab727689d463fe76710df2434524a` |

The current Universal APK has exactly the same byte size as the comparable
2026-08-31 symbol-packaging baseline, so measured Universal impact is **0
bytes**; the differing checksum is expected from rebuilt content/metadata. The
AAB increased from 50,659,286 to 50,694,841 bytes: **35,555 bytes (0.07018%)**.
ARM64 and AAB both pass their 19,340,398- and 51,666,803-byte budgets; source
assets are 2,038,407 bytes against 2,100,000. The older 52,046,296-byte
Universal measurement used different symbol-packaging conditions and is not a
like-for-like optimization baseline.

External Dart symbols are retained for ARM (1,913,236 bytes), ARM64 (2,245,096)
and x64 (2,244,648). Verified root iOS Simulator app archives are retained under
`build/post_identity_ios/` for development (62,620,412), staging (62,620,524)
and production (62,620,347 bytes).

## 22. Files changed

Runtime/source:

- `lib/src/core/network/auth/token_storage.dart`
- `lib/src/core/network/interceptors/auth_interceptor.dart`
- `lib/src/core/network/offline/offline_queue_manager.dart`
- `lib/src/core/network/options/request_extra.dart`
- `lib/src/core/shared/cubits/user_cubit/user_cubit.dart`
- `packages/app_notifications/lib/src/notification_controller.dart`
- `packages/app_socket/lib/src/generic_socket_client.dart`

Tests/documentation:

- `test/core/network/auth/token_storage_test.dart`
- `test/core/network/dio_network_audit_test.dart`
- `packages/app_socket/test/generic_socket_client_test.dart`
- `packages/app_notifications/test/notification_logging_test.dart` (new)
- `packages/app_notifications/NOTIFICATION_GUIDE.md`
- `docs/QA_MATRIX.md`
- `docs/TEST_COUNT_RECONCILIATION.md`
- `docs/DEPENDENCY_AUDIT.md`
- this report

No file, asset or API was removed; no dependency changed and no API was
deprecated. New public testing/session primitives are `TokenStorageBackend`,
`TokenStorage.forTesting`, `sessionGeneration`, `saveIfCurrent` and
`clearIfCurrent`. The final runtime-and-test diff is 954 added and 202 removed
lines across 11 files. Including documentation and this report, the complete
worktree change is 1,402 added and 228 removed lines across 16 files.

Recoverable backups are outside build directories at:

- `/tmp/flutter-base-final-audit.rw4aqL/backups/lib/src/core/network/auth/token_storage.dart`
- `/tmp/flutter-base-final-audit.rw4aqL/backups/lib/src/core/network/interceptors/auth_interceptor.dart`
- `/tmp/flutter-base-final-audit.rw4aqL/backups/android-kotlin-migration/`

## 23. Commands executed

Material commands (all from the target root unless noted):

```text
git status --short --branch
git rev-parse HEAD
git rev-list --left-right --count origin/main...HEAD
cursor-agent --version
cursor-agent status
claude --version
claude auth status
<delegation relay> --tool cursor-agent --model composer-2.5 --read-only ...
<delegation relay> --tool claude --model opus --effort high --read-only ...
<delegation relay> --tool claude --model sonnet --effort high --read-only ...
flutter pub get
flutter pub outdated --no-dev-dependencies
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
flutter test --no-pub test/core/network/auth/token_storage_test.dart test/core/network/dio_network_audit_test.dart test/core/network/php/php_envelope_test.dart
flutter analyze --no-pub
flutter test --no-pub --coverage --reporter=compact
flutter test --no-pub --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart
flutter test integration_test/live_http_stack_test.dart
flutter test test/core/widgets --no-pub --reporter=compact
flutter pub get / flutter analyze --no-pub / flutter test --no-pub in each optional package and required example
scripts/flutter_quality_gate.sh release --build
scripts/flutter_quality_gate.sh release
flutter build apk --debug --flavor development -t lib/main_development.dart --target-platform android-arm64
cd android && ./gradlew :app:compileDevelopmentDebugKotlin --no-daemon
flutter devices --machine
python3 /Users/abdelrahamndandash/.codex/skills/flutter-device-guard/scripts/device_lease.py --device auto -- <stateful device command>
dart format --output=none --set-exit-if-changed ...
git diff --check
```

The `git` commands above were read-only inspection only. No commit, branch,
checkout, restore, reset, clean, stash, pull, push or remote mutation occurred.

## 24. Remaining warnings

- Low free-disk headroom interrupted the monolithic build gate and Flutter's
  final Remote Config iOS copy step. Future complete release runs should start
  with sufficient space even though the root matrix and remaining checks were
  completed independently.
- Flutter's legacy-KGP compatibility warning remains; migration must be atomic
  across the app and every plugin and verified by the full Android matrix.
- Production signing, API/TLS pins, backend accounts, Firebase/APNs, restricted
  Maps keys, store delivery, privacy declarations, crash-symbol upload and real
  service journeys remain application-specific gates.
- Physical iOS and complete Android lifecycle/accessibility/picker/media/network
  journeys remain unverified for this exact diff.
- Cursor delegation requires a relay/CLI compatibility update before it can be
  counted as an independent provider review.

## 25. Final verdict

**Conditionally production-ready and suitable to freeze as the reusable
baseline.** No known reproducible session-boundary, offline-owner,
socket-lifecycle or notification-redaction defect remains in the verified
scenarios. Current release artifacts, budgets, root optional isolation and a
physical Samsung release-code smoke passed. There is no claim of zero future
crashes or that production signing, external services, store distribution and
complete physical accessibility/lifecycle QA are already approved.
