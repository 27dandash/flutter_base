#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_ROOT="$PROJECT_ROOT/docs/prompts"

fail() {
  echo "PROMPT LIBRARY INVALID: $*" >&2
  exit 1
}

[[ -f "$PROMPT_ROOT/AUTHORITATIVE_SPEC.md" ]] ||
  fail "missing AUTHORITATIVE_SPEC.md"
[[ -f "$PROJECT_ROOT/docs/REUSABLE_COMPONENT_CATALOG.md" ]] ||
  fail "missing canonical component catalog"
for concept in \
  'Android and iOS' \
  'native splash' \
  'Remote Config' \
  'APNs' \
  'temporary Figma/MCP asset' \
  'reference-frame size' \
  'saved response examples' \
  'empty and non-empty responses'; do
  grep -Fq "$concept" "$PROMPT_ROOT/AUTHORITATIVE_SPEC.md" ||
    fail "authoritative prompt spec is missing concept: $concept"
done

mapfile_safe() {
  while IFS= read -r line; do
    printf '%s\0' "$line"
  done
}

prompt_files=()
while IFS= read -r -d '' file; do
  prompt_files+=("$file")
done < <(
  find "$PROMPT_ROOT" -mindepth 2 -maxdepth 2 -type f \
    \( -path '*/codex/*.md' -o -path '*/cursor/*.md' -o -path '*/claude/*.md' \) \
    -print | sort | mapfile_safe
)

[[ "${#prompt_files[@]}" -eq 18 ]] ||
  fail "expected 18 tool prompts, found ${#prompt_files[@]}"

variables=(
  PROJECT_PATH FIGMA_URLS COLLECTION_PATHS_OR_URLS APP_VARIANTS FLAVORS
  USER_ROLES BACKEND_ENVIRONMENTS TEST_ACCOUNTS
)

for tool in codex cursor claude; do
  count="$(find "$PROMPT_ROOT/$tool" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
  [[ "$count" -eq 6 ]] || fail "$tool must contain six prompt families"
done

for file in "${prompt_files[@]}"; do
  grep -Eiq 'AUTHORITATIVE_SPEC\.md|authoritative' "$file" ||
    fail "$file does not bind to the shared specification"
  for variable in "${variables[@]}"; do
    grep -q "{{${variable}}}" "$file" ||
      fail "$file is missing {{${variable}}}"
  done
  if grep -Eq '/Users/|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|password[[:space:]]*[:=][[:space:]]*[^<{[:space:]]+' "$file"; then
    fail "$file contains a personal path or credential-like value"
  fi
done

for file in "$PROMPT_ROOT"/codex/*.md; do
  grep -q 'AGENTS.md' "$file" || fail "$file must require AGENTS.md"
done
for file in "$PROMPT_ROOT"/cursor/*.md; do
  grep -q 'Agent mode' "$file" || fail "$file must select Cursor Agent mode"
  grep -Eiq 'index|indexing' "$file" || fail "$file must require repository indexing"
done
for file in "$PROMPT_ROOT"/claude/*.md; do
  grep -q 'CLAUDE.md' "$file" || fail "$file must require CLAUDE.md"
  grep -q 'ledger' "$file" || fail "$file must preserve a task ledger"
done

if grep -R -n -E 'assume(s|d)? exactly two|fabricate (an )?(API|endpoint)|mocked.*as real' \
  "$PROMPT_ROOT"/codex "$PROMPT_ROOT"/cursor "$PROMPT_ROOT"/claude; then
  fail "a tool prompt contains a forbidden assumption"
fi

echo "Prompt library valid: 18 tool prompts, shared spec, variables, and tool adapters verified."
