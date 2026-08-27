# How to Use the Prompt Library

The supported prompt system lives at `docs/prompts/README.md`. It has one
authoritative specification and 18 adapted prompts: six workflow families for
Codex, Cursor, and Claude.

1. Fill variables using `docs/prompts/VARIABLES.md` without credentials.
2. Choose the current workflow stage in `docs/prompts/SELECTION_GUIDE.md`.
3. Copy the adapter for the tool that will actually execute the work.
4. Keep the authoritative specification with the prompt context.
5. Preserve each stage's evidence for the next lifecycle step.
6. Run `scripts/validate_prompt_library.sh` after any prompt edit.

There is no Git hook and no generated Cursor/Claude mirror. The old duplicated
rules and prompts are preserved under `.claude/reference/` and
`.cursor/reference/` as non-binding historical evidence. Active tool guidance
is intentionally small and points to the shared prompt system, preventing drift
without pretending different tools have identical capabilities.
