# Three-provider production closure

Evidence date: 2026-09-05. Target: `flutter_base` only. This report records the
completed Claude, Cursor and Codex implementation/review cycle and supersedes
the provider-execution status in the earlier 2026-09-03 independent-review
snapshot. Historical artifact measurements retain their original phase labels.

## Verdict

The reusable source baseline is **Conditionally production-ready and safe to
freeze**. All confirmed, locally testable defects found in this cycle were
fixed without changing the base architecture, deleting reusable capabilities,
or moving optional integrations into the root binary. Product signing, real
backend/Firebase/APNs/Maps configuration, store delivery and complete physical-
device accessibility/notification journeys remain application-specific gates.

## Provider responsibilities and review

- Claude Code 2.1.170, Opus 4.8/high, session
  `2c628907-df4e-4271-8473-8dab3d87814e`: session-generation races, refresh
  synchronization, token durability, offline-queue ownership and notification
  registration cleanup.
- Cursor Agent 2026.09.02, Composer 2.5, sessions
  `298f1b84-e462-43d3-9741-19eb1bb80ac8` and
  `5213ca43-7148-4c75-88a9-dfd2ec8367a9`: canonical/compatibility widgets and
  the Notifications, Maps, WebView, Socket and Remote Config optional packages.
- Codex: inspected both implementations, rejected or corrected false-positive
  tests and regressions, restored five overwritten Maps tests, tightened the
  notification lifecycle, added missing negative tests, reconciled counts,
  hardened CI/prompt tooling and ran the final gates.

No delegated result was accepted solely because it passed its own tests. In
particular, Codex corrected a false 48 dp assertion so it exercises the real
button, removed an unnecessary recommended global presenter, restored lost Maps
coverage, and made notification lifecycle tests deterministic.

## Closed findings

- Old refreshes and responses cannot save tokens, retry requests or terminate a
  newer session after logout/account switching.
- Token-pair persistence is serialized, versioned and fail-closed, with legacy
  migration and generation-safe mutations.
- Offline work is owner/generation scoped across initialization, clearing,
  replay and each asynchronous boundary; authenticated ciphertext rejects an
  altered owner scope.
- Refresh and retry preserve `Accept-Language`.
- Notification registration has compensating cleanup, lifecycle seams, safe
  URL policy and redacted logging.
- Widget disabled/loading/back/error/upload/dropdown/filter behaviors have
  regression coverage; raw technical failures are not rendered to users.
- Maps states/messages, WebView navigation policy, Socket authentication
  failures and Remote Config initialization status have explicit tests.
- Optional-package examples are analyzed and tested by CI when present.
- Claude, Cursor and Codex production prompts now reference only executable
  project-local quality, release, QA and size guidance. Archived Cursor rules
  cannot accidentally apply globally.
- Codegen checks AR/EN key counts dynamically; the current reproducible count is
  88 keys per locale.

## Verification totals

`scripts/flutter_quality_gate.sh full` passed 27 checks with zero skips or
builds using Flutter 3.47.1 and Dart 3.13.1:

| Suite | Passed | Expected skips | Failed |
|---|---:|---:|---:|
| Root/default | 270 | 2 | 0 |
| PHP inverse | 15 | 3 | 0 |
| Notifications | 32 | 0 | 0 |
| Remote Config | 17 | 0 | 0 |
| WebView | 12 | 0 | 0 |
| Maps | 14 | 0 | 0 |
| Socket | 10 | 0 | 0 |
| Optional examples | 3 | 0 | 0 |

Root line coverage is 2,908/4,980 = **58.39%**. The focused
`test/core/widgets` result is **79 passed** and is a subset of the 270 root
tests. Likewise, the previously reported 61 focused widget tests were a subset
of their then-current root total, never an additional suite. Counting only the
two inverse-only PHP assertions gives 360 non-duplicated verified behaviors.

Root and optional analyzers passed. Formatting checked 320 files with no
changes. Prompt validation, agent-instruction validation, optional-isolation,
architecture, assets, localization parity, code generation and `git diff
--check` passed. The standalone final codegen rerun reproduced generated output
and reported 88 AR/EN keys.

## Artifact and device limits

A fresh production Universal APK was built successfully with the same
`--split-debug-info=build/symbols/production` symbol-packaging conditions as
the post-identity artifact:

| Artifact | Bytes | SHA-256 | Result |
|---|---:|---|---|
| Universal production APK | 49,921,628 | `fd4eb7db82c07da8c5be61fee6f730607b7e53fb542734d636f46d6dc99888c1` | build and optional-integration isolation passed |

