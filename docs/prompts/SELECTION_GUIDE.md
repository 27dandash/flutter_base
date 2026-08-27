# Prompt Selection Guide

Use one prompt at a time and preserve its output as input evidence for the next
stage.

| Situation | Prompt family |
|---|---|
| Requirements exist but design does not | 1 — Create design |
| Figma is said to be complete | 2 — Review design |
| Collection exists and coding has not started | 3 — Review collection |
| Team claims the collection covers the product | 4 — Prove completeness |
| App is implemented and a test backend is authorized | 5 — Live comparison |
| Release candidate exists | 6 — Production readiness |

Choose the adapter for the tool that will actually execute the work. Do not use
a Codex adapter in Cursor or Claude merely because it mentions more tools.
