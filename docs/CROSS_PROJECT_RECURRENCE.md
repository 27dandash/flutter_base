# Cross-project recurrence inventory

Read-only scan date: 2026-08-26. Scope: Flutter source trees directly under
`/Users/abdelrahamndandash/StudioProjects`; build outputs, caches, Pods,
`.dart_tool`, SDKs, archives and backups were excluded. Only generic technical
patterns, basenames and file hashes were compared. No secret values, endpoints,
business models, product events, brand assets or workflows were copied.

Project codes used below: B=`flutter_clean_arch_base`, U=`uumarket`,
R=`rahoul`, M=`Migraf_Egazat`, O=`moshafy`, T=`matyah`, A=`anaammakkah`,
H=`herajone`, W=`Mawahib_AlSaudi`, S=`alsafaclub`, I=`Basiet`, V=`servena`,
N=`herajnokba`, D=`saudi_medbridge`, C=`rcjy_app`, F=`sofra`. The target base
is excluded from occurrence counts.

"Distinct" is the number of distinct content hashes. A high distinct count
means the files share a name/responsibility but contain conflicting product
assumptions; it is evidence for a contract, not permission to copy one.

| Component/behavior | Projects | Occurrences / distinct | Existing problems | Selected owner and implementation | Tests / migration |
|---|---|---:|---|---|---|
| Validators | B,U,R,M,O,T,A,H,W,S,I,V,N,D,C,F | 16 / 16 | Product rules mixed with generic rules | Root focused `Validators`; feature rules stay feature-owned | Unit invalid/null/bilingual cases; retained |
| Constants/config | same 16 | 16 / 16 | Brand IDs/endpoints frequently mixed in | Typed environment/flavor config in root; product values are release inputs | Environment and flavor tests; retained |
| Default text field | 15 projects | 15 / 15 | Inconsistent controller/initial, direction, errors, semantics | Root `DefaultTextField` generic contract | Widget validation/theme/RTL tests; retained and hardened |
| Image helper | 15 projects | 15 / 15 | Broad permissions, cancellation assumptions, API drift | Root injectable picker/cropper flow using modern picker behavior | Cancellation/error/platform smoke; retained |
| Navigation helper | 14 projects | 14 / 14 | Implicit context and product routes | Root navigation boundary plus typed/session routing policies | Router/session tests; retained |
| Snackbar/messages | 14 projects | 14 / 14 | Global context, stale messenger, long/stacked messages | Root `MessageUtils` now requires mounted context and replaces current message | Widget/use-site verification; migrated |
| Dropdown | 14 projects | 14 / 13 | Conflicting static/paginated and confirm behavior | Root `AppDropdown` with pending commit, stable identity and retryable pagination | Cancel/confirm/race/error/retry tests; hardened |
| Language switching | 13 projects | 13 / 13 | Global context and cached locale | Root context-owned `Languages.setLocaleWithContext` | Key parity/RTL/runtime flow; migrated |
| Bottom sheet | 13 projects | 13 / 12 | Product layout and selection coupled | Root dropdown sheet primitives for generic selection; feature sheets remain local | Widget behavior tests; retained |
| Loading button | 12 projects | 12 / 12 | Multiple APIs, weak disabled semantics, setState-after-dispose | Root `AppButton`; legacy buttons retained for migration | Async repeat/disposal/tap-target tests; adopted |
| Dialog | 12 projects | 12 / 12 | Product copy/navigation embedded | Root confirmation/dialog patterns; feature copy injected | Widget/router tests; retained |
| Empty state | 11 projects | 11 / 9 | Hardcoded artwork/copy | `AppStateView` compact/full empty contract | Widget matrix; retained |
| Pagination list | 11 projects | 11 / 8 | Duplicate requests, stale results, thrown-call lock | Root `PaginatedAsyncCubit` + `PaginatedListWidget` | First/refresh/more/error/retry/concurrency/disposal tests; hardened |
| Success dialog | 11 projects | 11 / 9 | Usually performs implicit navigation | Keep feature-owned unless copy/action is injected | Feature test required; not promoted as a global helper |
| App sizing/theme | 16/16 projects | 16 / 13 and 16 / 11 | Brand tokens differ | Root token system is template-owned; consuming app customizes documented tokens | Theme/RTL/widget tests; retained |
| Error/retry view | 6 projects | 6 / 3 | Mixed backend text and navigation | Root typed failures + `AppStateView` | Error mapping/widget retry tests; retained |
| WebView/payment WebView | 6 projects | 6 / 6 | Payment/product policies mixed with browser policy | Generic policy/controller in optional `app_webview`; payments feature-owned | Optional package tests; migrated boundary |
| Socket service | 5 projects | 5 / 5 | Event names/auth/session coupling | Optional `app_socket` contracts; product events stay outside | Optional lifecycle/reconnect tests; optional |
| API/Dio/auth/token/parser | 3 projects | 3 / 3 each | Token refresh races, raw errors/logging | Root typed network/session infrastructure; structurally redacted diagnostics | Dio/auth/parser/concurrency/log tests; hardened |
| Notifications/FCM | 3 projects | 3 / 3 | Device ID confused with FCM token; splash coupling | Optional `app_notifications`; no root concrete import | Optional lifecycle tests and root absence checks; optional |
| Maps | repeated integration pattern | conflicting | Keys, permissions and selection are product-sensitive | Optional `app_maps`; root holds no plugin | Optional controller tests; optional |
| Remote Config | repeated integration pattern | conflicting | Firebase/startup coupling | Optional `app_remote_config`, injected and bounded | Optional timeout/config tests; optional |

## Selection result

No reference implementation was copied verbatim. Representative implementations
of the known `rahoul` and `herajone` text-field/button/dropdown families were
reviewed as read-only reference points. Their divergent dependencies and product
assumptions confirmed that the safest reusable result was the smaller target
contract plus focused hardening. All reference projects remained untouched.

Capabilities that remain application-specific include payment workflows,
backend DTOs/envelopes beyond the documented opt-in PHP shape, socket events,
analytics events, maps business rules, notification routing, copy, branding,
credentials, endpoints and store identities.