This is 132 bytes (+0.000264%) above the comparable 49,921,496-byte
post-identity Universal APK. The output and 6.1 MiB external Dart symbols could
not be retained after measurement because the data volume reached 100%; an
attempted copy to `/tmp` failed because it is on the same volume. The partial
copy was deleted and is not treated as evidence. The recorded bytes and digest
were taken from the complete APK before safe build-directory cleanup.

The current AAB and split APKs were not rebuilt. The original
`services.gradle.org` wrapper URL failed before compilation because that host
resolved locally with a TLS certificate hostname mismatch. TLS verification
was not bypassed. The wrapper now uses Gradle's working official direct download
host and pins the published Gradle 9.1.0 all-distribution SHA-256. A wrapper
download and project-evaluation check passed: Gradle 9.1.0 ran on Java 17 and
`gradlew help` completed. Storage remained constrained at roughly 2.5 GiB free,
so APK/AAB size budgets and a fresh release install still require a separate
artifact run with adequate workspace headroom. Gradle also emitted a non-fatal
forward-compatibility notice for Flutter's future Built-in Kotlin migration;
that migration is an SDK-upgrade task, not a current Gradle 9.1 build failure.

The authoritative historical phase measurements remain:

- post-widget-hardening AAB: 50,618,821 bytes; the unsupported 50,618,560-byte
  number is superseded;
- dependency/live phase AAB: 50,651,242 bytes;
- post-identity AAB: 50,659,286 bytes.

They describe different retained builds and neither is relabeled as the current
artifact. Universal comparisons in their source reports use the symbol-
packaging configuration recorded beside each command/checksum.

A connected Samsung SM-A235F/API 34 was discovered read-only. No install or
launch reached the device in this closure: the first attempt stopped at the TLS
failure, and after the secure wrapper fix the remaining disk headroom was not
safe for a full release build/install matrix. No emulator or simulator was
created. The existing Samsung smoke and native-build results remain historical
evidence, not fresh evidence for these edits.

## Commands used for final verification

Commands were run from the project root with
`/Users/abdelrahamndandash/Documents/SDK/flutter` as the selected SDK:

```text
flutter pub get --offline
bash -n scripts/check_codegen_reproducibility.sh
bash -n scripts/validate_prompt_library.sh
bash -n scripts/validate_agent_instructions.sh
scripts/check_codegen_reproducibility.sh
scripts/validate_prompt_library.sh
scripts/validate_agent_instructions.sh
scripts/flutter_quality_gate.sh full
flutter test test/core/widgets
dart format --output=none --set-exit-if-changed .
flutter analyze
git diff --check
flutter devices --machine
cd android && ./gradlew --version
cd android && ./gradlew help --quiet
flutter build apk --release --flavor production -t lib/main_production.dart --split-debug-info="$PWD/build/symbols/production"
stat -f 'APK bytes=%z' build/app/outputs/flutter-apk/app-production-release.apk
shasum -a 256 build/app/outputs/flutter-apk/app-production-release.apk
unzip -Z1 build/app/outputs/flutter-apk/app-production-release.apk
```

The failed integration/build probes are intentionally not presented as passed:
`flutter test integration_test` selected the physical Android target and Gradle
failed during its verified download. Subsequent host-only probing demonstrated
that the integration gallery requires mobile plugin channels; experimental
host seams were reverted completely.

## Recovery and repository safety

Recoverable pre-edit archives are outside build directories:

- `/tmp/flutter-base-pre-delegation.L70SAv`
- `/tmp/flutter-base-pre-cursor-widgets.hkdgwf`
- `/tmp/flutter-base-pre-cursor-optionals.wFcVmY`
- `/tmp/flutter-base-final-closure.sponGr/final-closure-files.tgz`
- `/tmp/flutter-base-gradle-wrapper.g7ljIy/gradle-wrapper.properties`

Only target build caches were removed when disk space was exhausted. No source,
asset or reusable implementation was deleted. Reference projects were not
modified. No Git state-changing command, commit, merge, push, reset, checkout,
restore, clean or stash was performed.

## Exact target files changed in this cycle

The list below is the complete 85-file working-tree manifest including this
report:

