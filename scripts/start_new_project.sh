#!/usr/bin/env bash
#
# Removes template-only material from a fresh clone so a derived project starts
# with just the code, the living docs and the agent instructions.
#
# Removed (history of how the base was built, not guidance for a product):
#   * docs/ audits, reports, change manifests and command logs
#   * docs/reports, reports/, md/ (legacy guides)
#   * .claude/reference, .cursor/reference (archived skills/rules/prompts)
#
# Kept: ARCHITECTURE, INTEGRATION_GUIDE, TEMPLATE_CUSTOMIZATION,
# REUSABLE_COMPONENT_CATALOG, HARDENING_NOTES, RELEASE_CHECKLIST, QA_MATRIX,
# SIZE_AUDIT, DEPENDENCY_COMPATIBILITY_AUDIT, docs/adr, docs/prompts and the
# active agent instructions.
#
# Usage:
#   scripts/start_new_project.sh          # asks for confirmation
#   scripts/start_new_project.sh --yes    # no prompt
#   scripts/start_new_project.sh --dry-run
#
set -euo pipefail
cd "$(dirname "$0")/.."

mode=ask
case "${1:-}" in
  --yes) mode=yes ;;
  --dry-run) mode=dry ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

targets=(
  docs/AGENT_INSTRUCTIONS_AUDIT.md
  docs/AUDIT_REPORT.md
  docs/CHANGE_MANIFEST.md
  docs/CODEX_INSTRUCTIONS_AUDIT.md
  docs/COMMAND_LOG_2026-08-27.md
  docs/CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31.md
  docs/CROSS_PROJECT_RECURRENCE.md
  docs/DEPENDENCY_AUDIT.md
  docs/FINAL_DEPENDENCY_LIVE_SKILLS_PROMPTS_REPORT.md
  docs/FINAL_INDEPENDENT_PRODUCTION_REVIEW_2026-09-03.md
  docs/PRE_DESIGN_DELEGATED_AUDIT_2026-09-05.md
  docs/PRE_QA_HISTORICAL_TESTER_AUDIT_2026-08-31.md
  docs/STANDARDS_AUDIT.md
  docs/TEST_COUNT_RECONCILIATION.md
  docs/THREE_PROVIDER_CLOSURE_2026-09-05.md
  docs/WIDGET_HARDENING_REPORT.md
  docs/reports
  reports
  md
  .claude/reference
  .cursor/reference
)

present=()
for t in "${targets[@]}"; do
  [[ -e "$t" ]] && present+=("$t")
done

if [[ ${#present[@]} -eq 0 ]]; then
  echo "✓ Nothing to remove; the template material is already gone."
  exit 0
fi

printf 'Will remove:\n'
printf '  %s\n' "${present[@]}"

case "$mode" in
  dry) echo "(dry run, nothing removed)"; exit 0 ;;
  ask)
    read -r -p "Continue? [y/N] " ans
    case "$ans" in [yY]|[yY][eE][sS]) ;; *) echo "Aborted."; exit 1 ;; esac
    ;;
esac

rm -rf "${present[@]}"
echo "✓ Removed ${#present[@]} template-only paths."

# Mentions in kept docs of removed markdown files.
dangling=0
for removed in "${present[@]}"; do
  [[ "$removed" == *.md ]] || continue
  while IFS= read -r hit; do
    echo "⚠ $hit"
    dangling=1
  done < <(grep -rIn --include='*.md' --include='*.mdc' \
    --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool \
    -F "$(basename "$removed")" . 2>/dev/null || true)
done
if [[ $dangling -eq 1 ]]; then
  echo "Update the lines above (they mention removed files)."
fi

echo "Next: scripts/flutter_quality_gate.sh quick"
