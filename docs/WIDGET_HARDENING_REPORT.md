# Widget hardening report — 2026-08-27

## Verdict

The reusable widget surface is **conditionally production-ready**. The base now
has a deliberately small canonical surface rather than treating all legacy
widgets as independent design-system contracts. All locally reproducible
crash, lifecycle, disabled-state, Back-navigation, leak and raw-error findings
in scope were corrected. No widget or asset was deleted.

Real backend journeys, signed store artifacts, Firebase/APNs, Maps credentials,
native WebView content, camera/gallery OEM behavior, screen-reader sessions and
complete predictive-Back gesture QA remain product/device release gates.

## Canonical surface and implemented behavior

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

## Verified regressions fixed

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

## Tests and coverage

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

## Build and release results

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

## Release artifacts

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

## Final tooling consistency closeout

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

## Exact source/config/test files changed in this phase

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

## Compatibility-consolidation continuation

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
