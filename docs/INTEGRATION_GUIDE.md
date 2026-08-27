# Shared components and optional integrations

## Shared UI catalog

| Component | Location | Use |
| --- | --- | --- |
| `DefaultTextField` | `lib/src/core/widgets/fields/text_fields/` | Label/hint, controller or initial value, validation/error, password toggle, focus, keyboard/action, formatters, autofill, max length/lines, enabled/read-only, prefix/suffix, RTL/LTR |
| `AppDropdown<T>` | `lib/src/core/widgets/fields/drop_downs/app_drop_down/` | Confirmation-only single/multi selection, stable item ID, search, pagination, loading/error/retry, max height, keyboard/safe dismissal |
| `AppStateView` | `lib/src/core/widgets/handling_views/` | Loading/skeleton/content/empty/error/no-internet/permission-required in compact or scroll-safe full-page form |
| approved buttons/dialogs | `lib/src/core/widgets/buttons/`, `dialogs/` | Project theme and loading/disabled behavior |
| theme/tokens | `lib/src/config/themes/`, `lib/src/config/res/` | Colors, type, spacing, radii, responsive sizing, light/dark modes |

Use `DefaultTextField(controller: ...)` or `initialValue`, never both. Keep
business validation in a feature validator/controller. Password visibility has
configurable accessibility labels and cannot toggle while disabled.

`AppDropdown` keeps a pending notifier inside the sheet. Item taps never call
the external callback. Confirm returns the latest notifier value exactly once;
outside tap, Back, swipe, and cancellation return `null`. Use `itemId` when DTOs
do not implement value equality and `onRetry` for error state. Do not create a
second feature-specific confirmation selector for equivalent behavior.

`AppStateView` should reflect a finite state owned by a Cubit/controller. Never
leave a skeleton active without a terminal transition. Use skeletons where
shape continuity genuinely helps; a progress indicator is cheaper for short or
unknown layouts. `skeletonizer` is already used and release builds passed.

## Media picker and permissions

`ImageHelper` serializes picker requests, treats picker/crop cancellation as a
normal null result, catches platform/filesystem/state exceptions, validates file
existence/extension/size, supports Android lost-data recovery, and checks
`mounted` before UI work. Gallery selection uses the system image-picker/Photo
Picker path; the app does not request broad storage access. Camera is invoked
only after a user chooses Camera.

