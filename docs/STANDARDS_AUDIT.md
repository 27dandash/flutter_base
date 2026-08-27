# Missing-standards audit and ownership map

Audit updated: 2026-08-27. The classification prevents a reusable base from
silently becoming a product. `Root` means every consumer benefits without a
vendor SDK. `Optional` means an independently opted-in package. `Template`
means policy/checklist/code seam only. `Product` needs an approved business or
privacy decision. `Blocked` needs credentials, services, signing, stores, or
physical devices.

## Architecture and maintainability

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Enforced domain/module direction and no optional root imports | Root; `test/architecture/module_boundaries_test.dart` scans domain imports, root source, and root `pubspec` | Implemented |
| No cross-feature imports | Root policy in `AGENTS.md`; only the demo feature exists, so a multi-feature enforcement rule would currently be vacuous | Policy; extend test when second feature lands |
| DI lifetimes and no global mutable business/UI state | Root; constructor injection is required inside features, GetIt is limited to composition/legacy boundaries; blocking UI state is instance-owned; startup/session concurrency has tests | Implemented foundation; full generated lifetime graph test remains useful debt |
| Code generation reproducibility | Root; generated files are checked output, exact SDK constraints are recorded, build-runner command documented | Implemented; current analyzer-generator language warning is upstream/tooling debt |
| Upgrade and template customization | Template; `TEMPLATE_CUSTOMIZATION.md`, lockfile policy, migration gates | Implemented |
| ADRs for optional native integrations and symbols | Template; `docs/adr/0001-*` and `0002-*` | Implemented |
| Safe optional removal | Template; optional packages are path-isolated, root resolution is tested, and removal steps are documented | Implemented |

The root remains deliberately pragmatic: Navigator 1, a broad legacy shared
widget folder, and a small service-locator boundary are documented debt, not a
reason to perform a destabilizing rewrite.

## Release engineering

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Reproducible build environment | Root/CI; Flutter 3.47.1, Dart floor, lockfiles, Java 17, AGP/Gradle/Kotlin documented | Implemented locally; containerized bit-for-bit builds not claimed |
| Version strategy | Template; semantic `versionName` plus monotonically increasing build number, flavor suffixes only outside production | Documented |
| Flavor signing separation | Product; base is intentionally unsigned and stores no keys | Blocked by product signing owner |
| Environment validation and no debug production config | Root; production rejects placeholder/non-HTTPS endpoint and invalid/tied pins; release is non-debuggable | Automated |
| CI cache safety | Template; Flutter action cache is version-keyed; dependency lockfiles are retained; no credential-containing build cache | Implemented policy |
| Artifact names, symbols, mappings | CI; SHA-keyed artifact, Dart symbols, R8 mapping, native symbols, APK/AAB | Implemented with 90-day CI retention; long-term storage is product-owned |
| Rollback/internal testing/store release | Product/template checklist; preserve previous signed artifact/config, phased internal testing before promotion | Documented; execution blocked |
| Dependency lock policy | Root; commit root and optional lockfiles, update deliberately, run full graph/build matrix | Implemented |
| Size regressions | Root CI script with evidence-based ARM64/AAB/assets budgets | Implemented |

The remaining Flutter Built-in Kotlin warning is not hidden: the app plus
`image_picker_android`, `shared_preferences_android`, and
`url_launcher_android` still apply KGP. It builds on the specified SDK but is a
future migration gate.

