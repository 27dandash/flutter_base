# Test-count reconciliation

Evidence date: 2026-08-27. Counts below come from `flutter test
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
producing the current **219 passed + 2 conditional skipped**. No optional test
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
| Root default | 219 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 9 | 0 | 0 |
| Remote Config optional | 4 | 0 | 0 |
| WebView optional | 6 | 0 | 0 |
| Maps optional | 7 | 0 | 0 |
| Socket optional | 6 | 0 | 0 |
