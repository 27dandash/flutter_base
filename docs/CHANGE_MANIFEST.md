# Exact change manifest

This is the exact source-file delta between the final audited tree and the
supplied upstream `main` commit `cca26f9746832fee13f9e502833f5aa517f73ee7`.
Machine-local/generated build state (`build`, `.dart_tool`, Gradle caches,
Flutter ephemeral files, local properties, iOS generated registrants, and
unrelated editor/agent metadata) is excluded. Build artifacts are evidence,
not source deliverables.

## Added or modified

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

## Removed

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

## Dedicated size and standards audit additions

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

## 2026-08-27 hardening additions

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

## 2026-08-27 widget-hardening phase

The exact canonical media/picker/page, legacy hardening, migration, test,
optional-page and documentation file list is maintained in
`WIDGET_HARDENING_REPORT.md` to avoid duplicating a long manifest in two places.
No source, asset, font or configuration file was removed. The pre-phase backup
is
`/Users/abdelrahamndandash/Documents/Codex/2026-08-26/new-chat-2/work/backups/flutter-base-pre-widget-hardening-20260827.tar.gz`
(SHA-256
`aac1b37d2796db43dec6f784d5ffe9fdd71233fec5108d97998e77d04deef07c`).
No Git command was executed and no reference project was modified.

## 2026-08-27 compatibility consolidation

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

## 2026-08-27 final tooling consistency

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
