# Test-count reconciliation

Evidence dates: 2026-08-27 through 2026-09-03. Counts below come from `flutter test
--reporter=json`; hidden suite-loader events are excluded and conditional skips
are counted separately. Raw event logs were written outside the repository in
the Codex task work directory.

## Exact explanation

The reported **187 root tests** was an accounting error, not a former root
manifest. At that point the root had 157 passing tests and the five optional
packages had 30 passing tests. `157 + 30 = 187`; the aggregate was labeled
"root". This is independently supported by the unchanged optional-package
breakdown: Notifications 9, Remote Config 4, WebView 5, Maps 6 and Socket 6.

Four subsequently added root assertions—two architecture boundaries and two
asset/localization assertions—changed the real root count from 157 to the
previously reported 161. The first hardening audit added 18 behavior tests,
producing 179. The widget-hardening phase added 28 further behavior tests,
producing 207. The compatibility-consolidation continuation added 12 tests,
producing 219 passed + 2 conditional skipped. Subsequent identity, runtime and
history-audit work reached 228 root tests before this independent review. The
session-boundary hardening added nine behavior assertions, producing the
current **237 passed + 2 conditional skipped**. No optional test
is included in that root count.

| Previous item | Current location/name | Status | Reason / replacement coverage |
|---|---|---|---|
| Root manifest: 157 passing | Existing root files under `test/` | Retained | JSON discovery shows all baseline files; no missing/failed suite loader |
| 2 architecture boundary assertions | `test/architecture/module_boundaries_test.dart` | Added before this audit | Domain and optional/root import boundaries |
| 2 asset/parity assertions | `test/assets/asset_manifest_test.dart` | Added before this audit | Declared asset existence and AR/EN key parity |
| Misclassified optional 30 | Tests inside the five `packages/app_*` trees | Moved in accounting only; files retained | Still 9+4+5+6+6, executed independently |
| Async cancellation assertion | `AsyncCubit CancelledFailure restores initial...` | Behavior corrected/renamed | Prevents permanent loading after cancellation |
| Async throw/concurrency/disposal | three names in `async_cubit_test.dart` | Added | Typed unexpected error, latest wins, close safety |
| Pagination branches | seven names in `paginated_async_cubit_test.dart` | Added | Filter, append, dedupe, partial retry, throw, supersession, cancel/dispose |
| Unified buttons | three names in `app_button_test.dart` | Added | Duplicate submit, disabled action, accessible targets/variants |
| Button disposal | `async completion after disposal does not call setState` | Added | Safe asynchronous lifecycle completion |
| Paginated dropdown retry | `paginated initial error is retryable inside the sheet` | Added | First-page failure is no longer an empty dead end |
| Dropdown duplicate confirmation | `rapid confirmation applies once and does not pop the page` | Added | Prevents double pop/submission |
| Redacted network diagnostics | `debug diagnostics never contain URL, headers, or bodies` | Added | Secret/PII-bearing fields excluded structurally |
| Scoped blocking overlay | `controller scopes loading state and releases the barrier` | Added | No process-global UI state; lifecycle owned by caller |
| Canonical media lifecycle/fallback/viewer | `app_media_test.dart` | Added | Failure never exposes raw exceptions; async video initialization/disposal is generation-safe |
| Injectable picker field/service | `app_image_picker_field_test.dart`, `plugin_app_image_picker_service_test.dart` | Added | Cancellation, permission, lost activity, count/size, replace/remove, duplicate request and disposal |
| Page shell/Back behavior | `app_page_shell_test.dart` | Added | Normal/sliver layouts and contextual Back without global suppression |
| Async and paginated presentation | `async_bloc_builder_test.dart`, `paginated_list_widget_test.dart` | Added | Loading/empty/error transitions, refresh, scrolling, inline failure and retry |
| Dialog, sheet and feedback safety | `dialog_feedback_test.dart`, `legacy_widget_regressions_test.dart` | Added | Adaptive confirmation, context-owned sheets/messages and verified legacy regressions |
| Dropdown/text/button accessibility matrix | expanded widget tests | Added | Focus/keyboard, large data/text, RTL, light/dark, semantics and tap targets |
| Optional WebView/Maps page states | optional package page tests | Added outside root | Safe localized configuration failures without pulling packages into root |
| Compatibility media/state/action/navigation paths | expanded media/state/legacy widget tests | Added | Proves canonical delegation, scale mapping, async disposal, disabled semantics, viewer policy and contextual Back/Close |
| Session-generation token storage | `test/core/network/auth/token_storage_test.dart` | Added | Single encrypted pair, fail-closed write, stale refresh refusal, superseded write and legacy migration |
| Refresh/logout/account-switch races | `test/core/network/dio_network_audit_test.dart` | Added | Delayed refresh cannot overwrite a newer session; a stale success is cancelled after logout |
| Offline replay owner switch | `test/core/network/dio_network_audit_test.dart` | Added | Active replay is cancelled and the old owner's second mutation never runs under the new identity |
| Socket in-flight lifecycle races | `packages/app_socket/test/generic_socket_client_test.dart` | Added outside root | Auth change and pause/resume invalidate stale connection attempts |
| Notification privacy/localization | `packages/app_notifications/test/notification_logging_test.dart` | Added outside root | Debug output redacts payload/identity fields and action labels match Arabic/English |

No test was intentionally removed, merged away, or lost to discovery in this
audit. The sibling `flutter_clean_arch_base` directory is not an authoritative
historical manifest and was not used to manufacture missing test names.