## Security and privacy

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Secrets and rotation | Root policy rejects secrets; configuration contains public endpoint/pins only. Backend, signing, Firebase/APNs and Maps rotation owners are product-specific | Root policy implemented; real rotation blocked |
| Logging/redaction | Root diagnostics are debug-only and structurally omit URL/path/query/header/body/error text; Bloc logs contain types, not state/event values | Implemented and regression-tested |
| Timeouts/retry/idempotency | Root Dio/startup policy; bounded retries for safe/idempotent operations only, UUID operation identifiers, synchronized token refresh | Implemented and tested |
| Certificate pin rotation | Root requires distinct primary/backup exact-host SHA-256 pins and validity checks | Policy tested; live chain/rotation blocked |
| Secure-storage/database migration and corruption | Root AES-GCM owner-scoped queue, fail-closed legacy/corrupt record handling; product databases own schema migrations | Root behavior tested; device invalidation/restore blocked |
| Root/jailbreak | Documentation only; local encryption is not represented as protection against a fully compromised device | Documented |
| Screenshot/clipboard | Product; enable per sensitive screen after UX/legal decision, not globally in a generic base | Intentionally excluded |
| PII classes, retention, deletion | Template contracts and session cleanup hooks; exact categories/retention/legal basis are product-specific | Foundation present; product register blocked |
| iOS privacy manifest/required-reason APIs and Android Data Safety | Product plus third-party inventory; declarations depend on enabled SDKs and actual data use | Blocked until product integration |
| License and SDK inventory | `DEPENDENCY_AUDIT.md` records every direct resolved dependency and local license; Pub/Gradle graphs are reproducible | Implemented baseline; signed SBOM attestation remains CI-org work |
| Vulnerability scanning | Root direct Pub versions queried through OSV batch API; zero known records at audit time | Point-in-time implemented; repeat in CI and review transitives/native SDKs |
| Device/token backend contract | Optional notifications guide separates installation ID, FCM token, user ID, platform and backend record | Foundation implemented; live backend blocked |

## Reliability

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Global error boundaries | Root `runZonedGuarded`, Flutter error reporting and release `ErrorWidget` fallback | Implemented |
| No infinite startup waits | Root critical/non-blocking/optional/deferred coordinator with timeouts and once-only futures | Tested |
| Offline, retry, idempotency, concurrent requests | Root queue/cache/retry/auth refresh coordination | Tested locally; backend semantics blocked |
| Secure-store/cache corruption and migrations | Root fail-closed queue and cleanup; generic product DB migrations do not belong in root | Root tested; product-specific |
| Low storage/memory pressure | Product/device; root avoids unbounded startup and infinite skeletons, but OS fault injection is not automatable here | Blocked physical QA |
| Lifecycle/process death/restoration | Root/optional seams exist; Android picker lost-data handling and optional socket/notification policies are tested in isolation | Physical journey blocked |
| Clock/timezone changes | Root uses locale-aware `intl`; business deadlines and server-clock contracts are product rules | Product-specific |
| Pagination/duplicate requests | Root paginated Cubit prevents duplicates/stale results, maps throws, restores cancellation and ignores completion after disposal | Implemented and unit-tested; feature-specific integration tests required |

## Performance

No universal millisecond or memory number is defensible for an empty template on
one host. The root supplies bounded startup and image/list primitives; product
CI must establish cold/warm start, splash, frame/jank, memory, image cache,
large-list, network, battery, and background budgets on its supported device
matrix. DevTools CPU/memory/network/performance profiling and profile/release
benchmarks are **Blocked pending a real product flow and representative devices**.
Size budgets are the only performance budgets that are evidence-based at the
base level and are enforced now.

## Accessibility and localization

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Tap targets, semantics, focus, screen reader | `AppButton` variants pass Flutter Android/labeled tap-target guidelines; shared fields/dropdown expose semantics | Automated foundation present; TalkBack/VoiceOver device audit blocked |
| Contrast, large text, bold text, reduced motion, color-safe state | Design-system/product themes; base supports themes/text scale but cannot approve product colors/animation policy | Product/device validation blocked |
| Keyboard/focus order | Root for shared forms where applicable; desktop/web behavior is product platform scope | Partial |
| RTL accessibility | Root directional APIs and AR/EN widget coverage | Automated foundation; screen-reader device pass blocked |
| AR/EN completeness and missing keys | Root explicit translation files; exact key parity test | Implemented |
| Runtime locale and RTL/LTR | Root EasyLocalization source of truth and widget tests | Implemented |
| Plurals, dates, numbers, currencies, zones, mixed direction | Root `intl` foundation; actual copy/data formats depend on product requirements | Foundation; product cases required |
| Backend errors | Root typed/localizable failure mapping; raw backend errors are not a user-message contract | Implemented policy; endpoint mapping is product work |

Golden suites were not invented for placeholder screens. Accessibility
guidelines are automated for the reusable button contract and should expand
with stable product screens with approved copy, fonts,
contrast, text scaling, and semantics expectations.

## Design system