Android merged manifests for all built flavors contain no `READ_EXTERNAL_STORAGE`,
`WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, or `MANAGE_EXTERNAL_STORAGE`.
The external camera/picker contract requires no root storage permission. iOS
contains clear camera and photo-library usage descriptions.

| Scenario | Expected behavior |
| --- | --- |
| granted / picker result | validate, optionally crop, return existing supported file |
| denied / permanently denied by native UI | controlled plugin result/exception; no loader or crash |
| picker or cropper cancellation | return `null`; no state mutation |
| activity recreation | call lost-data recovery and validate recovered files |
| missing/unsupported/oversized file | reject with controlled result/error path |
| rapid requests | second request is ignored while the first owns the native UI |

Real camera/gallery UI, permanent-denial settings flow, process death, low-memory
recreation, and OEM Photo Picker fallback still require physical-device QA.

## Notifications and device registration

Add `packages/app_notifications` only if the product needs notifications, then
follow its README for Firebase/APNs/native configuration. Do not initialize it
inside critical bootstrap or request permission on launch.

Registration sequence:

1. Obtain/persist a random installation ID through injected secure-storage
   callbacks.
2. Read permission status without prompting unless a user action authorizes a
   prompt.
3. Retrieve the actual FCM registration token independently with a timeout.
4. Send explicitly named `installationId`, `fcmToken`, `platform`,
   `appVersion`, `flavor`, and optional authenticated `userId` fields.
5. Deduplicate the registration fingerprint.
6. Listen to token refresh and upsert the new association.
7. On logout/account switch, remove the previous association before registering
   the new user; backend failure remains retryable.

An installation ID identifies one app installation. An FCM token addresses the
current Firebase Messaging registration and can rotate. A user ID identifies an
account. None substitutes for another. If a backend accepts an installation ID
in an `fcm_token` field, the backend contract must be changed; the client must
not falsify it. Tokens, identifiers, notification data, and payloads are redacted
from debug logs; notification SDK diagnostics are forced off in release.

## WebView

Add a path dependency on `packages/app_webview`. `AppWebViewConfig` requires a
valid initial HTTPS host and allowed host set. Defaults are HTTPS-only,
JavaScript disabled, no JavaScript bridge, downloads disabled, and no SSL
bypass. Exact hosts/subdomains are allowed; malformed, insecure, or unrelated
navigation is rejected. External schemes are explicit/injected.

`AppWebViewPage` provides progress, error/retry, WebView back, typed close/cancel
results, success/failure callback rules, and duplicate completion protection.
The product supplies business callback URLs, deep-link policy, external launcher,
cookie/download policy, and flavor-specific host allowlists. Test real SSL,
downloads, process death, and external app handoff on both platforms.

## Google Maps

Add `packages/app_maps` and configure separately restricted Android and iOS API
keys through native/flavor configuration; never store keys in shared Dart code.
Pass whether configuration exists so missing keys render a controlled state.
The controller starts at a configured fallback without automatically prompting
for location. A user action may request current location with bounded service,
permission, and position checks. Map taps update a marker and optional injected
address lookup; lookup failure never discards a valid coordinate.

The package does not select a paid geocoder. Inject one only after documenting
provider, pricing/quota, privacy, localization, and retry policy. Real map tile
rendering, GPS accuracy, native key restriction, billing, lifecycle, and release
behavior require emulator/physical-device verification with real keys.

## Socket

Add `packages/app_socket`. Configure an HTTPS/WSS endpoint, timeout, authentication
provider, public headers, and bounded reconnect delays. `GenericSocketClient`
prevents duplicate connect/listener registration, maps parse/transport failures,
uses exponential backoff with jitter and a maximum, pauses on network/app loss,
reconnects on restoration, replaces transport on authentication change, and
disables reconnect after logout. It never owns feature event names or logs
tokens/payloads. Register a session cleanup hook for logout/account switch and
never await socket connection from splash.

## Localization and RTL checklist

- Add English/Arabic keys and regenerate locale accessors.
- Read translations and locale-sensitive formatting during build.
- Use `Languages.setLocaleWithContext` from mounted UI; root persistence and
  rebuild update retained routes when their widgets correctly read context.
- Use start/end, `EdgeInsetsDirectional`, `AlignmentDirectional`, and directional
  icons. Physical left/right helpers are deprecated.
- Test nested-route Back, dialogs, sheets, tabs/kept-alive pages, forms, mixed
  emails/phone/codes/numbers, large text, and light/dark themes.

## Reference-project migration table

The reference projects were inspected read-only. Their repository status was
clean before and after inspection.

| Reference/original | Purpose and dependencies | Assumptions removed / target | Tests | Status |
| --- | --- | --- | --- | --- |
| `rahoul` text-field implementations | themed form entry; project tokens/localization/forms | Existing base field was stronger; merged initial value, states, focus, autofill, password semantics into `DefaultTextField` | `default_text_field_test.dart` | Merged, no duplicate |
| `rahoul` dropdown/selection sheets | confirmation UI; project assets/models/cubits | Existing `AppDropdown` retained; added ID equality, retry, semantics, pending-confirm and rapid-tap safety | `app_dropdown_test.dart` | Merged, no duplicate |
| `rahoul` empty/loading/error widgets | common view state; project assets/strings | Consolidated generic finite states into `AppStateView`; retained existing Skeletonizer pagination use | `app_state_view_test.dart` | Generalized |
| `rahoul` socket client/config | real-time connection; Socket.IO, project endpoint/events and device/notification keys | Removed endpoint/event names and incorrect identifier coupling; transport abstraction moved to `packages/app_socket` | `generic_socket_client_test.dart` | Generalized optional package |
| `rahoul` picker/permission flows | gallery/camera/crop; plugin/context assumptions | Kept current packages; added serialization, cancellation, lost data, validation, safe context and exception handling | analyzer/release/manual matrix | Behavior merged |
| `herajone` WebView page | payment/browser callback page; unrestricted JS/navigation and business callbacks | Replaced with allowlisted HTTPS, JS-off default, injected schemes/callbacks and typed results in `packages/app_webview` | `webview_navigation_policy_test.dart` | Generalized optional package |
| `herajone` Google Maps page + platform config | map selection; geolocator, project location/address and hardcoded real-looking keys | Keys never copied; injected lookup, fallback, permissions, timeout, selection, confirmation, controlled missing config in `packages/app_maps` | `map_selection_controller_test.dart` | Generalized optional package |

No reference endpoint, project model, business event, credential, API key, or
asset was copied into the base.
