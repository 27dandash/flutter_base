# Project-Local Agent Instruction Audit

Audit date: 2026-08-27. The former Claude/Cursor mirror contained 29 skill
families, 29 Cursor rules, three duplicate prompt files, and filesystem-hidden
copies. It also referenced a nonexistent sync script and pre-commit hook,
described optional notifications as root code, named removed dependencies, and
fixed the language baseline at Dart 3.10.

No historical file was discarded. The exact former trees are preserved under
`.claude/reference/skills-legacy-2026-08/` and
`.cursor/reference/{rules-legacy-2026-08,prompts-legacy-2026-08}/`. A second
recoverable copy was made outside the project before consolidation.

## Individual skill decisions

Each row covers the former Claude skill and matching Cursor rule. Archived
references are not active instructions and may not override current source.

| Skill/instruction | Owner/tool | Purpose | Matching current capability | Referenced paths accurate before audit | Conflict/duplication | Decision |
|---|---|---|---|---|---|---|
| accessibility | Claude/Cursor | Semantics, targets, contrast | Canonical widget tests/catalog | Partly | Duplicated active standards | Merge into active production skill/catalog; archive original |
| api-design | Claude/Cursor | Create API/Postman contracts | Prompt families 3–4 | No; assumed one backend style/status set | Conflicted with contract-first rule | Convert to prompt specification; archive original |
| api-pipeline | Claude/Cursor | Contract-to-feature pipeline | `BaseRemoteSource`, features, network docs | Mostly | Repeated architecture templates | Merge into active skill/current docs; archive original |
| bloc-patterns | Claude/Cursor | Async/paginated Cubit | `core/state` | Mostly | Repeated widget/state rules | Merge into active skill/catalog; archive original |
| bloc-provider-scoping | Claude/Cursor | Provider ownership | Feature composition | Mostly | Overlapped BLoC/DI skills | Merge; archive original |
| clean-code-and-refactoring | Claude/Cursor | Maintainability | `AGENTS.md` architecture rules | Generic | Duplicated coding standards | Merge; archive original |
| coding-standards | Claude/Cursor | Master rulebook | Current source/catalog | No; stale widgets, packages, notifications and SDK | Largest conflict source | Replace with small active production skill; archive original |
| design-tokens | Claude/Cursor | Figma-token mapping | `config/res`, Figma prompt family | Mostly | Repeated Figma skills | Retain as historical mapping; active work uses shared spec/current tokens |
| di-and-architecture | Claude/Cursor | Injectable/GetIt boundaries | Composition root and module tests | Mostly | Duplicated architecture rules | Merge; archive original |
| error-handling-and-resilience | Claude/Cursor | Typed failures/retries | `Failure`, parser, state widgets | Partly; raw message assumptions differed | Conflicted with safe localized copy | Merge into active skill/current code; archive original |
| feature-development | Claude/Cursor | Full feature workflow | Active skill + prompt lifecycle | No; stale surface and mandatory rewrites | Duplicated feature-prompt | Merge into active skill and prompt library; archive original |
| feature-prompt | Claude/Cursor | Pasteable feature prompt | `docs/prompts/` | No; stale toolchain/integrations | Duplicate of feature-development | Replace with six-family tool adapters; archive original |
| figma-mcp-mapping | Claude/Cursor | Figma values to tokens | Current tokens and Figma adapters | Mostly | Overlapped two Figma skills | Convert to historical mapping; tool prerequisites now explicit in Codex prompt |
| figma-task-extractor | Claude/Cursor | Split Figma into tasks | Design inventory/matrices | Tool-dependent | Assumed tool access | Convert to documentation; adapters gate real access |
| figma-to-flutter | Claude/Cursor | Implement Figma | Canonical widgets/tokens | Partly; legacy widgets | Overlapped mapping skills | Merge into prompt library/current catalog; archive original |
| figma-widget-mapping | Claude/Cursor | Node-to-widget mapping | Canonical catalog | Partly; legacy families | Overlapped Figma skills | Convert to reference; archive original |
| flutter-patterns | Claude/Cursor | Widget/file patterns | Current feature/core layout | Partly; promoted compatibility widgets | Duplicated coding/widget skills | Merge into active skill/catalog; archive original |
| form-api-pipeline | Claude/Cursor | Form submission flow | `DefaultTextField`, `AppButton`, `BaseRemoteSource` | Partly; legacy loading button | Duplicated API/BLoC skills | Merge; archive original |
| logging-and-debugging | Claude/Cursor | Diagnostics/redaction | `AGENTS.md` security rules | Mostly | Small duplicate | Merge into active production skill; archive original |
| multi-screen-flow | Claude/Cursor | List/detail/edit/create | Feature routing/state | Mostly | Duplicated navigation/API guidance | Merge; archive original |
| navigation-patterns | Claude/Cursor | Go/router usage | Current router and `AppPageShell` | Partly; absolute “never Navigator” conflicted with framework modal internals | Duplicated flow skill | Merge with contextual navigation rule; archive original |
| notifications | Claude/Cursor | FCM/Awesome Notifications | `packages/app_notifications` | No; claimed `core/notifications` root module | Violated optional isolation | Convert to optional-package documentation; archive original |
| performance-and-memory | Claude/Cursor | Lifecycle/rebuild rules | Widget/state tests | Mostly | Over-strict blanket `setState` language elsewhere | Merge as evidence-based rules; archive original |
| post-feature-review | Claude/Cursor | Completion checklist | Quality gate and prompt family 6 | Mostly | Duplicate always-on rule | Merge into gates/readiness prompt; archive original |
| pubspec-manager | Claude/Cursor | Dependency/platform changes | Pubspecs and dependency audit | No; listed removed packages as installed | Conflicted with actual graph | Replace with inspect/outdated/gate workflow; archive original |
| rtl-arabic | Claude/Cursor | Arabic and directionality | Localization/assets/widget tests | Mostly | Duplicated design/widget rules | Merge into active skill/catalog; archive original |
| scaffold-patterns | Claude/Cursor | Page chrome/status bar | `AppPageShell`, legacy `DefaultScaffold` | Partly | Promoted legacy scaffold | Merge around `AppPageShell`; archive original |
| search-field-debounce | Claude/Cursor | Search with Rx debounce | `rxdart`, feature-owned search | Mostly | Narrow reusable example | Convert to documentation; archive original |
| widget-efficiency | Claude/Cursor | Semantic shallow widget trees | Flutter framework + canonical catalog | Partly; stylistic absolutes and legacy examples | 1,700+ line always-on rule | Convert to reference; active rule requires measurable benefit |

