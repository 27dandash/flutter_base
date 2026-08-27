# Authoritative Prompt Specification

Every tool-specific prompt in this library must apply this specification.
When an adapter conflicts with this file, this file wins unless the user gives
a narrower explicit instruction.

## Required inputs

Use these placeholders consistently:

- `{{PROJECT_PATH}}`
- `{{FIGMA_URLS}}`
- `{{COLLECTION_PATHS_OR_URLS}}`
- `{{APP_VARIANTS}}`
- `{{FLAVORS}}`
- `{{USER_ROLES}}`
- `{{BACKEND_ENVIRONMENTS}}`
- `{{TEST_ACCOUNTS}}`

Never place credentials in a prompt file. `{{TEST_ACCOUNTS}}` must point to a
secure handoff mechanism or name the account personas; it must not contain
passwords or tokens.

## Mandatory topology discovery

Before acting, inspect evidence and classify the project as one or more of:

- single app/single role;
- single app/multiple roles;
- multi-app;
- multi-flavor;
- white-label;
- shared backend;
- separate backend per app/flavor.

Do not assume exactly two apps, roles, Figma files, collections, or backends.
Produce an app/flavor × role × environment inventory and identify shared versus
variant-specific design, services, configuration, assets, and release gates.

## Base preservation rules

- Inspect before editing and reuse the canonical component catalog in
  `docs/REUSABLE_COMPONENT_CATALOG.md`.
- Preserve Clean Architecture, BLoC/Cubit, routing, DI, localization, flavors,
  compatibility adapters, and tests unless an approved migration says otherwise.
- Keep notifications, Remote Config, Maps, WebView, sockets, analytics, crash
  reporting, and other heavy providers in optional packages. An unused optional
  integration must add zero bytes to the root artifact.
- Never invent endpoints, fields, keys, credentials, backend behavior, Figma
  edits, device runs, screenshots, or command results.
- Never expose raw backend errors, secrets, tokens, PII, signing material, or
  private service details.
- Test Arabic/English, RTL/LTR, light/dark, Android/iOS, accessibility, loading,
  empty, error, offline, permissions, retry, and debug/release where applicable.
- Do not perform Git operations unless the user explicitly authorizes them.
- Treat Android and iOS as one release surface. Every creation/release workflow
  must verify IDs, flavor mapping, display names, launcher/AppIcon, native
  splash, Maps key sources/restrictions, Firebase app configuration, Remote
  Config defaults/fetch/fallback, signing, deep links, APNs, and store setup.
- Keep Maps and Firebase/Remote Config optional and absent from root when
  unused. Use key-free templates and controlled missing-config behavior.
- Stop before destructive uncertainty, production mutations, credential use,
  store submission, or a breaking architecture decision that needs approval.

## Evidence and completion

Separate inspected, executed, manually verified, inferred, and externally
blocked results. A mocked result is never live evidence. A visual inspection is
not pixel parity; matched screenshots and measured diffs are required.

Every matrix row must cover every applicable app/flavor, role, language, theme,
platform, environment, and state. External blockers remain open and cannot be
marked complete.

## Family contracts

### 1. Create design

Review requirements, branding, roles, existing design system, and current
screens first. Define shared and variant-specific journeys, components, states,
tokens, responsive behavior, keyboard behavior, accessibility, AR/EN, RTL/LTR,
and light/dark. Do not invent unsupported backend behavior or overwrite Figma
work without approval. Deliver a screen/state inventory and completeness matrix.
Define replaceable Android/iOS icons and native splash together and record
flavor/store branding requirements without inventing credentials.

### 2. Review completed design

Audit every Figma page, screen, component, variant, role, app/flavor, journey,
state, form, validation, destructive confirmation, navigation/Back behavior,
responsive breakpoint, language, direction, theme, and accessibility condition.
Produce a readiness verdict and blocking list. Fix only when authorized.

### 3. Review API collection before implementation

Inventory environments, base URLs, auth/refresh/logout/deletion, device ID versus
notification token, roles, permissions, headers, queries, bodies, multipart,
pagination/search/filter/sort, upload/download, envelopes, status codes, rate
limits, idempotency, timeouts, sockets, notifications, Maps, WebView callbacks,
deep links, external services, and missing secrets. Compare collection against
requirements, design, existing code, and environment templates. Deliver endpoint,
screen, role, missing-service, ambiguity, question, blocker, mockable, and
do-not-implement lists.

### 4. Prove collection completeness

Trace every screen, action, role, app/flavor, and state to a documented service.
Include CRUD, auth lifecycle, switching/logout/deletion, upload, pagination,
search/filter/sort, notification/socket/Maps/WebView/deep-link, legal/support,
version/update, Remote Config, analytics, and offline sync when applicable. The
only verdicts are `Complete`, `Complete with clarifications`, `Incomplete`, and
`Blocked`.

### 5. Live implementation versus Figma and collection

Run authorized test environments on available Android/iOS targets. Match device
size, pixel ratio, platform, language, theme, app/flavor, role, and data state.
Measure layout, type, color, icon, safe-area, navigation, modal, keyboard,
skeleton/state, mirroring, truncation, overflow, and dark-mode differences with
overlays/diffs where available. Validate real endpoint, environment, headers,
request, parsing, state, caching/account isolation, error mapping, and contract
validation. Record tolerances and re-test fixes screen by screen.

### 6. Final production/live readiness

Verify formatting, analyzer, tests, integration/live journeys, release smoke,
Android/iOS artifacts, signing, identifiers, display names, icons, native
splash, environments, secrets/TLS, Maps, Firebase/Remote Config/APNs, optional
integrations, deep links, WebView/socket security, observability
and symbols, privacy/Data Safety, permissions, accessibility/localization/themes,
performance/memory/startup/process death/offline, session lifecycle, versioning,
rollback, store metadata, and physical-device coverage. Report each app/flavor
separately. Allowed verdicts only: `Production-ready`, `Conditionally
production-ready`, `Not production-ready`. Required external gates prevent the
first verdict.
