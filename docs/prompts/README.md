# Reusable Prompt Library

This library is the supported workflow for design, API-contract, live parity,
and release-readiness work derived from this Flutter base.

Start with [AUTHORITATIVE_SPEC.md](AUTHORITATIVE_SPEC.md), then choose one of
the six families using [SELECTION_GUIDE.md](SELECTION_GUIDE.md). Every family
has a Codex, Cursor, and Claude adapter. The shared specification is normative;
the adapters describe how each tool must execute it.

## Prompt index

| Stage | Codex | Cursor | Claude |
|---|---|---|---|
| Create design | [Codex](codex/01-create-design.md) | [Cursor](cursor/01-create-design.md) | [Claude](claude/01-create-design.md) |
| Review design | [Codex](codex/02-review-design.md) | [Cursor](cursor/02-review-design.md) | [Claude](claude/02-review-design.md) |
| Review API collection | [Codex](codex/03-review-api-collection.md) | [Cursor](cursor/03-review-api-collection.md) | [Claude](claude/03-review-api-collection.md) |
| Prove collection completeness | [Codex](codex/04-prove-collection-complete.md) | [Cursor](cursor/04-prove-collection-complete.md) | [Claude](claude/04-prove-collection-complete.md) |
| Live Figma/API comparison | [Codex](codex/05-live-implementation-review.md) | [Cursor](cursor/05-live-implementation-review.md) | [Claude](claude/05-live-implementation-review.md) |
| Production readiness | [Codex](codex/06-production-readiness.md) | [Cursor](cursor/06-production-readiness.md) | [Claude](claude/06-production-readiness.md) |

Supporting material:

- [Variable-filling guide](VARIABLES.md)
- [Ordered lifecycle](WORKFLOW.md)
- [Single app](examples/single-app.md)
- [Single app with multiple roles](examples/multi-role.md)
- [Two apps/flavors](examples/two-apps.md)
- [Three or more apps/flavors](examples/many-apps.md)
- [Shared backend](examples/shared-backend.md)
- [Separate backend per flavor](examples/separate-backends.md)

Run `scripts/validate_prompt_library.sh` after changing this library.
Creation and release adapters inherit the authoritative Android/iOS identity,
flavor, Maps, Firebase/Remote Config, icon, native-splash, signing, link, APNs,
and store parity checks. Run `scripts/check_project_identity.sh` after identity
or native configuration changes.
