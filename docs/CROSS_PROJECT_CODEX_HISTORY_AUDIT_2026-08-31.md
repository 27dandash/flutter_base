# Cross-project Codex history audit — 2026-08-31

## Scope and evidence rules

This audit compares recurring Flutter engineering failures found in accessible
Codex history and project-local evidence with the current `flutter_base`.
Only `flutter_base` was writable. Every reference project, transcript, report,
worksheet, screenshot and video was inspected read-only. No historical agent
statement is treated as proof unless it is supported by source, a report with
executed evidence, a retained artifact, or a reproducible check.

Evidence grades used below:

- **A — executed:** retained command/device output or a current reproducible
  check.
- **B — inspected:** complete source/report/worksheet or retained visual
  evidence was inspected, but not rerun in its source project.
- **C — historical claim:** a transcript reports a result without sufficient
  retained independent evidence.
- **D — insufficient:** request-only, incomplete, duplicated recovery material,
  or unrelated evidence.

Secrets, credentials, private endpoints, signing material, user identifiers and
proprietary business data were deliberately excluded from this document.

## Evidence-source inventory

| Evidence family | Inventoried | Useful scope | Limits |
| --- | ---: | --- | --- |
| Current Codex transcripts | 44 physical JSONL files / 43 session IDs | 28 primary sessions, 8 explicitly tagged sub-agent sessions and 7 auxiliary `exec` sessions | Some early sessions contain no assistant result; transcript text alone is grade C |
| Recovery archive | 78 JSONL-like files / 29 session IDs | 20 overlap current history; 9 are recovery-only | Multiple forensic/reconstructed copies exist; the 9 recovery-only sessions are not promoted above grade C without corroboration |
| Union of accessible session IDs | 52 | Per-session ledger below | This is the accessible local set, not a claim that no other historical chat ever existed |
| Flutter project roots under `StudioProjects` | 18, including the target | 17 read-only references plus `flutter_base` | Builds, dependency resolution, formatting and generation were not run in references |
| Substantive Flutter reports | 37 after deduplicating copied base snapshots | 13 Codex/output reports and 24 project-local reports | Report assertions retain their reported evidence grade |
| Structured sheets | 2 XLSX workbooks | 46 Devixia issue rows and 15 bidi/render cases | Web-only findings are not automatically Flutter-base findings |
| Endpoint inventory | 1 CSV | 82 collection endpoints and example/completeness metadata | No live backend call was made |
| Historical runtime screenshots | 18 unique hashes | Android/iOS startup, light/dark and flavor identity states | Historical visual evidence; not current device execution |
| Historical runtime videos | 4 MP4 files | iOS light/dark and Samsung light/dark launch sequences | Metadata and retained extracted frame sequences were reviewed; this is not a new playback/device run |

The source-project inventory covered `Basiet`, `Mawahib_AlSaudi`,
`Migraf_Egazat`, `alsafaclub`, `anaammakkah`, `herajnokba`, `herajone`,
`matyah`, `moshafy`, `nahtadi`, `rahoul`, `rcjy_app`, `saudi_medbridge`,
`servena`, `sofra`, `uumarket`, and the older
`flutter_clean_arch_base`. Generated folders, caches, Pods, SDKs and archives
were excluded from source recurrence scans.

## Chat/task review ledger

The short session prefix is sufficient to distinguish the local records. Rows
marked “corroboration” were auxiliary analyses of a parent task and are not
double-counted as independent project recurrence.

### Primary/current sessions

