---
name: flutter-base-production
description: Maintain, extend, review, test, or release the flutter_base production foundation. Use for reusable widgets, state/network/session infrastructure, localization, optional packages, architecture boundaries, Flutter quality gates, Android/iOS flavors, size analysis, or project-local guidance in this repository.
---

# Flutter Base Production

Read `AGENTS.md` and the task-relevant document in `docs/` before editing.
Treat this repository as a reusable production foundation, not a demo app.

## Work read-first

1. Search the reusable catalog and existing source before creating a component.
2. Identify the owning boundary: root, optional package, feature, template/docs,
   or product-specific code.
3. Keep business logic feature-owned and dependency direction inward.
4. Add behavior-focused tests for success, failure, cancellation, concurrency,
   disposal, retry, and lifecycle branches that the change affects.
5. Verify Arabic/English, RTL/LTR, themes, semantics, keyboard and safe-area
   behavior for reusable UI.
6. Run format, analyzer and affected tests; run full gates in proportion to risk.
7. Use the Codex adapter under `docs/prompts/codex/` for reusable design,
   collection, live-parity, or production-readiness workflows.

## Hard boundaries

- The root cannot import concrete notifications, Remote Config, Maps, WebView,
  Socket, analytics, crash-reporting, or other heavy optional integrations.
- Do not retain `BuildContext`, translations, session data, or loading state in
  process-global helpers. Service lookup is allowed only at composition roots
  and documented legacy boundaries.
- Do not log URLs, headers, bodies, tokens, identifiers, PII, notification
  payloads, encryption material, or raw backend messages.
- Do not show raw backend messages. Map failures to typed, localized messages.
- Do not add pass-through use cases, cross-feature imports, giant utility
  files, unrelated flags, implicit navigation, or swallowed exceptions.
- Do not hardcode keys or silently change a backend contract.
- Never add caching, fake data, retries, or fallback navigation to conceal an
  upstream defect.
- Treat Android and iOS as one release surface: IDs, flavors, display names,
  icons, native splash, Maps/Firebase sources, signing, links, APNs, and store
  preparation must remain in parity.
- Keep Maps and Firebase/Remote Config optional and key-free by default. Never
  silently change Remote Config defaults or copy real service configuration.

## Approved foundations

- `DefaultTextField`: generic text entry; feature validation stays outside it.
- `AppDropdown`: pending selection applies only on Confirm; cancellation never
  commits. Supports static/paginated and single/multi modes.
- `AppButton`: primary, secondary, destructive, and text variants with async
  duplicate-submit protection and accessible targets.
- `AppStateView`: named content/loading/empty/error/offline/permission
  constructors, skeleton/retry/custom visual, and accessible state semantics.
- `AppMedia`: one safe asset/file/network image, SVG and optional-video
  contract; raw plugin errors are never UI copy.
- `AppImagePickerField`: injected camera/gallery, cancellation, recovery,
  replacement/removal and size/count validation.
- `AppPageShell`: normal/sliver page chrome with contextual Back; never disable
  Back globally.
- `ImageView`, legacy loading buttons, empty/error views, Back/Close controls,
  and `DefaultScaffold` are deprecated adapters only. Extend the canonical
  contract instead of adding behavior to a compatibility family.
- `AsyncCubit` and `PaginatedAsyncCubit`: typed failure, latest-result wins,
  cancellation recovery, disposal safety, and pagination request guards.
- `StartupCoordinator`, `UserCubit`, `SessionFailureCoordinator`, and the
  context-free session routing policy own startup/session transitions.

Read [the catalog](references/reusable-component-catalog.md) before adding or
changing shared behavior. Update the catalog when a reusable public contract
changes.

## Verification

Use the repository's configured Flutter SDK and the executable project-local
gate. It derives and enters the project root, never runs Git or dependency
resolution, and fails on the first failed check:

```text
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
scripts/flutter_quality_gate.sh release
```

`quick` is the routine root gate. `full` adds root coverage and independent
optional-package analyzers/tests. `release` checks already available audited
artifacts as well; use `scripts/flutter_quality_gate.sh release --build` only
when the intentionally expensive Android and iOS build matrix is required.
Dependency resolution must already exist; run `flutter pub get` explicitly in
the root or affected optional package during environment setup, not invisibly
inside the gate.

Native changes require affected flavor builds and
`scripts/check_project_identity.sh`. Release changes require the
matrix and gates in `docs/RELEASE_CHECKLIST.md`; size changes require
`docs/SIZE_AUDIT.md`. Record anything requiring real credentials, signing,
services, stores, or physical devices as a product release gate—never fake
verification.

## Legacy instructions

Historical duplicated instructions were moved to `.claude/reference/` and
`.cursor/reference/`. They can explain intent, but are not active skills/rules.
Root `CLAUDE.md`, the single active Claude skill, the single active Cursor rule,
`AGENTS.md`, this skill, current source/tests, and current `docs/` are the
supported surfaces. Do not resurrect a legacy prescription without reconciling
it against all of them.
