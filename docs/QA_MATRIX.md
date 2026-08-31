# QA and requirements traceability

Status reflects reproduced checks on Flutter 3.47.1 / Dart 3.13.1, macOS ARM64,
Java 17. `Passed` means the listed behavior ran; credential/device-dependent work
is `Blocked`, not inferred from unit tests.

## Automated suites

| Suite | Result | Scope |
| --- | --- | --- |
| Root `flutter test` (default PHP mode) | 227 passed, 2 conditional skips | network/auth/retry/cache/parser/offline/TLS/log redaction, startup, session/routing, architecture/optional boundaries, assets/translations, async/pagination concurrency, canonical and compatibility media/state/action/navigation widgets, theme/RTL/routes/accessibility |
| PHP inverse command | 15 passed, 3 skipped | explicitly executes `PHP_RESPONSE_MODE=false` behavior |
| `app_notifications` | 9 passed | IDs vs token, permission, timeout, dedupe, refresh, retry, logout/switch |
| `app_remote_config` | 16 passed | backward-compatible API, injection, lazy disablement, defaults, environment policies, bounded initialization/fetch/activation, concurrency, typed fallbacks, retry, offline-safe errors and disposal |
| `app_webview` | 6 passed | URL/host policy, schemes, callbacks, dedupe, safe localized invalid-configuration page state |
| `app_maps` | 7 passed | config, fallback, permissions/services, timeout, selection/lookup, accessible missing-key page state |
| `app_socket` | 6 passed | idempotency/listeners, network, auth change, logout, reconnect bounds |

The final root coverage snapshot is 2,474 of 4,072 instrumented lines
(60.76%). The focused `test/core/widgets` snapshot is 1,481 of 3,309 imported
lines (44.76%). `AppMedia` is 66.09%, `AppMediaViewerPage` and the legacy
`ImageView` adapter are 100%, `CustomAnimatedButton` is 92.50%, and
`AppStateView` is 92.16%; `DefaultScaffold` is 84.62%. No
trustworthy older LCOV artifact exists, so a numeric
non-regression comparison is not claimed. Coverage is a map for future product
paths, not a substitute for the behavior, boundary and security assertions.
The 62 focused widget tests are included within the 227 root tests; they are not
added to the root total.

The invalid “187 root” report and the current manifest are reconciled in
`TEST_COUNT_RECONCILIATION.md`: 187 was 157 root plus 30 optional tests. The
earlier “119 successful and 2 conditional” count described an even older tree.
The two default-run conditional tests are the OFF-mode guarantees in
`php_envelope_test.dart`; they skip because the default compile-time flag is on.
The dedicated false-mode command runs both OFF guarantees successfully and skips
the three ON-only parse tests. Shared pure envelope mapping tests run in both.
Thus both compile-time branches were executed; one is not claimed to cover the
other.

## Requirements-to-tests matrix

| Requirement | Unit/state test | Widget/integration/release evidence | Manual/device evidence | Status |
| --- | --- | --- | --- | --- |
| bounded once-only startup; optional failure | `startup_coordinator_test.dart` | root app route/failure design review; Android/iOS builds | cold/warm/resume under real plugin failures | Automated passed; device blocked |
| queue safe before optional persistence | `offline_queue_startup_test.dart` | full root suite | low-memory/slow secure storage | Passed locally |
| authenticated/unauthenticated/blocked/activation routing | `session_routing_policy_test.dart`, `session_failure_coordinator_test.dart` | unknown-route widget test; stack-clearing coordinator review | full real route journey and Back | Automated passed; product journey blocked |
| cleanup failure and extension hooks | `session_cleanup_test.dart` | immediate unauthenticated state code review | real socket/token/database cleanup | Automated passed; integrations blocked |
| concurrent auth refresh/session response | auth/Dio/PHP audit tests | full root suite | backend token expiry | Automated passed; backend blocked |
| TLS production policy | certificate/environment tests | minified production APK/AAB | valid/invalid/rotated real server chain | Policy passed; deployment blocked |
| AES-GCM queue confidentiality/integrity/owner | cipher and Dio queue tests | release build; secure-storage dependency | key invalidation, backup/restore, compromised device | Automated passed; device blocked |
| installation ID distinct from FCM token | notification coordinator tests | optional dependency isolation | Firebase/APNs and backend record inspection | Automated passed; Firebase/backend blocked |
| token pending/timeout never blocks startup | notification timeout test + startup tests | notification package absent from root | start during live FCM outage | Passed structurally; live blocked |
| token refresh/dedupe/logout/account switch | notification coordinator tests | cleanup hook API | backend/Firebase live | Automated passed; live blocked |
| confirmation selector pending/cancel/confirm/race/retry | `app_dropdown_test.dart` | RTL text-field/dropdown host tests | Back gesture, large text, long lists | Core passed; extended device QA required |
| standard text field | `default_text_field_test.dart` | light/dark/RTL app tests | autofill/IME/accessibility reader | Core passed; device QA required |
| common loading/empty/error states | `app_state_view_test.dart` | transition widget test | reduced motion/screen reader | Passed locally; accessibility device QA |
| safe canonical media lifecycle and errors | `app_media_test.dart`, `legacy_widget_regressions_test.dart` | asset/file/network/video contracts, safe fallback and viewer policy | codec failures and lifecycle on OEM devices | Widget lifecycle passed; native media device QA remains |
| legacy compatibility paths remain safe | media/state/legacy regression widget tests | canonical viewer/state delegation, async disposal, true disabled actions, contextual Back/Close | consuming-project migration smoke | Compatibility tests passed; external consumers require their own compile gate |
| injectable image picking | `app_image_picker_field_test.dart`, `plugin_app_image_picker_service_test.dart` | cancellation, permission, lost-result recovery, size/count, replace/remove, duplicate request and disposal | camera/gallery/process death/OEM fallback | Contract/plugin adapter passed; physical workflow remains |
| notification payload transport | optional `notification_payload_test.dart` | flat map, nested map, JSON object string, malformed data, ID collision, Arabic/English selection and unknown product event fallback | real FCM foreground/background/terminated delivery | Parser contract automated; backend event/target-ID routing remains application-specific |
| canonical page shell and Back | `app_page_shell_test.dart` | normal/sliver/contextual Back, RTL/theme/text-scale hosts | predictive Back gesture on supported Android | Framework behavior passed; gesture QA remains |
| pagination presentation | `paginated_list_widget_test.dart`, state tests | scroll load-more, refresh, empty and inline failure/retry | long-list jank and screen reader | Widget/state behavior passed; profile QA remains |
| WebView allowlist/callback lifecycle | WebView package tests | independent analyze | real TLS/network/download/external apps | Policy passed; native live blocked |
| Maps fallback/permission/selection | Maps package tests | independent analyze | real key, map renderer, GPS, billing | Controller passed; native live blocked |
| socket lifecycle/reconnect/auth change | socket package tests | independent analyze | real server/proxy/radio/background | Client passed; backend/device blocked |
| image cancellation/lost result/errors | injectable picker service/field tests | minified Android release; merged manifest | camera/gallery/process death/OEM fallback | Automated/release compile passed; physical blocked |
| locale source and directional layout | language/state review, widget tests | root RTL/theme tests; directional shared UI | nested routes/tabs/dialogs after runtime switch | Core passed; full product flow blocked |
| unknown route/no raw production error | widget test + bootstrap review | Android release and iOS simulator builds | crash reporter/symbols/state restoration | Local passed; real crash pipeline blocked |
| flavor separation | environment tests | Android 3 debug + production release/AAB; iOS 3 simulator; Xcode schemes/settings | side-by-side install and endpoint capture | Builds passed; installed product blocked |
| optional dependency exclusion | package independent analyze/tests | root Pub/Gradle/Xcode graph lacks Firebase/notification/WebView/Maps/socket | final store artifact inspection after opt-in | Passed for root |
| R8/resource shrinking/tree shaking | N/A | production release APK/AAB, icon shrink 99.9% | signed install and smoke | Build passed; signed smoke blocked |
| asset existence/translation parity | `asset_manifest_test.dart` | explicit production asset bundle inspection | final product copy/artwork review | Automated passed; product copy pending |
| size regression and symbols | `check_size_budget.sh` | ARM64/AAB gate; all Dart/R8/native symbol files produced | provider symbol upload/crash decoding | Build/gate passed; provider blocked |

