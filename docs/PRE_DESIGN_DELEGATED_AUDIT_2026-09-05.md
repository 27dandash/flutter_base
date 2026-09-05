# Pre-design delegated audit

Evidence date: 2026-09-05. This is the final source-readiness pass before a
real consuming application begins Figma/design implementation.

## Verdict

The base is **ready to begin product design implementation** while retaining
its overall **Conditionally production-ready** release classification. There
is no remaining confirmed reusable-source blocker. Product credentials,
signing, real services, store delivery and full physical-device journeys remain
release gates for the derived application, not reasons to add heavy behavior to
the base.

## Delegated review

- Claude Code 2.1.170, Opus/high, read-only session
  `e976995a-56a6-4d01-8379-b82d44468d19` audited session, storage, network,
  startup, release and test boundaries. It found no High/Medium source defect
  and proposed corrupt-token self-healing as one Low improvement.
- Cursor Agent 2026.09.02, Composer 2.5, read-only session
  `c21cd3d5-3dae-4183-96d4-537e100e83a2` audited the canonical design system.
  It confirmed dark-mode dropdown text defects and the explicit multiline API
  mismatch. Its first resumed response lacked the required report and was not
  accepted; the same session then supplied the evidence-based audit. Its final
  re-review accepted the explicit 48dp constraint, design-width geometry test
  and secure-field line-limit regression test with no further rework.
- Codex reproduced each accepted finding with a failing behavior test, reviewed
  both reports, rejected non-defects and found the incomplete persisted-session
  gap that neither external reviewer reported.

Both relays were read-only and made no changes. Their artifacts are under
`/tmp/flutter-base-final-delegate.UeiCDl/`.

The final Claude re-review returned **ACCEPT** for generation ordering,
deadlock/re-entrancy, original-error preservation, newer-transition safety and
the fail-closed tests. The final Cursor re-review returned **ACCEPT** for both
of its blocking widget findings.

## Implemented corrections

1. `AppDropdown` uses `ColorScheme.onSurface` and `onSurfaceVariant` for its
   trigger, label, header, custom message and unselected rows. Caller color
   overrides and selected/error brand colors remain supported.
2. `AppDropdown` now enforces a 48dp minimum trigger height. A real `InkWell`
   geometry assertion runs at the 375x812 design viewport and DPR 1, avoiding
   a false pass caused by test-viewport scaling.
3. `DefaultTextField` honors explicit `maxLines`/`minLines` independently of
   keyboard type. Secure/password fields remain safely single-line.
4. A malformed versioned token record is replaced with an authoritative empty
   record and cannot poison every subsequent startup or resurrect legacy keys.
5. Token and user persistence are treated as one logical session. If user
   persistence fails after token persistence, `UserCubit` clears the complete
   session before preserving and rethrowing the original failure.
6. Restore clears token-only and user-only partial sessions. An orphan token can
   no longer be attached to requests while UI state is logged out.
7. Session-restore debug output no longer interpolates the raw exception.

## Rejected recommendations

- `AppPageShell.sliver` did not gain implicit bottom padding. Sliver content
  owns its terminal safe-area/padding because lists, pinned controls and nested
  scroll layouts require different behavior; a global default would break
  valid layouts.
- No new field wrappers, product components, global presenter, architecture
  migration or root optional integration was added.
- The Gradle checksum concern was already resolved: the pin matches Gradle's
  official 9.1.0 all-distribution SHA-256, the secure direct host returned the
  official artifact, wrapper verification passed and `gradlew help` evaluated
  the project. TLS verification was never disabled.

## Verification

The full gate passed 27/27 checks with Flutter 3.47.1 / Dart 3.13.1 before the
final review delta. After that delta, the root analyzer, complete root suite,
complete widget subset and the two documentation validators were rerun:

| Evidence | Result |
|---|---:|
| Root analyzer | no issues |
| Root tests, final | 277 passed, 2 expected conditional skips |
| Focused widget tests, final | 82 passed; subset of root |
| Root coverage at full-gate snapshot | 2,941/5,004 = 58.77% |
| PHP inverse | 15 passed, 3 expected opposite-branch skips |
| Optional packages | 85 passed |
| Optional examples | 3 passed |
| Code generation | reproducible; 88 AR/EN keys |
| Optional integration isolation | passed |
| Full quality gate | 27 checks, 0 skipped, 0 failed |
| Final root analyzer | no issues |
| Prompt/instruction validators | passed |

The targeted four-suite run passed 41/41 after the initial fixes. The final
dropdown/text-field delta passed 21/21 before the complete 277-test root run.
No device, emulator, simulator, production endpoint, credential, Git state
change, commit or push was used during this audit.

## Files changed by this pass

```text
docs/PRE_DESIGN_DELEGATED_AUDIT_2026-09-05.md
docs/REUSABLE_COMPONENT_CATALOG.md
docs/TEST_COUNT_RECONCILIATION.md
lib/src/core/network/auth/token_storage.dart
lib/src/core/shared/cubits/user_cubit/user_cubit.dart
lib/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart
lib/src/core/widgets/fields/drop_downs/app_drop_down/widgets/dropdown_item_tile.dart
lib/src/core/widgets/fields/drop_downs/app_drop_down/widgets/dropdown_sheet_header.dart
lib/src/core/widgets/fields/text_fields/default_text_field.dart
test/core/network/auth/token_storage_test.dart
test/core/shared/cubits/user_cubit/user_cubit_lifecycle_test.dart
test/core/widgets/app_dropdown_test.dart
test/core/widgets/default_text_field_test.dart
```

Recovery archive:
`/tmp/flutter-base-pre-final-audit-fixes.jqgFW1/files.tgz`.
