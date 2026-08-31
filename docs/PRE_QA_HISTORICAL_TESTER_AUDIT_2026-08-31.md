# Pre-QA historical tester audit — 2026-08-31

## Scope and safety

This audit compares the reusable base with four supplied historical QA sheets:

| Sheet | Rows | Status breakdown | Priority breakdown |
|---|---:|---|---|
| Heraj user | 70 | Blocked 1, Closed 63, Skip 5, Resolved 1 | Critical 3, Medium 61, Low 6 |
| Heraj representative | 36 | Re-Open 1, Closed 35 | Critical 5, Medium 28, Low 3 |
| Anaam user | 41 | Open 10, Resolved 27, Skip 4 | Critical 5, Medium 26, Low 10 |
| Anaam kitchen | 14 | Open 7, Resolved 7 | Medium 14 |
| **Total** | **161** |  |  |

One tracker bug ID is shared between the two Heraj role sheets, so the input
contains 161 rows and 160 unique tracker IDs. The top-level `bugs` arrays were
treated as canonical because category references under-counted the Heraj
sheets. Every row's description, status, priority, category, notes and media
references was reviewed.

The tracker was read using HTTP GET only. No POST, PUT, PATCH or DELETE request
was made; no status, note, attachment or tracker record was changed. Tracker
URLs, share tokens, account data and endpoint values are intentionally absent
from this repository. The four downloaded JSON files remain temporary evidence
outside the project.

There were 274 media references resolving to 133 unique public attachment
pages. Of those, 120 were accessible and inspected (89 PNG screenshots and 31
MP4 videos, with three frames sampled per video); 13 links were deleted or no
longer exposed usable media. The unavailable evidence is a warning, not a
reason to infer missing behavior.

## Reference-project resolution

| QA scope | Read-only local root | Match evidence |
|---|---|---|
| Heraj user | `/Users/abdelrahamndandash/StudioProjects/herajnokba` | The repository declares a user entry point/flavor and a provider entry point/flavor in one shared codebase. |
| Heraj representative | `/Users/abdelrahamndandash/StudioProjects/herajnokba` | The provider flavor and provider-specific delivery/profile flows correspond to the representative sheet. |
| Anaam user | `/Users/abdelrahamndandash/StudioProjects/anaammakkah` | The single app bootstrap contains the individual account path documented by the project. |
| Anaam kitchen | `/Users/abdelrahamndandash/StudioProjects/anaammakkah` | The same app contains an explicit butcher/butchery account type and role-specific registration, profile and slaughter-request flows. |

Both reference roots were source-inspected only. No Flutter, generator, build,
format, dependency or cleanup command was run in either root, and neither was
modified.

## Tester-expectation catalog

The 161 rows normalize into the following reusable expectations. Counts are
recurrence signals and may overlap because one bug can exercise multiple
contracts.

| Expectation | Historical evidence | Correct reusable boundary |
|---|---|---|
| Reject invalid data before a request and show localized field-level feedback | Phone, national ID, VAT/tax, IBAN, plate, account number, price, empty ordered fields and excessive text appeared in all four scopes | Root validators and field plumbing provide primitives; the application owns backend/product rules such as allowed carrier prefixes and business maxima. |
| Back, retry and repeated taps must not create black screens, duplicate screens or stale forms | OTP Back/reset, stale registration forms, repeated FCM navigation, disabled actions and white/black transient screens | Root page/button/navigation primitives protect lifecycle and duplicate submission; feature controllers own draft reset policy. |
| Picker/media flows need camera/gallery, cancel, replace/remove, orientation, count/size and lifecycle safety | Registration documents, transfer receipts, avatars, advert galleries and return evidence recur across roles | Root `AppImagePickerField`/`AppMedia`; upload APIs and document rules remain feature-owned. |
| Dropdown/date/location selection must not summon the keyboard unexpectedly and must represent selected data clearly | Dropdown keyboard regressions, date/time fields, city selection and map selection recur | Root `AppDropdown`; optional `app_maps`; product fields and required-data rules remain local. |
| Loading must terminate in content, empty, retryable error or safe fallback | Blank home, skeleton-only notification screen, stale order state and first-load failures | Root async/pagination/state components; feature refresh triggers remain local. |
| Notifications must tolerate nested payload shapes, validate target IDs, avoid duplicate routing and never guess domain identifiers | Order, delivery, return, profile, blocked/deleted-account and chat routing defects recur in both products | Optional notifications package normalizes transport data and delegates typed actions; event names, target-key contracts and refresh behavior remain application-specific. |
| Session-ending events must clear data and reach one stable authentication destination | Block/delete/deactivate cases recur in both products | Root session coordinator plus optional notification adapter; backend delivery remains an external contract. |
| HTML and links need an explicit allow/open policy and safe localized failures | Static pages and chat links recur | Optional `app_webview` or an injected external-link policy; product content remains backend-owned. |
| Permission prompts must occur in context and denial must produce a usable state | Location and notifications were requested at surprising times or without a usable fallback | Optional integrations request permissions from explicit user flows; root startup must not block on them. |
| Server-driven state and money must not be fabricated on device | Order states, cancellation reasons, coupons, commissions, wallets, returns, pricing, distances and admin content dominate the sheets | Backend/admin/product ownership. The base provides typed failures and refresh/cancellation infrastructure only. |
| Arabic/English, RTL/LTR, currency/digits and backend validation copy must be coherent | Language switching, Arabic validation, digits/currency order and mixed copy recur | Root localization parity and directional widgets; consuming apps map backend codes to localized messages. |