| Session | Scope | Evidence | Reusable decision |
| --- | --- | --- | --- |
| `019ddd55-f0c` | servena | B/C | Media decode/viewer memory safety; compare with canonical `AppMedia` |
| `019dddf4-ea0` | rahoul | B/C | Broad widget, networking, release and design patterns; adopt only independently recurring contracts |
| `019ddf3f-564` | rcjy_app | D | Request-only/incomplete; inventory only |
| `019de041-417` | kayan | D | Insufficient assistant evidence; inventory only |
| `019df899-1c8` | local MCP task | D | Non-product tooling; excluded from Flutter recurrence |
| `019e2054-14c` | Mawahib_AlSaudi | B/C | Cross-platform/release and reusable UI evidence |
| `019e828b-c3c` | sofra | B | Mock/session leakage, API parsing and DI-lifetime regressions |
| `019e9dec-091` | Basiet | B | Media/card layout and safe parsing evidence |
| `019ec241-1f3` | older Flutter base | B/C | Historical foundation evidence; current base source wins |
| `019ec242-627` | matyah | B | Startup, cancellation and lifecycle failures |
| `019f461e-726` | uumarket | B/C | Release/API/UI evidence; only corroborated items retained |
| `019f6514-12f` | multi-project design/API work | B/C | Evidence-method and Figma/API workflow lessons |
| `019f7b0c-e93` | Devixia QA | B | Structured accessibility, state, routing and responsive findings |
| `019f9d4d-4ca` | short local task | D | Insufficient evidence |
| `019f9f29-51f` | Al Safa implementation/audit | B | State contracts, fake-data prohibition, API drift and release gates |
| `019fa5d3-5e9` | Anaam | B | Design-size, temporary assets, lifecycle, native plugin and accessibility regressions |
| `019fa81a-2be` | Herajnokba | B | Overflow, provider context, modal failure, socket and empty-layout regressions |
| `019fc25a-0db` | Saudi Medbridge | C | Limited project evidence; no new root contract |
| `019fc25a-900` | Herajone | B/C | Backend TLS outage versus client terminal-error-state ownership |
| `019ff120-06e` | Codex-history recovery | B/C | Recovery provenance and missing-history limits only |
| `01a02f06-e56` | local Codex tooling | D | Unrelated to reusable Flutter runtime |
| `01a03073-d44` | Flutter/release review | B/C | Corroborating release and architecture evidence |
| `01a0330b-f15` | local Codex task | D | No reusable Flutter finding established |
| `01a03e0a-4fb` | local instructions/skills review | B/C | Instruction consistency evidence |
| `01a03e1c-a52` | current base hardening lineage | A/B | Current implementation, test, size and release baseline |
| `01a04367-410` | GitHub profile work | D | Non-Flutter; excluded |
| `01a0451e-011` | Arnon design discovery | B | Figma readiness, asset provenance and state-inventory guidance |
| `01a053c1-ea4` | short archived task | D | Insufficient evidence |

### Auxiliary and explicitly tagged sub-agent sessions

| Session(s) | Parent scope | Evidence | Decision |
| --- | --- | --- | --- |
| `01a00600-927`, `01a0097c-235`, `01a00a16-7e6`, `01a014d3-cd2` | Multi-project/design review | C | Corroboration only; do not count as separate recurrence |
| `01a0193a-13e`, `01a01956-2ce`, `01a019cc-18f` | rahoul, Mawahib and sofra review | C | Corroboration only |
| `01a00eac-bfa` | Herajnokba parent task | C | Spawned review; corroboration only |
| `01a00977-00f`, `01a009a7-b5a`, `01a009ac-6ac`, `01a009c2-4e3`, `01a009c6-a0e`, `01a00ebb-2a5`, `01a00ed5-4f2` | Herajnokba auxiliary executions | B/C | Use only where the parent report or source confirms the finding |

### Recovery-only session IDs

| Session | Scope | Evidence | Decision |
| --- | --- | --- | --- |
| `019dfddf-b29` | Migraf_Egazat | C | Large archived record; API/client lessons require source/report corroboration |
| `019e8288-eff` | multi-flavor/auth task | C | Historical architecture evidence only |
| `019eca41-2e9` | Migraf collection review | C | Collection completeness guidance; no endpoint copied |
| `019ed461-ed1` | matyah | C | Corroborates current Matyah evidence only |
| `019f5bfc-982` | Basiet | C | Corroborates current Basiet evidence only |
| `019f5fd4-7ee` | unrelated model/tool task | D | Excluded |
| `019f6229-e5c` | Sonar/tooling task | D | Excluded from runtime recurrence |
| `019f83ea-095` | uumarket | C | Corroborates current UUMarket evidence only |
| `019ff11e-975` | history recovery controller | B/C | Provenance and inventory support; no runtime finding |