## Flavor/build matrix

| Platform/artifact | Development | Staging | Production |
| --- | --- | --- | --- |
| Android debug APK | Passed | Passed | Passed |
| Android release APK | N/A | N/A | Current Universal plus ARM32, ARM64 and x86_64 splits passed with external Dart symbols |
| Android AAB | N/A | N/A | Current production AAB passed with external Dart/native symbols and R8 mapping retained |
| Manifest merge | Passed | Passed | Passed debug + release |
| iOS simulator | Passed | Passed | Passed |
| Xcode scheme/config | Passed | Passed | Passed |
| signed Android/iOS archive | Blocked | Blocked | Blocked |

Android merged package IDs were `.dev`, `.staging`, and production base. All
merged roots contain only Internet, network-state, and wake-lock permissions.
The production iOS simulator artifact is 198,164 KiB allocated and contains bundle ID
`com.flutter.newproject`, display name `Flutter Base`, minimum iOS 15.0, and
camera/photo descriptions. Placeholder identities are not release approval.

The current unsigned ARM64 release artifact cannot be installed directly and
correctly fails Android certificate parsing until a consuming product supplies
release signing. For local smoke only, an unchanged copy was signed with the
machine's debug key and installed on Samsung SM-A235F/API 34. The current
process remained alive and top-resumed, logcat contained no fatal marker, and a
captured frame showed the expected bilingual controlled missing-production-
configuration state with Retry—not a black screen or infinite splash. This is
release-code smoke evidence, not production-signing approval. All three Android
debug flavors, current release artifacts, all three root iOS Simulator flavors,
and Maps/Remote Config Android+iOS production examples compiled successfully.

## Physical-device and manual matrix

For Android minimum/current API and iOS minimum/current versions:

- Cold/warm launch; background/resume; process death; low memory; offline and
  captive portal; secure storage unavailable/corrupt; no indefinite splash.
- Install three flavors side-by-side and capture actual endpoint/Firebase/deep
  link selection. Confirm production has no debug logs or debug-only tools.
- Logout, account deletion, blocked, activation, concurrent 401, offline logout,
  Back after logout, account switch, previous-user cache/queue isolation.
- Arabic/English cold start and both runtime directions on nested routes, Back,
  tabs/kept-alive pages, dialogs, sheets, validation, mixed-direction fields,
  large text, screen reader, light/dark, reduced motion.
- Camera/gallery/crop cancellation, denial/permanent denial/settings, Android
  Photo Picker/fallback, activity recreation, missing/oversized/unsupported file,
  rapid requests, release install.
- Notification prompt states, APNs/FCM token/refresh, foreground/background/
  terminated delivery/tap, backend association, logout/account switch.
- WebView real HTTPS/certificate/network/callback/external scheme/download;
  Maps real restricted keys/GPS/lifecycle; socket real auth/radio/proxy/resume.
- Signed Play/App Store artifacts, symbol upload, crash reporting, privacy
  manifests/declarations, store install/update/rollback.

These remain blocked until product identifiers, credentials, services, signing,
test accounts, and physical devices are supplied.