## PHP compile-time branches

`PHP_RESPONSE_MODE` selects whether HTTP 200 bodies using the custom PHP
`key/data/message` envelope are interpreted as PHP success/failure/session
signals. It does not select a different server at runtime.

| Configuration | Dedicated envelope result | Meaning |
|---|---:|---|
| Default / `true` | 16 passed, 2 OFF-only skipped | PHP success/fail/blocked/need-active parsing is enabled; normal shared mapping also runs |
| `--dart-define=PHP_RESPONSE_MODE=false` | 15 passed, 3 ON-only skipped | Envelope-looking bodies use the normal response path; both OFF guarantees run |

If `php_auth_interceptor_test.dart` is included in the false-mode command, its
three deliberately ON-only integration tests also skip, yielding 15 passed and
6 skipped. The canonical inverse-branch command therefore targets
`php_envelope_test.dart`, as documented in `RELEASE_CHECKLIST.md`. This is
expected conditional selection, not a silently hidden suite.

## Current independent totals

| Suite | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Root default | 237 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 16 | 0 | 0 |
| Remote Config optional | 16 | 0 | 0 |
| WebView optional | 6 | 0 | 0 |
| Maps optional | 7 | 0 | 0 |
| Socket optional | 8 | 0 | 0 |
| WebView example | 1 | 0 | 0 |
| Maps example | 1 | 0 | 0 |
| Remote Config example | 1 | 0 | 0 |

The 15 inverse-PHP passes are not added wholesale to the root total because
13 are shared assertions already discovered by the default run. Counting only
the two OFF-only assertions, the current non-double-counted total is
`237 root + 2 inverse-only + 53 optional + 3 examples = 295` behaviors.

## Three-provider closure totals — 2026-09-05

The table above is retained as the independent-review snapshot. Subsequent
session/offline/token work added 12 root tests (237 → 249), widget and
compatibility hardening added 18 (249 → 267), and this closure added three
tests (owner-bound queue encryption plus two AppErrorHandler matrix tests),
producing 270. The existing refresh test was strengthened to assert
`Accept-Language` on refresh and retry, so it adds coverage without adding a
new test name.

| Suite | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Root default | 270 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 32 | 0 | 0 |
| Remote Config optional | 17 | 0 | 0 |
| WebView optional | 12 | 0 | 0 |
| Maps optional | 14 | 0 | 0 |
| Socket optional | 10 | 0 | 0 |
| WebView example | 1 | 0 | 0 |
| Maps example | 1 | 0 | 0 |
| Remote Config example | 1 | 0 | 0 |

Only the two inverse-only PHP assertions are added to the default-root count.
The non-double-counted total is therefore
`270 root + 2 inverse-only + 85 optional + 3 examples = 360` behaviors.
The historically reported 61 focused widget tests remain a subset of their
then-current root total; they were never an additional suite to add to root.
The current `test/core/widgets` suite is **79 passed**, likewise a subset of
the current 270 root tests.

## Pre-design delegated audit totals — 2026-09-05

The post-closure Claude/Cursor/Codex audit added six behavior tests without
removing, renaming, skipping, or weakening an existing test:

- one corrupted token-record self-heal test;
- three incomplete-session tests covering failed user persistence, token-only
  restore and user-only restore;
- one dark-theme dropdown/real-trigger-size test;
- one explicit multiline contract test.

| Suite | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Root default | 276 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 32 | 0 | 0 |
| Remote Config optional | 17 | 0 | 0 |
| WebView optional | 12 | 0 | 0 |
| Maps optional | 14 | 0 | 0 |
| Socket optional | 10 | 0 | 0 |
| Optional examples | 3 | 0 | 0 |

The focused `test/core/widgets` suite is now **81 passed**, still a subset of
the 276 root tests. The non-double-counted total is
`276 root + 2 inverse-only + 85 optional + 3 examples = 366` behaviors. Root
line coverage is 2,941/5,004 = **58.77%**.

### Final delegated re-review delta

Cursor's evidence-based re-review identified that the dropdown's measured
48dp height was not yet an explicit production constraint. The implementation
now enforces that minimum and tests it at the design viewport. One additional
password-line-limit regression test was added; this is the only new test name
after the full-gate snapshot above.

- Final root default: **277 passed, 2 expected conditional skips**.
- Final `test/core/widgets`: **82 passed**, a subset of the 277 root tests.
- Final non-double-counted total: `277 + 2 + 85 + 3 = 367` behaviors.
- Coverage remains reported from the preceding full-gate coverage run; it was
  not represented as a new post-delta measurement.

## Accepted audit hardening closure — 2026-09-08

The accepted final audit fixes added 21 behavior tests without deleting,
renaming, skipping, or weakening any existing test:

- nine retry tests for `Retry-After` delta/date parsing, fallback, bounded
  delays, safe methods, and invalid or negative values;
- six authentication-interceptor tests for once-only failure ownership,
  storage/callback failures, one shared timeout budget, and late completion;
- three remote-source tests proving that only handled unauthorized failures
  bypass the session coordinator;
- three launcher tests proving diagnostics are stable and redact raw errors,
  URLs, and sensitive values.

- Current root default: **298 passed, 2 expected conditional skips**.
- Current `test/core/widgets`: **82 passed**, unchanged and still a subset of
  the 298 root tests.
- Current non-double-counted total:
  `298 + 2 inverse-only + 85 optional + 3 examples = 388` behaviors.
- Coverage was not regenerated for this non-UI hardening delta and remains the
  explicitly dated snapshot above.
