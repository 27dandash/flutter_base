# Architecture and hardening decisions

## Structure and dependency direction

```text
lib/
├── bootstrap/                    environment validation and startup ownership
├── src/
│   ├── config/                   public configuration, resources, locale, theme
│   ├── core/                     network, session, navigation, storage, shared UI
│   └── features/<feature>/
│       ├── presentation/         screens/widgets/Cubit; depends on domain
│       ├── domain/               entities, rules, repository contracts
│       └── data/                 DTOs/sources/repository implementations
└── main_<environment>.dart

packages/
├── app_notifications/            optional Firebase/native notifications
├── app_remote_config/            optional Firebase Remote Config
├── app_webview/                  optional webview_flutter module
├── app_maps/                     optional Maps/location module
└── app_socket/                   optional Socket.IO transport and generic client
```

The dependency rule is `presentation -> domain <- data`. The audited product
domain contains no Flutter, Dio, Hive, plugin, presentation, or concrete data
imports. Presentation obtains dependencies at screen composition boundaries;
new feature classes should use constructor injection. `GetIt` remains at the
application composition root and a small number of documented legacy helpers.

Clean Architecture is proportional here: a use case is justified by a rule or
coordination, and a mapper is justified by a transport/domain difference. Pub
packages are not created per feature. Packages are used only where a capability
has an independent native dependency or lifecycle. A Pub Workspace would not
remove dependencies from an application binary, so the optional packages remain
outside the root dependency graph.

## Startup ownership

`StartupCoordinator` gives every task an ID, kind, timeout, once-only future,
result, elapsed time, and controlled error. Only critical tasks delay `runApp`.

| Kind | Current tasks | Caller behavior | Failure behavior |
| --- | --- | --- | --- |
| Critical | localization runtime, screen metrics, composition/environment validation | awaited before `runApp` | bilingual recovery UI with guarded Retry |
| Non-blocking | secure session restore | starts after `runApp` | logged-out state; error hook; no splash wait |
| Optional | Hive/cache/AES-GCM offline queue | starts after `runApp` | queue/cache unavailable; app remains usable |
| Deferred | preferred orientations | starts after first app mount | reported, never blocks launch |

Notifications, Firebase, FCM token retrieval, permission prompts, Remote Config,
installation IDs, socket connection, analytics, network reachability, and product
service initialization must be registered as optional/non-blocking by consumers.
They must not navigate independently. Timeouts bound waits, repeated starts share
one execution, and the optional offline queue returns a safe zero count before
its persistence has opened, preventing an early `LateInitializationError`.

## Session and navigation

`UserCubit` is the session source of truth with explicit `restoring`, `loggedIn`,
`loggedOut`, `blocked`, and `needsActivation` states. Tokens remain in
`TokenStorage`; the user payload remains in secure storage. A session transition:

1. Emits the unauthenticated/typed state immediately.
2. Clears the active offline-queue owner so old writes cannot replay.
3. Runs bounded token, user payload, HTTP cache, and offline queue cleanup.
4. Runs registered optional hooks (socket disconnect, notification unregister,
   analytics identity, or product databases) and records every failed hook.
5. `SessionNavigationCoordinator` applies a configurable routing policy with
   stack removal; Back cannot reopen protected screens.

HTTP 401, PHP `unauthenticated`, blocked, and need-activation failures are
observed without a retained `BuildContext`. Concurrent terminations share one
future. Default blocked routing is login plus controlled message; activation
routes to `/activation` and preserves typed activation data. Products may inject
a different `SessionRoutingPolicy` after product approval.

## Network, cache, TLS, and offline writes

- One Dio client owns auth refresh, locale, typed errors, retry, and opt-in cache.
- Only safe/idempotent requests are retried automatically. Cache is disabled
  globally; explicit cache keys include locale and a non-empty session scope.
- Production environment validation requires HTTPS, a non-placeholder/non-dev
  host, and at least two different 64-hex SHA-256 pins. The pinning policy checks
  exact allowed hosts and certificate validity. No production callback accepts
  an invalid certificate. Primary plus backup pins support planned rotation.
- Certificate pins are public trust configuration, not secrets. A pin rollout
  still requires an overlap/recovery plan and real-server verification.
- Offline queue records use AES-256-GCM with a random secure-storage key, unique
  nonce, authentication tag, and owner scope as additional authenticated data.
  Secrets are stripped recursively. Legacy records without proven ownership are
  deleted fail-closed; corrupt/truncated records are removed and reported.
- Local encryption reduces casual at-rest disclosure; it does not protect a
  fully compromised/unlocked device.

## Localization and design system

`EasyLocalization` at the root is the locale source of truth and persists the
choice. Runtime changes call the mounted root context and update Intl. UI reads
locale/translated strings during build, not from `initState` or static cached
contexts. New layout uses directional padding/alignment; physical left/right
extension methods are deprecated for normal UI.

Approved shared primitives include `DefaultTextField`, `AppDropdown`, project
buttons/dialogs, design tokens, and `AppStateView`. `AppDropdown` commits only
after Confirm and reads the notifier at click time to close the same-frame
selection/confirmation race. Shared primitives contain no product validation,
routes, endpoints, events, or models.

## Environment and platform policy

Each environment has an explicit Dart target, Android flavor/application ID,
iOS scheme/build configurations/bundle ID, and display name. Production runtime
validation rejects default example configuration. Root Android manifests contain
only network state, Internet, and wake-lock permissions after merge; no broad
storage or Firebase/notification permission leaks from optional packages.

Root iOS and macOS use Swift Package Manager and have no Podfiles. Firebase
config copy scripts are flavor-selective and no fake config is supplied.
Signing, real bundle IDs, entitlements, associated domains, APNs, Maps keys,
TLS pins, and backend credentials belong to the consuming product and remain
release gates.

## Trade-offs and known architecture debt

- Navigator 1/named routes remain to avoid replacing stable base navigation for
  only three placeholder routes. A product with nested/deep-linked flows should
  adopt an approved declarative router behind the same session policy.
- Some legacy shared helpers and presentation screens still use service lookup;
  new work must not expand this pattern.
- Existing broad `core/widgets` is retained for compatibility. Future movement
  should be driven by ownership/reuse, not file-count aesthetics.
- Optional WebView/Maps/socket packages intentionally expose generic contracts
  and pure testable controllers. A consuming product owns business callbacks,
  event names, endpoints, keys, and paid geocoding choice.
