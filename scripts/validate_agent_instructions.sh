#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

fail() {
  echo "AGENT INSTRUCTIONS INVALID: $*" >&2
  exit 1
}

required=(
  AGENTS.md
  CLAUDE.md
  .codex/skills/flutter-base-production/SKILL.md
  .claude/skills/flutter-base-production/SKILL.md
  .cursor/rules/00-flutter-base-production.mdc
  docs/REUSABLE_COMPONENT_CATALOG.md
  docs/prompts/README.md
  scripts/flutter_quality_gate.sh
  scripts/check_project_identity.sh
  scripts/validate_prompt_library.sh
  tool/generate_locale_keys.dart
  tool/widget_gallery/main.dart
)
for path in "${required[@]}"; do
  [[ -e "$path" ]] || fail "referenced path does not exist: $path"
done

claude_active="$(find .claude/skills -type f -name 'SKILL.md' | wc -l | tr -d ' ')"
cursor_active="$(find .cursor/rules -type f -name '*.mdc' | wc -l | tr -d ' ')"
[[ "$claude_active" -eq 1 ]] || fail "expected one active Claude skill"
[[ "$cursor_active" -eq 1 ]] || fail "expected one active Cursor rule"

# The archives are template history; derived projects may delete them
# (scripts/start_new_project.sh). When present they must be complete.
if [[ -d .claude/reference/skills-legacy-2026-08 ]]; then
  claude_archived="$(find .claude/reference/skills-legacy-2026-08 -type f -name 'SKILL.md' | wc -l | tr -d ' ')"
  [[ "$claude_archived" -eq 29 ]] || fail "expected 29 archived Claude skills"
fi
if [[ -d .cursor/reference/rules-legacy-2026-08 ]]; then
  cursor_archived="$(find .cursor/reference/rules-legacy-2026-08 -type f -name '*.mdc' | wc -l | tr -d ' ')"
  [[ "$cursor_archived" -eq 29 ]] || fail "expected 29 archived Cursor rules"
fi

active=(
  AGENTS.md CLAUDE.md
  .codex/skills/flutter-base-production/SKILL.md
  .claude/skills/flutter-base-production/SKILL.md
  .cursor/rules/00-flutter-base-production.mdc
)
for legacy in md/CLAUDE.md md/HOW_TO_USE_PROMPTS.md; do
  [[ -f "$legacy" ]] && active+=("$legacy")
done

if grep -n -E '/Users/|scripts/sync-cursor\.sh|pre-commit hook|Dart 3\.10|core/notifications|pinput.*Already|flutter_offline' "${active[@]}"; then
  fail "an active instruction contains a personal path or obsolete directive"
fi

for file in AGENTS.md CLAUDE.md .codex/skills/flutter-base-production/SKILL.md; do
  grep -q 'flutter_quality_gate.sh' "$file" ||
    fail "$file must point to the executable quality gate"
done

for file in AGENTS.md CLAUDE.md .codex/skills/flutter-base-production/SKILL.md; do
  grep -q 'check_project_identity.sh' "$file" ||
    fail "$file must point to the cross-platform identity audit"
done

scripts/validate_prompt_library.sh >/dev/null
echo "Agent instructions valid: 1 Codex skill, 1 Claude skill, 1 Cursor rule; legacy archives complete or removed."