## Normalized recurring-failure taxonomy

Recurrence counts are conservative project/evidence-family counts, not raw
keyword hits or duplicated transcript counts.

| Rank | Failure class | Confirmed/corroborated evidence | Severity | Current base status |
| ---: | --- | --- | --- | --- |
| 1 | Malformed, empty or shape-changing API responses | Sofra, Al Safa, Anaam, Herajnokba, Migraf collection | Critical | Covered by typed failures, safe parsing and remote-source tests; prompt gap remained |
| 2 | Async callback/timer/plugin completion after disposal | Anaam, Matyah, media reviews | Critical | Covered across async state, media and picker tests |
| 3 | Startup blocked by optional network/Firebase/Remote Config work | Matyah, Anaam, Al Safa | Critical | Covered by `StartupCoordinator` timeout/fallback and optional packages |
| 4 | Fake/cache/static fallback concealing backend or session failure | Sofra, Al Safa, Anaam | Critical | Explicitly forbidden and covered by session/cache boundaries |
| 5 | Stale session or wrong DI lifetime leaking state/account data | Sofra, Devixia, auth reviews | Critical | Covered by scoped cleanup, `UserCubit`, refresh synchronization and tests |
| 6 | Fixed/fractional layout overflow under long text, keyboard or small screen | Herajnokba, Anaam, Basiet, Devixia | High | Canonical widgets have small-screen/large-text tests; feature layouts remain product-owned |
| 7 | Loading/error/empty state never reaches a terminal actionable state | Herajone, Devixia, Al Safa, Anaam | High | Covered by `AppStateView`, async/pagination state and startup fallback |
| 8 | Unsafe media decode/viewer/video lifecycle | servena, Basiet, Matyah | High | Covered by `AppMedia` and compatibility regression tests |
| 9 | Modal closes on request failure or loses pending input | Herajnokba, selection reviews | High | Covered by confirm-on-commit dropdown/dialog contracts |
| 10 | Repeated submit/request/permission/listener execution | Al Safa, Anaam, Herajnokba, Devixia | High | Covered in buttons, pagination, notifications and socket packages |
| 11 | Raw backend/plugin exception or sensitive request logging | Anaam, Al Safa, security audits | High | Covered by typed localized mapping and structural redaction |
| 12 | Cancellation/null-response and retry race handling | Matyah, network reviews | High | Covered by Dio cancellation, retry and latest-result-wins tests |
| 13 | Back disabled globally or delayed navigation firing after disposal | Anaam, legacy-base review | High | Covered by `AppPageShell`, routing policy and legacy regressions |
| 14 | Wrong provider/navigation context | Herajnokba, navigation reviews | High | Architecture guidance covers composition boundaries; feature-specific providers remain local |
| 15 | Socket/notification listener duplication and lifecycle leaks | Herajnokba, notification reviews | High | Optional packages contain idempotency/lifecycle tests |
| 16 | Incomplete localization, stale locale, raw keys or mixed direction | Devixia, Anaam, Al Safa | High | Covered by runtime switching, parity tests and direction-aware components |
| 17 | Missing semantics, tap targets, focus or repeated loading announcements | Devixia, Anaam | High | Mostly covered; skeleton semantics was the one verified code gap |
| 18 | Picker cancellation, permission denial, lost activity or native setup | Anaam, picker reviews | High | Covered by injected picker contract and lost-data recovery tests |
| 19 | Temporary Figma-hosted assets and wrong reference-frame scaling | Anaam | High | Runtime code is clean; project prompt gap remained |
| 20 | Incomplete/floating Figma version, missing state inventory or asset rights | Arnon, Al Safa, Anaam | High | Documentation/prompt concern, not root runtime code |
| 21 | API collection lacks saved examples or stable empty/non-empty contracts | collection audit, Al Safa, Migraf | High | Prompt gap remained; no generic runtime dependency justified |
| 22 | WebView/Maps missing configuration or unsafe error UI | Al Safa and optional-package audits | High | Covered in isolated optional packages |
| 23 | Android/iOS identity, flavor, symbols or release parity drift | multiple release audits | High | Root covered; optional-example Kotlin application gap found and fixed |
| 24 | Native home-widget/background scheduling | Nahtadi | Product-specific | Excluded from root; documentation/application integration only |
| 25 | Signing, real services, store policy, backend certificates/content | multiple projects | External | Product/backend/store gates; cannot be solved generically in the base |

