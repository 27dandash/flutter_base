# Repository guidance

This is a reusable Flutter base, not a product. Read this file, `README.md`,
and the relevant document under `docs/` before changing code.

Codex should also load `.codex/skills/flutter-base-production/SKILL.md` for
repository work. Active Claude and Cursor guidance lives in root `CLAUDE.md`,
`.claude/skills/flutter-base-production/`, and
`.cursor/rules/00-flutter-base-production.mdc`. Historical material under
`.claude/reference/`, `.cursor/reference/`, and `md/` is non-binding evidence.
This file, active tool guidance, current source/tests, and current `docs/` take
precedence whenever historical examples conflict.

## Required workflow

1. Inspect existing infrastructure and shared widgets before adding anything.
2. Preserve the optional-package boundary: the root must not depend on
   `app_notifications`, `app_remote_config`, `app_webview`, `app_maps`, or
   `app_socket` unless a consuming product explicitly opts in.
3. Keep business-specific routes, endpoints, events, models, keys, and assets
   out of `core` and optional packages.
4. Add focused tests for new services, state transitions, widgets, routing,
   timeouts, cancellation, repeated execution, and failure paths.
5. Run `dart format` on changed Dart files, root `flutter analyze` and
   `flutter test`, then analyze/test every changed optional package.
6. Verify the affected flavor in debug and release when native code or
   platform configuration changes. Never hide an upstream warning.
7. For design/API/live/release workflows, use the matching adapter in
   `docs/prompts/README.md` and validate it with
   `scripts/validate_prompt_library.sh`.

## Architecture

- Business features are feature-first: `presentation -> domain <- data`.
- Domain code must not import Flutter, Dio, Hive, plugins, or data-layer types.
- Use constructor injection within features. Service lookup belongs at the
  composition root and at documented legacy boundaries only.
- Add a use case only for a business rule or meaningful coordination; do not
  create pass-through layers mechanically.
- Authentication/session state is centralized in `UserCubit`. Session-changing
  network failures go through `SessionFailureCoordinator`; navigation uses the
  context-free session routing policy.
- Only critical startup tasks may delay `runApp`. Firebase, notifications,
  tokens, sockets, analytics, persistence, and network access are not critical.

## Design system and localization

- Reuse `DefaultTextField`, `AppDropdown`, `AppStateView`, `AppButton`,
  `AppMedia`, `AppImagePickerField`, `AppPageShell`, dialogs, spacing,
  typography, radii, and colors before creating variants.
- Do not add new image/video/viewer/picker wrappers. New media code uses the
  canonical media request and injected picker service. Keep Maps/WebView UI in
  their optional packages.
- Confirmation selection remains pending until Confirm. Dismissal, Back, and
  swipe-down must not mutate the committed value.
- Feature validation and business rules never belong in shared widgets.
- UI must support Arabic/English, RTL/LTR, light/dark themes, large text, safe
  areas, keyboard insets, and accessibility semantics.
- Prefer `EdgeInsetsDirectional`, `AlignmentDirectional`, start/end, and
  direction-aware icons. Do not cache translations or retain a `BuildContext`.
- Extend a shared component when the behavior is genuinely shared. A distinct
  design may use a feature component, but document the deviation and test it.

## Security and release rules

- Never commit secrets, real endpoints, Firebase files, Maps keys, signing
  data, pins, tokens, identifiers, or test credentials.
- Production requires HTTPS, a non-placeholder endpoint, and primary plus
  backup SHA-256 certificate pins. Never add a permissive certificate callback.
- Do not log URLs, headers, bodies, tokens, notification payloads, personal
  data, queue plaintext, encryption material, or identifiers. Diagnostics must
  be debug-only and structurally redacted.
- Offline writes require an authenticated owner scope and authenticated
  encryption; session termination clears or isolates every user-scoped store.
- Use Photo Picker/image-picker behavior without broad Android storage access.
- A real release remains blocked until signing, backend, Firebase/notifications,
  Maps, deep links, and physical-device journeys are verified for that product.

## Identity and native parity

- The reusable identity is `flutter_base` / `Flutter Base`; Android and iOS
  production IDs are `com.flutter.newproject`, with `.dev` and `.staging`
  suffixes. A derived app must replace both platforms in the same change.
- Every native change must verify Android and iOS IDs, display names, flavors,
  launcher/AppIcon, native splash, signing, deep links, APNs, and store setup.
- Maps and Firebase remain optional. Configure separate Android/iOS sources for
  development, staging, and production; never commit real keys/service files.
- Preserve Remote Config public defaults/contracts and test disabled,
  missing-config, timeout, offline, fetch/activation, typed fallback,
  concurrency, and disposal behavior.
- Run `scripts/check_project_identity.sh` after naming, branding, native,
  prompt, or release configuration changes.

## Local commands

Use the explicit SDK configured by the consuming environment. Standard commands
and every flavor build are documented in `docs/RELEASE_CHECKLIST.md`.

```bash
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
scripts/flutter_quality_gate.sh release
```

Use `release --build` only when the intentionally expensive Android/iOS build
matrix is required. The gate reads the configured Flutter SDK from the project,
runs no Git command and never resolves dependencies implicitly.

Generated source is reproduced with `dart run build_runner build` followed by
`dart run tool/generate_locale_keys.dart`. Do not use the removed
`--delete-conflicting-outputs` build_runner option. The test-only widget gallery
is `tool/widget_gallery/main.dart`; no production entry point may import it.
