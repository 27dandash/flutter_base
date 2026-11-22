# Project history

One archive of the point-in-time audits, reports and logs produced while building this base. It is not guidance for a product: `scripts/start_new_project.sh` removes it from derived projects. Current guidance lives in `ARCHITECTURE.md`, `INTEGRATION_GUIDE.md`, `RELEASE_CHECKLIST.md` and `AGENTS.md`.

## Contents

- [AGENT_INSTRUCTIONS_AUDIT.md](#agentinstructionsaudit)
- [AUDIT_REPORT.md](#auditreport)
- [CHANGE_MANIFEST.md](#changemanifest)
- [CODEX_INSTRUCTIONS_AUDIT.md](#codexinstructionsaudit)
- [COMMAND_LOG_2026-08-27.md](#commandlog2026-08-27)
- [CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31.md](#crossprojectcodexhistoryaudit2026-08-31)
- [CROSS_PROJECT_RECURRENCE.md](#crossprojectrecurrence)
- [DEPENDENCY_AUDIT.md](#dependencyaudit)
- [FINAL_DEPENDENCY_LIVE_SKILLS_PROMPTS_REPORT.md](#finaldependencyliveskillspromptsreport)
- [FINAL_INDEPENDENT_PRODUCTION_REVIEW_2026-09-03.md](#finalindependentproductionreview2026-09-03)
- [PRE_DESIGN_DELEGATED_AUDIT_2026-09-05.md](#predesigndelegatedaudit2026-09-05)
- [PRE_QA_HISTORICAL_TESTER_AUDIT_2026-08-31.md](#preqahistoricaltesteraudit2026-08-31)
- [STANDARDS_AUDIT.md](#standardsaudit)
- [TEST_COUNT_RECONCILIATION.md](#testcountreconciliation)
- [THREE_PROVIDER_CLOSURE_2026-09-05.md](#threeproviderclosure2026-09-05)
- [WIDGET_HARDENING_REPORT.md](#widgethardeningreport)
- [PROJECT_IDENTITY_MIGRATION_REPORT.md](#projectidentitymigrationreport)


---

## AGENT_INSTRUCTIONS_AUDIT

*Source: `docs/AGENT_INSTRUCTIONS_AUDIT.md`*

### Project-Local Agent Instruction Audit

Audit date: 2026-08-27. The former Claude/Cursor mirror contained 29 skill
families, 29 Cursor rules, three duplicate prompt files, and filesystem-hidden
copies. It also referenced a nonexistent sync script and pre-commit hook,
described optional notifications as root code, named removed dependencies, and
fixed the language baseline at Dart 3.10.

No historical file was discarded. The exact former trees are preserved under
`.claude/reference/skills-legacy-2026-08/` and
`.cursor/reference/{rules-legacy-2026-08,prompts-legacy-2026-08}/`. A second
recoverable copy was made outside the project before consolidation.

#### Individual skill decisions

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

#### Other instruction surfaces

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

#### Precedence

1. Explicit user instruction.
2. `AGENTS.md` and root `CLAUDE.md`.
3. The active tool-specific production skill/rule.
4. Current source, tests, and current `docs/`.
5. Historical archives for context only.

The active surfaces contain no personal absolute paths, credentials, missing
scripts, Git-hook assumptions, fixed app count, or concrete optional integration
inside the root.


---

## AUDIT_REPORT

*Source: `docs/AUDIT_REPORT.md`*

### Final production-base audit

Audit reproduced and extended: 2026-08-27. Base: supplied local tree corresponding to upstream
`main` at the start of the work. No Git repository was initialized and no
commit/push was made. The `rahoul` and `herajone` reference projects were not
modified.

#### Verdict

**Conditionally production-ready.** The root and all optional packages resolve,
analyze, test, and build under the pinned Flutter 3.47.1 / Dart 3.13.1 toolchain.
The binary-size anomaly is explained byte-for-byte and materially reduced. This
is still a reusable template, not a signed store product.

| Area | Result |
| --- | --- |
| Size | ARM64 distribution APK 18,816,110; AAB 50,618,227; representative Play download 9,247,946 bytes |
| Optimization | -2,725,888 ARM64 APK and -4,496,394 AAB versus supplied baseline, with functionality retained |
| Optional isolation | Firebase/notifications, Remote Config, WebView, Maps and Socket contribute zero to root artifacts |
| Architecture | Domain/optional boundaries are now executable tests; startup/session/security policies remain intact |
| Assets | Explicit 16-file manifest, 2,037,307 source bytes, no duplicate hash, missing/key-parity tests |
| Android | R8/resource shrinking, non-debuggable production, ABI splits, AAB and external symbols verified |
| iOS | Simulator flavor builds are valid compile checks; signed archive/thinning/download size is blocked |
| Product release | Blocked by real IDs/signing/backend/TLS rotation/Firebase/APNs/Maps/deep links/privacy/store/device QA |

#### Findings fixed

- Upgraded `file_picker` from 10.3.10 to 12.1.1 and migrated its API, removing
  Apache Tika from Android DEX/resources and resolving the optional Maps
  package's `win32` constraint.
- Upgraded `share_plus` to 13.3.0 for the current built-in-Kotlin-compatible
  plugin line.
- Replaced directory-wide assets with explicit runtime files; removed 28
  verified-unused/duplicate files and regenerated `AppAssets`.
- Added executable root/domain/optional boundary checks, missing-asset and
  Arabic/English translation-key parity checks.
- Added root-plus-each-optional resolution checks, measured size budgets,
  ABI-split distribution builds, and CI retention of Dart/R8/native symbols.
- Added the detailed size report, missing-standards ownership map, ADRs, and
  product customization/upgrade/removal instructions.
- Added redacted network/Bloc diagnostics, latest-result-wins async state,
  hardened pagination and retryable paginated dropdown behavior.
- Added `AppButton`, scoped blocking overlay state, tests for accessibility,
  duplicate submission, cancellation, concurrency, thrown calls and disposal.
- Added the recurrence inventory, reusable catalog, exact test reconciliation,
  dependency/license/OSV audit and a validated repository-local Codex skill.

No security or maintained dependency was removed solely for size. Lottie is the
largest reachable non-framework Dart package at 362,490 decompressed AOT bytes,
but it powers intentional shared state UI and was retained. Secure storage,
authenticated cryptography, networking, session cleanup, media acquisition and
optional source packages were retained.

#### Evidence map

- `SIZE_AUDIT.md`: matched minimal control, exact artifact/components,
  dependency-by-dependency attribution, optional increments, bundletool device
  estimate, budgets, commands, symbol policy and iOS limitation.
- `STANDARDS_AUDIT.md`: every requested architecture, release, security,
  reliability, performance, accessibility, localization, design, testing,
  observability and platform capability classified by owner/status.
- `RELEASE_CHECKLIST.md`: reproducible commands, release/symbol/rollback and
  blocked inputs.
- `QA_MATRIX.md`: automated and manual/device requirements traceability.
- `CHANGE_MANIFEST.md`: edited, added and removed paths.
- `CROSS_PROJECT_RECURRENCE.md`, `REUSABLE_COMPONENT_CATALOG.md`,
  `TEST_COUNT_RECONCILIATION.md`, `DEPENDENCY_AUDIT.md` and
  `CODEX_INSTRUCTIONS_AUDIT.md`: reuse/discovery/test/dependency evidence.

#### Remaining warnings and blocks

Flutter reports that the app plus `image_picker_android`,
`shared_preferences_android`, and `url_launcher_android` still apply the Kotlin
Gradle Plugin. It is not suppressed: this exact stack builds, but a coordinated
Built-in Kotlin migration remains future work as upstream plugins permit.

Production needs approved identifiers, signing stored outside source, real
backend and overlapping TLS pins, privacy/data-safety declarations, Firebase/
APNs and Maps configuration if enabled, deep-link association, crash-provider
consent and symbol upload, store exports, and representative physical-device
journeys. The controlled startup failure with placeholder production config is
expected behavior, not a release-ready product launch.


---

## CHANGE_MANIFEST

*Source: `docs/CHANGE_MANIFEST.md`*

### Exact change manifest

This is the exact source-file delta between the final audited tree and the
supplied upstream `main` commit `cca26f9746832fee13f9e502833f5aa517f73ee7`.
Machine-local/generated build state (`build`, `.dart_tool`, Gradle caches,
Flutter ephemeral files, local properties, iOS generated registrants, and
unrelated editor/agent metadata) is excluded. Build artifacts are evidence,
not source deliverables.

#### Added or modified

- `.fvmrc`
- `.github/workflows/flutter_quality.yml`
- `.gitignore`
- `AGENTS.md`
- `README.md`
- `analysis_options.yaml`
- `android/app/build.gradle.kts`
- `android/app/proguard-rules.pro`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
- `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.jar`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/gradlew`
- `android/gradlew.bat`
- `android/settings.gradle.kts`
- `config/example.json`
- `docs/ARCHITECTURE.md`
- `docs/AUDIT_REPORT.md`
- `docs/CHANGE_MANIFEST.md`
- `docs/INTEGRATION_GUIDE.md`
- `docs/QA_MATRIX.md`
- `docs/RELEASE_CHECKLIST.md`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/development.xcscheme`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/production.xcscheme`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/staging.xcscheme`
- `ios/Runner.xcworkspace/contents.xcworkspacedata`
- `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `ios/Runner/Info.plist`
- `ios/scripts/copy_firebase_config.sh`
- `lib/bootstrap/app_environment.dart`
- `lib/bootstrap/bootstrap.dart`
- `lib/main.dart`
- `lib/main_development.dart`
- `lib/main_production.dart`
- `lib/main_staging.dart`
- `lib/src/app.dart`
- `lib/src/config/app_config.dart`
- `lib/src/config/language/languages.dart`
- `lib/src/config/language/locale_keys.g.dart`
- `lib/src/config/res/assets.gen.dart`
- `lib/src/config/res/config_imports.dart`
- `lib/src/config/res/constants_manager.dart`
- `lib/src/config/themes/app_theme.dart`
- `lib/src/core/navigation/Constants/router_constants.dart`
- `lib/src/core/navigation/Transition/implementation/fade/Animator/fade_animator.dart`
- `lib/src/core/navigation/Transition/implementation/rotation/Animator/rotation_animator.dart`
- `lib/src/core/navigation/Transition/implementation/rotation/rotation_transition_animation.dart`
- `lib/src/core/navigation/Transition/implementation/scale/Animator/scale_animator.dart`
- `lib/src/core/navigation/Transition/implementation/scale/scale_transition_animation.dart`
- `lib/src/core/navigation/Transition/implementation/shake/shake_transition_animation.dart`
- `lib/src/core/navigation/Transition/implementation/size/Animator/size_animator.dart`
- `lib/src/core/navigation/Transition/implementation/size/size_transition_animation.dart`
- `lib/src/core/navigation/Transition/implementation/slide/Option/slide_animation_option.dart`
- `lib/src/core/navigation/Transition/implementation/slide/animator/slide_animator.dart`
- `lib/src/core/navigation/Transition/implementation/slide/slide_transition_animation.dart`
- `lib/src/core/navigation/Transition/transition_type_builder.dart`
- `lib/src/core/navigation/named_routes.dart`
- `lib/src/core/navigation/navigator.dart`
- `lib/src/core/navigation/page_router/Implementation/cupertino_page_router.dart`
- `lib/src/core/navigation/page_router/Implementation/custom_page_router.dart`
- `lib/src/core/navigation/page_router/Implementation/material_page_router.dart`
- `lib/src/core/navigation/page_router/page_router_builder.dart`
- `lib/src/core/navigation/route_generator.dart`
- `lib/src/core/network/auth/token_storage.dart`
- `lib/src/core/network/base/base_remote_source.dart`
- `lib/src/core/network/cache/cache_config.dart`
- `lib/src/core/network/cubits/offline_queue_cubit.dart`
- `lib/src/core/network/dio_client.dart`
- `lib/src/core/network/error/failures.dart`
- `lib/src/core/network/exceptions/app_exception.dart`
- `lib/src/core/network/interceptors/auth_interceptor.dart`
- `lib/src/core/network/interceptors/cache_interceptor.dart`
- `lib/src/core/network/interceptors/locale_interceptor.dart`
- `lib/src/core/network/interceptors/retry_interceptor.dart`
- `lib/src/core/network/offline/offline_queue_cipher.dart`
- `lib/src/core/network/offline/offline_queue_manager.dart`
- `lib/src/core/network/offline/queued_operation.dart`
- `lib/src/core/network/parser/response_parser.dart`
- `lib/src/core/network/parser/status_code_handler.dart`
- `lib/src/core/network/security/certificate_pinning_policy.dart`
- `lib/src/core/session/session_cleanup.dart`
- `lib/src/core/session/session_failure_coordinator.dart`
- `lib/src/core/session/session_navigation_coordinator.dart`
- `lib/src/core/session/session_routing_policy.dart`
- `lib/src/core/shared/cubits/user_cubit/user_cubit.dart`
- `lib/src/core/shared/cubits/user_cubit/user_state.dart`
- `lib/src/core/shared/extensions/context_extension.dart`
- `lib/src/core/shared/extensions/form_mixin.dart`
- `lib/src/core/shared/extensions/json_extensions.dart`
- `lib/src/core/shared/extensions/string_extension.dart`
- `lib/src/core/shared/extensions/widgets/margin_extention.dart`
- `lib/src/core/shared/extensions/widgets/padding_extension.dart`
- `lib/src/core/shared/helpers/arabic_numbers_formatter.dart`
- `lib/src/core/shared/helpers/cache_service.dart`
- `lib/src/core/shared/helpers/helpers.dart`
- `lib/src/core/shared/helpers/image_helper.dart`
- `lib/src/core/shared/helpers/input_formatters.dart`
- `lib/src/core/shared/helpers/lancher_helper.dart`
- `lib/src/core/shared/helpers/validators.dart`
- `lib/src/core/shared/models/user_model.dart`
- `lib/src/core/shared/service_locators/setup_service_locators.config.dart`
- `lib/src/core/shared/service_locators/setup_service_locators.dart`
- `lib/src/core/startup/startup_coordinator.dart`
- `lib/src/core/state/async/async_bloc_builder.dart`
- `lib/src/core/state/paginated/lookup_remote_source.dart`
- `lib/src/core/state/paginated/paginated_async_cubit.dart`
- `lib/src/core/state/paginated/paginated_data.dart`
- `lib/src/core/state/paginated/paginated_list_config.dart`
- `lib/src/core/state/paginated/paginated_list_widget.dart`
- `lib/src/core/state/paginated/paginated_lookup_cubit.dart`
- `lib/src/core/state/paginated/pagination_meta.dart`
- `lib/src/core/widgets/badge_icon_widget.dart`
- `lib/src/core/widgets/buttons/button_close.dart`
- `lib/src/core/widgets/buttons/custom_animated_button.dart`
- `lib/src/core/widgets/buttons/loading_button.dart`
- `lib/src/core/widgets/carousel/custom_image_carousel.dart`
- `lib/src/core/widgets/custom_html_widget.dart`
- `lib/src/core/widgets/custom_loading.dart`
- `lib/src/core/widgets/custom_messages.dart`
- `lib/src/core/widgets/custom_widget_validator.dart`
- `lib/src/core/widgets/dialogs/success_dialog.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/widgets/dropdown_item_tile.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/widgets/dropdown_sheet_header.dart`
- `lib/src/core/widgets/fields/text_fields/default_text_field.dart`
- `lib/src/core/widgets/handling_views/app_error_handler.dart`
- `lib/src/core/widgets/handling_views/app_state_view.dart`
- `lib/src/core/widgets/handling_views/empty_widget.dart`
- `lib/src/core/widgets/icon_widget.dart`
- `lib/src/core/widgets/image_widgets/cached_image.dart`
- `lib/src/core/widgets/image_widgets/custom_avatar.dart`
- `lib/src/core/widgets/image_widgets/custom_image_slider.dart`
- `lib/src/core/widgets/image_widgets/image_view.dart`
- `lib/src/core/widgets/image_widgets/upload_image.dart`
- `lib/src/core/widgets/navigation_bar/animated_button.dart`
- `lib/src/core/widgets/navigation_bar/custom_navigation_bar.dart`
- `lib/src/core/widgets/offline_sync_banner.dart`
- `lib/src/core/widgets/pickers/custom_date_picker.dart`
- `lib/src/core/widgets/pickers/custom_dialog.dart`
- `lib/src/core/widgets/pickers/default_bottom_sheet.dart`
- `lib/src/core/widgets/riyal_price_text.dart`
- `lib/src/core/widgets/scaffolds/arrow_widget.dart`
- `lib/src/core/widgets/unauthenticated/show_modal_bottom_sheet.dart`
- `lib/src/core/widgets/unauthenticated/unauthenticated_bottomsheet.dart`
- `lib/src/core/widgets/universal_media/controller.dart`
- `lib/src/core/widgets/universal_media/widgets.dart`
- `lib/src/features/products/data/mappers/product_mapper.dart`
- `lib/src/features/products/data/models/product_model.dart`
- `lib/src/features/products/data/repositories/products_repository_impl.dart`
- `lib/src/features/products/domain/entities/product_entity.dart`
- `lib/src/features/products/domain/usecases/get_products_usecase.dart`
- `lib/src/features/products/presentation/cubits/products_cubit.dart`
- `lib/src/features/products/presentation/view/product_details_screen.dart`
- `lib/src/features/products/presentation/widgets/product_card.dart`
- `lib/src/features/products/presentation/widgets/products_body.dart`
- `lib/src/features/products/presentation/widgets/products_search_field.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `packages/app_maps/README.md`
- `packages/app_maps/analysis_options.yaml`
- `packages/app_maps/lib/app_maps.dart`
- `packages/app_maps/lib/src/app_map_page.dart`
- `packages/app_maps/lib/src/map_models.dart`
- `packages/app_maps/lib/src/map_selection_controller.dart`
- `packages/app_maps/pubspec.lock`
- `packages/app_maps/pubspec.yaml`
- `packages/app_maps/test/map_selection_controller_test.dart`
- `packages/app_notifications/NOTIFICATION_GUIDE.md`
- `packages/app_notifications/README.md`
- `packages/app_notifications/analysis_options.yaml`
- `packages/app_notifications/lib/app_notifications.dart`
- `packages/app_notifications/lib/src/models/notification_enums.dart`
- `packages/app_notifications/lib/src/models/notification_payload.dart`
- `packages/app_notifications/lib/src/notification_controller.dart`
- `packages/app_notifications/lib/src/notification_manager.dart`
- `packages/app_notifications/lib/src/notification_router.dart`
- `packages/app_notifications/lib/src/registration/device_registration.dart`
- `packages/app_notifications/lib/src/registration/notification_registration_coordinator.dart`
- `packages/app_notifications/lib/src/registration/persistent_installation_id_provider.dart`
- `packages/app_notifications/pubspec.lock`
- `packages/app_notifications/pubspec.yaml`
- `packages/app_notifications/test/notification_registration_coordinator_test.dart`
- `packages/app_notifications/test/persistent_installation_id_provider_test.dart`
- `packages/app_remote_config/README.md`
- `packages/app_remote_config/analysis_options.yaml`
- `packages/app_remote_config/lib/app_remote_config.dart`
- `packages/app_remote_config/pubspec.lock`
- `packages/app_remote_config/pubspec.yaml`
- `packages/app_remote_config/test/app_remote_config_test.dart`
- `packages/app_socket/README.md`
- `packages/app_socket/analysis_options.yaml`
- `packages/app_socket/lib/app_socket.dart`
- `packages/app_socket/lib/src/generic_socket_client.dart`
- `packages/app_socket/lib/src/socket_io_transport.dart`
- `packages/app_socket/lib/src/socket_models.dart`
- `packages/app_socket/lib/src/socket_transport.dart`
- `packages/app_socket/pubspec.lock`
- `packages/app_socket/pubspec.yaml`
- `packages/app_socket/test/generic_socket_client_test.dart`
- `packages/app_webview/README.md`
- `packages/app_webview/analysis_options.yaml`
- `packages/app_webview/lib/app_webview.dart`
- `packages/app_webview/lib/src/app_webview_page.dart`
- `packages/app_webview/lib/src/webview_config.dart`
- `packages/app_webview/lib/src/webview_navigation_policy.dart`
- `packages/app_webview/pubspec.lock`
- `packages/app_webview/pubspec.yaml`
- `packages/app_webview/test/webview_navigation_policy_test.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `scripts/check_size_budget.sh`
- `test/bootstrap/app_environment_test.dart`
- `test/core/network/cache/cache_config_test.dart`
- `test/core/network/certificate_pinning_policy_test.dart`
- `test/core/network/certificate_pinning_test.dart`
- `test/core/network/dio_network_audit_test.dart`
- `test/core/network/error/failure_mapping_test.dart`
- `test/core/network/offline/offline_queue_cipher_test.dart`
- `test/core/network/offline/offline_queue_startup_test.dart`
- `test/core/network/parser/response_parser_test.dart`
- `test/core/network/parser/status_code_handler_test.dart`
- `test/core/network/php/php_auth_interceptor_test.dart`
- `test/core/network/php/php_envelope_test.dart`
- `test/core/session/session_cleanup_test.dart`
- `test/core/session/session_failure_coordinator_test.dart`
- `test/core/session/session_routing_policy_test.dart`
- `test/core/shared/helpers/validators_test.dart`
- `test/core/shared/models/user_model_test.dart`
- `test/core/startup/startup_coordinator_test.dart`
- `test/core/state/async/async_cubit_test.dart`
- `test/core/widgets/app_dropdown_test.dart`
- `test/core/widgets/app_state_view_test.dart`
- `test/core/widgets/default_text_field_test.dart`
- `test/widget_test.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

#### Removed

- `assets/svg/base_svg/Onboarding_1.png`
- `assets/svg/base_svg/Onboarding_2.png`
- `assets/svg/base_svg/Onboarding_3.png`
- `ios/Podfile`
- `ios/Podfile.lock`
- `lib/src/core/notifications/EXPLANATION.md`
- `lib/src/core/notifications/models/notification_enums.dart`
- `lib/src/core/notifications/models/notification_payload.dart`
- `lib/src/core/notifications/notification_controller.dart`
- `lib/src/core/notifications/notification_manager.dart`
- `lib/src/core/notifications/notification_router.dart`
- `lib/src/core/shared/cubits/base_url/base_url_cubit.dart`

The removed root notification implementation moved to the optional
`packages/app_notifications` boundary. The old base-URL Cubit was replaced by
compile-time flavor configuration. The three onboarding PNGs had no runtime
references. Root iOS Podfiles were removed for the verified SwiftPM-only setup.

#### Dedicated size and standards audit additions

Added or modified after the original audit manifest was compiled:

- `.github/workflows/flutter_quality.yml`
- `README.md`
- `docs/AUDIT_REPORT.md`
- `docs/CHANGE_MANIFEST.md`
- `docs/QA_MATRIX.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/SIZE_AUDIT.md`
- `docs/STANDARDS_AUDIT.md`
- `docs/TEMPLATE_CUSTOMIZATION.md`
- `docs/adr/0001-optional-native-integrations.md`
- `docs/adr/0002-release-symbols-and-size.md`
- `lib/src/config/res/assets.gen.dart`
- `lib/src/core/shared/helpers/image_helper.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `scripts/check_optional_resolution.sh`
- `scripts/check_size_budget.sh`
- `test/architecture/module_boundaries_test.dart`
- `test/assets/asset_manifest_test.dart`

The following 28 source assets were removed after static reference,
configuration, generated-accessor, duplicate-hash and final-bundle checks:

- `assets/fonts/Beiruti-Black.ttf`
- `assets/fonts/Beiruti-ExtraBold.ttf`
- `assets/lottie/error_4.json`
- `assets/lottie/no_internet.json`
- `assets/lottie/wait.json`
- `assets/svg/base_svg/app_logo.svg`
- `assets/svg/base_svg/Carousel_1.svg`
- `assets/svg/base_svg/Carousel_2.svg`
- `assets/svg/base_svg/Carousel_3.svg`
- `assets/svg/base_svg/Check Box.svg`
- `assets/svg/base_svg/Check Box_empty.svg`
- `assets/svg/base_svg/Upload_doted.svg`
- `assets/svg/base_svg/change_email.svg`
- `assets/svg/base_svg/change_pass.svg`
- `assets/svg/base_svg/chats_empty.svg`
- `assets/svg/base_svg/complain_empty.svg`
- `assets/svg/base_svg/correct.svg`
- `assets/svg/base_svg/delete_all.svg`
- `assets/svg/base_svg/drop_down_arrow_down.svg`
- `assets/svg/base_svg/notification_delete.svg`
- `assets/svg/base_svg/notification_dialog.svg`
- `assets/svg/base_svg/notification_empty.svg`
- `assets/svg/base_svg/notifications copy.svg`
- `assets/svg/base_svg/notifications.svg`
- `assets/svg/base_svg/notify.svg`
- `assets/svg/base_svg/profile.svg`
- `assets/svg/base_svg/sessions_empty.svg`
- `assets/translations/lang.json`

Temporary matched-control and optional-increment projects were outside the base
and were deleted after their measurements were recorded in `SIZE_AUDIT.md`.

#### 2026-08-27 hardening additions

Added:

- `.codex/skills/flutter-base-production/SKILL.md`
- `.codex/skills/flutter-base-production/agents/openai.yaml`
- `.codex/skills/flutter-base-production/references/reusable-component-catalog.md`
- `docs/CODEX_INSTRUCTIONS_AUDIT.md`
- `docs/COMMAND_LOG_2026-08-27.md`
- `docs/CROSS_PROJECT_RECURRENCE.md`
- `docs/DEPENDENCY_AUDIT.md`
- `docs/REUSABLE_COMPONENT_CATALOG.md`
- `docs/TEST_COUNT_RECONCILIATION.md`
- `lib/src/core/widgets/buttons/app_button.dart`
- `test/core/network/logging_interceptor_test.dart`
- `test/core/state/paginated/paginated_async_cubit_test.dart`
- `test/core/widgets/app_button_test.dart`
- `test/core/widgets/blocking_overlay_test.dart`

Modified:

- `AGENTS.md`
- `docs/AUDIT_REPORT.md`
- `docs/CHANGE_MANIFEST.md`
- `docs/QA_MATRIX.md`
- `docs/SIZE_AUDIT.md`
- `docs/STANDARDS_AUDIT.md`
- `lib/src/config/language/languages.dart`
- `lib/src/core/network/interceptors/logging_interceptor.dart`
- `lib/src/core/shared/helpers/helpers.dart`
- `lib/src/core/shared/helpers/loading_manager.dart`
- `lib/src/core/shared/observer/bloc_observer.dart`
- `lib/src/core/state/async/async_cubit.dart`
- `lib/src/core/state/paginated/paginated_async_cubit.dart`
- `lib/src/core/widgets/buttons/loading_button.dart`
- `lib/src/core/widgets/custom_loading.dart`
- `lib/src/core/widgets/custom_messages.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart`
- `lib/src/features/products/presentation/widgets/product_card.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/core/state/async/async_cubit_test.dart`
- `test/core/widgets/app_dropdown_test.dart`

No target source, asset, font or configuration file was deleted in this
follow-up. Before modifications, recoverable copies were archived outside build
directories at
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-pre-hardening-20260826.tar.gz`
(SHA-256 `3c025cb77dc50ca50f42374c595271539384a7a0f759e3720c3f7d07af839c38`).

#### 2026-08-27 widget-hardening phase

The exact canonical media/picker/page, legacy hardening, migration, test,
optional-page and documentation file list is maintained in
`WIDGET_HARDENING_REPORT.md` to avoid duplicating a long manifest in two places.
No source, asset, font or configuration file was removed. The pre-phase backup
is
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-pre-widget-hardening-20260827.tar.gz`
(SHA-256
`aac1b37d2796db43dec6f784d5ffe9fdd71233fec5108d97998e77d04deef07c`).
No Git command was executed and no reference project was modified.

#### 2026-08-27 compatibility consolidation

`ImageView`, legacy empty/error states and retained animated/navigation controls
were internally consolidated onto the canonical media/state/navigation
contracts. `VisitorBody` migrated to `AppButton`. Twelve behavior tests were
added across the existing media, state and legacy-regression test files. Exact
source paths and the replacement rationale are in
`WIDGET_HARDENING_REPORT.md`.

The targeted pre-change backup is
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-widget-consolidation-20260827.tar.gz`
(SHA-256
`9bb4fdb6c469b9e679567d478845c80d6ff671b9adc5a83eaa5c31e5dede20b6`).
No source, asset, font or configuration capability was deleted.

#### 2026-08-27 final tooling consistency

Added executable `scripts/flutter_quality_gate.sh` with `quick`, `full`, and
`release` modes plus explicit `release --build`. Updated the local Codex skill,
repository guidance, release checklist, QA/size/widget reports and command log
to reference the executable gate and authoritative measurements. Three comments
make deliberate deprecated compatibility usage analyzer-safe; no behavior or
architecture changed. The configured-SDK release gate passed 19 checks with no
skips.

Pre-change backups are outside build directories:

- `flutter-base-quality-gate-consistency-20260827.tar.gz`, SHA-256
  `6997304d99bdcd9a69db00d5e6b382332ce48ed6023cb7fbde06018a17087f12`.
- `flutter-base-final-format-drift-20260827.tar.gz`, SHA-256
  `561dd4f748a6d9310ef35da96bfe3b8621e2e7edb97c2a3c595d102148437bd1`.

No Git command was executed and no reference project was modified.
The temporary control project was moved to macOS Trash after measurement.


---

## CODEX_INSTRUCTIONS_AUDIT

*Source: `docs/CODEX_INSTRUCTIONS_AUDIT.md`*

### Project-local instruction audit

#### Verdict

`AGENTS.md` and `.codex/skills/flutter-base-production/SKILL.md` are the
canonical instructions for Codex. The new skill is repository-local and does
not change global Codex configuration.

The repository also contains 29 Claude skills plus Cursor rules/prompts and
older `md/` guides. They are retained because they contain useful historical
context, but they are not the source of truth for Codex.

#### Conflicts found

| Legacy statement | Current evidence | Resolution |
|---|---|---|
| Dart 3.10 | Current SDK is Dart 3.13.1 | Current toolchain wins |
| Translation source is `lang.json` | Root uses `assets/translations/ar.json` and `en.json` | Current assets/tests win |
| Notifications are already wired in root | Notifications are an optional package and root absence is tested | Optional boundary wins |
| Arabic font is Expo Arabic | Root design system uses Beiruti | Current `pubspec.yaml` wins |
| Material icons must never be used | Framework icons are valid when accessible and tree-shaken | Component/design decision wins |
| Dropdown error UI is prohibited | Production dropdown contract requires loading/empty/error/retry | Current widget contract wins |
| Global context/loading helpers are acceptable | Architecture forbids retained global UI state | Context-owned APIs win |

#### Required future behavior

Codex must inspect the reusable catalog, reuse approved components, keep heavy
integrations optional, test meaningful failure/lifecycle branches, verify
localization/accessibility/platform effects, and document justified deviations.
It must not hardcode keys, change backend contracts silently, or introduce fake
data/caching to hide defects.


---

## COMMAND_LOG_2026-08-27

*Source: `docs/COMMAND_LOG_2026-08-27.md`*

### Command log — 2026-08-26/27 hardening audit

No Git command was executed. Commands were run from the target root unless a
different working directory is shown. The explicit Flutter SDK was
`/Users/abdelrahamndandash/Documents/SDK/flutter 2`.

#### Read-only discovery

```bash
find /Users/abdelrahamndandash/StudioProjects ... -name pubspec.yaml
rg --files lib test docs packages .claude .cursor md
rg -n <component/import/config patterns> <target and read-only reference roots>
sed -n <requested ranges> <inspected source/docs/instruction files>
wc -l -c <instruction and source inventories>
shasum -a 256 <repeated generic reference implementations>
flutter --version
java -version
df -h /
du -sh build .dart_tool android/.gradle
```

Project discovery pruned `.git`, `build`, `.dart_tool`, `.gradle`, `Pods`, SDK,
archive, cache and backup directories. Reference-project commands were limited
to `find`, `rg`, `sed`, `wc` and `shasum`.

#### Backup and local skill

```bash
tar -czf .../work/backups/flutter-base-pre-hardening-20260826.tar.gz <changed-file set>
shasum -a 256 .../work/backups/flutter-base-pre-hardening-20260826.tar.gz
python3 .../skill-creator/scripts/init_skill.py flutter-base-production --path .codex/skills --resources references
python3 -m pip install --target .../work/skill-validator-deps PyYAML
PYTHONPATH=.../work/skill-validator-deps python3 .../skill-creator/scripts/quick_validate.py .codex/skills/flutter-base-production
tar -czf .../work/backups/flutter-base-size-script-pre-update-20260827.tar.gz scripts/check_size_budget.sh .github/workflows/flutter_quality.yml
```

The validator initially failed because its host Python lacked `yaml`; PyYAML
was installed only in the task work directory and validation then passed.

#### Format, analysis and tests

```bash
flutter pub get
dart format <changed Dart files>
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter=json
flutter test --coverage --reporter=compact
flutter test --dart-define=PHP_RESPONSE_MODE=false --reporter=json test/core/network/php/php_envelope_test.dart
```

Optional packages, each from its own directory:

```bash
flutter analyze
flutter test
```

This was repeated for `app_notifications`, `app_remote_config`, `app_webview`,
`app_maps`, and `app_socket`.

Dependency evidence:

```bash
flutter pub outdated --no-dev-dependencies
flutter pub deps --style=compact
cd android && ./gradlew app:dependencies --configuration productionReleaseRuntimeClasspath
curl -H 'Content-Type: application/json' --data-binary @osv-pub-query.json https://api.osv.dev/v1/querybatch
```

#### Android builds and inspection

```bash
flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart --target-platform android-arm64 --analyze-size
flutter build apk --release --flavor production -t lib/main_production.dart --target-platform android-arm64 --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart --split-debug-info=build/symbols/production
apkanalyzer manifest debuggable build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer apk summary build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer dex list build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer files list build/app/outputs/flutter-apk/app-production-release.apk
ESTIMATED_DOWNLOAD_BYTES=9247946 DART_AOT_BYTES=5047176 NATIVE_LIBRARY_BYTES=11879416 ./scripts/check_size_budget.sh
```

`flutter clean` followed by `flutter pub get` was used between debug, Android
release and iOS matrices because the 8 GiB free-space ceiling could not retain
all generated intermediates together. Two build attempts failed only with
`No space left on device`; after target-only generated cleanup, every matrix
entry passed. No reference project was cleaned.

#### Bundletool and Samsung smoke

```bash
curl -L --fail https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar -o .../work/bundletool-all-1.18.3.jar
java -jar bundletool-all-1.18.3.jar get-device-spec --device-id=R58TA0LQH8E --output=samsung-a23-device.json --overwrite
java -jar bundletool-all-1.18.3.jar build-apks --bundle=app-production-release.aab --output=production-samsung-final.apks --device-spec=samsung-a23-device.json --overwrite
java -jar bundletool-all-1.18.3.jar get-size total --apks=production-samsung-final.apks --device-spec=samsung-a23-device.json
java -jar bundletool-all-1.18.3.jar install-apks --apks=production-samsung.apks --device-id=R58TA0LQH8E
adb -s R58TA0LQH8E logcat -c
adb -s R58TA0LQH8E shell am force-stop com.example.clean_arch_base
adb -s R58TA0LQH8E shell monkey -p com.example.clean_arch_base -c android.intent.category.LAUNCHER 1
adb -s R58TA0LQH8E shell pidof com.example.clean_arch_base
adb -s R58TA0LQH8E logcat -d '*:E'
```

#### iOS matrix

```bash
flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart
du -sk build/ios/iphonesimulator/Runner.app
```

#### Matched control and symbol retention

The temporary control used `flutter create`, then the same AGP/Gradle/Kotlin,
production flavor, R8 and resource-shrink settings were applied. Commands:

```bash
flutter build apk --release --flavor production -t lib/main.dart
flutter build apk --release --flavor production -t lib/main.dart --target-platform android-arm64 --analyze-size
flutter build appbundle --release --flavor production -t lib/main.dart --split-debug-info=build/symbols/production
bundletool build-apks ... --device-spec=samsung-a23-device.json
bundletool get-size total ... --device-spec=samsung-a23-device.json
trash .../work/flutter-size-control-20260827
```

Final root symbols were retained with:

```bash
tar -czf .../work/production-symbols-final-20260827.tar.gz build/symbols/production build/app/outputs/mapping/productionRelease build/app/outputs/native-debug-symbols/productionRelease
shasum -a 256 .../work/production-symbols-final-20260827.tar.gz
```

#### Widget-hardening phase

```bash
tar -czf .../work/backups/flutter-base-pre-widget-hardening-20260827.tar.gz <target base>
dart format --output=none --set-exit-if-changed lib test packages
flutter analyze --no-pub
flutter test --no-pub --reporter=compact
flutter test --no-pub --coverage test/core/widgets
flutter test --no-pub --coverage
flutter test --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart

for package in app_notifications app_remote_config app_webview app_maps app_socket; do
  cd packages/$package
  flutter pub get
  flutter analyze --no-pub
  flutter test --no-pub
done

flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --target-platform android-arm64 --analyze-size

flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart

flutter pub deps --style=compact --no-dev
unzip -l app-production-universal-release.apk
apkanalyzer apk summary app-production-universal-release.apk
apkanalyzer manifest debuggable app-production-universal-release.apk
bundletool build-apks --device-spec=samsung-a23-device.json ...
bundletool get-size total --device-spec=samsung-a23-device.json ...
bundletool install-apks --device-id=R58TA0LQH8E ...
adb -s R58TA0LQH8E logcat ...
```

The first optional-package recheck after `flutter clean` intentionally stopped
when package resolution was absent. `flutter pub get` was then run inside each
target-owned optional package and all five analyzers/tests passed. A transient
Gradle cache miss after disk pressure was repaired with
`./gradlew help --refresh-dependencies --no-daemon`; no cache directory or
reference project was manually deleted.

#### Compatibility-consolidation verification

```bash
tar -czf .../work/backups/flutter-base-widget-consolidation-20260827.tar.gz <targeted widget/test/docs paths>
dart format --output=none --set-exit-if-changed lib test packages
flutter analyze --no-pub
flutter test --no-pub
flutter test --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart
flutter test --coverage test/core/widgets
flutter test --coverage

flutter build apk --debug --flavor development -t lib/main_development.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --debug --flavor production -t lib/main_production.dart
flutter clean
flutter pub get
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build apk --release --flavor production -t lib/main_production.dart \
  --split-per-abi --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production -t lib/main_production.dart \
  --split-debug-info=build/symbols/production
flutter build ios --simulator --flavor development -t lib/main_development.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart

bundletool build-apks --device-spec=samsung-a23-device.json ...
bundletool get-size total --device-spec=samsung-a23-device.json ...
bundletool install-apks --device-id=R58TA0LQH8E ...
adb -s R58TA0LQH8E logcat ...
```

All matrices passed. The final Samsung bundletool estimate is 9,248,252 bytes;
the release process remained alive with no fatal app exception. Built-in
Kotlin migration remains an explicit future Flutter-toolchain warning.

#### Final documentation/tooling consistency gate

The project-local quality gate was added and then executed without its optional
build flag because the expensive build matrix and release artifacts had already
been verified and retained:

```bash
bash -n scripts/flutter_quality_gate.sh
scripts/flutter_quality_gate.sh release
wc -c build/app/outputs/bundle/productionRelease/app-production-release.aab
shasum -a 256 build/app/outputs/bundle/productionRelease/app-production-release.aab
```

`quick` covers format, root analysis/tests, the PHP inverse and root optional
isolation. `full` adds root coverage and every optional analyzer/test. `release`
adds available size/artifact isolation gates; `release --build` is the explicit
expensive build opt-in. The gate executes no Git command and never touches a
reference project.

The first consistency run exposed that the shell `PATH` still named Flutter
3.38.9 / Dart 3.10.8 while the project resolution named Flutter 3.47.1 / Dart
3.13.1. The script was corrected to derive `flutter.sdk` from the project
configuration without embedding an absolute path. The final configured-SDK
run passed 19 checks with zero skips, reported 219 root tests plus two expected
skips, 15 PHP-inverse tests plus three opposite-branch skips, 32 optional tests,
and 2,435/4,069 covered root lines (59.84%).

#### Dependency, live-runtime, skills and prompt-system phase

The configured SDK path was used for direct commands; the quality gate resolves
the same SDK from `android/local.properties` without embedding it.

```bash
flutter --version
flutter doctor -v
java -version
./android/gradlew --version
xcodebuild -version
pod --version
swift --version

flutter pub outdated --json
flutter pub upgrade --dry-run
flutter pub upgrade
flutter pub get
flutter pub deps --style=compact
curl -fsS -H 'Content-Type: application/json' --data <querybatch> \
  https://api.osv.dev/v1/querybatch

dart run build_runner build
dart run tool/generate_locale_keys.dart
./scripts/check_codegen_reproducibility.sh
./scripts/validate_agent_instructions.sh
./scripts/validate_prompt_library.sh

flutter test test/integration/live_http_stack_test.dart --no-pub
flutter test integration_test/widget_gallery_live_test.dart \
  -d emulator-5554 --flavor development --no-pub
flutter test integration_test/base_runtime_smoke_test.dart \
  -d emulator-5556 --flavor development --no-pub
flutter test integration_test/widget_gallery_live_test.dart \
  -d B20E1D04-857B-443F-AA98-FE567A431F57 \
  --flavor development --no-pub
flutter test integration_test/base_runtime_smoke_test.dart \
  -d B20E1D04-857B-443F-AA98-FE567A431F57 \
  --flavor development --no-pub
flutter test test/core/widgets --no-pub --reporter=compact

flutter clean
flutter pub get
./scripts/flutter_quality_gate.sh quick
./scripts/flutter_quality_gate.sh full
./scripts/flutter_quality_gate.sh release --build

apkanalyzer manifest debuggable \
  build/app/outputs/flutter-apk/app-production-universal-release.apk
apkanalyzer dex list \
  build/app/outputs/flutter-apk/app-production-universal-release.apk
wc -c build/app/outputs/flutter-apk/*.apk \
  build/app/outputs/bundle/productionRelease/app-production-release.aab
shasum -a 256 build/app/outputs/flutter-apk/*.apk \
  build/app/outputs/bundle/productionRelease/app-production-release.aab
```

The Android 16 release smoke used `apksigner` on a temporary copy with an
ephemeral QA-only key, then `adb install`, `am start`, HOME/resume, two Retry
taps, screenshot inspection and PID-filtered logcat. Signing material was
removed immediately. The original unsigned artifact was not modified.

Two negative environmental attempts were retained as evidence: the existing
Android emulator rejected the 128 MB debug test APK for insufficient storage,
and the Samsung SM-A235F was keyguard-locked, so its secure-storage integration
test could not complete. A fresh temporary AVD was created from the already
installed API 36 image, used for the successful full-base smoke, and deleted
afterwards. No existing AVD or reference-project data was erased.


---

## CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31

*Source: `docs/CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31.md`*

### Cross-project Codex history audit — 2026-08-31

#### Scope and evidence rules

This audit compares recurring Flutter engineering failures found in accessible
Codex history and project-local evidence with the current `flutter_base`.
Only `flutter_base` was writable. Every reference project, transcript, report,
worksheet, screenshot and video was inspected read-only. No historical agent
statement is treated as proof unless it is supported by source, a report with
executed evidence, a retained artifact, or a reproducible check.

Evidence grades used below:

- **A — executed:** retained command/device output or a current reproducible
  check.
- **B — inspected:** complete source/report/worksheet or retained visual
  evidence was inspected, but not rerun in its source project.
- **C — historical claim:** a transcript reports a result without sufficient
  retained independent evidence.
- **D — insufficient:** request-only, incomplete, duplicated recovery material,
  or unrelated evidence.

Secrets, credentials, private endpoints, signing material, user identifiers and
proprietary business data were deliberately excluded from this document.

#### Evidence-source inventory

| Evidence family | Inventoried | Useful scope | Limits |
| --- | ---: | --- | --- |
| Current Codex transcripts | 44 physical JSONL files / 43 session IDs | 28 primary sessions, 8 explicitly tagged sub-agent sessions and 7 auxiliary `exec` sessions | Some early sessions contain no assistant result; transcript text alone is grade C |
| Recovery archive | 78 JSONL-like files / 29 session IDs | 20 overlap current history; 9 are recovery-only | Multiple forensic/reconstructed copies exist; the 9 recovery-only sessions are not promoted above grade C without corroboration |
| Union of accessible session IDs | 52 | Per-session ledger below | This is the accessible local set, not a claim that no other historical chat ever existed |
| Flutter project roots under `StudioProjects` | 18, including the target | 17 read-only references plus `flutter_base` | Builds, dependency resolution, formatting and generation were not run in references |
| Substantive Flutter reports | 37 after deduplicating copied base snapshots | 13 Codex/output reports and 24 project-local reports | Report assertions retain their reported evidence grade |
| Structured sheets | 2 XLSX workbooks | 46 Devixia issue rows and 15 bidi/render cases | Web-only findings are not automatically Flutter-base findings |
| Endpoint inventory | 1 CSV | 82 collection endpoints and example/completeness metadata | No live backend call was made |
| Historical runtime screenshots | 18 unique hashes | Android/iOS startup, light/dark and flavor identity states | Historical visual evidence; not current device execution |
| Historical runtime videos | 4 MP4 files | iOS light/dark and Samsung light/dark launch sequences | Metadata and retained extracted frame sequences were reviewed; this is not a new playback/device run |

The source-project inventory covered `Basiet`, `Mawahib_AlSaudi`,
`Migraf_Egazat`, `alsafaclub`, `anaammakkah`, `herajnokba`, `herajone`,
`matyah`, `moshafy`, `nahtadi`, `rahoul`, `rcjy_app`, `saudi_medbridge`,
`servena`, `sofra`, `uumarket`, and the older
`flutter_clean_arch_base`. Generated folders, caches, Pods, SDKs and archives
were excluded from source recurrence scans.

#### Chat/task review ledger

The short session prefix is sufficient to distinguish the local records. Rows
marked “corroboration” were auxiliary analyses of a parent task and are not
double-counted as independent project recurrence.

##### Primary/current sessions

| Session | Scope | Evidence | Reusable decision |
| --- | --- | --- | --- |
| `019ddd55-f0c` | servena | B/C | Media decode/viewer memory safety; compare with canonical `AppMedia` |
| `019dddf4-ea0` | rahoul | B/C | Broad widget, networking, release and design patterns; adopt only independently recurring contracts |
| `019ddf3f-564` | rcjy_app | D | Request-only/incomplete; inventory only |
| `019de041-417` | kayan | D | Insufficient assistant evidence; inventory only |
| `019df899-1c8` | local MCP task | D | Non-product tooling; excluded from Flutter recurrence |
| `019e2054-14c` | Mawahib_AlSaudi | B/C | Cross-platform/release and reusable UI evidence |
| `019e828b-c3c` | sofra | B | Mock/session leakage, API parsing and DI-lifetime regressions |
| `019e9dec-091` | Basiet | B | Media/card layout and safe parsing evidence |
| `019ec241-1f3` | older Flutter base | B/C | Historical foundation evidence; current base source wins |
| `019ec242-627` | matyah | B | Startup, cancellation and lifecycle failures |
| `019f461e-726` | uumarket | B/C | Release/API/UI evidence; only corroborated items retained |
| `019f6514-12f` | multi-project design/API work | B/C | Evidence-method and Figma/API workflow lessons |
| `019f7b0c-e93` | Devixia QA | B | Structured accessibility, state, routing and responsive findings |
| `019f9d4d-4ca` | short local task | D | Insufficient evidence |
| `019f9f29-51f` | Al Safa implementation/audit | B | State contracts, fake-data prohibition, API drift and release gates |
| `019fa5d3-5e9` | Anaam | B | Design-size, temporary assets, lifecycle, native plugin and accessibility regressions |
| `019fa81a-2be` | Herajnokba | B | Overflow, provider context, modal failure, socket and empty-layout regressions |
| `019fc25a-0db` | Saudi Medbridge | C | Limited project evidence; no new root contract |
| `019fc25a-900` | Herajone | B/C | Backend TLS outage versus client terminal-error-state ownership |
| `019ff120-06e` | Codex-history recovery | B/C | Recovery provenance and missing-history limits only |
| `01a02f06-e56` | local Codex tooling | D | Unrelated to reusable Flutter runtime |
| `01a03073-d44` | Flutter/release review | B/C | Corroborating release and architecture evidence |
| `01a0330b-f15` | local Codex task | D | No reusable Flutter finding established |
| `01a03e0a-4fb` | local instructions/skills review | B/C | Instruction consistency evidence |
| `01a03e1c-a52` | current base hardening lineage | A/B | Current implementation, test, size and release baseline |
| `01a04367-410` | GitHub profile work | D | Non-Flutter; excluded |
| `01a0451e-011` | Arnon design discovery | B | Figma readiness, asset provenance and state-inventory guidance |
| `01a053c1-ea4` | short archived task | D | Insufficient evidence |

##### Auxiliary and explicitly tagged sub-agent sessions

| Session(s) | Parent scope | Evidence | Decision |
| --- | --- | --- | --- |
| `01a00600-927`, `01a0097c-235`, `01a00a16-7e6`, `01a014d3-cd2` | Multi-project/design review | C | Corroboration only; do not count as separate recurrence |
| `01a0193a-13e`, `01a01956-2ce`, `01a019cc-18f` | rahoul, Mawahib and sofra review | C | Corroboration only |
| `01a00eac-bfa` | Herajnokba parent task | C | Spawned review; corroboration only |
| `01a00977-00f`, `01a009a7-b5a`, `01a009ac-6ac`, `01a009c2-4e3`, `01a009c6-a0e`, `01a00ebb-2a5`, `01a00ed5-4f2` | Herajnokba auxiliary executions | B/C | Use only where the parent report or source confirms the finding |

##### Recovery-only session IDs

| Session | Scope | Evidence | Decision |
| --- | --- | --- | --- |
| `019dfddf-b29` | Migraf_Egazat | C | Large archived record; API/client lessons require source/report corroboration |
| `019e8288-eff` | multi-flavor/auth task | C | Historical architecture evidence only |
| `019eca41-2e9` | Migraf collection review | C | Collection completeness guidance; no endpoint copied |
| `019ed461-ed1` | matyah | C | Corroborates current Matyah evidence only |
| `019f5bfc-982` | Basiet | C | Corroborates current Basiet evidence only |
| `019f5fd4-7ee` | unrelated model/tool task | D | Excluded |
| `019f6229-e5c` | Sonar/tooling task | D | Excluded from runtime recurrence |
| `019f83ea-095` | uumarket | C | Corroborates current UUMarket evidence only |
| `019ff11e-975` | history recovery controller | B/C | Provenance and inventory support; no runtime finding |

#### Normalized recurring-failure taxonomy

Recurrence counts are conservative project/evidence-family counts, not raw
keyword hits or duplicated transcript counts.

| Rank | Failure class | Confirmed/corroborated evidence | Severity | Current base status |
| ---: | --- | --- | --- | --- |
| 1 | Malformed, empty or shape-changing API responses | Sofra, Al Safa, Anaam, Herajnokba, Migraf collection | Critical | Covered by typed failures, safe parsing and remote-source tests; prompt gap remained |
| 2 | Async callback/timer/plugin completion after disposal | Anaam, Matyah, media reviews | Critical | Covered across async state, media and picker tests |
| 3 | Startup blocked by optional network/Firebase/Remote Config work | Matyah, Anaam, Al Safa | Critical | Covered by `StartupCoordinator` timeout/fallback and optional packages |
| 4 | Fake/cache/static fallback concealing backend or session failure | Sofra, Al Safa, Anaam | Critical | Explicitly forbidden and covered by session/cache boundaries |
| 5 | Stale session or wrong DI lifetime leaking state/account data | Sofra, Devixia, auth reviews | Critical | Covered by scoped cleanup, `UserCubit`, refresh synchronization and tests |
| 6 | Fixed/fractional layout overflow under long text, keyboard or small screen | Herajnokba, Anaam, Basiet, Devixia | High | Canonical widgets have small-screen/large-text tests; feature layouts remain product-owned |
| 7 | Loading/error/empty state never reaches a terminal actionable state | Herajone, Devixia, Al Safa, Anaam | High | Covered by `AppStateView`, async/pagination state and startup fallback |
| 8 | Unsafe media decode/viewer/video lifecycle | servena, Basiet, Matyah | High | Covered by `AppMedia` and compatibility regression tests |
| 9 | Modal closes on request failure or loses pending input | Herajnokba, selection reviews | High | Covered by confirm-on-commit dropdown/dialog contracts |
| 10 | Repeated submit/request/permission/listener execution | Al Safa, Anaam, Herajnokba, Devixia | High | Covered in buttons, pagination, notifications and socket packages |
| 11 | Raw backend/plugin exception or sensitive request logging | Anaam, Al Safa, security audits | High | Covered by typed localized mapping and structural redaction |
| 12 | Cancellation/null-response and retry race handling | Matyah, network reviews | High | Covered by Dio cancellation, retry and latest-result-wins tests |
| 13 | Back disabled globally or delayed navigation firing after disposal | Anaam, legacy-base review | High | Covered by `AppPageShell`, routing policy and legacy regressions |
| 14 | Wrong provider/navigation context | Herajnokba, navigation reviews | High | Architecture guidance covers composition boundaries; feature-specific providers remain local |
| 15 | Socket/notification listener duplication and lifecycle leaks | Herajnokba, notification reviews | High | Optional packages contain idempotency/lifecycle tests |
| 16 | Incomplete localization, stale locale, raw keys or mixed direction | Devixia, Anaam, Al Safa | High | Covered by runtime switching, parity tests and direction-aware components |
| 17 | Missing semantics, tap targets, focus or repeated loading announcements | Devixia, Anaam | High | Mostly covered; skeleton semantics was the one verified code gap |
| 18 | Picker cancellation, permission denial, lost activity or native setup | Anaam, picker reviews | High | Covered by injected picker contract and lost-data recovery tests |
| 19 | Temporary Figma-hosted assets and wrong reference-frame scaling | Anaam | High | Runtime code is clean; project prompt gap remained |
| 20 | Incomplete/floating Figma version, missing state inventory or asset rights | Arnon, Al Safa, Anaam | High | Documentation/prompt concern, not root runtime code |
| 21 | API collection lacks saved examples or stable empty/non-empty contracts | collection audit, Al Safa, Migraf | High | Prompt gap remained; no generic runtime dependency justified |
| 22 | WebView/Maps missing configuration or unsafe error UI | Al Safa and optional-package audits | High | Covered in isolated optional packages |
| 23 | Android/iOS identity, flavor, symbols or release parity drift | multiple release audits | High | Root covered; optional-example Kotlin application gap found and fixed |
| 24 | Native home-widget/background scheduling | Nahtadi | Product-specific | Excluded from root; documentation/application integration only |
| 25 | Signing, real services, store policy, backend certificates/content | multiple projects | External | Product/backend/store gates; cannot be solved generically in the base |

#### Base gap analysis and adoption matrix

| Candidate | Evidence | Base comparison | Classification | Decision |
| --- | --- | --- | --- | --- |
| Collapse skeleton accessibility into one loading announcement | Devixia rows plus `AppStateView` source inspection | Skeleton branch exposed placeholder semantics unlike spinner branch | Root improvement | Implement without API change; add widget regression test |
| Reject temporary Figma/MCP runtime asset URLs | Anaam report and source recurrence | No such URL exists in base; prompt does not say this explicitly | Guidance | Add authoritative prompt requirement and validator concept |
| Validate design reference size against actual Figma frames | Anaam measured 360×690 versus 430×932 mismatch | Base uses a documented 375×812 reference, but derived-app workflow lacks an explicit verification rule | Guidance | Add prompt requirement; no hardcoded universal size rule |
| Freeze design version and inventory screens separately from states/modals | Arnon, Al Safa, Anaam | Prompt requests inventories but not frozen-version/prototype/placeholder provenance explicitly | Guidance | Strengthen shared design contracts |
| Require saved fresh response examples and stable empty/non-empty/mutation shapes | Collection and backend-drift audits | Runtime parser is defensive; collection workflow could still approve an ambiguous contract | Guidance | Strengthen API collection contracts |
| Diagnose screenshots/videos through reproducible runtime before editing | Cross-project reports contain both historical and live findings | Evidence section distinguishes grades but does not require runtime-first visual diagnosis | Guidance | Add explicit evidence workflow |
| Add more wrappers, integrations or dependencies | No repeated uncovered contract | Current canonical/optional boundaries already cover them | Excluded | No code/dependency change |
| Copy native home widget, business flows, models, endpoints or assets | Single-project or proprietary | Not generic and may add native/runtime weight | Product-specific | Excluded |
| Alter architecture, routing, DI or state management | No evidence of a base-level deficiency | Would add migration risk without measurable gain | Excluded | No change |

#### Evidence-to-test traceability

| Evidence class | Existing protection | Added by this audit |
| --- | --- | --- |
| Repeated loading announcements | State widgets already test terminal transitions, RTL and large text | Skeleton exposes one live-region label while child placeholders are excluded |
| Startup/optional deadlock | Startup coordinator timeout/retry/fallback tests; optional Remote Config tests | None; already covered |
| Async disposal/cancellation | Async cubit, pagination, media, picker and plugin-service tests | None; already covered |
| Session/account leakage | cleanup, routing, 401 synchronization, scoped cache/queue tests | None; already covered |
| API shape/error mapping | parser, remote source, retry and typed failure tests | Guidance tightened; no duplicate runtime helper |
| Overflow/RTL/theme/text scale | canonical widget suites and accessibility tests | None; product screens remain application-owned |
| Optional integration leakage | dependency/isolation gate and package analyzers/tests | None; zero-byte boundary retained |
| Prompt regressions | `validate_prompt_library.sh` validates 18 adapters against the shared spec | New evidence-derived design/API concepts validated centrally |

#### Exclusions and ownership

- **Backend-owned:** certificate expiry, malformed server content types,
  undocumented response envelopes, missing/developing endpoints, content,
  account state and service availability. The client still must terminate in a
  safe localized state.
- **Product-specific:** roles and financial arithmetic, product journeys,
  native home widgets, notification event names, socket rooms, maps behavior,
  brand assets, business models and per-screen Figma parity.
- **Release-specific:** signing, Firebase/APNs, Maps keys, links, store accounts,
  policy decisions and production service verification.
- **Already covered:** canonical media/picker/page/button/dropdown/state
  contracts, lifecycle disposal, synchronized auth refresh, account cleanup,
  cancellation, pagination guards, optional integrations and native identity
  parity.

#### Implemented improvements and impact

The evidence supports one small runtime hardening change, one regression test,
and shared prompt/tooling clarification. It does not support a dependency
addition, architectural rewrite, widget-family expansion, public API break,
asset deletion or root-native identity change. Expected binary-size impact is
effectively zero beyond a small Dart semantics wrapper; optional-package
isolation is unchanged.

Implemented:

- `AppStateView` skeletons now expose one live-region loading announcement and
  exclude placeholder-child semantics.
- A widget regression test protects the single-announcement contract.
- The shared prompt specification now rejects temporary Figma/MCP asset URLs,
  verifies reference-frame sizing and frozen design versions, separates screens
  from states/modals, treats historical visuals as leads, and requires fresh,
  stable empty/non-empty API response examples.
- The prompt validator enforces those shared concepts for all 18
  Codex/Claude/Cursor adapters.
- The first release run exposed missing Kotlin plugin application in the Maps
  example. Maps and Remote Config Android examples now apply the same current
  Kotlin Android plugin required by their native sources, and the identity gate
  protects both files. This is a current Flutter 3.47.1 compatibility fix; the
  upstream future Built-in Kotlin warning remains documented rather than hidden.

No dependency constraint or lockfile changed. The final Universal APK, ARM64
APK and AAB are byte-for-byte identical to the retained post-identity artifacts,
so the measured root binary impact of this audit is **0 bytes**. No optional
integration entered the root.

#### Final verification

| Check | Result |
| --- | --- |
| `scripts/flutter_quality_gate.sh quick` | passed: 9 checks |
| `scripts/flutter_quality_gate.sh full` | passed: 27 checks |
| `scripts/flutter_quality_gate.sh release --build` | passed after the optional-example fix: 59 checks, 0 skips, builds enabled |
| Root analyzer | no issues |
| Root tests | 227 passed, 2 intentional conditional skips |
| Focused widget tests | 62 passed; subset of root, not additional |
| Root coverage | 2,474/4,072 lines, 60.76% |
| Focused widget coverage | 1,481/3,309 lines, 44.76% |
| PHP inverse | 15 passed, 3 opposite-branch skips |
| Optional packages | 5 analyzers and 44 tests passed |
| Optional examples | 3 analyzers/tests plus Maps and Remote Config Android/iOS production builds passed |
| Android root | 3 debug flavors, Universal, ARM32, ARM64, x86_64 and AAB passed |
| iOS root | development, staging and production Simulator builds passed |
| Code generation | reproducible: 16 outputs and 83 AR/EN keys |
| Optional isolation | root dependency graph and Universal APK entries passed |
| Samsung ARM64/API 34 | current release code installed via a temporary debug-signed copy; process alive/top-resumed, safe bilingual terminal state, no fatal marker |

Final retained artifact evidence:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Universal APK | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| ARM32 split | 15,846,674 | `7df5fcf2d56f9189199765cccd6b17f8456d013438fdd36aa81e3f15287f9d14` |
| ARM64 split | 18,601,894 | `e97b63ee6f2e9949e915a6014d31c95c90995a7acdbd04395295d7736616aede` |
| x86_64 split | 20,020,086 | `059ec12a3513461ff8229943168d1eef102df7fe6a4e4aef0f06566461fca8f3` |
| Production AAB | 50,659,286 | `6f4f6ae7540ac9b80868ba98be9dfc1c6725db5e2bb5400a6f3e56aca1cb1636` |

The 50,618,821-byte AAB remains the labeled widget-hardening phase artifact;
50,659,286 bytes is the current post-identity/current-source artifact. The
unsupported 50,618,560-byte value remains superseded. Universal comparisons in
the size report retain their symbol-packaging labels.

The exact changed source/documentation files are:

- `README.md`
- `docs/CROSS_PROJECT_CODEX_HISTORY_AUDIT_2026-08-31.md`
- `docs/QA_MATRIX.md`
- `docs/prompts/AUTHORITATIVE_SPEC.md`
- `lib/src/core/widgets/handling_views/app_state_view.dart`
- `packages/app_maps/example/android/app/build.gradle.kts`
- `packages/app_remote_config/example/android/app/build.gradle.kts`
- `scripts/check_project_identity.sh`
- `scripts/validate_prompt_library.sh`
- `test/core/widgets/app_state_view_test.dart`

No source, asset, dependency or configuration was deleted. One failed
release-gate staging directory containing reproducible build outputs was removed
after recording artifact sizes/checksums and before the successful full rebuild.
The temporary debug-signed smoke APK is not a distributable production artifact.

Commands executed materially included read-only streaming/inventory scripts,
`flutter pub get` in the target root and optional packages/examples, format,
prompt/agent/identity validators, focused/root/conditional/optional tests,
coverage, analyzers, code-generation reproduction,
`scripts/flutter_quality_gate.sh quick|full|release --build`, Android/iOS builds,
artifact size/checksum checks, temporary APK signing, ADB install/launch/logcat,
and screenshot inspection. No dependency upgrade command and no Git state-
changing command was run.

#### Remaining gates and verdict

- Production Android signing is intentionally absent; the retained release APK
  is unsigned.
- Real backend, test accounts, Firebase/APNs, Maps keys, sockets, WebView
  services, deep links, store distribution and provider symbol upload remain
  product gates.
- Physical iOS archive/device QA and wider device/accessibility matrices remain
  product gates.
- Flutter reports a future Built-in Kotlin migration warning; Firebase plugins
  and Maps iOS SwiftPM support must be revisited with a future compatible
  dependency/toolchain migration, not changed ad hoc here.

Exact reconciliation totals:

| Measure | Total |
| --- | ---: |
| Accessible chat/task IDs reviewed | 52 |
| Flutter projects inspected | 18: target plus 17 read-only references |
| Substantive Flutter reports reviewed | 37 |
| Structured test-sheet rows reviewed | 61: 46 issue rows plus 15 bidi/render cases |
| Structured unique issue records | 46; narrative report findings were normalized instead of assigned invented IDs |
| Historical runtime screenshots reviewed | 18 unique hashes |
| Historical runtime videos reviewed | 4 |
| Normalized failure classes | 25 |
| Classes already covered before this audit | 18 |
| Classes with implemented hardening in this audit | 2: skeleton semantics and optional-example native build parity |
| Documentation-only classes | 3: design assets/sizing, design completeness and collection contracts |
| Backend/external-owned classes | 1 normalized class |
| Product-specific excluded classes | 1 normalized class |
| Blocked real-service/release class | 1 normalized class |
| Regression tests added | 1 |
| Final distinct tests | 274: 227 root + 44 optional-package + 3 optional-example tests |
| Conditional PHP proof | 15 passed/3 skipped in inverse mode; not added to the distinct-test total |
| Root coverage | 2,470/4,069 (60.70%) before; 2,474/4,072 (60.76%) after |
| Universal APK | 49,921,496 before and after; 0-byte change |
| ARM64 split APK | 18,601,894 before and after; 0-byte change |
| Production AAB | 50,659,286 before and after; 0-byte change |

Final reusable-baseline verdict: **freeze-ready**. Overall classification:
**Conditionally production-ready**, because the real-product gates above cannot
be completed generically.

Verification results and exact command outcomes are recorded in
`docs/QA_MATRIX.md` after execution. Historical screenshots/videos are never
presented as a current device run, and reference projects remain untouched.


---

## CROSS_PROJECT_RECURRENCE

*Source: `docs/CROSS_PROJECT_RECURRENCE.md`*

### Cross-project recurrence inventory

Read-only scan date: 2026-08-26. Scope: Flutter source trees directly under
`/Users/abdelrahamndandash/StudioProjects`; build outputs, caches, Pods,
`.dart_tool`, SDKs, archives and backups were excluded. Only generic technical
patterns, basenames and file hashes were compared. No secret values, endpoints,
business models, product events, brand assets or workflows were copied.

Project codes used below: B=`flutter_clean_arch_base`, U=`uumarket`,
R=`rahoul`, M=`Migraf_Egazat`, O=`moshafy`, T=`matyah`, A=`anaammakkah`,
H=`herajone`, W=`Mawahib_AlSaudi`, S=`alsafaclub`, I=`Basiet`, V=`servena`,
N=`herajnokba`, D=`saudi_medbridge`, C=`rcjy_app`, F=`sofra`. The target base
is excluded from occurrence counts.

"Distinct" is the number of distinct content hashes. A high distinct count
means the files share a name/responsibility but contain conflicting product
assumptions; it is evidence for a contract, not permission to copy one.

| Component/behavior | Projects | Occurrences / distinct | Existing problems | Selected owner and implementation | Tests / migration |
|---|---|---:|---|---|---|
| Validators | B,U,R,M,O,T,A,H,W,S,I,V,N,D,C,F | 16 / 16 | Product rules mixed with generic rules | Root focused `Validators`; feature rules stay feature-owned | Unit invalid/null/bilingual cases; retained |
| Constants/config | same 16 | 16 / 16 | Brand IDs/endpoints frequently mixed in | Typed environment/flavor config in root; product values are release inputs | Environment and flavor tests; retained |
| Default text field | 15 projects | 15 / 15 | Inconsistent controller/initial, direction, errors, semantics | Root `DefaultTextField` generic contract | Widget validation/theme/RTL tests; retained and hardened |
| Image helper | 15 projects | 15 / 15 | Broad permissions, cancellation assumptions, API drift | Root injectable picker/cropper flow using modern picker behavior | Cancellation/error/platform smoke; retained |
| Navigation helper | 14 projects | 14 / 14 | Implicit context and product routes | Root navigation boundary plus typed/session routing policies | Router/session tests; retained |
| Snackbar/messages | 14 projects | 14 / 14 | Global context, stale messenger, long/stacked messages | Root `MessageUtils` now requires mounted context and replaces current message | Widget/use-site verification; migrated |
| Dropdown | 14 projects | 14 / 13 | Conflicting static/paginated and confirm behavior | Root `AppDropdown` with pending commit, stable identity and retryable pagination | Cancel/confirm/race/error/retry tests; hardened |
| Language switching | 13 projects | 13 / 13 | Global context and cached locale | Root context-owned `Languages.setLocaleWithContext` | Key parity/RTL/runtime flow; migrated |
| Bottom sheet | 13 projects | 13 / 12 | Product layout and selection coupled | Root dropdown sheet primitives for generic selection; feature sheets remain local | Widget behavior tests; retained |
| Loading button | 12 projects | 12 / 12 | Multiple APIs, weak disabled semantics, setState-after-dispose | Root `AppButton`; legacy buttons retained for migration | Async repeat/disposal/tap-target tests; adopted |
| Dialog | 12 projects | 12 / 12 | Product copy/navigation embedded | Root confirmation/dialog patterns; feature copy injected | Widget/router tests; retained |
| Empty state | 11 projects | 11 / 9 | Hardcoded artwork/copy | `AppStateView` compact/full empty contract | Widget matrix; retained |
| Pagination list | 11 projects | 11 / 8 | Duplicate requests, stale results, thrown-call lock | Root `PaginatedAsyncCubit` + `PaginatedListWidget` | First/refresh/more/error/retry/concurrency/disposal tests; hardened |
| Success dialog | 11 projects | 11 / 9 | Usually performs implicit navigation | Keep feature-owned unless copy/action is injected | Feature test required; not promoted as a global helper |
| App sizing/theme | 16/16 projects | 16 / 13 and 16 / 11 | Brand tokens differ | Root token system is template-owned; consuming app customizes documented tokens | Theme/RTL/widget tests; retained |
| Error/retry view | 6 projects | 6 / 3 | Mixed backend text and navigation | Root typed failures + `AppStateView` | Error mapping/widget retry tests; retained |
| WebView/payment WebView | 6 projects | 6 / 6 | Payment/product policies mixed with browser policy | Generic policy/controller in optional `app_webview`; payments feature-owned | Optional package tests; migrated boundary |
| Socket service | 5 projects | 5 / 5 | Event names/auth/session coupling | Optional `app_socket` contracts; product events stay outside | Optional lifecycle/reconnect tests; optional |
| API/Dio/auth/token/parser | 3 projects | 3 / 3 each | Token refresh races, raw errors/logging | Root typed network/session infrastructure; structurally redacted diagnostics | Dio/auth/parser/concurrency/log tests; hardened |
| Notifications/FCM | 3 projects | 3 / 3 | Device ID confused with FCM token; splash coupling | Optional `app_notifications`; no root concrete import | Optional lifecycle tests and root absence checks; optional |
| Maps | repeated integration pattern | conflicting | Keys, permissions and selection are product-sensitive | Optional `app_maps`; root holds no plugin | Optional controller tests; optional |
| Remote Config | repeated integration pattern | conflicting | Firebase/startup coupling | Optional `app_remote_config`, injected and bounded | Optional timeout/config tests; optional |

#### Selection result

No reference implementation was copied verbatim. Representative implementations
of the known `rahoul` and `herajone` text-field/button/dropdown families were
reviewed as read-only reference points. Their divergent dependencies and product
assumptions confirmed that the safest reusable result was the smaller target
contract plus focused hardening. All reference projects remained untouched.

Capabilities that remain application-specific include payment workflows,
backend DTOs/envelopes beyond the documented opt-in PHP shape, socket events,
analytics events, maps business rules, notification routing, copy, branding,
credentials, endpoints and store identities.


---

## DEPENDENCY_AUDIT

*Source: `docs/DEPENDENCY_AUDIT.md`*

### Root dependency audit

Audit dates: 2026-08-27 and 2026-09-03. Versions and licenses were read from the resolved local
package metadata/LICENSE files. Size and transitive ownership are detailed in
`SIZE_AUDIT.md`; the production Pub and Gradle graphs were also searched for
optional integrations.

#### Production dependencies

| Dependency / resolved | Purpose and actual use | Native/security surface | License | Owner/decision |
|---|---|---|---|---|
| Flutter SDK 3.47.1 | UI/runtime/platform | Engine per ABI; framework security updates | BSD-style | Required root |
| dio 5.11.0 | HTTP, interceptors, cancellation | Network input/auth; typed mapping required | MIT | Required root |
| crypto 3.0.7 | SHA-256 pin fingerprint | Security primitive; no custom crypto | BSD-style | Required root |
| cryptography 2.9.0 | AES-256-GCM offline records | Key lifecycle/nonce/integrity sensitive | Apache-2.0 | Required root |
| dio_cache_interceptor 3.5.1 | Explicit scoped GET cache | Risk of user-data retention; never implicit | Apache-2.0 | Root; 4.x migration deferred and tested separately |
| hive_ce 2.19.3 | Optional local persistence/queue | File storage; owner isolation and migrations | BSD-style | Root capability, initialization optional |
| hive_ce_flutter 2.3.4 | Hive Flutter initialization | Path-provider bridge | BSD-style | Keep with Hive |
| connectivity_plus 7.3.1 | Reachability signal | Platform plugin; never proof of Internet | BSD-style | Required root |
| intl 0.20.3 | Date/number/locale semantics | Locale correctness, no native SDK | BSD-style | Required root |
| easy_localization 3.0.8 | Runtime AR/EN and persistence | Avoid cached strings/global context | MIT | Required root |
| image_picker 1.2.3 | Photo Picker/camera | Runtime permissions and platform lifecycle | BSD-style | Required root media contract |
| file_picker 12.1.1 | Document selection | User-selected file validation | MIT | Root reusable; product may remove with API/tests |
| image_cropper 11.0.0 | Shared crop workflow | Native UI/temporary files | BSD-style | Compatibility pin; 12.x conflicts in current Swift graph |
| flutter_html 3.0.0 | Shared sanitized rich text | Untrusted HTML/link handling | MIT | Retain while widget exists |
| video_player 2.14.0 | Shared video playback | Native codecs/network/media lifecycle | BSD-style | Retain while media contract exists |
| cached_network_image 3.4.1 | Image cache/loading | Disk/memory/network cache privacy | MIT | Root; removable with shared image widget |
| flutter_screenutil 5.9.3 | Existing responsive token compatibility | Dart only | Apache-2.0 | Retain; migrate deliberately |
| flutter_secure_storage 10.3.1 | Tokens/session/queue key | Keychain/Keystore/Tink critical | BSD-style | Required; 11.x needs planned storage migration |
| equatable 2.1.0 | State/value equality | Dart only | MIT | Required root |
| flutter_bloc 9.1.1 | State management | Dart only; lifecycle discipline | MIT | Architecture standard |
| get_it 9.2.1 | Composition-root lookup | Global-lifetime misuse risk | MIT | Composition boundary only |
| injectable 3.0.0 | Reproducible DI generation | Generated graph reviewed/tested | MIT | Root build contract |
| flutter_svg 2.3.0 | Vector assets | SVG parsing; use trusted bundled assets | MIT | Required shared UI |
| lottie 3.5.1 | Shared finite-state animation | Largest reachable Dart UI dependency | MIT | Retained intentionally |
| flutter_animate 4.5.2 | Bounded transitions | Reduced-motion/product restraint | BSD-style | Retain only for reachable components |
| skeletonizer 2.1.3 | First-page skeleton | Animation/accessibility behavior | MIT | Required shared state UI |
| share_plus 13.3.0 | System share sheet | Platform handoff; caller owns lifecycle | BSD-style | Required helper capability |
| url_launcher 6.3.2 | Validated external links | Scheme/host validation | BSD-style | Required platform adapter |
| rxdart 0.28.0 | Debounce/stream coordination | Disposal/backpressure correctness | Apache-2.0 | Retain with existing helpers |
| uuid 4.6.0 | Idempotency/queue identifiers | Not a secret or auth token | MIT | Required root |
| dartz 0.10.1 | Existing typed `Either` contracts | Old API/maintenance watch, Dart only | MIT | Retain until deliberate breaking migration |

`pretty_dio_logger` was removed. Its release size was already zero through tree
shaking, but its debug configuration exposed headers and bodies. The internal
replacement is structurally redacted and behavior-tested.

#### Maintenance and vulnerability evidence

The 2026-09-03 `flutter pub outdated --no-dev-dependencies` review found five
direct lines requiring a decision: `cached_network_image` 3.4.1→4.0.0,
`dio_cache_interceptor` 3.5.1→4.0.7, `file_picker` 12.1.1→12.2.0,
`image_cropper` 11.0.0→12.2.1 and `flutter_secure_storage` 10.3.1→11.0.0.
The first, cache, cropper and secure-storage upgrades contain breaking or
platform/storage changes and require dedicated migrations. The compatible
`file_picker` update was not mixed into this security/concurrency review. No
dependency was changed.

An OSV `querybatch` check of all 222 resolved hosted Pub package versions returned
zero known vulnerability records on the audit date. This is point-in-time
evidence, not proof of absence; CI should repeat it and security updates can
override normal upgrade cadence.

#### Development-only dependencies

`flutter_test`, `integration_test`, `mocktail`, `bloc_test`, `build_runner`, `flutter_gen_runner`,
`injectable_generator`, `hive_ce_generator`, `flutter_lints`, and
`http_mock_adapter` are test/code-generation/lint tooling. They are absent from
release runtime graphs. Generated output is reproducible and analyzed; mocks do
not enter production code.

#### Optional-absence result

The current root Pub graph, production Gradle runtime graph, generated plugin
registrant, Universal APK, DEX and AAB contain no Firebase Core/Messaging/Remote
Config, notification implementation, Google Maps, WebView, Socket.IO,
Crashlytics or analytics provider. Their source packages contribute zero bytes
until a consuming app opts in.


---

## FINAL_DEPENDENCY_LIVE_SKILLS_PROMPTS_REPORT

*Source: `docs/FINAL_DEPENDENCY_LIVE_SKILLS_PROMPTS_REPORT.md`*

### Final dependency, live-runtime, skills and prompt-system report

Date: 2026-08-27

#### Readiness verdict

**Conditionally production-ready and suitable to freeze as the reusable
baseline.** All safe local work in this phase is complete. The Clean
Architecture/BLoC/GetIt/Injectable/router identity, canonical widget surface,
compatibility paths and optional-package isolation remain intact.

The classification cannot become Production-ready for a derived product until
that product supplies and verifies real API/TLS configuration, signing,
Firebase/APNs/Maps as applicable, store/privacy metadata, a physical iOS device
matrix and unlocked physical-Android end-to-end journeys.

#### Important runtime regression found and fixed

The new full-base device smoke found a real first-route crash that isolated
widget tests did not expose. `bootstrap.dart` imported
`FadeAnimationOptions` through an uppercase URI while the router imported the
same file through a lowercase URI. On a case-insensitive filesystem Dart loaded
two incompatible library identities and threw a runtime type cast.

The bootstrap import now uses the canonical lowercase identity. A source-level
architecture regression test rejects noncanonical navigation import segments,
and the complete bootstrap/unknown-route smoke now passes on Android and iOS.
The pre-fix bootstrap file is recoverable at:

`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/navigation-case-fix-20260827-152023`

#### Toolchain and dependency result

The toolchain remained Flutter 3.47.1 stable / Dart 3.13.1 because it was
already the newest verified stable compatible baseline. Java 17, Gradle 9.1.0,
AGP 9.0.1, Kotlin plugin 2.3.20, compile/target SDK 36, minimum SDK 24, Xcode
26.6, Swift 6.3.3 and iOS 15 remain mutually buildable.

Forty-eight compatible resolved Pub packages were upgraded. Six dev-only
Flutter-driver packages entered through the new SDK `integration_test`
dependency. Three production pins remain deliberate:

- `dio_cache_interceptor 3.5.1`: 4.x has a breaking cache/hit API.
- `image_cropper 11.0.0`: 12.x conflicts with the current SwiftPM/TOCrop graph.
- `flutter_secure_storage 10.3.1`: 11.x changes Android requirements and needs
  a persisted-storage migration exercise.

Build Runner 2.15.1 and Hive CE Generator 1.11.2 are the latest versions the
current generator graph can resolve. There is no dependency override. The
complete per-direct-dependency table is in
`docs/DEPENDENCY_COMPATIBILITY_AUDIT.md`.

OSV `querybatch` checked all **222 resolved hosted packages** and returned
**zero known advisories** at the audit time. Root production licenses remain
permissive BSD-style/MIT/Apache-2.0. This is point-in-time evidence, not a
guarantee; derived-project CI must repeat vulnerability and license review.

The remaining tool warning is Flutter's future AGP built-in-Kotlin migration.
A partial conversion was rejected: app and plugins still apply the Kotlin
Gradle Plugin. The migration must be done atomically and re-run through this
same Android/device matrix.

#### Code generation

- Injectable now owns `TokenStorage` through a module provider; static and DI
  identity tests pass and the unregistered-dependency warning is gone.
- The obsolete `--delete-conflicting-outputs` flag was removed because Build
  Runner 2.15 no longer accepts/needs it.
- `tool/generate_locale_keys.dart` deterministically generates the 83 camelCase
  AR/EN translated getters expected by this base. The generic
  Easy Localization generator was not retained because it produced an
  incompatible API and broke 141 references.
- `scripts/check_codegen_reproducibility.sh` rebuilds in a temporary copy and
  checksum-compares Injectable, Hive CE, FlutterGen and locale output. It
  passed without changing the source tree.

#### Live widget and complete-base evidence

| Target | Harness | Result | What is actually proven |
|---|---|---|---|
| Android 16 emulator | Widget gallery | 1/1 pass | Real taps, repeated submission, theme/locale switch, RTL, text focus/Tab, dropdown, dialog, sheet, snackbar, overlay, media failure and Back |
| Android 16 clean temporary emulator | Full-base bootstrap | 1/1 pass | Real startup, secure-storage anonymous restore, stable session route, unknown route, return without black screen or uncaught Flutter error |
| iOS 26.5 Simulator | Widget gallery | 1/1 pass | Same canonical interaction journey on the iOS runtime |
| iOS 26.5 Simulator | Full-base bootstrap | 1/1 pass | Startup/session/unknown-route journey on the iOS runtime |
| Android 16 emulator | Release-compiled smoke | Pass | Temporarily QA-signed copy cold-started, displayed controlled bilingual missing-production-config state, survived HOME/resume and double Retry; zero fatal markers |
| Samsung SM-A235F/API 34 | Full-base integration attempt | Blocked | Device was connected but keyguard/NotificationShade locked; secure storage timed out and the test was stopped rather than called a pass |

The temporary Android AVD was created from the already-installed API 36 image
because the two existing AVDs had insufficient free data space for the 128 MB
debug integration APK. It was deleted after the successful smoke. No existing
AVD/app data was erased. The production APK remains unsigned and unmodified;
the ephemeral QA key and signed copy were deleted.

The gallery is external at `tool/widget_gallery/main.dart`; it is not reachable
from any production entry point. Maps and WebView have key/network-free example
applications inside their optional packages. Picker cancellation uses an
injectable fake in the gallery, so native camera/crop/lost-activity behavior is
not falsely reported as live.

#### Live networking evidence

Six behavior-focused tests use a real local `HttpServer`, actual TCP sockets
and Dio's IO adapter—no production backend and no mocked transport. They cover:

- JSON, empty, text content type and redirect responses.
- 400, 401, 403, 404, 409, 422, 429, 500, 502 and 503 typed mapping.
- malformed JSON, a 256 KiB response and slow streaming.
- timeout, connection refusal and cancellation.
- idempotent GET retry versus no unsafe POST replay.
- concurrent requests and multipart upload.

Raw server text is retained only as technical metadata; localized safe failure
keys are the user-facing output. Concurrent-401 single refresh, refresh
success/failure, logout/account switch, encrypted queue/replay/corruption,
redaction, PHP on/off and session routing remain strongly covered by existing
unit/integration-policy tests, but are not mislabeled as live real-backend
journeys.

#### Exact test and quality-gate totals

| Suite | Passed | Skipped | Counting note |
|---|---:|---:|---|
| Root/default | 226 | 2 | Includes the six local-socket tests and 61 focused widget tests |
| Focused reusable-widget subset | 61 | 0 | Subset of the 226, not additional |
| PHP inverse configuration | 15 | 3 | Opposite compile-time branch; reported separately, not added to root count |
| Optional packages | 32 | 0 | Notifications 9, Remote Config 4, WebView 6, Maps 7, Socket 6 |
| Optional Maps/WebView examples | 2 | 0 | 1 each; package-owned safe-state examples |
| Device/simulator integration | 4 | 0 | Gallery + full base on Android and iOS; not part of root 226 |

Root line coverage is **2470/4069 = 60.70%**. The prior 61-widget-test number
remains a subset. Coverage is behavior evidence, not a production-readiness
claim by itself.

Quality gate results:

- `quick`: passed 8 checks, 0 skipped.
- `full`: passed 24 checks, 0 skipped.
- `release --build`: passed 36 checks, 0 skipped, complete build matrix.

#### Build and artifact matrix

Android development, staging and production debug APKs passed. The production
Universal APK, all three ABI splits and AAB passed with external Dart symbols.
iOS development, staging and production Simulator builds passed. R8 mapping
was produced, `debuggable=false`, there is one `classes.dex`, Material Icons
were 99.9% tree-shaken and Universal entry isolation passed.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Universal production APK | 49,913,424 | `cc308d0aadbdcab4723a991fa660c3640708ea1d496da97e54221d0bc79492b2` |
| ARM32 split | 15,838,606 | `814b77496a181404f0ac00e288b982045440c274db9b2f31471f93e07f5725eb` |
| ARM64 split | 18,593,822 | `41e924320dd6488926eba4d6c290fcb89df53950dfa331288eee5b80d323c37f` |
| x86_64 split | 20,012,014 | `6f13514752d3b2539ebce192616b67c9adf79e77e39613160382fcaaee865e33` |
| Production AAB | 50,651,242 | `5232545e2ae7cb223aa1635f38374331d9fc90f74e80485125ef8751d5c538b9` |

The comparable post-widget artifacts used the same external-symbol packaging.
The Universal changed +29,484 bytes (+0.0591%) and AAB +32,421 (+0.0641%) after
dependency/source hardening. The earlier 50,618,821-byte AAB remains the
authoritative post-widget baseline; 50,651,242 is the authoritative artifact
after this phase. The unsupported 50,618,560 value remains superseded.

ARM64 (18,593,822 < 19,340,398), AAB (50,651,242 < 51,666,803) and source assets
(2,056,847 < 2,100,000) pass their existing evidence-based budgets. Root Pub,
registrant and APK-entry searches show zero Firebase/notifications/Maps/WebView/
Socket concrete integration.

#### Skills and instructions

Every former project-local skill/rule was audited individually. The 29 Claude
skills and 29 Cursor rules were highly duplicated and contained stale SDK,
widget, notification-root and nonexistent-script claims. None was deleted:
they were moved to dated inactive reference directories and backed up outside
the project.

Active discoverable surface now consists of:

- `AGENTS.md` and `.codex/skills/flutter-base-production/SKILL.md` for Codex.
- root `CLAUDE.md` and `.claude/skills/flutter-base-production/SKILL.md` for Claude.
- `.cursor/rules/00-flutter-base-production.mdc` for Cursor.

`scripts/validate_agent_instructions.sh` proves there is exactly one active
tool surface for each tool, 29+29 archived legacy files, real referenced
scripts, no personal path/credential/stale claim and a valid prompt library.
`docs/AGENT_INSTRUCTIONS_AUDIT.md` records all 29 individual decisions and
precedence.

#### Reusable prompt system

`docs/prompts/` contains 29 files: one authoritative specification, index,
selection/variables/workflow guides, six topology examples and **18 adapters**
(six families × Codex/Cursor/Claude). All eight required placeholders occur in
every adapter. The validator passed.

The shared spec handles one app, multiple roles, arbitrary app/flavor counts,
white label, shared/separate backends, one/multiple Figma files/collections,
AR/EN, RTL/LTR, light/dark, Android/iOS and debug/release. The six families are
design creation, design review, pre-implementation collection review,
collection completeness proof, live Figma/API comparison and final production
readiness.

Tool differences are intentional:

- Codex adapters require `AGENTS.md`, repository skills, progress commentary,
  exact tool evidence and mandatory Figma skill loading before Figma calls.
- Cursor adapters require repository indexing, Agent mode, a plan before
  material edits, terminal evidence and manual checkpoints when external tools
  are unavailable.
- Claude adapters require `CLAUDE.md`, a persistent task ledger, concise
  checkpoints and strict separation of executed evidence from recommendations.

No adapter assumes exactly two apps/roles, fabricates APIs or claims unavailable
Figma/device/backend access.

#### Target files changed

No widget redesign or architecture replacement was performed. The phase touched
only these target-owned surfaces:

- Dependency/generation: `pubspec.yaml`, `pubspec.lock`,
  `lib/src/core/shared/service_locators/setup_service_locators.dart`, its
  generated config, `lib/src/config/language/locale_keys.g.dart`, FlutterGen
  asset/font outputs, `tool/generate_locale_keys.dart`,
  `scripts/check_codegen_reproducibility.sh`.
- Runtime safety: `lib/bootstrap/bootstrap.dart`, network failure/exception
  mapping, `lib/src/core/session/session_failure_coordinator.dart`, their tests,
  `test/architecture/module_boundaries_test.dart`,
  `test/integration/live_http_stack_test.dart`.
- Live harnesses: `tool/widget_gallery/main.dart`, both files under
  `integration_test/`, Maps/WebView `example/` files and those package READMEs.
- Tooling: `Makefile`, `README.md`, `AGENTS.md`, `CLAUDE.md`, active Codex/
  Claude/Cursor skill/rule files, `md/CLAUDE.md`,
  `md/HOW_TO_USE_PROMPTS.md`, `scripts/flutter_quality_gate.sh`,
  `scripts/check_optional_resolution.sh`, both instruction/prompt validators.
- Documentation: `docs/DEPENDENCY_AUDIT.md`,
  `docs/DEPENDENCY_COMPATIBILITY_AUDIT.md`,
  `docs/AGENT_INSTRUCTIONS_AUDIT.md`, `docs/SIZE_AUDIT.md`, this report,
  command log, and all 29 files listed by `docs/prompts/README.md`.
- Historical moves: the exact old Claude/Cursor files listed row-by-row in
  `docs/AGENT_INSTRUCTIONS_AUDIT.md` now live under
  `.claude/reference/skills-legacy-2026-08/` and
  `.cursor/reference/{rules-legacy-2026-08,prompts-legacy-2026-08}/`.

Recoverable external backups were created for dependency/lockfiles, DI,
localization generation, integration harness setup, raw-message safety, agent
instructions, tooling consistency and the navigation case fix under:

`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/`

No source/widget/asset was deleted in this phase. Generated `build/` and
`.dart_tool/` were cleaned once to recover disk space and then completely
reproduced by the final matrix.

#### Remaining external gates

- Production API URL, two real TLS pins and real auth/account-switch/block/
  activation/delete flows.
- Android/iOS production signing and store-delivered install.
- Firebase/APNs, Maps, WebView, Socket and Remote Config only when selected by
  a real product.
- Unlocked Samsung/physical-Android native picker/crop/media/background QA.
- Physical iOS device, archive/export, app thinning and notification delivery.
- App-specific privacy manifests/Data Safety, legal copy, accessibility audit,
  performance budgets, crash/symbol provider upload and store review.

No Git command was executed. No reference project was modified.


---

## FINAL_INDEPENDENT_PRODUCTION_REVIEW_2026-09-03

*Source: `docs/FINAL_INDEPENDENT_PRODUCTION_REVIEW_2026-09-03.md`*

### Final independent production review

Evidence date: 2026-09-03. Target: `flutter_base` only. This report supersedes
test counts in older phase reports, but it does not relabel old artifacts as
current builds.

#### 1. Executive summary

The base remains **Conditionally production-ready**. The independent review
found two release-gating account-boundary races and one persistence-consistency
gap. Codex reproduced the control-flow defects, implemented session-generation
guards, cancelled stale offline/network/socket work, made token-pair persistence
single-record and serialized, and added negative regression tests. Notification
debug output and bilingual action labels were also hardened.

The final non-build release gate passed all 29 checks with 237 root tests, 53
optional-package tests and three optional-example tests. Fresh Android debug,
Universal/split release APKs, AAB, all three root iOS Simulator flavors and the
required optional examples were built. The current ARM64 release-code path was
also smoke-tested on the connected Samsung API 34 device with successful cold
and warm launches and no fatal Flutter/Android log marker.

The monolithic `release --build` invocation is not reported as one successful
command: it initially stopped during optional Maps iOS because the data volume
filled. After safe build-cache cleanup, Maps iOS passed independently. Remote
Config iOS completed Xcode compilation and produced a valid universal
`Runner.app`, but Flutter's post-build `rsync` copy then failed for the same disk
reason. This is an environmental wrapper failure, not claimed as a fully passed
Flutter command. Subject to the application-specific gates listed below, this
base is suitable to freeze as the reusable baseline.

#### 2. Delegation-skill evidence

The installed `cursor-delegate` and `claude-delegate` skills and every directly
required reference were read before invocation. Provider reviews used the
skill-owned relay, read-only mode and raw output under
`/tmp/flutter-base-final-audit.rw4aqL/`, outside the repository. Codex alone
edited the worktree. Authentication was checked without retaining private
account fields.

Cursor could not begin a review: the installed relay adds `--trust`, while the
installed Cursor Agent 2026.01.28 rejects it as an unknown option. One
deterministic attempt was sufficient; the other two Cursor model passes were
skipped rather than wasting quota. Claude Opus completed. Two distinct/smaller
Claude Sonnet instruction audits exhausted their turn limits without a final
report, so neither is counted as completed evidence.

#### 3. Provider/model matrix

| Provider | Model | Scope | Authenticated | Started | Completed | Raw findings | Codex confirmed | False positives checked | Accepted |
| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| Cursor Agent | `composer-2.5` | Architecture/network | Yes | Yes | No: CLI flag incompatibility | 0 | 0 | 0 | 0 |
| Cursor Agent | `cursor-grok-4.6-low` | Widgets/prompts | Yes | Skipped after deterministic blocker | No | 0 | 0 | 0 | 0 |
| Cursor Agent | `auto` | Adversarial final pass | Yes | Skipped after deterministic blocker | No | 0 | 0 | 0 | 0 |
| Claude Code | Opus (resolved by provider as Opus 4.8) | Auth/session/offline architecture | Yes | Yes | Yes, 38 turns | 7 | 5 | 3 | 5 |
| Claude Code | Sonnet | Prompt/skill audit | Yes | Yes | No: max turns | 0 usable | 0 | 0 | 0 |
| Claude Code | Sonnet | Reduced prompt/skill retry | Yes | Yes | No: max turns | 0 usable | 0 | 0 | 0 |
| Codex | Current task model | Consolidation, reproduction, implementation, tests | Yes | Yes | Yes | 7 normalized | 5 | 3 | 5 |

Provider statistics: four calls attempted, one succeeded and three failed; three
conditional passes were skipped. Attempt wall time was about 22 minutes. There
was one usable reviewer report with seven normalized findings. There can be no
honest cross-provider voting or agreement statistic when Cursor never executed;
decisions were made from source evidence and Codex reproduction instead.

The first Sonnet relay marked already-dirty files as a possible read-only
violation. Its permitted tool surface was only Read/Glob/Grep and the same files
had already been changed by Codex. No delegated edit was found. The smaller
retry also reported no attributable violation.

#### 4. Reviewer comparison

Claude uniquely identified the missing session-generation boundary. Codex
confirmed the refresh, offline replay and token persistence paths directly and
extended the same invariant to active requests and sockets. No Cursor comparison
was possible due to the deterministic CLI mismatch. The result is therefore a
multi-provider attempt with one completed external reviewer, not a fabricated
multi-provider consensus.

#### 5. Verified findings

| ID | Severity | Finding | Decision / evidence |
| --- | --- | --- | --- |
| F1 | High | A delayed refresh could save old tokens and retry after logout/account switch | Confirmed and fixed with captured monotonic session generations, per-generation single-flight refresh and stale-request cancellation |
| F2 | High | An in-memory offline replay could continue old-owner writes with a new user's token | Confirmed and fixed with owner/generation checks around every await plus cancellation/invalidation |
| F3 | Medium | Two separately persisted tokens and memory-first mutation allowed partial state | Confirmed and fixed with one versioned encrypted record, serialized mutations, fail-closed memory and legacy migration |
| F4 | Medium | Negative race/storage tests were missing | Confirmed; nine root assertions plus four optional-package assertions were added |
| F5 | Low | Refresh did not inherit the request language despite a source comment | Confirmed; `Accept-Language` is explicitly forwarded to the isolated refresh client |
| F6 | Low | Navigation coalescing might discard a second different target in one frame | Not reproduced; current termination single-flight prevents the proposed normal path. No speculative state machine added |
| F7 | Info | Arbitrary one-shot request bodies are not generally replayable | True as a constraint, but current root request APIs produce replayable JSON/FormData. Kept documented rather than adding a broad cloning framework |

#### 6. False positives

Three reviewer hypotheses were explicitly rejected: route state does not remain
stuck after re-login; the certificate validator still enforces pins for normally
trusted certificates; and logout without a different login does not replay an
old queue successfully. Startup ordering between persistence and session
restoration also converges through the existing guarded queue activation.

#### 7. Implemented improvements

- `TokenStorage` now stores a versioned access/refresh pair in one encrypted
  record, serializes mutations, migrates legacy keys and exposes conditional
  generation-safe save/clear operations.
- `AuthInterceptor` records session ownership on every authenticated request,
  rejects stale results as cancellation, refreshes once per generation and
  cannot log out or overwrite a newer account.
- Session termination cancels active remote-source requests before cleanup.
- Offline synchronization reserves its worker before the reachability await,
  rechecks owner/generation at each asynchronous boundary and cancels stale work.
- Socket authentication/network/lifecycle changes detach in-flight connections;
  stale transports cannot publish state or schedule reconnects.
- Notification logs no longer expose raw exceptions or common payload/identity
  fields; call action labels have explicit Arabic and English parity.

#### 8. Rejected recommendations

No architecture replacement, Router migration, generic request-body cloner,
new integration, dependency upgrade, widget redesign or additional wrapper was
accepted. Retry-After/jitter remains a product policy decision: current retries
are bounded and limited to idempotent reads, and no verified defect justified
changing timing semantics in this review.

#### 9. Architecture result

Clean Architecture boundaries, BLoC/Cubit, GetIt/Injectable composition,
Navigator named routes and feature ownership remain intact. Root has no concrete
Firebase, notifications, Maps, WebView or Socket dependency. Session generation
is owned by credential storage and consumed at the network boundary, avoiding
global mutable user models or cross-feature imports.

Known deliberate debt remains: broad compatibility exports under `core/widgets`,
the small service-locator composition boundary and named-route placeholders.
None is a release defect for the reusable base.

#### 10. Feature inventory

Root retains startup coordination, environment/flavor validation, typed Dio
errors, refresh tokens, retry/cancellation, encrypted owner-scoped offline queue,
secure token/user storage, runtime AR/EN localization and RTL, routing/session
cleanup, the canonical widget system, media/picker contracts and test tooling.

Notifications, Remote Config, WebView, Maps and Socket remain independent
packages. Analytics, crash reporting and real service wiring remain injectable
or product-owned. No existing generic capability or public widget was removed.

#### 11. Widget and live-gallery result

The canonical surface remains `AppButton`, `DefaultTextField`, `AppDropdown`,
`AppStateView`, `AppMedia`, `AppImagePickerField`, `AppPageShell`, async and
pagination presenters, context-owned dialogs/sheets/messages and compatibility
adapters. The 62 focused widget tests are a subset of the 237 root tests.

No widget changed in this review. Historical Android/iOS gallery journeys remain
documented. A current root release-code smoke on the physical Samsung verified
the controlled bilingual missing-production-configuration state and Retry
action, with no black screen or infinite splash. This was not a complete gallery
or TalkBack/VoiceOver journey, and no virtual device was started.

#### 12. Dio/network result

The root still has six real loopback-HTTP tests covering response types,
status mapping, malformed/large/slow bodies, timeout/refusal/cancellation,
idempotent retry, concurrency and multipart upload. These are included in the
root total. Production endpoints were not called. Raw backend strings remain
technical metadata rather than user-facing copy.

#### 13. Refresh-token/session result

Refresh-token support is present and now session-bound. A request captures the
credential generation before transport; refresh save, retry, response delivery
and auth-failure cleanup all verify it. Logout/account switch synchronously
invalidates the generation and cancels active remote requests. Regression tests
prove delayed refresh and delayed success cannot cross the boundary.

Remaining product gates are real token rotation/revocation semantics, backend
idempotency, blocked/activation/account-deletion responses and real multi-account
journeys.

#### 14. Optional-package result

All five packages analyzed and tested independently in the completed final gate:
Notifications 16, Remote Config 16, WebView 6, Maps 7 and Socket 8. WebView,
Maps and Remote Config examples each passed one test. Root Pub dependency
isolation passed. The current Universal APK entry check also passed: no concrete
Firebase, Notifications, Maps, WebView or Socket integration entered the root
artifact.

#### 15. Prompt audit

The active library remains 18 adapters: six lifecycle families for each of
Codex, Cursor and Claude. Shared normative behavior lives in
`docs/prompts/AUTHORITATIVE_SPEC.md`; tool adapters intentionally differ in
their planning, checkpoint and tool-availability requirements. Validation
passed. No prompt was added, removed or changed in this review.

#### 16. Skill audit

The discoverable project-local surface remains one production skill/rule per
tool: Codex, Claude and Cursor. Twenty-nine former Claude skills and 29 Cursor
rules are preserved under inactive dated references. The active files refer to
real scripts including `scripts/flutter_quality_gate.sh`; the instruction
validator passed. No global skill was modified.

#### 17. Prompt-to-skill matrix

| Prompt family | Codex | Cursor | Claude | Intentionally excluded |
| --- | --- | --- | --- | --- |
| Design creation/review | Project skill + Figma prerequisite when used | Active project rule | Project skill | Device/release skills unless implementation begins |
| API collection/completeness | Project skill and contract-first checks | Active project rule | Project skill | Figma when no design evidence exists |
| Live implementation comparison | Project skill; Figma/device skills only when applicable | Active project rule + manual fallback | Project skill + explicit evidence ledger | Optional integrations not selected by product |
| Production readiness | Project skill + quality/device gate as applicable | Active project rule | Project skill | No skill is forced merely because it exists |

#### 18. Test and coverage result

| Suite | Pass | Skip | Counting rule |
| --- | ---: | ---: | --- |
| Root/default | 237 | 2 | Includes 62 widget and six loopback-network tests |
| PHP inverse | 15 | 3 | Only two OFF-only assertions are distinct from root |
| Optional packages | 53 | 0 | 16 + 16 + 6 + 7 + 8 |
| Optional examples | 3 | 0 | WebView + Maps + Remote Config |
| Non-double-counted total | 295 | 2 default + 3 inverse-branch selectors | 237 + 2 inverse-only + 53 + 3 |

Root coverage is 2,609/4,228 lines = **61.71%**, the authoritative final
snapshot. Before this review the first quick gate had 228 root passes; the review
added nine root assertions. Optional Notifications and Socket each added two
behavior tests. No regression test was removed.

Completed verification: formatting (307 files, zero changes), root analyzer,
237-test full root run/coverage, PHP inverse, root isolation, reproducible
generation, five optional analyzers/tests, three optional-example
analyzers/tests, release size budgets and Universal APK optional-integration
isolation. The authoritative final non-build command reported:
`QUALITY GATE PASSED: mode=release checks=29 skipped=0 builds=0`.

#### 19. Dependency and toolchain result

No dependency or lockfile changed. Direct packages requiring planned decisions
are `cached_network_image` 4.x, `dio_cache_interceptor` 4.x, `file_picker`
12.2, `image_cropper` 12.x and `flutter_secure_storage` 11.x. Breaking native,
cache and persisted-data changes were not mixed into this review.

Toolchain: Flutter 3.47.1 stable, Dart 3.13.1, Java 17.0.15 ARM64, AGP 9.0.1,
Gradle 9.1.0, Kotlin plugin 2.3.20, Xcode 26.6, Swift 6.3.3 and CocoaPods
1.16.2. Flutter 3.47 warns that legacy KGP support is temporary. An isolated
built-in-Kotlin migration was attempted according to the
[official Flutter guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers),
but both packaging and compile-only validation ran out of disk. It was reverted
without Git so the last fully proven Android configuration remains active.

#### 20. Build/device matrix

| Target | Current-review result |
| --- | --- |
| Android development/staging/production debug | Passed for all three flavors |
| Universal/split APK/AAB | Universal, ARM32, ARM64, x86_64 and production AAB passed |
| iOS three root Simulator flavors | Passed; apps preserved as verified ZIP archives |
| Optional Maps Android/iOS | Passed independently |
| Optional Remote Config Android | Passed |
| Optional Remote Config iOS | Xcode compilation passed and produced a valid universal app; Flutter wrapper failed during post-build `rsync` because disk filled |
| Android physical Samsung ARM64/API 34 | Passed release-code cold/warm smoke; 1,397 ms cold and 222 ms hot launch |
| Android emulator / iOS Simulator boot | Not authorized in this task; none started |

The physical smoke used an unchanged copy of the unsigned ARM64 release APK,
locally QA-signed with the machine's debug key. It installed without deleting
app data; the process stayed alive and top-resumed, and PID-filtered logcat had
no `AndroidRuntime` or Flutter error marker. This does not replace production
signing or full real-service/device QA.

#### 21. Artifact sizes and SHA-256

Fresh current artifacts are retained with the following exact sizes and hashes:

| Current artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Universal APK | 49,921,496 | `6aa42e0cb54087535e262189c163e3312094ee704e29f4ad69ff1f32425639a6` |
| ARM32 split | 15,846,674 | `4868c427e3fc9ef036220f58f61480767b509ced3873f558f5c9eddf1a222f5e` |
| ARM64 split | 18,601,894 | `21b52e1d5a90fbb5a74e8b0e01243bd7d404396b7c31332c678e3c2387adb0c9` |
| x86_64 split | 20,020,086 | `09dece176ff3240d8b099e8dedaf1b16b4e40630bdf4351559436327111a2277` |
| Production AAB | 50,694,841 | `42dd442d8d7d8974f2d810bccfc6a8f65b5d346a6bb5d8fe06c05056c9ad5543` |
| R8 mapping | 25,724,248 | `162acbd8207144f8c7c2f6b7ba4e3ea52953712bb8d220c34f33555c51185f18` |
| Native symbols ZIP | 133,788,125 | `51b4eda4016c9d5ea7bd3b21df3c5721023ab727689d463fe76710df2434524a` |

The current Universal APK has exactly the same byte size as the comparable
2026-08-31 symbol-packaging baseline, so measured Universal impact is **0
bytes**; the differing checksum is expected from rebuilt content/metadata. The
AAB increased from 50,659,286 to 50,694,841 bytes: **35,555 bytes (0.07018%)**.
ARM64 and AAB both pass their 19,340,398- and 51,666,803-byte budgets; source
assets are 2,038,407 bytes against 2,100,000. The older 52,046,296-byte
Universal measurement used different symbol-packaging conditions and is not a
like-for-like optimization baseline.

External Dart symbols are retained for ARM (1,913,236 bytes), ARM64 (2,245,096)
and x64 (2,244,648). Verified root iOS Simulator app archives are retained under
`build/post_identity_ios/` for development (62,620,412), staging (62,620,524)
and production (62,620,347 bytes).

#### 22. Files changed

Runtime/source:

- `lib/src/core/network/auth/token_storage.dart`
- `lib/src/core/network/interceptors/auth_interceptor.dart`
- `lib/src/core/network/offline/offline_queue_manager.dart`
- `lib/src/core/network/options/request_extra.dart`
- `lib/src/core/shared/cubits/user_cubit/user_cubit.dart`
- `packages/app_notifications/lib/src/notification_controller.dart`
- `packages/app_socket/lib/src/generic_socket_client.dart`

Tests/documentation:

- `test/core/network/auth/token_storage_test.dart`
- `test/core/network/dio_network_audit_test.dart`
- `packages/app_socket/test/generic_socket_client_test.dart`
- `packages/app_notifications/test/notification_logging_test.dart` (new)
- `packages/app_notifications/NOTIFICATION_GUIDE.md`
- `docs/QA_MATRIX.md`
- `docs/TEST_COUNT_RECONCILIATION.md`
- `docs/DEPENDENCY_AUDIT.md`
- this report

No file, asset or API was removed; no dependency changed and no API was
deprecated. New public testing/session primitives are `TokenStorageBackend`,
`TokenStorage.forTesting`, `sessionGeneration`, `saveIfCurrent` and
`clearIfCurrent`. The final runtime-and-test diff is 954 added and 202 removed
lines across 11 files. Including documentation and this report, the complete
worktree change is 1,402 added and 228 removed lines across 16 files.

Recoverable backups are outside build directories at:

- `/tmp/flutter-base-final-audit.rw4aqL/backups/lib/src/core/network/auth/token_storage.dart`
- `/tmp/flutter-base-final-audit.rw4aqL/backups/lib/src/core/network/interceptors/auth_interceptor.dart`
- `/tmp/flutter-base-final-audit.rw4aqL/backups/android-kotlin-migration/`

#### 23. Commands executed

Material commands (all from the target root unless noted):

```text
git status --short --branch
git rev-parse HEAD
git rev-list --left-right --count origin/main...HEAD
cursor-agent --version
cursor-agent status
claude --version
claude auth status
<delegation relay> --tool cursor-agent --model composer-2.5 --read-only ...
<delegation relay> --tool claude --model opus --effort high --read-only ...
<delegation relay> --tool claude --model sonnet --effort high --read-only ...
flutter pub get
flutter pub outdated --no-dev-dependencies
scripts/flutter_quality_gate.sh quick
scripts/flutter_quality_gate.sh full
flutter test --no-pub test/core/network/auth/token_storage_test.dart test/core/network/dio_network_audit_test.dart test/core/network/php/php_envelope_test.dart
flutter analyze --no-pub
flutter test --no-pub --coverage --reporter=compact
flutter test --no-pub --dart-define=PHP_RESPONSE_MODE=false test/core/network/php/php_envelope_test.dart
flutter test integration_test/live_http_stack_test.dart
flutter test test/core/widgets --no-pub --reporter=compact
flutter pub get / flutter analyze --no-pub / flutter test --no-pub in each optional package and required example
scripts/flutter_quality_gate.sh release --build
scripts/flutter_quality_gate.sh release
flutter build apk --debug --flavor development -t lib/main_development.dart --target-platform android-arm64
cd android && ./gradlew :app:compileDevelopmentDebugKotlin --no-daemon
flutter devices --machine
python3 /Users/abdelrahamndandash/.codex/skills/flutter-device-guard/scripts/device_lease.py --device auto -- <stateful device command>
dart format --output=none --set-exit-if-changed ...
git diff --check
```

The `git` commands above were read-only inspection only. No commit, branch,
checkout, restore, reset, clean, stash, pull, push or remote mutation occurred.

#### 24. Remaining warnings

- Low free-disk headroom interrupted the monolithic build gate and Flutter's
  final Remote Config iOS copy step. Future complete release runs should start
  with sufficient space even though the root matrix and remaining checks were
  completed independently.
- Flutter's legacy-KGP compatibility warning remains; migration must be atomic
  across the app and every plugin and verified by the full Android matrix.
- Production signing, API/TLS pins, backend accounts, Firebase/APNs, restricted
  Maps keys, store delivery, privacy declarations, crash-symbol upload and real
  service journeys remain application-specific gates.
- Physical iOS and complete Android lifecycle/accessibility/picker/media/network
  journeys remain unverified for this exact diff.
- Cursor delegation requires a relay/CLI compatibility update before it can be
  counted as an independent provider review.

#### 25. Final verdict

**Conditionally production-ready and suitable to freeze as the reusable
baseline.** No known reproducible session-boundary, offline-owner,
socket-lifecycle or notification-redaction defect remains in the verified
scenarios. Current release artifacts, budgets, root optional isolation and a
physical Samsung release-code smoke passed. There is no claim of zero future
crashes or that production signing, external services, store distribution and
complete physical accessibility/lifecycle QA are already approved.


---

## PRE_DESIGN_DELEGATED_AUDIT_2026-09-05

*Source: `docs/PRE_DESIGN_DELEGATED_AUDIT_2026-09-05.md`*

### Pre-design delegated audit

Evidence date: 2026-09-05. This is the final source-readiness pass before a
real consuming application begins Figma/design implementation.

#### Verdict

The base is **ready to begin product design implementation** while retaining
its overall **Conditionally production-ready** release classification. There
is no remaining confirmed reusable-source blocker. Product credentials,
signing, real services, store delivery and full physical-device journeys remain
release gates for the derived application, not reasons to add heavy behavior to
the base.

#### Delegated review

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

#### Implemented corrections

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

#### Rejected recommendations

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

#### Verification

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

#### Files changed by this pass

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


---

## PRE_QA_HISTORICAL_TESTER_AUDIT_2026-08-31

*Source: `docs/PRE_QA_HISTORICAL_TESTER_AUDIT_2026-08-31.md`*

### Pre-QA historical tester audit — 2026-08-31

#### Scope and safety

This audit compares the reusable base with four supplied historical QA sheets:

| Sheet | Rows | Status breakdown | Priority breakdown |
|---|---:|---|---|
| Heraj user | 70 | Blocked 1, Closed 63, Skip 5, Resolved 1 | Critical 3, Medium 61, Low 6 |
| Heraj representative | 36 | Re-Open 1, Closed 35 | Critical 5, Medium 28, Low 3 |
| Anaam user | 41 | Open 10, Resolved 27, Skip 4 | Critical 5, Medium 26, Low 10 |
| Anaam kitchen | 14 | Open 7, Resolved 7 | Medium 14 |
| **Total** | **161** |  |  |

One tracker bug ID is shared between the two Heraj role sheets, so the input
contains 161 rows and 160 unique tracker IDs. The top-level `bugs` arrays were
treated as canonical because category references under-counted the Heraj
sheets. Every row's description, status, priority, category, notes and media
references was reviewed.

The tracker was read using HTTP GET only. No POST, PUT, PATCH or DELETE request
was made; no status, note, attachment or tracker record was changed. Tracker
URLs, share tokens, account data and endpoint values are intentionally absent
from this repository. The four downloaded JSON files remain temporary evidence
outside the project.

There were 274 media references resolving to 133 unique public attachment
pages. Of those, 120 were accessible and inspected (89 PNG screenshots and 31
MP4 videos, with three frames sampled per video); 13 links were deleted or no
longer exposed usable media. The unavailable evidence is a warning, not a
reason to infer missing behavior.

#### Reference-project resolution

| QA scope | Read-only local root | Match evidence |
|---|---|---|
| Heraj user | `/Users/abdelrahamndandash/StudioProjects/herajnokba` | The repository declares a user entry point/flavor and a provider entry point/flavor in one shared codebase. |
| Heraj representative | `/Users/abdelrahamndandash/StudioProjects/herajnokba` | The provider flavor and provider-specific delivery/profile flows correspond to the representative sheet. |
| Anaam user | `/Users/abdelrahamndandash/StudioProjects/anaammakkah` | The single app bootstrap contains the individual account path documented by the project. |
| Anaam kitchen | `/Users/abdelrahamndandash/StudioProjects/anaammakkah` | The same app contains an explicit butcher/butchery account type and role-specific registration, profile and slaughter-request flows. |

Both reference roots were source-inspected only. No Flutter, generator, build,
format, dependency or cleanup command was run in either root, and neither was
modified.

#### Tester-expectation catalog

The 161 rows normalize into the following reusable expectations. Counts are
recurrence signals and may overlap because one bug can exercise multiple
contracts.

| Expectation | Historical evidence | Correct reusable boundary |
|---|---|---|
| Reject invalid data before a request and show localized field-level feedback | Phone, national ID, VAT/tax, IBAN, plate, account number, price, empty ordered fields and excessive text appeared in all four scopes | Root validators and field plumbing provide primitives; the application owns backend/product rules such as allowed carrier prefixes and business maxima. |
| Back, retry and repeated taps must not create black screens, duplicate screens or stale forms | OTP Back/reset, stale registration forms, repeated FCM navigation, disabled actions and white/black transient screens | Root page/button/navigation primitives protect lifecycle and duplicate submission; feature controllers own draft reset policy. |
| Picker/media flows need camera/gallery, cancel, replace/remove, orientation, count/size and lifecycle safety | Registration documents, transfer receipts, avatars, advert galleries and return evidence recur across roles | Root `AppImagePickerField`/`AppMedia`; upload APIs and document rules remain feature-owned. |
| Dropdown/date/location selection must not summon the keyboard unexpectedly and must represent selected data clearly | Dropdown keyboard regressions, date/time fields, city selection and map selection recur | Root `AppDropdown`; optional `app_maps`; product fields and required-data rules remain local. |
| Loading must terminate in content, empty, retryable error or safe fallback | Blank home, skeleton-only notification screen, stale order state and first-load failures | Root async/pagination/state components; feature refresh triggers remain local. |
| Notifications must tolerate nested payload shapes, validate target IDs, avoid duplicate routing and never guess domain identifiers | Order, delivery, return, profile, blocked/deleted-account and chat routing defects recur in both products | Optional notifications package normalizes transport data and delegates typed actions; event names, target-key contracts and refresh behavior remain application-specific. |
| Session-ending events must clear data and reach one stable authentication destination | Block/delete/deactivate cases recur in both products | Root session coordinator plus optional notification adapter; backend delivery remains an external contract. |
| HTML and links need an explicit allow/open policy and safe localized failures | Static pages and chat links recur | Optional `app_webview` or an injected external-link policy; product content remains backend-owned. |
| Permission prompts must occur in context and denial must produce a usable state | Location and notifications were requested at surprising times or without a usable fallback | Optional integrations request permissions from explicit user flows; root startup must not block on them. |
| Server-driven state and money must not be fabricated on device | Order states, cancellation reasons, coupons, commissions, wallets, returns, pricing, distances and admin content dominate the sheets | Backend/admin/product ownership. The base provides typed failures and refresh/cancellation infrastructure only. |
| Arabic/English, RTL/LTR, currency/digits and backend validation copy must be coherent | Language switching, Arabic validation, digits/currency order and mixed copy recur | Root localization parity and directional widgets; consuming apps map backend codes to localized messages. |

#### Normalized failure and ownership matrix

| Failure class | Recurring examples | Primary owner | Base action |
|---|---|---|---|
| Input normalization/validation | Saudi phone formats, VAT/tax, ID, IBAN, price, empty form order | Root primitive + feature policy | Harden only evidence-backed generic normalization; do not encode product maxima or backend carrier policy. |
| Form/OTP lifecycle | Clear rejected OTP, reset draft on intentional Back, no stale validation | Feature controller using root lifecycle-safe widgets | Document boundary; do not create an authentication UI framework. |
| Navigation/route identity | Wrong tab, duplicate detail screen, deleted entity route, missing Back | Feature router using root shell/session policies | Root already covers safe Back and unknown routes; target IDs remain product-specific. |
| Notification transport | Nested JSON payload, foreground/background/terminated delivery, duplicate taps | Optional package + consuming app + backend | Normalize payload transport generically; retain injected router and product-owned event map. |
| Media/picker lifecycle | Cancel, replace, camera/gallery, lost activity, rotated or incomplete images | Root picker/media + feature upload | Already canonical and tested; no duplicate helper. |
| Maps/permissions | First location, denied permission, saved versus selected address | Optional maps package + feature UX | Already optional/injectable; keys and checkout/location rules stay local. |
| HTML/WebView/external link | CKEditor links, payment WebView, chat URLs | Optional webview/external launcher + backend content | Already optional; no concrete WebView dependency enters root. |
| Async refresh/retry | State changes only after manual refresh, skeleton/blank terminal state | Root async/pagination + feature invalidation | Root covers finite request states; FCM/domain invalidation remains local. |
| API/admin data contract | Missing reason, wrong totals, missing IDs, incorrect distance/status/action flags | Backend/admin | No mobile workaround, cache or guessed value in base. |
| Product/design decision | Shipping options, free-price policy, labels, wallet semantics, screen presence | Product owner/application | Never promote into generic base. |
| Localization/accessibility/layout | RTL alignment, Arabic errors, clipped actions, currency position | Root widget contract + application copy | Canonical widgets already cover direction/theme/text scale/semantics; feature layouts need their own tests. |

#### Base comparison and pre-implementation adoption matrix

This matrix was completed before code changes for this phase.

| Historical pattern | Existing base evidence | Decision |
|---|---|---|
| Phone must start with the Saudi mobile stem and accept realistic formatting | `Validators.validateSaudiPhone` accepts local, `0` and `+966` forms but does not normalize Arabic digits | **Adopt:** normalize Arabic digits without narrowing carrier prefixes. |
| Saudi VAT/tax number needs more than a length check | The base has a backwards-compatible generic 15-digit VAT validator; Anaam implements the Saudi `3…3` rule | **Adopt:** add a separate strict Saudi VAT validator, preserving the generic API. |
| Nested FCM `data` maps/JSON must route identically to flat payloads | Both reference projects independently flatten nested payloads; optional `NotificationPayload` currently reads only the outer map | **Adopt in optional package:** deterministic non-throwing payload normalization with tests. |
| Product notification types and `order_id`/`delivery_id`/`return_id` routing | References contain large conflicting domain event tables | **Reject for base:** keep event-to-action mapping injected and application-owned. Never guess one identifier from another. |
| OTP reset and registration draft reset | Reference behavior is tied to authentication flows and backend resend/upsert contracts | **Reject for root:** feature controller responsibility; root fields already expose controllers/focus safely. |
| Vehicle plate, bank-account length, wallet maximum, price/weight/category rules | Each is product or backend-policy dependent | **Reject for root:** document/test in the consuming feature. |
| Camera/gallery/reset/lost-result behavior | Canonical root picker already covers the contract and has widget/service tests | **Retain:** no new wrapper or migration. |
| Dropdown keyboard and confirmation behavior | Canonical dropdown already covers focus, pending confirm/cancel, large lists and retry | **Retain:** no redesign. |
| Static HTML, payment WebView and map picker | Existing optional packages provide safe state/policy contracts | **Retain optional:** no root binary dependency. |
| Order, wallet, return, coupon, commission, distance and admin-content defects | Evidence and notes identify backend/admin/domain ownership | **Do not mask:** no fake values, mobile filtering, inferred state or local cache workaround. |

#### Pre-QA risk interpretation

Historical sheets are regression evidence, not a specification for embedding
the two products in the template. The base can prevent the repeated transport,
validation, lifecycle and presentation mistakes, but it cannot prove each
future application's backend event delivery, order state machine, payment
provider, map keys, admin content or store configuration.

#### Implemented from the adoption matrix

- Saudi mobile validation now normalizes Arabic-Indic digits while retaining
  the existing local, `0` and `+966` forms.
- `validateSaudiVat` adds the strict Saudi `3` + 13 digits + `3` structure;
  the existing generic 15-digit VAT validator remains unchanged for backwards
  compatibility.
- The optional notifications package now normalizes flat, nested-map and JSON
  object-string payloads without throwing. Nested application keys win, a
  colliding outer transport ID is retained as `notification_id`, unknown
  product event names remain available to the injected application router, and
  no domain target ID is inferred.
- Behavior tests cover valid, invalid, localized, malformed, collision and
  unknown-event branches. No widget, architecture, domain flow or reference
  project was redesigned.

No gallery scenario was added because these changes have no visual state. The
existing widget gallery continues to cover the canonical fields, buttons,
dropdown, state, media and picker surfaces implicated by the historical bugs.

#### Final verification

The project-local release gate completed against the final source and retained
artifacts:

| Check | Final result |
|---|---|
| Flutter/Dart | Flutter 3.47.1, Dart 3.13.1 |
| Formatting | 306 files checked, 0 changed |
| Root analyzer | No issues |
| Root tests | 228 passed, 2 intentional conditional skips |
| Root coverage | 2,485/4,079 lines, 60.92% |
| PHP inverse configuration | 15 passed, 3 opposite-branch skips |
| Optional packages | 5 analyzers and 49 tests passed |
| Optional examples | 3 analyzers and 3 tests passed |
| Generated sources | Reproducible: 16 outputs and 83 AR/EN keys |
| Final release gate | `mode=release checks=29 skipped=0 builds=0` |
| Optional isolation | Root dependency graph and Universal APK entries passed |

The 49 optional-package tests and three optional-example tests are separate
from the 228 root tests. The PHP inverse command proves the opposite compile-
time configuration of tests already present in the root suite and is not added
again to the distinct-test total. The resulting distinct automated total is
280 tests. The five notification-payload tests are included in the 14-test
notifications package total.

The monolithic `scripts/flutter_quality_gate.sh release --build` invocation
passed every pre-build check and the Android matrix, then stopped while copying
the iOS staging Simulator app because the host volume had no free space. This
was an environmental failure, not a compiler or test failure. Reproducible
intermediates and already-recorded debug artifacts were reclaimed, and every
remaining command from the gate was then run unchanged and passed. A final
`scripts/flutter_quality_gate.sh release` re-ran all analyzers, tests,
generation, budgets and isolation checks against those artifacts and produced
the 29-check pass above.

##### Release matrix and retained artifacts

- Android development, staging and production debug flavors built.
- Production Universal, ARM32, ARM64, x86_64 and AAB builds completed with
  external Dart symbols. Native symbols and R8 mappings were retained.
- Root iOS development, staging and production Simulator builds completed.
- Maps and Remote Config production examples built for Android and iOS.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Universal APK | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| ARM32 split APK | 15,846,674 | `7df5fcf2d56f9189199765cccd6b17f8456d013438fdd36aa81e3f15287f9d14` |
| ARM64 split APK | 18,601,894 | `e97b63ee6f2e9949e915a6014d31c95c90995a7acdbd04395295d7736616aede` |
| x86_64 split APK | 20,020,086 | `059ec12a3513461ff8229943168d1eef102df7fe6a4e4aef0f06566461fca8f3` |
| Production AAB | 50,659,286 | `6f4f6ae7540ac9b80868ba98be9dfc1c6725db5e2bb5400a6f3e56aca1cb1636` |
| Native-symbol archive | 133,760,000 | `09f38d0d023339dba07f2dab5e9ecf018cb387448aa651b83e24111d7cdb07ae` |

The Universal comparison uses the same external-Dart-symbol packaging
configuration as the current audited baseline. The current AAB value is
50,659,286 bytes; earlier phase-specific AAB measurements are not substituted
for this final artifact. ARM64, AAB and source-assets budgets passed, and the
Universal archive contains no concrete notifications, Firebase, Maps, WebView
or socket integration.

The connected Samsung SM-A235F/API 34 passed a release-code smoke using an
unchanged temporary copy of the ARM64 APK signed with the machine's debug key.
Cold launch, repeated Retry, HOME and hot resume kept the process alive and
top-resumed with no fatal, ANR or native-signal marker. The visible terminal
state was the expected bilingual safe startup failure for placeholder
production configuration, not a black screen or infinite splash. The original
unsigned release artifact was not modified, and the temporary signed files
were deleted.

Generated debug APKs, duplicate release copies, Simulator apps and failed
build intermediates were removed only after their build success, byte size and
where applicable checksum had been recorded. No source, asset, dependency,
configuration or production symbol artifact was deleted. The Gradle 9.1.0
build cache was also reclaimed after the root Android matrix completed; it is
reproducible and contains no project source.

Files changed for this pre-QA phase are:

- `docs/PRE_QA_HISTORICAL_TESTER_AUDIT_2026-08-31.md`
- `docs/QA_MATRIX.md`
- `docs/REUSABLE_COMPONENT_CATALOG.md`
- `lib/src/core/shared/helpers/validators.dart`
- `test/core/shared/helpers/validators_test.dart`
- `packages/app_notifications/README.md`
- `packages/app_notifications/lib/app_notifications.dart`
- `packages/app_notifications/lib/src/models/notification_payload.dart`
- `packages/app_notifications/lib/src/models/notification_payload_normalizer.dart`
- `packages/app_notifications/test/notification_payload_test.dart`

The target already contained unrelated uncommitted audit/widget/identity work;
it was preserved without reset, restore, staging or cleanup. Material commands
for this phase were read-only tracker/media retrieval, source inventory, Dart
format verification, root and optional analyzers/tests, PHP inverse tests,
coverage, generated-source reproduction, Android/iOS flavor and optional-
example builds, size/isolation checks, SHA-256 calculation, temporary APK
signing, and ADB install/launch/Retry/resume/log inspection. No dependency
upgrade command was run.

##### Warnings and final verdict

Flutter 3.47.1 reports future migration warnings for Built-in Kotlin in the
root/examples, for Firebase plugins used by the Remote Config example, and for
Swift Package Manager support in `google_maps_flutter_ios`. All current builds
pass; these are dependency/toolchain upgrade watch items, not present release
failures.

**Pre-QA verdict: ready with warnings.** The reusable contracts implicated by
the historical evidence are implemented and verified. Thirteen historical
media links are unavailable, and future applications must still test their own
domain event table, backend/admin behavior, credentials, signing and real
service integrations.

**Project verdict: Conditionally production-ready reusable baseline.** There
is no known reproducible crash in the verified scenarios, no infinite splash,
no silent black screen and no unintended optional integration in the root
binary. Production signing, real backend accounts, Firebase/APNs, Maps keys,
deep links, store delivery and complete product-specific physical-device QA
remain application release gates.

No tracker write method was used, neither read-only reference project was
modified, and no Git state-changing command, commit or push was performed.


---

## STANDARDS_AUDIT

*Source: `docs/STANDARDS_AUDIT.md`*

### Missing-standards audit and ownership map

Audit updated: 2026-08-27. The classification prevents a reusable base from
silently becoming a product. `Root` means every consumer benefits without a
vendor SDK. `Optional` means an independently opted-in package. `Template`
means policy/checklist/code seam only. `Product` needs an approved business or
privacy decision. `Blocked` needs credentials, services, signing, stores, or
physical devices.

#### Architecture and maintainability

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Enforced domain/module direction and no optional root imports | Root; `test/architecture/module_boundaries_test.dart` scans domain imports, root source, and root `pubspec` | Implemented |
| No cross-feature imports | Root policy in `AGENTS.md`; only the demo feature exists, so a multi-feature enforcement rule would currently be vacuous | Policy; extend test when second feature lands |
| DI lifetimes and no global mutable business/UI state | Root; constructor injection is required inside features, GetIt is limited to composition/legacy boundaries; blocking UI state is instance-owned; startup/session concurrency has tests | Implemented foundation; full generated lifetime graph test remains useful debt |
| Code generation reproducibility | Root; generated files are checked output, exact SDK constraints are recorded, build-runner command documented | Implemented; current analyzer-generator language warning is upstream/tooling debt |
| Upgrade and template customization | Template; `TEMPLATE_CUSTOMIZATION.md`, lockfile policy, migration gates | Implemented |
| ADRs for optional native integrations and symbols | Template; `docs/adr/0001-*` and `0002-*` | Implemented |
| Safe optional removal | Template; optional packages are path-isolated, root resolution is tested, and removal steps are documented | Implemented |

The root remains deliberately pragmatic: Navigator 1, a broad legacy shared
widget folder, and a small service-locator boundary are documented debt, not a
reason to perform a destabilizing rewrite.

#### Release engineering

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Reproducible build environment | Root/CI; Flutter 3.47.1, Dart floor, lockfiles, Java 17, AGP/Gradle/Kotlin documented | Implemented locally; containerized bit-for-bit builds not claimed |
| Version strategy | Template; semantic `versionName` plus monotonically increasing build number, flavor suffixes only outside production | Documented |
| Flavor signing separation | Product; base is intentionally unsigned and stores no keys | Blocked by product signing owner |
| Environment validation and no debug production config | Root; production rejects placeholder/non-HTTPS endpoint and invalid/tied pins; release is non-debuggable | Automated |
| CI cache safety | Template; Flutter action cache is version-keyed; dependency lockfiles are retained; no credential-containing build cache | Implemented policy |
| Artifact names, symbols, mappings | CI; SHA-keyed artifact, Dart symbols, R8 mapping, native symbols, APK/AAB | Implemented with 90-day CI retention; long-term storage is product-owned |
| Rollback/internal testing/store release | Product/template checklist; preserve previous signed artifact/config, phased internal testing before promotion | Documented; execution blocked |
| Dependency lock policy | Root; commit root and optional lockfiles, update deliberately, run full graph/build matrix | Implemented |
| Size regressions | Root CI script with evidence-based ARM64/AAB/assets budgets | Implemented |

The remaining Flutter Built-in Kotlin warning is not hidden: the app plus
`image_picker_android`, `shared_preferences_android`, and
`url_launcher_android` still apply KGP. It builds on the specified SDK but is a
future migration gate.

#### Security and privacy

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Secrets and rotation | Root policy rejects secrets; configuration contains public endpoint/pins only. Backend, signing, Firebase/APNs and Maps rotation owners are product-specific | Root policy implemented; real rotation blocked |
| Logging/redaction | Root diagnostics are debug-only: request in red, response in green, path/query/body printed with credential-like keys as `<redacted>`; host and headers are never printed; Bloc logs contain types, not state/event values | Implemented and regression-tested |
| Timeouts/retry/idempotency | Root Dio/startup policy; bounded retries for safe/idempotent operations only, UUID operation identifiers, synchronized token refresh | Implemented and tested |
| Certificate pin rotation | Root requires distinct primary/backup exact-host SHA-256 pins and validity checks | Policy tested; live chain/rotation blocked |
| Secure-storage/database migration and corruption | Root AES-GCM owner-scoped queue, fail-closed legacy/corrupt record handling; product databases own schema migrations | Root behavior tested; device invalidation/restore blocked |
| Root/jailbreak | Documentation only; local encryption is not represented as protection against a fully compromised device | Documented |
| Screenshot/clipboard | Product; enable per sensitive screen after UX/legal decision, not globally in a generic base | Intentionally excluded |
| PII classes, retention, deletion | Template contracts and session cleanup hooks; exact categories/retention/legal basis are product-specific | Foundation present; product register blocked |
| iOS privacy manifest/required-reason APIs and Android Data Safety | Product plus third-party inventory; declarations depend on enabled SDKs and actual data use | Blocked until product integration |
| License and SDK inventory | `DEPENDENCY_AUDIT.md` records every direct resolved dependency and local license; Pub/Gradle graphs are reproducible | Implemented baseline; signed SBOM attestation remains CI-org work |
| Vulnerability scanning | Root direct Pub versions queried through OSV batch API; zero known records at audit time | Point-in-time implemented; repeat in CI and review transitives/native SDKs |
| Device/token backend contract | Optional notifications guide separates installation ID, FCM token, user ID, platform and backend record | Foundation implemented; live backend blocked |

#### Reliability

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Global error boundaries | Root `runZonedGuarded`, Flutter error reporting and release `ErrorWidget` fallback | Implemented |
| No infinite startup waits | Root critical/non-blocking/optional/deferred coordinator with timeouts and once-only futures | Tested |
| Offline, retry, idempotency, concurrent requests | Root queue/cache/retry/auth refresh coordination | Tested locally; backend semantics blocked |
| Secure-store/cache corruption and migrations | Root fail-closed queue and cleanup; generic product DB migrations do not belong in root | Root tested; product-specific |
| Low storage/memory pressure | Product/device; root avoids unbounded startup and infinite skeletons, but OS fault injection is not automatable here | Blocked physical QA |
| Lifecycle/process death/restoration | Root/optional seams exist; Android picker lost-data handling and optional socket/notification policies are tested in isolation | Physical journey blocked |
| Clock/timezone changes | Root uses locale-aware `intl`; business deadlines and server-clock contracts are product rules | Product-specific |
| Pagination/duplicate requests | Root paginated Cubit prevents duplicates/stale results, maps throws, restores cancellation and ignores completion after disposal | Implemented and unit-tested; feature-specific integration tests required |

#### Performance

No universal millisecond or memory number is defensible for an empty template on
one host. The root supplies bounded startup and image/list primitives; product
CI must establish cold/warm start, splash, frame/jank, memory, image cache,
large-list, network, battery, and background budgets on its supported device
matrix. DevTools CPU/memory/network/performance profiling and profile/release
benchmarks are **Blocked pending a real product flow and representative devices**.
Size budgets are the only performance budgets that are evidence-based at the
base level and are enforced now.

#### Accessibility and localization

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Tap targets, semantics, focus, screen reader | `AppButton` variants pass Flutter Android/labeled tap-target guidelines; shared fields/dropdown expose semantics | Automated foundation present; TalkBack/VoiceOver device audit blocked |
| Contrast, large text, bold text, reduced motion, color-safe state | Design-system/product themes; base supports themes/text scale but cannot approve product colors/animation policy | Product/device validation blocked |
| Keyboard/focus order | Root for shared forms where applicable; desktop/web behavior is product platform scope | Partial |
| RTL accessibility | Root directional APIs and AR/EN widget coverage | Automated foundation; screen-reader device pass blocked |
| AR/EN completeness and missing keys | Root explicit translation files; exact key parity test | Implemented |
| Runtime locale and RTL/LTR | Root EasyLocalization source of truth and widget tests | Implemented |
| Plurals, dates, numbers, currencies, zones, mixed direction | Root `intl` foundation; actual copy/data formats depend on product requirements | Foundation; product cases required |
| Backend errors | Root typed/localizable failure mapping; raw backend errors are not a user-message contract | Implemented policy; endpoint mapping is product work |

Golden suites were not invented for placeholder screens. Accessibility
guidelines are automated for the reusable button contract and should expand
with stable product screens with approved copy, fonts,
contrast, text scaling, and semantics expectations.

#### Design system

The root already provides standard fields, confirmation-based dropdown sheet,
an approved `AppButton` variant family, dialogs, state/error/empty views, skeleton/pagination primitives,
responsive tokens, light/dark themes, validation patterns, and repository-local
reuse instructions. Arabic/English, RTL/LTR, theme and shared-widget tests exist.
A comprehensive widget catalog/Previewer is useful once product visual tokens
are approved; creating a second documentation UI inside an empty base is not a
runtime requirement and is classified **Template/product-specific**.

#### Testing and observability

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Unit/state/repository/widget/network/security tests | Root and five optional packages | Implemented and passing |
| Router/flavor/release smoke tests | Root routing policy/widget tests plus Android/iOS build matrix | Local automated portion implemented |
| Integration and physical-device matrix | Product endpoints, permissions, camera/crop, auth, process death, accessibility | Blocked inputs/devices |
| Golden tests | Product design approval and stable rendering environment | Intentionally deferred |
| Migration tests | Root queue legacy/corruption; product DB schemas add their own | Root portion implemented |
| Fixture policy/flaky detection | Template: deterministic fakes, no production credentials/network; CI reruns must investigate rather than mask flakes | Documented |
| Traceability | `QA_MATRIX.md` | Implemented |
| Crash/nonfatal reporting | Root callback/error seams; provider must be opt-in and non-blocking | Optional/product; provider blocked |
| Structured secure logs/breadcrumbs | Root redaction policy and Flutter error context | Foundation; provider-specific sink blocked |
| Version/build/flavor/platform context | Root environment metadata available at composition boundary | Foundation |
| Performance monitoring and consent | Optional/product; must not initialize before consent or block startup | Intentionally not bundled |
| Request correlation IDs | Backend/product contract; Dio interceptors provide insertion seam | Blocked contract |
| Symbol upload/symbolication | CI archives all symbol forms; provider upload needs credentials | Archive implemented; upload blocked |

All observability providers must be replaceable/disabled without startup
failure. The base therefore exposes policy and hooks but contains no analytics or
crash vendor SDK.

#### Platform readiness

| Standard | Classification and evidence | Status |
| --- | --- | --- |
| Android API/R8/edge-to-edge/predictive Back | Root current Flutter templates, `PopScope`, minify/resource shrink release builds | Builds pass; minimum/current device behavior blocked |
| Permissions and Photo Picker | Root picker flow with no broad storage permission | Static/release verified; physical allow/deny/process-death blocked |
| Notifications/APNs/background states/channels | Optional notifications package plus product config | Package tests pass; Firebase/APNs/device blocked |
| Deep/App/Universal Links | Product domains, association files, route matrix | Intentionally excluded/blocked |
| iOS scenes/lifecycle/privacy | Root SceneDelegate and simulator builds; declarations depend on actual product APIs | Simulator passed; signed/device/privacy review blocked |
| Google Maps restrictions | Optional package; keys/billing/quotas belong to product | Package tests pass; live service blocked |
| WebView security | Optional HTTPS/host/scheme/navigation policy | Tests pass; real host/download/SSL journeys blocked |
| Background modes | Product only when genuinely needed | No unnecessary mode enabled |
| iOS archive/app thinning | Product signing/export | Blocked |

#### Implemented in this audit

- Removed Tika through maintained plugin upgrades and adapted the picker API.
- Proved every optional dependency graph resolves with the root and still adds
  zero code until opted in.
- Removed verified-unused/duplicate assets and made declarations explicit.
- Added missing-asset/translation-parity and architecture-boundary tests.
- Added measured size budgets, external symbol retention, ABI-split release
  artifacts, and optional-resolution CI checks.
- Added size evidence, ADRs, upgrade/customization/removal instructions, and
  explicit classification of missing standards.
- Added a Codex-discoverable project skill, reusable catalog and cross-project
  recurrence/test-count evidence.
- Replaced value/payload diagnostics with structural redaction, removed the
  logger dependency, scoped blocking UI state, and hardened async/pagination/
  dropdown concurrency, retry, cancellation and disposal behavior.

#### Readiness

The base remains **Conditionally production-ready**. There is no locally
reproducible analyzer, test, dependency-resolution, or Android release blocker.
It cannot become “Production-ready” until a consuming app supplies and verifies
identities, signing, backend/TLS rotation, privacy declarations, Firebase/APNs,
Maps/deep links, observability consent and symbols, stores, and the physical
device/accessibility/performance matrix.


---

## TEST_COUNT_RECONCILIATION

*Source: `docs/TEST_COUNT_RECONCILIATION.md`*

### Test-count reconciliation

Evidence dates: 2026-08-27 through 2026-09-03. Counts below come from `flutter test
--reporter=json`; hidden suite-loader events are excluded and conditional skips
are counted separately. Raw event logs were written outside the repository in
the Codex task work directory.

#### Exact explanation

The reported **187 root tests** was an accounting error, not a former root
manifest. At that point the root had 157 passing tests and the five optional
packages had 30 passing tests. `157 + 30 = 187`; the aggregate was labeled
"root". This is independently supported by the unchanged optional-package
breakdown: Notifications 9, Remote Config 4, WebView 5, Maps 6 and Socket 6.

Four subsequently added root assertions—two architecture boundaries and two
asset/localization assertions—changed the real root count from 157 to the
previously reported 161. The first hardening audit added 18 behavior tests,
producing 179. The widget-hardening phase added 28 further behavior tests,
producing 207. The compatibility-consolidation continuation added 12 tests,
producing 219 passed + 2 conditional skipped. Subsequent identity, runtime and
history-audit work reached 228 root tests before this independent review. The
session-boundary hardening added nine behavior assertions, producing the
current **237 passed + 2 conditional skipped**. No optional test
is included in that root count.

| Previous item | Current location/name | Status | Reason / replacement coverage |
|---|---|---|---|
| Root manifest: 157 passing | Existing root files under `test/` | Retained | JSON discovery shows all baseline files; no missing/failed suite loader |
| 2 architecture boundary assertions | `test/architecture/module_boundaries_test.dart` | Added before this audit | Domain and optional/root import boundaries |
| 2 asset/parity assertions | `test/assets/asset_manifest_test.dart` | Added before this audit | Declared asset existence and AR/EN key parity |
| Misclassified optional 30 | Tests inside the five `packages/app_*` trees | Moved in accounting only; files retained | Still 9+4+5+6+6, executed independently |
| Async cancellation assertion | `AsyncCubit CancelledFailure restores initial...` | Behavior corrected/renamed | Prevents permanent loading after cancellation |
| Async throw/concurrency/disposal | three names in `async_cubit_test.dart` | Added | Typed unexpected error, latest wins, close safety |
| Pagination branches | seven names in `paginated_async_cubit_test.dart` | Added | Filter, append, dedupe, partial retry, throw, supersession, cancel/dispose |
| Unified buttons | three names in `app_button_test.dart` | Added | Duplicate submit, disabled action, accessible targets/variants |
| Button disposal | `async completion after disposal does not call setState` | Added | Safe asynchronous lifecycle completion |
| Paginated dropdown retry | `paginated initial error is retryable inside the sheet` | Added | First-page failure is no longer an empty dead end |
| Dropdown duplicate confirmation | `rapid confirmation applies once and does not pop the page` | Added | Prevents double pop/submission |
| Redacted network diagnostics | `debug diagnostics never contain URL, headers, or bodies` | Added | Secret/PII-bearing fields excluded structurally |
| Scoped blocking overlay | `controller scopes loading state and releases the barrier` | Added | No process-global UI state; lifecycle owned by caller |
| Canonical media lifecycle/fallback/viewer | `app_media_test.dart` | Added | Failure never exposes raw exceptions; async video initialization/disposal is generation-safe |
| Injectable picker field/service | `app_image_picker_field_test.dart`, `plugin_app_image_picker_service_test.dart` | Added | Cancellation, permission, lost activity, count/size, replace/remove, duplicate request and disposal |
| Page shell/Back behavior | `app_page_shell_test.dart` | Added | Normal/sliver layouts and contextual Back without global suppression |
| Async and paginated presentation | `async_bloc_builder_test.dart`, `paginated_list_widget_test.dart` | Added | Loading/empty/error transitions, refresh, scrolling, inline failure and retry |
| Dialog, sheet and feedback safety | `dialog_feedback_test.dart`, `legacy_widget_regressions_test.dart` | Added | Adaptive confirmation, context-owned sheets/messages and verified legacy regressions |
| Dropdown/text/button accessibility matrix | expanded widget tests | Added | Focus/keyboard, large data/text, RTL, light/dark, semantics and tap targets |
| Optional WebView/Maps page states | optional package page tests | Added outside root | Safe localized configuration failures without pulling packages into root |
| Compatibility media/state/action/navigation paths | expanded media/state/legacy widget tests | Added | Proves canonical delegation, scale mapping, async disposal, disabled semantics, viewer policy and contextual Back/Close |
| Session-generation token storage | `test/core/network/auth/token_storage_test.dart` | Added | Single encrypted pair, fail-closed write, stale refresh refusal, superseded write and legacy migration |
| Refresh/logout/account-switch races | `test/core/network/dio_network_audit_test.dart` | Added | Delayed refresh cannot overwrite a newer session; a stale success is cancelled after logout |
| Offline replay owner switch | `test/core/network/dio_network_audit_test.dart` | Added | Active replay is cancelled and the old owner's second mutation never runs under the new identity |
| Socket in-flight lifecycle races | `packages/app_socket/test/generic_socket_client_test.dart` | Added outside root | Auth change and pause/resume invalidate stale connection attempts |
| Notification privacy/localization | `packages/app_notifications/test/notification_logging_test.dart` | Added outside root | Debug output redacts payload/identity fields and action labels match Arabic/English |

No test was intentionally removed, merged away, or lost to discovery in this
audit. The sibling `flutter_clean_arch_base` directory is not an authoritative
historical manifest and was not used to manufacture missing test names.

#### PHP compile-time branches

`PHP_RESPONSE_MODE` selects whether HTTP 200 bodies using the custom PHP
`key/data/message` envelope are interpreted as PHP success/failure/session
signals. It does not select a different server at runtime.

| Configuration | Dedicated envelope result | Meaning |
|---|---:|---|
| Default / `true` | 16 passed, 2 OFF-only skipped | PHP success/fail/blocked/need-active parsing is enabled; normal shared mapping also runs |
| `--dart-define=PHP_RESPONSE_MODE=false` | 15 passed, 3 ON-only skipped | Envelope-looking bodies use the normal response path; both OFF guarantees run |

If `php_auth_interceptor_test.dart` is included in the false-mode command, its
three deliberately ON-only integration tests also skip, yielding 15 passed and
6 skipped. The canonical inverse-branch command therefore targets
`php_envelope_test.dart`, as documented in `RELEASE_CHECKLIST.md`. This is
expected conditional selection, not a silently hidden suite.

#### Current independent totals

| Suite | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Root default | 237 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 16 | 0 | 0 |
| Remote Config optional | 16 | 0 | 0 |
| WebView optional | 6 | 0 | 0 |
| Maps optional | 7 | 0 | 0 |
| Socket optional | 8 | 0 | 0 |
| WebView example | 1 | 0 | 0 |
| Maps example | 1 | 0 | 0 |
| Remote Config example | 1 | 0 | 0 |

The 15 inverse-PHP passes are not added wholesale to the root total because
13 are shared assertions already discovered by the default run. Counting only
the two OFF-only assertions, the current non-double-counted total is
`237 root + 2 inverse-only + 53 optional + 3 examples = 295` behaviors.

#### Three-provider closure totals — 2026-09-05

The table above is retained as the independent-review snapshot. Subsequent
session/offline/token work added 12 root tests (237 → 249), widget and
compatibility hardening added 18 (249 → 267), and this closure added three
tests (owner-bound queue encryption plus two AppErrorHandler matrix tests),
producing 270. The existing refresh test was strengthened to assert
`Accept-Language` on refresh and retry, so it adds coverage without adding a
new test name.

| Suite | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Root default | 270 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 32 | 0 | 0 |
| Remote Config optional | 17 | 0 | 0 |
| WebView optional | 12 | 0 | 0 |
| Maps optional | 14 | 0 | 0 |
| Socket optional | 10 | 0 | 0 |
| WebView example | 1 | 0 | 0 |
| Maps example | 1 | 0 | 0 |
| Remote Config example | 1 | 0 | 0 |

Only the two inverse-only PHP assertions are added to the default-root count.
The non-double-counted total is therefore
`270 root + 2 inverse-only + 85 optional + 3 examples = 360` behaviors.
The historically reported 61 focused widget tests remain a subset of their
then-current root total; they were never an additional suite to add to root.
The current `test/core/widgets` suite is **79 passed**, likewise a subset of
the current 270 root tests.

#### Pre-design delegated audit totals — 2026-09-05

The post-closure Claude/Cursor/Codex audit added six behavior tests without
removing, renaming, skipping, or weakening an existing test:

- one corrupted token-record self-heal test;
- three incomplete-session tests covering failed user persistence, token-only
  restore and user-only restore;
- one dark-theme dropdown/real-trigger-size test;
- one explicit multiline contract test.

| Suite | Passed | Skipped | Failed |
|---|---:|---:|---:|
| Root default | 276 | 2 | 0 |
| PHP envelope inverse | 15 | 3 | 0 |
| Notifications optional | 32 | 0 | 0 |
| Remote Config optional | 17 | 0 | 0 |
| WebView optional | 12 | 0 | 0 |
| Maps optional | 14 | 0 | 0 |
| Socket optional | 10 | 0 | 0 |
| Optional examples | 3 | 0 | 0 |

The focused `test/core/widgets` suite is now **81 passed**, still a subset of
the 276 root tests. The non-double-counted total is
`276 root + 2 inverse-only + 85 optional + 3 examples = 366` behaviors. Root
line coverage is 2,941/5,004 = **58.77%**.

##### Final delegated re-review delta

Cursor's evidence-based re-review identified that the dropdown's measured
48dp height was not yet an explicit production constraint. The implementation
now enforces that minimum and tests it at the design viewport. One additional
password-line-limit regression test was added; this is the only new test name
after the full-gate snapshot above.

- Final root default: **277 passed, 2 expected conditional skips**.
- Final `test/core/widgets`: **82 passed**, a subset of the 277 root tests.
- Final non-double-counted total: `277 + 2 + 85 + 3 = 367` behaviors.
- Coverage remains reported from the preceding full-gate coverage run; it was
  not represented as a new post-delta measurement.

#### Accepted audit hardening closure — 2026-09-08

The accepted final audit fixes added 21 behavior tests without deleting,
renaming, skipping, or weakening any existing test:

- nine retry tests for `Retry-After` delta/date parsing, fallback, bounded
  delays, safe methods, and invalid or negative values;
- six authentication-interceptor tests for once-only failure ownership,
  storage/callback failures, one shared timeout budget, and late completion;
- three remote-source tests proving that only handled unauthorized failures
  bypass the session coordinator;
- three launcher tests proving diagnostics are stable and redact raw errors,
  URLs, and sensitive values.

- Current root default: **298 passed, 2 expected conditional skips**.
- Current `test/core/widgets`: **82 passed**, unchanged and still a subset of
  the 298 root tests.
- Current non-double-counted total:
  `298 + 2 inverse-only + 85 optional + 3 examples = 388` behaviors.
- Coverage was not regenerated for this non-UI hardening delta and remains the
  explicitly dated snapshot above.


---

## THREE_PROVIDER_CLOSURE_2026-09-05

*Source: `docs/THREE_PROVIDER_CLOSURE_2026-09-05.md`*

### Three-provider production closure

Evidence date: 2026-09-05. Target: `flutter_base` only. This report records the
completed Claude, Cursor and Codex implementation/review cycle and supersedes
the provider-execution status in the earlier 2026-09-03 independent-review
snapshot. Historical artifact measurements retain their original phase labels.

#### Verdict

The reusable source baseline is **Conditionally production-ready and safe to
freeze**. All confirmed, locally testable defects found in this cycle were
fixed without changing the base architecture, deleting reusable capabilities,
or moving optional integrations into the root binary. Product signing, real
backend/Firebase/APNs/Maps configuration, store delivery and complete physical-
device accessibility/notification journeys remain application-specific gates.

#### Provider responsibilities and review

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

#### Closed findings

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

#### Verification totals

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

#### Artifact and device limits

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

#### Commands used for final verification

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

#### Recovery and repository safety

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

#### Exact target files changed in this cycle

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


---

## WIDGET_HARDENING_REPORT

*Source: `docs/WIDGET_HARDENING_REPORT.md`*

### Widget hardening report — 2026-08-27

#### Verdict

The reusable widget surface is **conditionally production-ready**. The base now
has a deliberately small canonical surface rather than treating all legacy
widgets as independent design-system contracts. All locally reproducible
crash, lifecycle, disabled-state, Back-navigation, leak and raw-error findings
in scope were corrected. No widget or asset was deleted.

Real backend journeys, signed store artifacts, Firebase/APNs, Maps credentials,
native WebView content, camera/gallery OEM behavior, screen-reader sessions and
complete predictive-Back gesture QA remain product/device release gates.

#### Canonical surface and implemented behavior

- `AppMedia` covers asset/file/network images and SVG, optional injected video,
  loading, safe failure/fallback, explicit viewer policy, cancellation-safe
  generations, lifecycle disposal and accessible/localized semantics. Raw
  exceptions are never rendered.
- `AppImagePickerField` uses `AppImagePickerService`; the plugin adapter covers
  camera/gallery, cancellation, permission failure, lost activity recovery,
  replacement/removal, count/byte limits, duplicate-request prevention and
  safe disposal.
- `AppPageShell` supports normal and sliver pages, leading/trailing actions,
  contextual custom Back handling, framework-native default Back behavior,
  RTL/LTR, themes and text scaling. It does not globally suppress Back.
- `AppButton`, `DefaultTextField`, `AppDropdown`, `AppStateView`,
  `FullScreenLoadingManager`, `AsyncBlocBuilder`, `PaginatedListWidget`,
  `AppErrorHandler`, adaptive confirmation, default sheets and `MessageUtils`
  were hardened around loading/disabled/duplicate action, injected/contextual
  navigation, focus/semantics, themes, direction and bounded feedback.
- WebView and Maps page-state implementations remain in optional packages and
  accept safe localized configuration/error copy.

Legacy classifications and removal preconditions are in
`WIDGET_LEGACY_MATRIX.md`. `ProductsScreen` migrated from `DefaultScaffold` to
`AppPageShell`; unauthenticated actions migrated from `DefaultButton` to
`AppButton`. Other call sites were intentionally retained where visual or
behavioral equivalence was not proven.

#### Verified regressions fixed

| Finding | Resolution |
| --- | --- |
| `UniversalMediaWidget` video initialization failure | Compatibility wrapper delegates to generation-safe `AppMedia`; legacy controller also handles failure without force unwrap or raw copy |
| `ImageView` disposed during async initialization | Deprecated adapter now delegates to the tested canonical `AppMediaViewerPage`; the duplicate video controller/lifecycle implementation was removed |
| `SuccessDialogBody` delayed navigation | Owned cancelable `Timer`; contextual navigator; disposal cancels delayed action |
| `CachedImage.ignoreClick` | Default viewer opening is bypassed when requested; custom tap remains explicit |
| `DefaultButton.disabled` | Disabled/loading callbacks are `null`, so actions cannot fire |
| `UploadImageWidget` notifier leak | Owned `ValueNotifier` is disposed |
| `DefaultScaffold` Back behavior | Global `PopScope(canPop: false)` removed; contextual Back belongs to `AppPageShell` |
| `AppWebViewPage` raw errors | Policy/config/network/plugin failures map to injected localized messages with safe retry/loading states |

#### Tests and coverage

Root: **219 passed, 2 conditional skipped, 0 failed**. The skips are the
expected PHP inverse compile-time assertions. The explicit inverse command is
**15 passed, 3 opposite-branch skipped**.

Optional packages: Notifications 9, Remote Config 4, WebView 6, Maps 7 and
Socket 6: **32 passed, 0 failed**. All root and optional analyzers report no
issues.

Focused widget suite: **61 passed**. These 61 are a focused subset of the 219
root tests, not 61 additional tests. The final quality-gate rerun produced
full-root LCOV of **2,435 / 4,069 lines (59.84%)**. Focused widget LCOV imports:
**1,476 / 3,584 (41.18%)**;
`AppMedia` is 66.09%, the canonical viewer and legacy `ImageView` adapter are
100%, `CustomAnimatedButton` is 92.50%, `AppStateView` is 89.58%, and the
legacy scaffold adapter is 84.62%. These percentages are evidence, not a
substitute for behavior assertions.

Added widget coverage includes loading/disabled/failure/empty, rapid actions
and retries, asynchronous disposal, focus/keyboard, Arabic/English RTL/LTR,
light/dark, large text/small layouts, semantics/tap targets, pagination
scroll/refresh/inline failure, dropdown single/multi/500-item data, safe media,
picker lifecycle and optional WebView/Maps page states.

#### Build and release results

| Check | Result |
| --- | --- |
| Format verification | 293 files checked, 0 changed |
| Root analyzer | No issues |
| Optional analyzers | No issues in all five packages |
| Android development/staging/production debug | Passed |
| Production universal APK | Passed, non-debuggable |
| ARM32/ARM64/x86_64 splits | Passed |
| Production AAB | Passed |
| ARM64 analyze-size | Passed; DevTools JSON produced |
| iOS development/staging/production simulator | Passed |
| Size budgets | Passed |
| Root optional-isolation checks | No dependency, registrant or APK-entry match |
| Samsung SM-A235F / API 34 release smoke | Installed/launched, process alive, no fatal Flutter/Android exception |

The Samsung smoke used placeholder production configuration, which correctly
showed the controlled startup-failure experience. It does not prove backend,
authentication, camera, media codec, WebView, Maps or notification journeys.

#### Release artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Universal external-symbol APK | 49,883,940 | `0e9486b7e7bfd281694def7f951a3cf122dddce99fe34830d9288047aa1e8ecc` |
| ARM32 split | 15,841,890 | `3a519fb1bc303d3431af5e939c24fbd3f83fa636f8f990261ba975d71e77cf61` |
| ARM64 split | 18,580,722 | `21196114cff091281da7995ecbb52807060eed1f902f0bb980cf56321212d28c` |
| x86_64 split | 19,998,914 | `383ee453f26a57380df6d12f8bb9b92b3469e7bab9c42e5cd79bdbd37d318f1f` |
| AAB | 50,618,821 | `8baeafc863bb9b1251854f50a3c207c946ee4b552d5c1898d5b3e8ed61daf63c` |

The 49,883,940-byte universal is 2,162,356 bytes (4.15%) below the earlier
52,046,296-byte artifact. These are explicitly different packaging
configurations: the final artifact externalizes Dart debug information, while
the earlier comparison artifact did not. The difference is symbol-packaging
impact, not a like-for-like widget-code saving. No saving is attributed to
deleting widgets or production behavior. Symbols and R8 mapping were retained.

The authoritative final AAB is **50,618,821 bytes**, identified by the SHA-256
above after the final rebuild. A previously circulated 50,618,560-byte value
has no matching final artifact or command-log checksum and is superseded; it
must not be used as a release baseline.

#### Final tooling consistency closeout

`scripts/flutter_quality_gate.sh` is the executable project-local entry point.
It selects the Flutter SDK recorded by the project instead of trusting a
possibly stale shell `PATH`, enters the root, fails on required check failures,
and provides `quick`, `full`, and `release` modes. Expensive platform builds run
only with the explicit `release --build` option. It contains no user-specific
absolute path, credentials, Git command, or reference-project operation.

The final `release` invocation passed **19 checks with 0 skips**: format (293
files, 0 changes), root and five optional analyzers, 219 root tests with two
expected conditional skips, PHP inverse 15/3, 32 optional tests, root dependency
isolation, ARM64/AAB budgets, and Universal-APK entry isolation. No further
widget or architecture redesign was performed.

The reusable base can therefore be frozen as the maintained baseline. Its
classification remains **conditionally production-ready** because signing,
real services/credentials, store delivery, and product-specific physical-device
journeys remain release gates for each consuming application.

Consistency-phase target changes:

- `scripts/flutter_quality_gate.sh` (new)
- `.codex/skills/flutter-base-production/SKILL.md`
- `AGENTS.md`
- `docs/COMMAND_LOG_2026-08-27.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/QA_MATRIX.md`
- `docs/SIZE_AUDIT.md`
- `docs/WIDGET_HARDENING_REPORT.md`
- `docs/CHANGE_MANIFEST.md`
- three compatibility-use comments in `custom_animated_button.dart`,
  `loading_button.dart`, and `products_body.dart`, required to keep analyzer
  intent explicit for deliberately retained deprecated adapters.

Recoverable pre-change documentation backup:
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-quality-gate-consistency-20260827.tar.gz`
(SHA-256
`6997304d99bdcd9a69db00d5e6b382332ce48ed6023cb7fbde06018a17087f12`).
The five files checked for SDK-specific formatting also have a targeted backup
at
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-final-format-drift-20260827.tar.gz`
(SHA-256
`561dd4f748a6d9310ef35da96bfe3b8621e2e7edb97c2a3c595d102148437bd1`).

#### Exact source/config/test files changed in this phase

New canonical implementation files:

- `lib/src/core/widgets/media/app_media.dart`
- `lib/src/core/widgets/media/app_media_models.dart`
- `lib/src/core/widgets/media/app_media_viewer_page.dart`
- `lib/src/core/widgets/media/app_video_controller.dart`
- `lib/src/core/widgets/media/media.dart`
- `lib/src/core/widgets/image_picker/app_image_picker_field.dart`
- `lib/src/core/widgets/image_picker/app_image_picker_models.dart`
- `lib/src/core/widgets/image_picker/app_image_picker_service.dart`
- `lib/src/core/widgets/image_picker/plugin_app_image_picker_service.dart`
- `lib/src/core/widgets/image_picker/image_picker.dart`
- `lib/src/core/widgets/scaffolds/app_page_shell.dart`
- `lib/src/core/widgets/scaffolds/scaffolds.dart`

Hardened/migrated implementation and configuration:

- `lib/src/config/language/locale_keys.g.dart`
- `assets/translations/ar.json`
- `assets/translations/en.json`
- `lib/src/core/widgets/universal_media/controller.dart`
- `lib/src/core/widgets/universal_media/universal_media_widget.dart`
- `lib/src/core/widgets/universal_media/widgets.dart`
- `lib/src/core/widgets/image_widgets/image_view.dart`
- `lib/src/core/widgets/image_widgets/cached_image.dart`
- `lib/src/core/widgets/image_widgets/upload_image.dart`
- `lib/src/core/widgets/dialogs/success_dialog.dart`
- `lib/src/core/widgets/dialogs/visitor_pop_up.dart`
- `lib/src/core/widgets/buttons/default_button.dart`
- `lib/src/core/widgets/buttons/app_button.dart`
- `lib/src/core/widgets/scaffolds/default_scaffold.dart`
- `lib/src/core/widgets/fields/text_fields/default_text_field.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/widgets/dropdown_item_tile.dart`
- `lib/src/core/widgets/fields/drop_downs/app_drop_down/widgets/dropdown_sheet_container.dart`
- `lib/src/core/widgets/handling_views/app_state_view.dart`
- `lib/src/core/widgets/handling_views/app_error_handler.dart`
- `lib/src/core/shared/helpers/loading_manager.dart`
- `lib/src/core/widgets/custom_messages.dart`
- `lib/src/core/widgets/pickers/default_bottom_sheet.dart`
- `lib/src/core/widgets/unauthenticated/unauthenticated_bottomsheet.dart`
- `lib/src/features/products/presentation/imports/products_imports.dart`
- `lib/src/features/products/presentation/view/products_screen.dart`
- `packages/app_webview/lib/src/webview_config.dart`
- `packages/app_webview/lib/src/app_webview_page.dart`
- `packages/app_maps/lib/src/map_models.dart`
- `packages/app_maps/lib/src/app_map_page.dart`
- `pubspec.yaml`
- `pubspec.lock`

New or expanded tests:

- `test/core/widgets/app_media_test.dart`
- `test/core/widgets/app_image_picker_field_test.dart`
- `test/core/widgets/plugin_app_image_picker_service_test.dart`
- `test/core/widgets/app_page_shell_test.dart`
- `test/core/widgets/legacy_widget_regressions_test.dart`
- `test/core/widgets/async_bloc_builder_test.dart`
- `test/core/widgets/paginated_list_widget_test.dart`
- `test/core/widgets/dialog_feedback_test.dart`
- `test/core/widgets/app_button_test.dart`
- `test/core/widgets/app_dropdown_test.dart`
- `test/core/widgets/default_text_field_test.dart`
- `test/core/widgets/blocking_overlay_test.dart`
- `packages/app_webview/test/app_webview_page_test.dart`
- `packages/app_maps/test/app_map_page_test.dart`

Guidance/report files changed or added:

- `AGENTS.md`
- `.codex/skills/flutter-base-production/SKILL.md`
- `.codex/skills/flutter-base-production/references/reusable-component-catalog.md`
- `docs/REUSABLE_COMPONENT_CATALOG.md`
- `docs/WIDGET_LEGACY_MATRIX.md`
- `docs/WIDGET_HARDENING_REPORT.md`
- `docs/QA_MATRIX.md`
- `docs/TEST_COUNT_RECONCILIATION.md`
- `docs/SIZE_AUDIT.md`
- `docs/CHANGE_MANIFEST.md`
- `docs/COMMAND_LOG_2026-08-27.md`

No source, configuration, asset or font was removed. The recoverable pre-phase
backup is
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-pre-widget-hardening-20260827.tar.gz`
(76 MiB, SHA-256
`aac1b37d2796db43dec6f784d5ffe9fdd71233fec5108d97998e77d04deef07c`).
No Git command was executed and no reference project was modified.

#### Compatibility-consolidation continuation

The final clarification authorized compatibility-preserving internal redesign
when it provides measurable benefit. The following additional consolidation
was completed and verified:

- Removed the second video-controller/lifecycle implementation from
  `ImageView`; it is now a deprecated, fully tested adapter to
  `AppMediaViewerPage`. Viewer min/max scale, autoplay and loop options moved
  into the canonical contract.
- `CachedImage` now opens `AppMediaViewerPage`, while `ignoreClick` still
  suppresses the implicit viewer and image semantics remain explicit.
- Added named `AppStateView.content/loading/empty/error/offline/
  permissionRequired` constructors, optional title/visual support and state
  semantics that preserve the retry action without duplicate visual/text
  announcements. `EmptyWidget` and `ErrorView` now delegate to these paths.
- Hardened the retained animated action against post-disposal completion,
  duplicate execution and fake-disabled callbacks; added keyboard focus,
  semantics and a 48dp minimum target. Legacy loading buttons are deprecated
  and have no production call sites.
- Replaced global Back/Close actions in retained controls with contextual
  `Navigator.maybePop`, fixed directional arrow transformation and migrated
  `VisitorBody` to `AppButton`.
- A compatibility test exposed an unused `context.locale` read in
  `DefaultScaffold` that crashed outside `EasyLocalization`; the coupling was
  removed and Back behavior is now covered through a real Navigator stack.

Additional source files changed in this continuation:

- `lib/src/core/widgets/buttons/custom_animated_button.dart`
- `lib/src/core/widgets/buttons/loading_button.dart`
- `lib/src/core/widgets/buttons/button_close.dart`
- `lib/src/core/widgets/buttons/default_button.dart`
- `lib/src/core/widgets/scaffolds/arrow_widget.dart`
- `lib/src/core/widgets/scaffolds/default_scaffold.dart`
- `lib/src/core/widgets/handling_views/app_state_view.dart`
- `lib/src/core/widgets/handling_views/empty_widget.dart`
- `lib/src/core/widgets/handling_views/error_view.dart`
- `lib/src/core/widgets/media/app_media.dart`
- `lib/src/core/widgets/media/app_media_viewer_page.dart`
- `lib/src/core/widgets/image_widgets/image_view.dart`
- `lib/src/core/widgets/image_widgets/cached_image.dart`
- `lib/src/core/widgets/dialogs/visitor_pop_up.dart`
- `test/core/widgets/app_media_test.dart`
- `test/core/widgets/app_state_view_test.dart`
- `test/core/widgets/legacy_widget_regressions_test.dart`
- `.codex/skills/flutter-base-production/SKILL.md`
- `.codex/skills/flutter-base-production/references/reusable-component-catalog.md`
- `docs/CHANGE_MANIFEST.md`
- `docs/COMMAND_LOG_2026-08-27.md`
- `docs/QA_MATRIX.md`
- `docs/REUSABLE_COMPONENT_CATALOG.md`
- `docs/SIZE_AUDIT.md`
- `docs/TEST_COUNT_RECONCILIATION.md`
- `docs/WIDGET_HARDENING_REPORT.md`
- `docs/WIDGET_LEGACY_MATRIX.md`

The targeted pre-continuation backup is
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-widget-consolidation-20260827.tar.gz`
(42,605 bytes; SHA-256
`9bb4fdb6c469b9e679567d478845c80d6ff671b9adc5a83eaa5c31e5dede20b6`).
No reusable file was removed: `image_view.dart` was replaced in place by its
compatibility adapter. Generated Flutter crash logs were not retained.


---

## PROJECT_IDENTITY_MIGRATION_REPORT

*Source: `docs/reports/PROJECT_IDENTITY_MIGRATION_REPORT.md`*

### Flutter Base identity, branding, and native-parity report

Date: 2026-08-27
Toolchain: Flutter 3.47.1, Dart 3.13.1, macOS ARM64, Java 17
Scope: final project identity, neutral branding, Android/iOS parity, native
splash/icons, optional Maps and Remote Config examples, reusable README and
project-local agent guidance.

#### 1. Readiness classification

**Conditionally production-ready as a reusable baseline.** The reusable and
locally verifiable identity work is complete. Product IDs, signing, restricted
Maps keys, per-flavor Firebase projects, APNs, backend configuration, store
records, privacy declarations and full physical-device journeys remain derived-
project release gates.

The complete post-identity release matrix now passes. The final run of
`scripts/flutter_quality_gate.sh release --build` completed 59 checks with zero
skips, produced fresh APK/AAB and symbol evidence, and was followed by release
launch verification on Samsung API 34, Android Emulator API 36 and iOS
Simulator. The reusable-baseline verdict is **Reusable baseline frozen**. The
overall production classification remains **Conditionally production-ready**.

#### 2. Paths, backup, and recovery

| Item | Value |
| --- | --- |
| Old path | `/Users/abdelrahamndandash/StudioProjects/flutter_clean_arch_base-main` |
| Final path | `/Users/abdelrahamndandash/StudioProjects/flutter_base` |
| Operation | Verified source/destination, archived source, then one authorized directory `mv`; no copied second project |
| Backup | `/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter_clean_arch_base-main-pre-identity-20260827-162517.tar.gz` |
| Backup bytes | 1.7 MiB compressed |
| Backup SHA-256 | `24740f6a2005d32b2d7f9122c8e7033a9b656d539b82f6994c51995594945f42` |
| Verification | `tar -tzf` succeeded before the rename |

The archive excludes only reproducible build/cache output (`build`, `.dart_tool`,
Pods, ephemeral, Gradle and OS metadata). It contains the source, native project,
assets, configuration, tests, documentation and the removed root launch catalog.

#### 3. Neutral identity and flavor parity

The originally suggested mixed-case `com.flutter.newProject` was deliberately
normalized to the portable lowercase `com.flutter.newproject` everywhere.

| Flavor | Android ID | iOS bundle ID | Display name |
| --- | --- | --- | --- |
| Development | `com.flutter.newproject.dev` | `com.flutter.newproject.dev` | Flutter Base Dev |
| Staging | `com.flutter.newproject.staging` | `com.flutter.newproject.staging` | Flutter Base Staging |
| Production | `com.flutter.newproject` | `com.flutter.newproject` | Flutter Base |

The Dart package is `flutter_base`; package imports, generated registrars, tests,
the widget gallery and integration harness use that identity. MainActivity is
`android/app/src/main/kotlin/com/flutter/newproject/MainActivity.kt`. Runner and
RunnerTests have flavor-correct iOS identifiers. Linux, macOS, Windows and web
metadata were neutralized as well.

#### 4. Branding audit, removals, and retentions

The automated audit searches, case-insensitively, for:

- Arabic Awamer variants including `أوامر الشبكة`;
- Awamer/Awaamer English transliterations;
- I Craft/ICraft/iCraft variants;
- `flutter_clean_arch_base-main` and the old package path;
- `com.example.clean_arch_base`, `com.example.cleanArchBase` and old package
  imports;
- personal paths and Apple `DEVELOPMENT_TEAM` values in active guidance/native
  templates.

No old Awamer or I Craft product artwork/text was present in the pre-migration
source. The active launcher art was Flutter's stock logo; it was classified as
obsolete template identity and replaced, not mistaken for user artwork. Generic
network/connectivity terminology and translations were retained.

Removed from the original root after backup and reference checks:

- `android/app/src/main/kotlin/com/example/clean_arch_base/MainActivity.kt`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`;
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`.

The LaunchImage files were the obsolete stock catalog, were no longer referenced
after the native LaunchScreen migration, and are recoverable from the archive.
No reusable widget, product asset, font or behavior was deleted. Reproducible
empty package directories, generated IDE files, `.DS_Store` files and Flutter
crash logs were removed without treating them as source assets. Optional-example
stock LaunchImage catalogs created by scaffolding were also replaced before the
examples became deliverables.

#### 5. Neutral icon and logo system

Authoritative replaceable sources:

- `tool/branding/neutral_app_icon.svg`;
- `tool/branding/neutral_launch_mark.svg`;
- `tool/branding/generate_native_branding.sh`.

The deterministic generator produces Android legacy/adaptive/monochrome and
notification assets, iOS AppIcon and launch assets, and the equivalent optional-
example assets. Web, macOS and Windows stock Flutter icons were replaced too.

| Evidence | Result |
| --- | --- |
| Root iOS 1024 icon | 1024×1024, RGB, no alpha, 37,839 bytes |
| Root/Maps/Remote Config 1024 SHA-256 | `20af2447c2b90b79e019f374f7d74ac00979786b210e778be5740b7616a6836d` for all three |
| Neutral icon SVG SHA-256 | `0032e5c8169a07111a98f8672f9f6d78a9c1f61788e1a9c9c19520f54ab99dfb` |
| Neutral launch SVG SHA-256 | `1764776ce4b7cda6333bf2771b89e91cdd90cf634e7e8e252dd3aa6c9ad5fe1a` |
| Active LaunchImage catalogs | none |

#### 6. Native splash parity

| Flavor | Android | iOS | Light/dark resources | Old brand absent |
| --- | --- | --- | --- | --- |
| Development | `LaunchTheme`, pre-12 layer-list and Android 12+ theme | native `LaunchScreen.storyboard` | yes | audit passed |
| Staging | same neutral resource contract | native `LaunchScreen.storyboard` | yes | audit passed |
| Production | same neutral resource contract | native `LaunchScreen.storyboard` | yes | audit passed |

Android uses `values`, `values-night`, `values-v31` and `values-night-v31`, a
neutral vector mark and the normal Flutter theme transition. It does not depend
on a Dart splash. iOS uses a centered `LaunchMark`, a light/dark
`LaunchBackground` colorset and `scaleAspectFit`; no runtime/network dependency
or obsolete LaunchImage remains.

Compilation proves resource validity for all root flavors. Fresh light/dark
native-launch captures on Samsung API 34 and iOS Simulator show the centered
neutral mark, correct background variants and no old stock/product artwork.

#### 7. Optional Google Maps parity

Maps remains isolated in `packages/app_maps`; the root dependency graph and root
artifact contract contain no Google Maps plugin.

| Flavor | Android ID | Android key source | iOS bundle ID | iOS key source | Missing-key behavior |
| --- | --- | --- | --- | --- | --- |
| Development | `com.flutter.newproject.maps.dev` | ignored `android/maps.properties` → `MAPS_API_KEY_DEVELOPMENT` | `com.flutter.newproject.maps.dev` | ignored `MapsDevelopment.local.xcconfig` | controlled accessible page; no platform map |
| Staging | `com.flutter.newproject.maps.staging` | `MAPS_API_KEY_STAGING` | `com.flutter.newproject.maps.staging` | `MapsStaging.local.xcconfig` | controlled accessible page; no platform map |
| Production | `com.flutter.newproject.maps` | `MAPS_API_KEY_PRODUCTION` | `com.flutter.newproject.maps` | `MapsProduction.local.xcconfig` | controlled accessible page; no platform map |

Tracked `.example` files contain placeholders only; real files are ignored.
Android injects a manifest placeholder. iOS reads `GOOGLE_MAPS_API_KEY` from the
selected build setting and calls `GMSServices.provideAPIKey` only for a nonempty,
non-placeholder value. Development/staging cannot silently read the production
setting.

Restriction guidance requires Android package ID plus debug/release signing
certificate SHA-1/SHA-256, and exact iOS bundle ID, with separate environment
keys, billing/quota ownership and rotation. No real key was read, copied or
logged. Android production debug and iOS production simulator examples built;
real rendering is correctly blocked until authorized restricted keys exist.

#### 8. Optional Firebase and Remote Config parity

Remote Config remains isolated in `packages/app_remote_config`; Firebase Core
and Firebase Remote Config are absent from the root Dart dependency and plugin-
registration graph.

| Flavor | Android example ID and file | iOS example ID and file | Policy | Missing configuration |
| --- | --- | --- | --- | --- |
| Development | `com.flutter.newproject.remoteconfig.dev`, `app/src/development/google-services.json` | `com.flutter.newproject.remoteconfig.dev`, `Runner/Firebase/development/GoogleService-Info.plist` | fetch timeout 10s, minimum interval zero | plugin/config copy safely skipped; disabled/default state works |
| Staging | `com.flutter.newproject.remoteconfig.staging`, staging file | matching staging bundle/file | fetch timeout 10s, minimum interval 15m | same controlled behavior |
| Production | `com.flutter.newproject.remoteconfig`, production file | matching production bundle/file | fetch timeout 10s, minimum interval 1h | same controlled behavior |

All committed Firebase files end in `.example`. The iOS copy script selects by
configuration, rejects literal template markers and skips absent configuration.
The Android Google Services plugin is applied only when a real file exists.
Root Android/iOS also contain neutral flavor templates, but no Firebase Dart
package or runtime initialization.

#### 9. Base versus Rahoul Remote Config comparison

Rahoul was inspected read-only only for relevant source patterns and config-file
placement. No Firebase file, key, ID, endpoint or product-specific parameter was
read into or copied to this base.

| Concern | Current base | Rahoul pattern | Better approach/action |
| --- | --- | --- | --- |
| Initialization | injectable initializer/backend, lazy when disabled | direct `FirebaseRemoteConfig.instance` in a product Cubit | retain base |
| Timeout/interval | explicit bounded policies: 10s; 0/15m/1h | 10s and 1h | retain base; adds safe environment policy |
| Fetch/activate | separate operations plus shared concurrent `fetchAndActivate` | direct fetch-and-activate | retain base |
| Defaults | available before network, typed fallbacks | product URL fallback flow | retain generic base; do not copy URLs |
| Failure/retry | safe status/error codes, timeout, retryable init, no raw exception | retry loop then product endpoint fallback | retain bounded base |
| DI/testability | basic and advanced backend contracts | concrete Firebase dependency | retain base |
| Typed access | string/bool/int/double/JSON with malformed fallback | product-specific values | retain base |
| Startup | optional and independently bounded | product startup/Cubit owned | retain non-blocking base |
| Native files | flavor `.example` templates on Android/iOS | real files at platform app/Runner locations | document placement only; copied no data |

Backward compatibility is preserved for the original constructor/backend,
`initialize`, `fetchRequiredString`, and original timeout/minimum-interval
semantics. Advanced behavior is additive. Firebase cached/last-known values
remain owned by the native SDK.

#### 10. Remote Config behavior and tests

Implemented behavior includes explicit DI, lazy disablement, defaults before
network, environment policy, bounded initialization/fetch/activation,
fetch-and-activate, safe typed access, JSON fallback, missing/malformed fallback,
offline-safe errors, retry after failed initialization, shared concurrent work,
disposal/lifecycle protection and no raw Firebase exception/user value logging.

The package has **16 passing behavior tests** covering the old compatibility API,
disabled provider, missing config, defaults, policies, success/no-change,
concurrency, fetch/offline/activation failure, malformed typed/JSON values,
repeated initialization/retry, timeout and disposal. The optional example adds
one widget test proving default behavior without Firebase startup. These are
mock/controlled tests, not live Firebase verification.

#### 11. README and local-agent guidance

Rahoul README structure was inspected read-only at heading/link-placement level.

| Rahoul pattern | Suitable | Neutral adaptation |
| --- | --- | --- |
| overview, apps, features, technologies | yes | reusable-base purpose and optional integrations |
| requirements/setup/environment | yes | portable root-relative setup and flavor matrix |
| run/build commands | yes | verified development/staging/production commands |
| Figma/API/store/support links | yes | explicit `{{...}}` placeholders |
| product names, roles, credentials and links | no | not copied |

The root README now has exactly **47 H2 sections** and **29 unique neutral
placeholders**, including project metadata, design/API/docs links, store/privacy/
support links, IDs, Maps/Firebase sources, Remote Config defaults, splash/icon
sources, roles/variants/environments and screenshots. It contains a derived-
project replacement checklist and no personal path or real-looking credential.

Active Codex, Claude and Cursor instructions and the prompt library require
Android/iOS parity for identity, flavors, Maps, Firebase, Remote Config, native
splash, icons, signing, links, APNs and stores. The executable project-local
quality gate now includes identity validation and resolves the configured SDK.

#### 12. Exact source delta and generated files

Because Git was prohibited, the exact delta is defined against the checksum-
verified archive rather than a Git diff. The following dry-run produces the
file-by-file manifest while excluding only reproducible state:

```bash
rsync -rcn --delete --itemize-changes \
  --exclude='.dart_tool/' --exclude='build/' --exclude='.gradle/' \
  --exclude='Pods/' --exclude='ephemeral/' --exclude='coverage/' \
  --exclude='.idea/' --exclude='*.iml' --exclude='local.properties' \
  --exclude='Generated.xcconfig' --exclude='flutter_export_environment.sh' \
  /path/to/extracted-backup/flutter_clean_arch_base-main/ ./
```

Material changed/new groups (the command above expands every file exactly):

- root identity: `pubspec.yaml`, all `package:flutter_base` import consumers,
  generated registrars/config, root tests and integration/gallery harnesses;
- root Android: `android/app/build.gradle.kts`, flavor templates/resources,
  MainActivity, all launcher/notification/splash resources;
- root iOS: `ios/Runner.xcodeproj/project.pbxproj`, AppIcon set,
  LaunchScreen/LaunchBackground/LaunchMark, Firebase templates/copy script;
- secondary platforms: Linux, macOS, Windows and web identity/icon files;
- Maps: package README and the complete neutral native example under
  `packages/app_maps/example/{android,ios}` plus controlled Dart state/test;
- Remote Config: package API/README/tests and the complete neutral native example
  under `packages/app_remote_config/example/{android,ios}`;
- tooling: `tool/branding/*`, `tool/configure_optional_ios_flavors.rb`,
  `scripts/check_project_identity.sh`, quality/instruction/prompt validators;
- documentation/guidance: root README, active AGENTS/Claude/Cursor skills/rules,
  QA/release docs, authoritative prompt spec and prompt README;
- this report: `docs/reports/PROJECT_IDENTITY_MIGRATION_REPORT.md`.

Generated/reproducible files include optional-example Gradle wrappers, Xcode
workspaces/schemes, plugin registrants, lockfiles, icon rasters and splash
rasters/vectors. Native branding is reproducible with
`tool/branding/generate_native_branding.sh`; optional iOS flavor projects are
reproducible/idempotent with `tool/configure_optional_ios_flavors.rb`.

#### 13. Final post-identity quality gate

| Check | Final result |
| --- | --- |
| `scripts/flutter_quality_gate.sh release --build` | passed: 59 checks, 0 skips |
| Identity/branding/native parity | passed |
| Agent instructions and prompt library | passed |
| Format | 304 files, 0 changed |
| Root analyzer | no issues |
| Root tests | 226 passed, 2 intentional conditional skips |
| Focused widget tests | 61; subset of the 226, not additional |
| Root coverage | 2,470/4,069 lines, 60.70% |
| PHP inverse | 15 passed, 3 opposite-branch skips |
| Code generation | 16 outputs and 83 locale keys reproduced |
| Optional package analyzers | all five passed |
| Optional package tests | 44: notifications 9, Remote Config 16, WebView 6, Maps 7, Socket 6 |
| Optional example tests | 3: WebView 1, Maps 1, Remote Config 1 |
| Root optional dependency graph | isolated; passed |
| Universal APK entry/DEX isolation | passed; zero forbidden optional packages |
| Android debug flavors | development, staging and production ARM64 passed |
| Android production | Universal, ARM32, ARM64, x86_64 and AAB passed |
| Root iOS Simulator | development, staging and production passed |
| Maps example build | Android production ARM64 debug and iOS production Simulator passed |
| Remote Config example build | Android production ARM64 debug and iOS production Simulator passed |
| Size budgets | passed |

Android reports Flutter's future Built-in Kotlin migration warning. Maps iOS
reports that `google_maps_flutter_ios` still requires CocoaPods instead of Swift
Package Manager. Both are upstream future-toolchain warnings, not current build
failures.

#### 14. Authoritative post-identity artifacts

All paths below are relative to the project root. Timestamps use Cairo time.

| Artifact | Timestamp | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-development-debug.apk` | 2026-08-27 22:16:42 | 101,568,642 | `d632ddd7456b10e7ffebd88de116e2a5d0a54b3a6400c5910377e9a7f573dc70` |
| `build/app/outputs/flutter-apk/app-staging-debug.apk` | 2026-08-27 22:17:04 | 101,568,526 | `c445f85f208d8e9ff7848a26019b17e71abd993d367893d9ba0fd81921da31ff` |
| `build/app/outputs/flutter-apk/app-production-debug.apk` | 2026-08-27 22:17:26 | 101,568,646 | `fb9d68dd7eeffb06ce11a15b3886418f63a32c1d5d7187bd440955106c665674` |
| `build/app/outputs/flutter-apk/app-production-release.apk` | 2026-08-27 22:18:04 | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| `build/app/outputs/flutter-apk/app-production-universal-release.apk` | 2026-08-27 22:18:05 | 49,921,496 | `21c9301cb4a628ee2d27b0cf13ddcd2684dde27727763c9ddf9dfc8084722eb8` |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-production-release.apk` | 2026-08-27 22:18:34 | 15,846,674 | `7df5fcf2d56f9189199765cccd6b17f8456d013438fdd36aa81e3f15287f9d14` |
| `build/app/outputs/flutter-apk/app-arm64-v8a-production-release.apk` | 2026-08-27 22:18:33 | 18,601,894 | `e97b63ee6f2e9949e915a6014d31c95c90995a7acdbd04395295d7736616aede` |
| `build/app/outputs/flutter-apk/app-x86_64-production-release.apk` | 2026-08-27 22:18:34 | 20,020,086 | `059ec12a3513461ff8229943168d1eef102df7fe6a4e4aef0f06566461fca8f3` |
| `build/app/outputs/bundle/productionRelease/app-production-release.aab` | 2026-08-27 22:19:06 | **50,659,286** | `6f4f6ae7540ac9b80868ba98be9dfc1c6725db5e2bb5400a6f3e56aca1cb1636` |

The final post-identity AAB value above supersedes the earlier phase values
50,618,821 and 50,618,560 bytes. The last comparable retained pre-identity
dependency-hardening artifacts were Universal 49,913,424 and AAB 50,651,242
bytes. Identity/native-resource work therefore added 8,072 bytes (0.01617%) to
Universal and 8,044 bytes (0.01588%) to AAB. Against the historical 52,046,296-
byte Universal, the final artifact is 2,124,800 bytes smaller (4.08252%), but
that historical comparison uses different Dart-symbol packaging and is not
presented as a pure widget/identity saving.

Release APKs are `com.flutter.newproject`, `Flutter Base`, target API 36,
minimum API 24 and non-debuggable. The AAB manifest has the same package,
`com.flutter.newproject.MainActivity`, `LaunchTheme`, `@mipmap/ic_launcher` and
no debuggable attribute. The Universal APK contains ARM32, ARM64 and x86_64.
R8/resource shrinking is configured and the release mapping is nonempty.

#### 15. Symbols, mappings and packaging

| Evidence | Bytes | SHA-256 |
| --- | ---: | --- |
| `build/app/outputs/mapping/productionRelease/mapping.txt` | 25,724,248 | `162acbd8207144f8c7c2f6b7ba4e3ea52953712bb8d220c34f33555c51185f18` |
| `build/app/outputs/native-debug-symbols/productionRelease/native-debug-symbols.zip` | 133,759,971 | `de2f195823e0c8d3eb39a0d1c4e7191236be05880fe0ebebe8bece8dc2e8d69a` |
| `build/symbols/production/app.android-arm.symbols` | 1,907,728 | `7779fcc6673242e80082c2b477c999c4441a08f939868a57f93b76dc91dd717f` |
| `build/symbols/production/app.android-arm64.symbols` | 2,237,016 | `b6cc38bb5d3713fdcf6a22ad73c355a397a450c1f06b6484cf573a1ed7738a9e` |
| `build/symbols/production/app.android-x64.symbols` | 2,237,720 | `ba2ba8cff2950ac5c43319aa49eb5bfc5f4020310b1385f1bea07c0c845134e3` |

The external native archive contains 14 unstripped `.so` files under ABI-
qualified `lib/` paths. The AAB separately contains nine compressed native
symbol-table entries in `BUNDLE-METADATA`; those entries are genuinely inside
the AAB. The full native archive, external Dart `.symbols` files and external
R8 mapping remain separate files beside the store artifact.

#### 16. Identity, isolation and credential inspection

- APK/AAB entry scans, Universal DEX package inspection and the root dependency
  graph found no Firebase, Maps, WebView, Socket, notifications or Remote Config
  concrete integration in Root.
- APK/AAB decompressed-string scans found no old Awamer/I Craft identity, old
  package IDs/imports, Google API-key pattern, Firebase app-ID pattern or private
  key marker.
- Release resource tables contain neutral launcher resources and Launch/Normal
  themes; visual captures confirm the neutral light/dark launch mark.
- Every retained iOS app has the expected bundle ID/display name, compiled
  `LaunchScreen.storyboardc`, two compiled AppIcon files, no LaunchImage, no real
  Firebase file, no Maps-key pattern and no old identity.
- Source/native templates contain no Apple Team assignment or real optional-
  service configuration.

#### 17. Android and iOS launch evidence

The unsigned reusable release artifact was not altered. A separate debug-key-
signed smoke copy was created outside the project and verified with APK v2/v3.

| Runtime | Result |
| --- | --- |
| Samsung SM-A235F, API 34, unlocked | cold release launch passed; light and dark native visuals captured; controlled startup error shown; double Retry, background/resume and Back passed; zero fatal lines |
| Android ARM64 Emulator, API 36 | cold release launch passed; controlled startup error shown; double Retry passed; zero fatal lines |
| iPhone 16 Pro Simulator, iOS 18.4 | all three flavors installed/launched; development showed controlled authentication-required state; staging/production showed controlled startup state; zero Runner fatal/crash events |
| iOS production light/dark | native LaunchScreen captured with centered neutral mark and correct light/dark background |

Evidence is stored outside the project under the task work directory, including
Samsung light/dark videos/frames, Samsung and API-36 first-route screenshots,
iOS flavor screenshots and production light/dark launch videos/frames. No claim
is made for signed physical iOS or App Store execution.

#### 18. Disk recovery and quality-gate hardening

The initial read-only check found 17.34 GiB free, so no deletion was initially
required. The first full matrix expanded root Android/iOS intermediates and
Gradle caches until iOS failed with 240 MiB free. Project-local cleanup was then
proven insufficient. Removed items were reproducible only: root `build`, root
`.dart_tool/flutter_build`/`hooks_runner`, optional-example build output,
target-related Runner DerivedData, incomplete release staging directories and
the Gradle 9.3.1 version cache generated by optional-example builds. The unique
pre-rename archive, source, reports, final screenshots, final APK/AAB, Dart
symbols, native symbols and R8 mapping are preserved.

Temporary failed-attempt evidence directories were removed only after their
contents were superseded by a later clean build; they are not authoritative
artifacts. The final artifacts above are checksum-backed. Disk after the
successful gate was 4.1 GiB free; a later non-authoritative optional runtime
rebuild attempt recreated Gradle cache and was stopped/cleaned, leaving about
1.7 GiB. The successful optional builds/tests from the gate remain authoritative;
no live Maps/Firebase service success is claimed.

Exact reproducible paths removed during recovery (some were recreated and
removed more than once between failed attempts) were:

- `/Users/abdelrahamndandash/StudioProjects/flutter_base/build` (only incomplete
  attempts; the final checksum-backed `build` evidence was restored and kept);
- `/Users/abdelrahamndandash/StudioProjects/flutter_base/.dart_tool/flutter_build`;
- `/Users/abdelrahamndandash/StudioProjects/flutter_base/.dart_tool/hooks_runner`;
- `packages/app_maps/example/build` and its generated `android/.gradle/9.3.1`;
- `packages/app_remote_config/example/build`;
- `packages/app_webview/example/build`;
- `/Users/abdelrahamndandash/Library/Developer/Xcode/DerivedData/Runner-ecgbggnutcwtlqarkbhbavlusgtp`;
- `/Users/abdelrahamndandash/.gradle/caches/9.3.1` after local cleanup was
  measured and proved insufficient; this version cache is reproducible;
- `/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/first_failed_release_evidence-20260827`;
- incomplete `flutter-base-release-stage.9tLNuy`, `.Mb8YTP`, `.GI9e66` and
  `.CoWnOO` directories under the task-specific macOS temporary directory.

No source, unique recovery archive, final report, final artifact, final symbol,
R8 mapping or final visual evidence was deleted. The required pre-rename archive
and its SHA-256 remain unchanged.

The gate now stages each Android artifact immediately, clears only allowlisted
reproducible intermediates between flavors/platforms, preserves each iOS app,
forces fresh Dart symbol generation, creates an external native-symbol archive,
and uses ARM64-only debug build checks while retaining all release ABIs. This
eliminates the verified peak-disk regression without changing product behavior.

#### 19. Commands executed in the final verification

Material commands included:

```bash
flutter pub get                         # root, optional packages and examples
dart run build_runner build
dart run tool/generate_locale_keys.dart
scripts/check_project_identity.sh
scripts/flutter_quality_gate.sh release --build
apkanalyzer manifest ...
apkanalyzer resources ...
apkanalyzer dex packages ...
bundletool dump manifest --bundle=... --module=base
shasum -a 256 <each artifact/symbol file>
apksigner verify ...
apksigner sign ... --out <external-smoke-copy> <ARM64-release>
adb install / am start / screencap / screenrecord / logcat / uimode
xcrun simctl boot / install / launch / screenshot / recordVideo / log show
```

All Flutter commands used the SDK selected by `android/local.properties`
(Flutter 3.47.1, Dart 3.13.1). No dependency upgrade command was run. The only
intentional project-file changes in this final verification are
`scripts/flutter_quality_gate.sh` and this report. A temporary native-symbol
Gradle experiment was reverted byte-for-byte; `android/app/build.gradle.kts`
matches its pre-experiment SHA-256
`5636ca48e971d7a8074a0a09ba1f28678820e87938ef1392be0f4d7fda10534f`.

#### 20. Remaining application-specific gates

- Replace neutral identity/design/store records for the real product.
- Configure protected Android/iOS signing and CI secret injection.
- Supply authorized backend environments and real test accounts.
- Create per-flavor Firebase/APNs projects and restricted Maps keys.
- Complete live Maps, Firebase, notification, backend and deep-link testing.
- Complete physical iOS release/archive/App Store verification.
- Complete product privacy, Data Safety, licenses, accessibility and store review.
- Track Flutter's Built-in Kotlin migration and Maps iOS SwiftPM support before
  the future toolchain versions make those warnings errors.

#### 21. Reference-project, Git and freeze confirmation

Rahoul and every project other than `flutter_base` remained read-only. No build,
format, generation, migration or configuration command was executed in them.
No secret/config content was copied. **No Git command was performed and no Git
state was created or modified.**

Final reusable-baseline verdict: **Reusable baseline frozen**.
Overall production classification: **Conditionally production-ready**.