## Other instruction surfaces

| Instruction | Owner/tool | Accuracy/decision |
|---|---|---|
| `AGENTS.md` | Codex/all | Retained and updated; authoritative repository behavior |
| `.codex/skills/flutter-base-production/SKILL.md` | Codex | Retained and updated; references only real scripts/catalog/prompts |
| root `CLAUDE.md` | Claude | Added as authoritative entry point |
| `.claude/skills/flutter-base-production/SKILL.md` | Claude | Added as the single discoverable project skill |
| `.cursor/rules/00-flutter-base-production.mdc` | Cursor | Added as the single active always-on rule |
| `md/CLAUDE.md` | Historical readers | Replaced by a compatibility pointer; full prior text archived |
| `md/HOW_TO_USE_PROMPTS.md` | All | Replaced with the real prompt-library workflow; removed nonexistent Git-hook/sync claims |
| former `.cursor/prompt/*` | Cursor | Archived; superseded by six Cursor adapters |
| `docs/prompts/*` | Codex/Cursor/Claude | Added shared authoritative spec, 18 adapters, guides, examples, lifecycle, and validation |

## Precedence

1. Explicit user instruction.
2. `AGENTS.md` and root `CLAUDE.md`.
3. The active tool-specific production skill/rule.
4. Current source, tests, and current `docs/`.
5. Historical archives for context only.

The active surfaces contain no personal absolute paths, credentials, missing
scripts, Git-hook assumptions, fixed app count, or concrete optional integration
inside the root.