## Base gap analysis and adoption matrix

| Candidate | Evidence | Base comparison | Classification | Decision |
| --- | --- | --- | --- | --- |
| Collapse skeleton accessibility into one loading announcement | Devixia rows plus `AppStateView` source inspection | Skeleton branch exposed placeholder semantics unlike spinner branch | Root improvement | Implement without API change; add widget regression test |
| Reject temporary Figma/MCP runtime asset URLs | Anaam report and source recurrence | No such URL exists in base; prompt does not say this explicitly | Guidance | Add authoritative prompt requirement and validator concept |
| Validate design reference size against actual Figma frames | Anaam measured 360×690 versus 430×932 mismatch | Base uses a documented 375×812 reference, but derived-app workflow lacks an explicit verification rule | Guidance | Add prompt requirement; no hardcoded universal size rule |
| Freeze design version and inventory screens separately from states/modals | Arnon, Al Safa, Anaam | Prompt requests inventories but not frozen-version/prototype/placeholder provenance explicitly | Guidance | Strengthen shared design contracts |
| Require saved fresh response examples and stable empty/non-empty/mutation shapes | Collection and backend-drift audits | Runtime parser is defensive; collection workflow could still approve an ambiguous contract | Guidance | Strengthen API collection contracts |
| Diagnose screenshots/videos through reproducible runtime before editing | Cross-project reports contain both historical and live findings | Evidence section distinguishes grades but does not require runtime-first visual diagnosis | Guidance | Add explicit evidence workflow |
| Add more wrappers, integrations or dependencies | No repeated uncovered contract | Current canonical/optional boundaries already cover them | Excluded | No code/dependency change |
| Copy native home widget, business flows, models, endpoints or assets | Single-project or proprietary | Not generic and may add native/runtime weight | Product-specific | Excluded |
| Alter architecture, routing, DI or state management | No evidence of a base-level deficiency | Would add migration risk without measurable gain | Excluded | No change |

## Evidence-to-test traceability

| Evidence class | Existing protection | Added by this audit |
| --- | --- | --- |
| Repeated loading announcements | State widgets already test terminal transitions, RTL and large text | Skeleton exposes one live-region label while child placeholders are excluded |
| Startup/optional deadlock | Startup coordinator timeout/retry/fallback tests; optional Remote Config tests | None; already covered |
| Async disposal/cancellation | Async cubit, pagination, media, picker and plugin-service tests | None; already covered |
| Session/account leakage | cleanup, routing, 401 synchronization, scoped cache/queue tests | None; already covered |
| API shape/error mapping | parser, remote source, retry and typed failure tests | Guidance tightened; no duplicate runtime helper |
| Overflow/RTL/theme/text scale | canonical widget suites and accessibility tests | None; product screens remain application-owned |
| Optional integration leakage | dependency/isolation gate and package analyzers/tests | None; zero-byte boundary retained |
| Prompt regressions | `validate_prompt_library.sh` validates 18 adapters against the shared spec | New evidence-derived design/API concepts validated centrally |

## Exclusions and ownership

- **Backend-owned:** certificate expiry, malformed server content types,
  undocumented response envelopes, missing/developing endpoints, content,
  account state and service availability. The client still must terminate in a
  safe localized state.
