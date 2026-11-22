#!/usr/bin/env bash
#
# Removes template-only material from a fresh clone so a derived project starts
# with just the code, the living docs and the agent instructions.
#
# Removed (history of how the base was built, not guidance for a product):
#   * docs/HISTORY.md (archived audits, reports, change manifests, command logs)
#   * reports/, md/ (legacy guides)
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
  docs/HISTORY.md
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
