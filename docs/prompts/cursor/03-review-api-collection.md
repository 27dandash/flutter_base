# Cursor Agent Prompt — Review the API Collection Before Implementation

Use Agent mode and index `{{PROJECT_PATH}}`. Read `.cursor/rules/` plus the
authoritative spec. Inspect `{{COLLECTION_PATHS_OR_URLS}}`, `{{FIGMA_URLS}}`,
`{{APP_VARIANTS}}`, `{{FLAVORS}}`, `{{USER_ROLES}}`,
`{{BACKEND_ENVIRONMENTS}}`, and secure `{{TEST_ACCOUNTS}}` references.

Execute family 3 read-only first. Redact environment secrets and do not assume
Postman/Figma/device access. Produce a plan before code changes; this stage
normally makes none. Cite collection item and code file evidence for endpoint,
screen, role, missing configuration/service, ambiguity, questions, blockers,
mockable work, and do-not-implement lists. Never fabricate a contract.
