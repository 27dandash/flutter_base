# Codex Prompt — Review the API Collection Before Implementation

Scope: `{{PROJECT_PATH}}`; evidence: `{{FIGMA_URLS}}`,
`{{COLLECTION_PATHS_OR_URLS}}`, `{{APP_VARIANTS}}`, `{{FLAVORS}}`,
`{{USER_ROLES}}`, `{{BACKEND_ENVIRONMENTS}}`, `{{TEST_ACCOUNTS}}`.

Read `AGENTS.md`, network/architecture instructions, and the authoritative spec;
execute family 3. Inspect collection and environment values read-only, redact
secrets, and compare the contract with design, requirements, code, session
lifecycle, and optional integrations. Do not invent or implement an ambiguous
endpoint. Continue through inventories and traceability that are locally safe,
then return backend questions, missing keys/services/endpoints, blockers,
mockable work, and a do-not-implement list with exact source evidence.