```text
.claude/skills/flutter-base-production/SKILL.md
.cursor/reference/rules-legacy-2026-08/error-handling-and-resilience.mdc
.cursor/reference/rules-legacy-2026-08/flutter-base-coding-standards.mdc
.cursor/reference/rules-legacy-2026-08/flutter-feature-development.mdc
.cursor/reference/rules-legacy-2026-08/post-feature-review.mdc
.cursor/reference/rules-legacy-2026-08/scaffold-statusbar.mdc
.cursor/reference/rules-legacy-2026-08/widget-efficiency.mdc
.cursor/rules/00-flutter-base-production.mdc
.github/workflows/flutter_quality.yml
assets/translations/ar.json
assets/translations/en.json
android/gradle/wrapper/gradle-wrapper.properties
docs/DEPENDENCY_AUDIT.md
docs/FINAL_INDEPENDENT_PRODUCTION_REVIEW_2026-09-03.md
docs/QA_MATRIX.md
docs/TEST_COUNT_RECONCILIATION.md
docs/THREE_PROVIDER_CLOSURE_2026-09-05.md
docs/prompts/claude/06-production-readiness.md
docs/prompts/codex/06-production-readiness.md
docs/prompts/cursor/06-production-readiness.md
lib/src/config/language/locale_keys.g.dart
lib/src/core/network/auth/token_storage.dart
lib/src/core/network/interceptors/auth_interceptor.dart
lib/src/core/network/offline/offline_queue_manager.dart
lib/src/core/network/options/request_extra.dart
lib/src/core/shared/cubits/user_cubit/user_cubit.dart
lib/src/core/shared/helpers/loading_manager.dart
lib/src/core/state/paginated/paginated_list_widget.dart
lib/src/core/widgets/buttons/default_button.dart
lib/src/core/widgets/custom_messages.dart
lib/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart
lib/src/core/widgets/fields/text_fields/default_text_field.dart
lib/src/core/widgets/handling_views/error_view.dart
lib/src/core/widgets/image_widgets/upload_image.dart
lib/src/core/widgets/pickers/custom_dialog.dart
lib/src/core/widgets/unauthenticated/unauthenticated_bottomsheet.dart
lib/src/features/products/presentation/controllers/products_view_controller.dart
lib/src/features/products/presentation/widgets/products_filter_sheet.dart
md/EXAMPLES.md
packages/app_maps/README.md
packages/app_maps/example/ios/Runner/Info.plist
packages/app_maps/lib/src/app_map_page.dart
packages/app_maps/lib/src/map_models.dart
packages/app_maps/test/app_map_page_test.dart
packages/app_maps/test/map_selection_controller_test.dart
packages/app_notifications/NOTIFICATION_GUIDE.md
packages/app_notifications/lib/app_notifications.dart
packages/app_notifications/lib/src/notification_controller.dart
packages/app_notifications/lib/src/notification_manager.dart
packages/app_notifications/lib/src/notification_manager_platform.dart
packages/app_notifications/lib/src/notification_url_policy.dart
packages/app_notifications/lib/src/registration/notification_registration_coordinator.dart
packages/app_notifications/test/notification_logging_test.dart
packages/app_notifications/test/notification_manager_lifecycle_test.dart
packages/app_notifications/test/notification_registration_coordinator_test.dart
packages/app_notifications/test/notification_url_policy_test.dart
packages/app_remote_config/README.md
packages/app_remote_config/lib/app_remote_config.dart
packages/app_remote_config/test/app_remote_config_test.dart
packages/app_socket/README.md
packages/app_socket/lib/src/generic_socket_client.dart
packages/app_socket/lib/src/socket_models.dart
packages/app_socket/test/generic_socket_client_test.dart
packages/app_webview/test/app_webview_behavior_test.dart
packages/app_webview/test/webview_navigation_policy_test.dart
scripts/check_codegen_reproducibility.sh
scripts/validate_prompt_library.sh
test/core/network/auth/token_storage_test.dart
test/core/network/dio_network_audit_test.dart
test/core/network/offline/offline_queue_cipher_test.dart
test/core/network/offline/offline_queue_clear_before_init_test.dart
test/core/network/offline/offline_queue_clear_during_init_test.dart
test/core/shared/cubits/user_cubit/user_cubit_lifecycle_test.dart
test/core/widgets/app_dropdown_test.dart
test/core/widgets/app_error_handler_test.dart
test/core/widgets/app_state_view_test.dart
test/core/widgets/blocking_overlay_test.dart
test/core/widgets/default_text_field_test.dart
test/core/widgets/dialog_feedback_test.dart
test/core/widgets/legacy_widget_regressions_test.dart
test/core/widgets/localized_widget_harness.dart
test/core/widgets/paginated_list_widget_test.dart
test/core/widgets/unauthenticated_bottomsheet_test.dart
test/core/widgets/upload_image_widget_test.dart
test/features/products/products_view_controller_test.dart
```