## Normalized failure and ownership matrix

| Failure class | Recurring examples | Primary owner | Base action |
|---|---|---|---|
| Input normalization/validation | Saudi phone formats, VAT/tax, ID, IBAN, price, empty form order | Root primitive + feature policy | Harden only evidence-backed generic normalization; do not encode product maxima or backend carrier policy. |
| Form/OTP lifecycle | Clear rejected OTP, reset draft on intentional Back, no stale validation | Feature controller using root lifecycle-safe widgets | Document boundary; do not create an authentication UI framework. |
| Navigation/route identity | Wrong tab, duplicate detail screen, deleted entity route, missing Back | Feature router using root shell/session policies | Root already covers safe Back and unknown routes; target IDs remain product-specific. |
| Notification transport | Nested JSON payload, foreground/background/terminated delivery, duplicate taps | Optional package + consuming app + backend | Normalize payload transport generically; retain injected router and product-owned event map. |
| Media/picker lifecycle | Cancel, replace, camera/gallery, lost activity, rotated or incomplete images | Root picker/media + feature upload | Already canonical and tested; no duplicate helper. |
| Maps/permissions | First location, denied permission, saved versus selected address | Optional maps package + feature UX | Already optional/injectable; keys and checkout/location rules stay local. |
| HTML/WebView/external link | CKEditor links, payment WebView, chat URLs | Optional webview/external launcher + backend content | Already optional; no concrete WebView dependency enters root. |
| Async refresh/retry | State changes only after manual refresh, skeleton/blank terminal state | Root async/pagination + feature invalidation | Root covers finite request states; FCM/domain invalidation remains local. |
| API/admin data contract | Missing reason, wrong totals, missing IDs, incorrect distance/status/action flags | Backend/admin | No mobile workaround, cache or guessed value in base. |
| Product/design decision | Shipping options, free-price policy, labels, wallet semantics, screen presence | Product owner/application | Never promote into generic base. |
| Localization/accessibility/layout | RTL alignment, Arabic errors, clipped actions, currency position | Root widget contract + application copy | Canonical widgets already cover direction/theme/text scale/semantics; feature layouts need their own tests. |

## Base comparison and pre-implementation adoption matrix

This matrix was completed before code changes for this phase.

