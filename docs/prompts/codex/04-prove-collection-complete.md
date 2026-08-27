# Codex Prompt — Prove Collection Completeness

For `{{PROJECT_PATH}}`, trace `{{FIGMA_URLS}}` and requirements against
`{{COLLECTION_PATHS_OR_URLS}}` across `{{APP_VARIANTS}}`, `{{FLAVORS}}`,
`{{USER_ROLES}}`, `{{BACKEND_ENVIRONMENTS}}`, and authorized
`{{TEST_ACCOUNTS}}` personas.

Read `AGENTS.md` and `docs/prompts/AUTHORITATIVE_SPEC.md`; execute family 4.
Produce the required app/flavor × role × screen/action × service matrix from
inspected evidence. Use only Complete, Complete with clarifications, Incomplete,
or Blocked. Continue automatically through every discoverable screen and action.
Never infer completeness from folder names, mocked examples, or a successful
collection import.
