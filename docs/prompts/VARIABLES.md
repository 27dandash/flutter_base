# Variable-Filling Guide

| Variable | Fill with | Do not put here |
|---|---|---|
| `{{PROJECT_PATH}}` | Authorized project root | A parent directory containing unrelated projects |
| `{{FIGMA_URLS}}` | One or more file/node URLs and ownership notes | Access tokens |
| `{{COLLECTION_PATHS_OR_URLS}}` | Collection/environment locations | Secret environment values |
| `{{APP_VARIANTS}}` | All apps/brands/targets, or `one` | An assumed two-app list |
| `{{FLAVORS}}` | Build flavors and entry points | Signing credentials |
| `{{USER_ROLES}}` | Every role/persona and permissions source | Real personal data |
| `{{BACKEND_ENVIRONMENTS}}` | Local/test/staging/production topology | Passwords, tokens, private keys |
| `{{TEST_ACCOUNTS}}` | Secure reference or synthetic personas | Inline credentials |

Use `not applicable`, `unknown—discover`, or `blocked—ask owner` rather than
inventing a value. Lists may contain one, two, three, or any larger number.