- **Product-specific:** roles and financial arithmetic, product journeys,
  native home widgets, notification event names, socket rooms, maps behavior,
  brand assets, business models and per-screen Figma parity.
- **Release-specific:** signing, Firebase/APNs, Maps keys, links, store accounts,
  policy decisions and production service verification.
- **Already covered:** canonical media/picker/page/button/dropdown/state
  contracts, lifecycle disposal, synchronized auth refresh, account cleanup,
  cancellation, pagination guards, optional integrations and native identity
  parity.

## Implemented improvements and impact

The evidence supports one small runtime hardening change, one regression test,
and shared prompt/tooling clarification. It does not support a dependency
addition, architectural rewrite, widget-family expansion, public API break,
asset deletion or root-native identity change. Expected binary-size impact is
effectively zero beyond a small Dart semantics wrapper; optional-package
isolation is unchanged.

Implemented:

- `AppStateView` skeletons now expose one live-region loading announcement and
  exclude placeholder-child semantics.
- A widget regression test protects the single-announcement contract.
- The shared prompt specification now rejects temporary Figma/MCP asset URLs,
  verifies reference-frame sizing and frozen design versions, separates screens
  from states/modals, treats historical visuals as leads, and requires fresh,
  stable empty/non-empty API response examples.
- The prompt validator enforces those shared concepts for all 18
  Codex/Claude/Cursor adapters.
- The first release run exposed missing Kotlin plugin application in the Maps
  example. Maps and Remote Config Android examples now apply the same current
  Kotlin Android plugin required by their native sources, and the identity gate
  protects both files. This is a current Flutter 3.47.1 compatibility fix; the
  upstream future Built-in Kotlin warning remains documented rather than hidden.

No dependency constraint or lockfile changed. The final Universal APK, ARM64
APK and AAB are byte-for-byte identical to the retained post-identity artifacts,
so the measured root binary impact of this audit is **0 bytes**. No optional
integration entered the root.

## Final verification

| Check | Result |
| --- | --- |
| `scripts/flutter_quality_gate.sh quick` | passed: 9 checks |
| `scripts/flutter_quality_gate.sh full` | passed: 27 checks |
| `scripts/flutter_quality_gate.sh release --build` | passed after the optional-example fix: 59 checks, 0 skips, builds enabled |
| Root analyzer | no issues |
| Root tests | 227 passed, 2 intentional conditional skips |
| Focused widget tests | 62 passed; subset of root, not additional |
| Root coverage | 2,474/4,072 lines, 60.76% |
| Focused widget coverage | 1,481/3,309 lines, 44.76% |
| PHP inverse | 15 passed, 3 opposite-branch skips |
| Optional packages | 5 analyzers and 44 tests passed |
| Optional examples | 3 analyzers/tests plus Maps and Remote Config Android/iOS production builds passed |
| Android root | 3 debug flavors, Universal, ARM32, ARM64, x86_64 and AAB passed |
| iOS root | development, staging and production Simulator builds passed |
| Code generation | reproducible: 16 outputs and 83 AR/EN keys |
| Optional isolation | root dependency graph and Universal APK entries passed |
| Samsung ARM64/API 34 | current release code installed via a temporary debug-signed copy; process alive/top-resumed, safe bilingual terminal state, no fatal marker |

Final retained artifact evidence:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Universal APK | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| ARM32 split | 15,846,674 | `7df5fcf2d56f9189199765cccd6b17f8456d013438fdd36aa81e3f15287f9d14` |
| ARM64 split | 18,601,894 | `e97b63ee6f2e9949e915a6014d31c95c90995a7acdbd04395295d7736616aede` |
| x86_64 split | 20,020,086 | `059ec12a3513461ff8229943168d1eef102df7fe6a4e4aef0f06566461fca8f3` |
| Production AAB | 50,659,286 | `6f4f6ae7540ac9b80868ba98be9dfc1c6725db5e2bb5400a6f3e56aca1cb1636` |