| Historical pattern | Existing base evidence | Decision |
|---|---|---|
| Phone must start with the Saudi mobile stem and accept realistic formatting | `Validators.validateSaudiPhone` accepts local, `0` and `+966` forms but does not normalize Arabic digits | **Adopt:** normalize Arabic digits without narrowing carrier prefixes. |
| Saudi VAT/tax number needs more than a length check | The base has a backwards-compatible generic 15-digit VAT validator; Anaam implements the Saudi `3…3` rule | **Adopt:** add a separate strict Saudi VAT validator, preserving the generic API. |
| Nested FCM `data` maps/JSON must route identically to flat payloads | Both reference projects independently flatten nested payloads; optional `NotificationPayload` currently reads only the outer map | **Adopt in optional package:** deterministic non-throwing payload normalization with tests. |
| Product notification types and `order_id`/`delivery_id`/`return_id` routing | References contain large conflicting domain event tables | **Reject for base:** keep event-to-action mapping injected and application-owned. Never guess one identifier from another. |
| OTP reset and registration draft reset | Reference behavior is tied to authentication flows and backend resend/upsert contracts | **Reject for root:** feature controller responsibility; root fields already expose controllers/focus safely. |
| Vehicle plate, bank-account length, wallet maximum, price/weight/category rules | Each is product or backend-policy dependent | **Reject for root:** document/test in the consuming feature. |
| Camera/gallery/reset/lost-result behavior | Canonical root picker already covers the contract and has widget/service tests | **Retain:** no new wrapper or migration. |
| Dropdown keyboard and confirmation behavior | Canonical dropdown already covers focus, pending confirm/cancel, large lists and retry | **Retain:** no redesign. |
| Static HTML, payment WebView and map picker | Existing optional packages provide safe state/policy contracts | **Retain optional:** no root binary dependency. |
| Order, wallet, return, coupon, commission, distance and admin-content defects | Evidence and notes identify backend/admin/domain ownership | **Do not mask:** no fake values, mobile filtering, inferred state or local cache workaround. |

## Pre-QA risk interpretation

Historical sheets are regression evidence, not a specification for embedding
the two products in the template. The base can prevent the repeated transport,
validation, lifecycle and presentation mistakes, but it cannot prove each
future application's backend event delivery, order state machine, payment
provider, map keys, admin content or store configuration.

## Implemented from the adoption matrix

- Saudi mobile validation now normalizes Arabic-Indic digits while retaining
  the existing local, `0` and `+966` forms.
- `validateSaudiVat` adds the strict Saudi `3` + 13 digits + `3` structure;
  the existing generic 15-digit VAT validator remains unchanged for backwards
  compatibility.
- The optional notifications package now normalizes flat, nested-map and JSON
  object-string payloads without throwing. Nested application keys win, a
  colliding outer transport ID is retained as `notification_id`, unknown
  product event names remain available to the injected application router, and
  no domain target ID is inferred.
- Behavior tests cover valid, invalid, localized, malformed, collision and
  unknown-event branches. No widget, architecture, domain flow or reference
  project was redesigned.

No gallery scenario was added because these changes have no visual state. The
existing widget gallery continues to cover the canonical fields, buttons,
dropdown, state, media and picker surfaces implicated by the historical bugs.

## Final verification

The project-local release gate completed against the final source and retained
artifacts:

| Check | Final result |
|---|---|
| Flutter/Dart | Flutter 3.47.1, Dart 3.13.1 |
| Formatting | 306 files checked, 0 changed |
| Root analyzer | No issues |
| Root tests | 228 passed, 2 intentional conditional skips |
| Root coverage | 2,485/4,079 lines, 60.92% |
| PHP inverse configuration | 15 passed, 3 opposite-branch skips |
| Optional packages | 5 analyzers and 49 tests passed |
| Optional examples | 3 analyzers and 3 tests passed |
| Generated sources | Reproducible: 16 outputs and 83 AR/EN keys |
| Final release gate | `mode=release checks=29 skipped=0 builds=0` |
| Optional isolation | Root dependency graph and Universal APK entries passed |

The 49 optional-package tests and three optional-example tests are separate
from the 228 root tests. The PHP inverse command proves the opposite compile-
time configuration of tests already present in the root suite and is not added
again to the distinct-test total. The resulting distinct automated total is
280 tests. The five notification-payload tests are included in the 14-test
notifications package total.

The monolithic `scripts/flutter_quality_gate.sh release --build` invocation
passed every pre-build check and the Android matrix, then stopped while copying
the iOS staging Simulator app because the host volume had no free space. This
was an environmental failure, not a compiler or test failure. Reproducible
intermediates and already-recorded debug artifacts were reclaimed, and every
remaining command from the gate was then run unchanged and passed. A final
`scripts/flutter_quality_gate.sh release` re-ran all analyzers, tests,
generation, budgets and isolation checks against those artifacts and produced
the 29-check pass above.

### Release matrix and retained artifacts

- Android development, staging and production debug flavors built.
- Production Universal, ARM32, ARM64, x86_64 and AAB builds completed with
  external Dart symbols. Native symbols and R8 mappings were retained.