The root already provides standard fields, confirmation-based dropdown sheet,
an approved `AppButton` variant family, dialogs, state/error/empty views, skeleton/pagination primitives,
responsive tokens, light/dark themes, validation patterns, and repository-local
reuse instructions. Arabic/English, RTL/LTR, theme and shared-widget tests exist.
A comprehensive widget catalog/Previewer is useful once product visual tokens
are approved; creating a second documentation UI inside an empty base is not a
runtime requirement and is classified **Template/product-specific**.

## Testing and observability

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Unit/state/repository/widget/network/security tests | Root and five optional packages | Implemented and passing |
| Router/flavor/release smoke tests | Root routing policy/widget tests plus Android/iOS build matrix | Local automated portion implemented |
| Integration and physical-device matrix | Product endpoints, permissions, camera/crop, auth, process death, accessibility | Blocked inputs/devices |
| Golden tests | Product design approval and stable rendering environment | Intentionally deferred |
| Migration tests | Root queue legacy/corruption; product DB schemas add their own | Root portion implemented |
| Fixture policy/flaky detection | Template: deterministic fakes, no production credentials/network; CI reruns must investigate rather than mask flakes | Documented |
| Traceability | `QA_MATRIX.md` | Implemented |
| Crash/nonfatal reporting | Root callback/error seams; provider must be opt-in and non-blocking | Optional/product; provider blocked |
| Structured secure logs/breadcrumbs | Root redaction policy and Flutter error context | Foundation; provider-specific sink blocked |
| Version/build/flavor/platform context | Root environment metadata available at composition boundary | Foundation |
| Performance monitoring and consent | Optional/product; must not initialize before consent or block startup | Intentionally not bundled |
| Request correlation IDs | Backend/product contract; Dio interceptors provide insertion seam | Blocked contract |
| Symbol upload/symbolication | CI archives all symbol forms; provider upload needs credentials | Archive implemented; upload blocked |

All observability providers must be replaceable/disabled without startup
failure. The base therefore exposes policy and hooks but contains no analytics or
crash vendor SDK.

## Platform readiness

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Android API/R8/edge-to-edge/predictive Back | Root current Flutter templates, `PopScope`, minify/resource shrink release builds | Builds pass; minimum/current device behavior blocked |
| Permissions and Photo Picker | Root picker flow with no broad storage permission | Static/release verified; physical allow/deny/process-death blocked |
| Notifications/APNs/background states/channels | Optional notifications package plus product config | Package tests pass; Firebase/APNs/device blocked |
| Deep/App/Universal Links | Product domains, association files, route matrix | Intentionally excluded/blocked |
| iOS scenes/lifecycle/privacy | Root SceneDelegate and simulator builds; declarations depend on actual product APIs | Simulator passed; signed/device/privacy review blocked |
| Google Maps restrictions | Optional package; keys/billing/quotas belong to product | Package tests pass; live service blocked |
| WebView security | Optional HTTPS/host/scheme/navigation policy | Tests pass; real host/download/SSL journeys blocked |
| Background modes | Product only when genuinely needed | No unnecessary mode enabled |
| iOS archive/app thinning | Product signing/export | Blocked |

## Implemented in this audit

- Removed Tika through maintained plugin upgrades and adapted the picker API.
- Proved every optional dependency graph resolves with the root and still adds
  zero code until opted in.
- Removed verified-unused/duplicate assets and made declarations explicit.
- Added missing-asset/translation-parity and architecture-boundary tests.
- Added measured size budgets, external symbol retention, ABI-split release
  artifacts, and optional-resolution CI checks.
- Added size evidence, ADRs, upgrade/customization/removal instructions, and
  explicit classification of missing standards.
- Added a Codex-discoverable project skill, reusable catalog and cross-project
  recurrence/test-count evidence.
- Replaced value/payload diagnostics with structural redaction, removed the
  logger dependency, scoped blocking UI state, and hardened async/pagination/
  dropdown concurrency, retry, cancellation and disposal behavior.

## Readiness

The base remains **Conditionally production-ready**. There is no locally
reproducible analyzer, test, dependency-resolution, or Android release blocker.
It cannot become “Production-ready” until a consuming app supplies and verifies
identities, signing, backend/TLS rotation, privacy declarations, Firebase/APNs,
Maps/deep links, observability consent and symbols, stores, and the physical
device/accessibility/performance matrix.
