# Claude project guidance

This repository is a reusable Flutter production base, not a product. Read
`AGENTS.md`, `.claude/skills/flutter-base-production/SKILL.md`, and the
task-relevant current document under `docs/` before acting.

## Precedence and scope

User instructions win, then this file and `AGENTS.md`, then the active local
skill, current source/tests, and current `docs/`. Historical material under
`.claude/reference/`, `.cursor/reference/`, and `md/` is documentation-only and
must never override the active architecture or toolchain.

Inspect before editing. Work only in the authorized project. Do not use Git,
credentials, production services, store submission, or destructive operations
unless explicitly authorized. Never fabricate file, command, Figma, device,
backend, or release evidence.

## Base rules

- Preserve feature-first Clean Architecture, BLoC/Cubit, current routing/DI,
  flavors, localization, compatibility adapters, and optional-package isolation.
- Reuse the catalog in `docs/REUSABLE_COMPONENT_CATALOG.md`. Canonical UI is
  `AppButton`, `DefaultTextField`, `AppDropdown`, `AppStateView`, `AppMedia`,
  `AppImagePickerField`, `AppPageShell`, standard dialogs/sheets/messages,
  `AsyncBlocBuilder`, and `PaginatedListWidget`.
- Heavy integrations remain in `packages/app_*`; never import their concrete
  dependencies into the root merely to make an example convenient.
- Keep Android/iOS identity, flavor IDs, display names, icons, native splash,
  Maps/Firebase sources, signing, deep links, APNs, and store preparation in
  parity. Run `scripts/check_project_identity.sh`.
- Preserve optional Remote Config defaults/contracts. Real Firebase/Maps
  verification requires authorized per-flavor credentials.
- Keep feature validation and business behavior feature-owned. Do not cache a
  translation or `BuildContext`, create global mutable UI/session state, add
  pass-through layers, or show untrusted backend/plugin exception text.
- Test success, failure, invalid input, timeout, cancellation, concurrency,
  retries, lifecycle/disposal, AR/EN, RTL/LTR, themes, text scaling, semantics,
  debug, and release where applicable.

## Commands

Resolve Flutter from `android/local.properties`; do not hardcode a personal SDK
path. Routine checks:

```text
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
scripts/flutter_quality_gate.sh release
```

Use `release --build` only for the expensive native matrix. Regenerate source
with `dart run build_runner build`, then
`dart run tool/generate_locale_keys.dart`; generated output must be stable.
The external gallery entry point is `tool/widget_gallery/main.dart` and is not a
production route.

For reusable design/API/live/release workflows, select the Claude adapter from
`docs/prompts/README.md`, keep a persistent task ledger, and distinguish advice
from work actually executed.