- Root iOS development, staging and production Simulator builds completed.
- Maps and Remote Config production examples built for Android and iOS.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Universal APK | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| ARM32 split APK | 15,846,674 | `7df5fcf2d56f9189199765cccd6b17f8456d013438fdd36aa81e3f15287f9d14` |
| ARM64 split APK | 18,601,894 | `e97b63ee6f2e9949e915a6014d31c95c90995a7acdbd04395295d7736616aede` |
| x86_64 split APK | 20,020,086 | `059ec12a3513461ff8229943168d1eef102df7fe6a4e4aef0f06566461fca8f3` |
| Production AAB | 50,659,286 | `6f4f6ae7540ac9b80868ba98be9dfc1c6725db5e2bb5400a6f3e56aca1cb1636` |
| Native-symbol archive | 133,760,000 | `09f38d0d023339dba07f2dab5e9ecf018cb387448aa651b83e24111d7cdb07ae` |

The Universal comparison uses the same external-Dart-symbol packaging
configuration as the current audited baseline. The current AAB value is
50,659,286 bytes; earlier phase-specific AAB measurements are not substituted
for this final artifact. ARM64, AAB and source-assets budgets passed, and the
Universal archive contains no concrete notifications, Firebase, Maps, WebView
or socket integration.

The connected Samsung SM-A235F/API 34 passed a release-code smoke using an
unchanged temporary copy of the ARM64 APK signed with the machine's debug key.
Cold launch, repeated Retry, HOME and hot resume kept the process alive and
top-resumed with no fatal, ANR or native-signal marker. The visible terminal
state was the expected bilingual safe startup failure for placeholder
production configuration, not a black screen or infinite splash. The original
unsigned release artifact was not modified, and the temporary signed files
were deleted.

Generated debug APKs, duplicate release copies, Simulator apps and failed
build intermediates were removed only after their build success, byte size and
where applicable checksum had been recorded. No source, asset, dependency,
configuration or production symbol artifact was deleted. The Gradle 9.1.0
build cache was also reclaimed after the root Android matrix completed; it is
reproducible and contains no project source.

Files changed for this pre-QA phase are:

- `docs/PRE_QA_HISTORICAL_TESTER_AUDIT_2026-08-31.md`
- `docs/QA_MATRIX.md`
- `docs/REUSABLE_COMPONENT_CATALOG.md`
- `lib/src/core/shared/helpers/validators.dart`
- `test/core/shared/helpers/validators_test.dart`
- `packages/app_notifications/README.md`
- `packages/app_notifications/lib/app_notifications.dart`
- `packages/app_notifications/lib/src/models/notification_payload.dart`
- `packages/app_notifications/lib/src/models/notification_payload_normalizer.dart`
- `packages/app_notifications/test/notification_payload_test.dart`

The target already contained unrelated uncommitted audit/widget/identity work;
it was preserved without reset, restore, staging or cleanup. Material commands
for this phase were read-only tracker/media retrieval, source inventory, Dart
format verification, root and optional analyzers/tests, PHP inverse tests,
coverage, generated-source reproduction, Android/iOS flavor and optional-
example builds, size/isolation checks, SHA-256 calculation, temporary APK
signing, and ADB install/launch/Retry/resume/log inspection. No dependency
upgrade command was run.

### Warnings and final verdict

Flutter 3.47.1 reports future migration warnings for Built-in Kotlin in the
root/examples, for Firebase plugins used by the Remote Config example, and for
Swift Package Manager support in `google_maps_flutter_ios`. All current builds
pass; these are dependency/toolchain upgrade watch items, not present release
failures.

**Pre-QA verdict: ready with warnings.** The reusable contracts implicated by
the historical evidence are implemented and verified. Thirteen historical
media links are unavailable, and future applications must still test their own
domain event table, backend/admin behavior, credentials, signing and real
service integrations.

**Project verdict: Conditionally production-ready reusable baseline.** There
is no known reproducible crash in the verified scenarios, no infinite splash,
no silent black screen and no unintended optional integration in the root
binary. Production signing, real backend accounts, Firebase/APNs, Maps keys,
deep links, store delivery and complete product-specific physical-device QA
remain application release gates.

No tracker write method was used, neither read-only reference project was
modified, and no Git state-changing command, commit or push was performed.
