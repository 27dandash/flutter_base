---
name: flutter-base-production
description: Maintain, extend, review, test, or release this reusable Flutter production base, including canonical widgets, Clean Architecture, BLoC/Cubit, networking/session, localization, optional packages, flavors, project prompts, and quality gates.
---

# Flutter Base Production

Read root `CLAUDE.md`, `AGENTS.md`, `docs/REUSABLE_COMPONENT_CATALOG.md`, and the
task-relevant current document before editing. Inspect actual code and commands;
historical skills under `.claude/reference/` are evidence only.

## Execution contract

1. Classify work as root foundation, optional package, feature-owned,
   documentation/template, or product-specific.
2. Reuse canonical components and services before creating a new abstraction.
3. Preserve dependency direction, constructor injection, session/startup
   ownership, localization at read time, and optional-integration zero-byte
   isolation.
4. Never invent contracts, keys, credentials, results, or access. Never render
   untrusted backend/plugin exception text or log sensitive request data.
5. Add behavior-focused tests for affected branches, including async disposal,
   cancellation, concurrency, retry, locale/direction/theme, and accessibility.
6. Run the smallest relevant gate, then full/release checks in proportion to
   native, security, or artifact risk. Record exact evidence and blockers.
7. Keep Android/iOS IDs, flavors, names, icons, native splash, Maps/Firebase
   sources, signing, links, APNs, and stores in parity; run
   `scripts/check_project_identity.sh`.

## Current supported surfaces

- UI: `AppButton`, `DefaultTextField`, `AppDropdown`, `AppStateView`,
  `AppMedia`, `AppImagePickerField`, `AppPageShell`, adaptive dialogs,
  standard sheets/messages, `AsyncBlocBuilder`, `PaginatedListWidget`.
- Infrastructure: typed `Failure`, `BaseRemoteSource`, cancellation, idempotent
  retry, scoped cache, encrypted offline queue, synchronized refresh,
  `StartupCoordinator`, `UserCubit`, and `SessionFailureCoordinator`.
- Optional only: notifications, Remote Config, Maps, WebView, sockets, and
  provider-specific observability/analytics.
- Tooling: `scripts/flutter_quality_gate.sh`,
  `scripts/validate_prompt_library.sh`, `dart run build_runner build`, and
  `dart run tool/generate_locale_keys.dart`.

Use the tool-specific prompt library under `docs/prompts/` for design, contract,
live parity, and production-readiness work. Do not resurrect an archived skill
without reconciling it with the current source and active guidance first.
