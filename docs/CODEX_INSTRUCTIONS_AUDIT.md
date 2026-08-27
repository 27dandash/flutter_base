# Project-local instruction audit

## Verdict

`AGENTS.md` and `.codex/skills/flutter-base-production/SKILL.md` are the
canonical instructions for Codex. The new skill is repository-local and does
not change global Codex configuration.

The repository also contains 29 Claude skills plus Cursor rules/prompts and
older `md/` guides. They are retained because they contain useful historical
context, but they are not the source of truth for Codex.

## Conflicts found

| Legacy statement | Current evidence | Resolution |
|---|---|---|
| Dart 3.10 | Current SDK is Dart 3.13.1 | Current toolchain wins |
| Translation source is `lang.json` | Root uses `assets/translations/ar.json` and `en.json` | Current assets/tests win |
| Notifications are already wired in root | Notifications are an optional package and root absence is tested | Optional boundary wins |
| Arabic font is Expo Arabic | Root design system uses Beiruti | Current `pubspec.yaml` wins |
| Material icons must never be used | Framework icons are valid when accessible and tree-shaken | Component/design decision wins |
| Dropdown error UI is prohibited | Production dropdown contract requires loading/empty/error/retry | Current widget contract wins |
| Global context/loading helpers are acceptable | Architecture forbids retained global UI state | Context-owned APIs win |

## Required future behavior

Codex must inspect the reusable catalog, reuse approved components, keep heavy
integrations optional, test meaningful failure/lifecycle branches, verify
localization/accessibility/platform effects, and document justified deviations.
It must not hardcode keys, change backend contracts silently, or introduce fake
data/caching to hide defects.