The 50,618,821-byte AAB remains the labeled widget-hardening phase artifact;
50,659,286 bytes is the current post-identity/current-source artifact. The
unsupported 50,618,560-byte value remains superseded. Universal comparisons in
the size report retain their symbol-packaging labels.

The exact changed source/documentation files are:

- `README.md`
- `docs/CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31.md`
- `docs/QA_MATRIX.md`
- `docs/prompts/AUTHORITATIVE_SPEC.md`
- `lib/src/core/widgets/handling_views/app_state_view.dart`
- `packages/app_maps/example/android/app/build.gradle.kts`
- `packages/app_remote_config/example/android/app/build.gradle.kts`
- `scripts/check_project_identity.sh`
- `scripts/validate_prompt_library.sh`
- `test/core/widgets/app_state_view_test.dart`

No source, asset, dependency or configuration was deleted. One failed
release-gate staging directory containing reproducible build outputs was removed
after recording artifact sizes/checksums and before the successful full rebuild.
The temporary debug-signed smoke APK is not a distributable production artifact.

Commands executed materially included read-only streaming/inventory scripts,
`flutter pub get` in the target root and optional packages/examples, format,
prompt/agent/identity validators, focused/root/conditional/optional tests,
coverage, analyzers, code-generation reproduction,
`scripts/flutter_quality_gate.sh quick|full|release --build`, Android/iOS builds,
artifact size/checksum checks, temporary APK signing, ADB install/launch/logcat,
and screenshot inspection. No dependency upgrade command and no Git state-
changing command was run.

## Remaining gates and verdict

- Production Android signing is intentionally absent; the retained release APK
  is unsigned.
- Real backend, test accounts, Firebase/APNs, Maps keys, sockets, WebView
  services, deep links, store distribution and provider symbol upload remain
  product gates.
- Physical iOS archive/device QA and wider device/accessibility matrices remain
  product gates.
- Flutter reports a future Built-in Kotlin migration warning; Firebase plugins
  and Maps iOS SwiftPM support must be revisited with a future compatible
  dependency/toolchain migration, not changed ad hoc here.

Exact reconciliation totals:

| Measure | Total |
| --- | ---: |
| Accessible chat/task IDs reviewed | 52 |
| Flutter projects inspected | 18: target plus 17 read-only references |
| Substantive Flutter reports reviewed | 37 |
| Structured test-sheet rows reviewed | 61: 46 issue rows plus 15 bidi/render cases |
| Structured unique issue records | 46; narrative report findings were normalized instead of assigned invented IDs |
| Historical runtime screenshots reviewed | 18 unique hashes |
| Historical runtime videos reviewed | 4 |
| Normalized failure classes | 25 |
| Classes already covered before this audit | 18 |
| Classes with implemented hardening in this audit | 2: skeleton semantics and optional-example native build parity |
| Documentation-only classes | 3: design assets/sizing, design completeness and collection contracts |
| Backend/external-owned classes | 1 normalized class |
| Product-specific excluded classes | 1 normalized class |
| Blocked real-service/release class | 1 normalized class |
| Regression tests added | 1 |
| Final distinct tests | 274: 227 root + 44 optional-package + 3 optional-example tests |
| Conditional PHP proof | 15 passed/3 skipped in inverse mode; not added to the distinct-test total |
| Root coverage | 2,470/4,069 (60.70%) before; 2,474/4,072 (60.76%) after |
| Universal APK | 49,921,496 before and after; 0-byte change |
| ARM64 split APK | 18,601,894 before and after; 0-byte change |
| Production AAB | 50,659,286 before and after; 0-byte change |

Final reusable-baseline verdict: **freeze-ready**. Overall classification:
**Conditionally production-ready**, because the real-product gates above cannot
be completed generically.

Verification results and exact command outcomes are recorded in
`docs/QA_MATRIX.md` after execution. Historical screenshots/videos are never
presented as a current device run, and reference projects remain untouched.
