# Reusable component and service catalog

Search this catalog and the referenced source before creating shared code.
Feature-specific behavior belongs under its feature even when it uses these
foundations.

## UI

| Contract | Location | Use it for | Do not put in it |
|---|---|---|---|
| `DefaultTextField` | `lib/src/core/widgets/fields/text_fields/default_text_field.dart` | Label/hint, controller or initial value, formatter, validation plumbing, focus, password, autofill, line/length, enabled/read-only and semantics | Feature validation or backend rules |
| `AppDropdown<T>` | `lib/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart` | Static/paginated single or multi selection, search, pending confirm/cancel, loading/empty/error/retry | Product DTO assumptions or implicit navigation |
| `AppButton` | `lib/src/core/widgets/buttons/app_button.dart` | Primary/secondary/destructive/text actions, disabled/loading state and duplicate-submit prevention | Business orchestration |
| `AppMedia` + `AppMediaRequest` | `lib/src/core/widgets/media/` | Asset/file/network image or SVG, optional video, safe loading/failure, fullscreen policy, disposal and semantics | Product galleries, raw plugin errors or implicit navigation policy |
| `AppImagePickerField` + `AppImagePickerService` | `lib/src/core/widgets/image_picker/` | Injectable camera/gallery picking, cancellation, lost-result recovery, replacement/removal, count/size policy and safe lifecycle | Upload API calls, feature permissions copy or product validation |
| `AppPageShell` | `lib/src/core/widgets/scaffolds/app_page_shell.dart` | Normal/sliver page chrome, contextual Back, predictive-Back-compatible default behavior, directional actions and theme scaling | Global Back suppression or feature routing rules |
| `AppStateView` | `lib/src/core/widgets/handling_views/app_state_view.dart` | Compact/full loading, skeleton, empty, error, offline and permission-required presentation | Raw backend messages |
| `FullScreenLoadingManager` + `BlockingOverlayController` | `lib/src/core/shared/helpers/loading_manager.dart` | Scope-owned blocking overlay when a normal loading button is insufficient | Global/static loading state |
| `MessageUtils` | `lib/src/core/widgets/custom_messages.dart` | Short, context-owned replacement snackbar | Stored/global context or long workflows |
| `PaginatedListWidget` | `lib/src/core/state/paginated/paginated_list_widget.dart` | Refreshable list, skeleton, empty, first/partial error, retry and load-more footer | Fetching/business rules |

Legacy `DefaultButton`, `LoadingButton`, `LoadingButtonWithIcon`,
`CustomAnimatedButton`, and `ButtonClose` are deprecated compatibility APIs.
Their internals now enforce real disabled states, safe async disposal,
accessible targets and contextual navigation, but new work uses `AppButton` or
an accessible standard icon button. No root production call site uses the
legacy loading-button family.

Legacy media/image widgets (`UniversalMediaWidget`, `ImageView`, `CachedImage`,
`UploadImageWidget` and the old universal-media subwidgets) remain only for
compatibility or staged migration. `ImageView` now delegates completely to
`AppMediaViewerPage`, and `CachedImage` opens that same canonical viewer. Legacy
`EmptyWidget`/`ErrorView` delegate to `AppStateView`. New code uses `AppMedia`,
`AppImagePickerField`, and the named `AppStateView` constructors.
`DefaultScaffold` is compatibility-only; new normal and sliver pages use
`AppPageShell`. See `WIDGET_LEGACY_MATRIX.md` before migration or removal.

## Canonical usage

```dart
AppButton(
  label: LocaleKeys.save,
  loadingLabel: LocaleKeys.loading,
  onPressed: controller.save,
)

AppMedia(
  request: AppMediaRequest.detect(url),
  semanticLabel: localizedDescription,
  openBehavior: AppMediaOpenBehavior.fullscreen,
)

AppImagePickerField(
  service: PluginAppImagePickerService(),
  maxCount: 4,
  maxBytes: 5 * 1024 * 1024,
  onChanged: controller.setAttachments,
)

AppPageShell.sliver(
  title: Text(LocaleKeys.products),
  slivers: [SliverList.builder(/* feature-owned rows */)],
)

AppStateView.error(
  title: localizedTitle,
  message: localizedSafeMessage,
  actionLabel: localizedRetry,
  onAction: controller.retry,
)
```

All user-facing copy and semantics must be resolved at build time. Canonical
widgets support direction-aware layout and Material light/dark themes. Video
and picker plugin behavior is hidden behind injectable contracts so tests can
cover failure, cancellation and disposal without native channels.

## Supported-state and accessibility matrix

| Component | Supported states | Accessibility, theme and locale contract |
| --- | --- | --- |
| `AppButton` | enabled, disabled, externally loading, internally submitting, primary/secondary/destructive/text | 48dp minimum target, button/enabled semantics, focus/autofocus, theme color scheme, localized visible/loading label |
| `DefaultTextField` | controller or initial value, validation/error, read-only/disabled, password, focus, formatter, multiline/length | semantic label, autofill/input action, configurable suggestions, directional padding, theme borders/fill/cursor, caller-localized copy |
| `AppDropdown` | single/multi pending selection, confirm/cancel, search, paginated/static loading/empty/error/retry | focus and keyboard activation, selected/enabled item semantics, safe area/large-list layout, directional/theme-aware sheet, localized labels |
| `AppMedia` | loading, image/SVG/video ready, safe failure/fallback, play/pause, viewer disabled/fullscreen | one caller-provided media description, localized state/action copy, directional layout, theme surface, disposal-safe async controller |
| `AppImagePickerField` | empty/list, busy, cancel, permission denied, lost recovery, too large, max reached, replace/remove | labeled camera/gallery/replace/remove actions, duplicate-action guard, localized errors, theme/direction-aware controls |
| `AppStateView` | named content/loading/empty/error/offline/permission constructors, skeleton, retry, custom visual, compact/full | explicit parent state semantics without duplicate visual/text announcements, accessible retry, caller-localized title/message, theme/direction inheritance |
| `AppPageShell` | normal/sliver, default/contextual Back, custom leading/actions, safe-area | framework Back semantics and predictive-Back path by default, directional app bars, theme/text-scale inheritance |
| `PaginatedListWidget` | initial loading, refresh, empty, data, append, end, first/partial failure and retry | state widgets provide semantics; list/refresh use native scrolling behavior; feature owns localized row semantics |
| `MessageUtils` | replacement snackbar with bounded duration | explicit live-region message, contextual messenger, caller-localized safe copy |

## State, network, session and storage

| Contract | Location | Guarantees |
|---|---|---|
| `AsyncCubit<T>` | `lib/src/core/state/async/` | Typed result, latest execution wins, previous data, cancellation recovery, thrown-error mapping and disposal safety |
| `PaginatedAsyncCubit<T>` | `lib/src/core/state/paginated/` | Initial/refresh/load-more/end, duplicate prevention, latest filter wins, partial retry, cancellation and disposal safety |
| `Failure` hierarchy | `lib/src/core/network/error/` | Closed typed error map and localized safe UI messages |
| `DioClient` and interceptors | `lib/src/core/network/` | Locale/auth/retry/cache ordering, synchronized auth handling, cancellation and redacted debug diagnostics |
| `StartupCoordinator` | `lib/src/bootstrap/` | Bounded critical startup, retry and controlled failure; optional integrations cannot deadlock splash |
| `UserCubit` / session coordinators | `lib/src/core/session/`, `lib/src/core/shared/cubits/user_cubit/` | Central session transition, cleanup hooks and context-free routing policy |
| `SecureTokenStorage` / queue cipher | `lib/src/core/network/auth/`, `lib/src/core/network/offline/` | Secure token access and AES-256-GCM owner-scoped queued writes |
| `Languages` | `lib/src/config/language/languages.dart` | Mounted-context runtime switch and current-locale lookup without cached translation |

## Optional packages

| Package | Capability | Root rule |
|---|---|---|
| `packages/app_notifications` | Notification permissions, token lifecycle and delivery adapter | Opt in explicitly; must not block startup |
| `packages/app_remote_config` | Bounded remote configuration adapter | Inject; missing optional config is nonfatal |
| `packages/app_webview` | Secure navigation/host policy and lifecycle | Product payment rules stay outside |
| `packages/app_maps` | Map/permission/location controller contracts | Keys and product selection are release inputs |
| `packages/app_socket` | Socket lifecycle/reconnect/auth hooks | Product events and payloads stay outside |

Crash reporting, analytics and performance monitoring are provider-independent
composition concerns. Add a product-selected adapter in an optional package;
do not add an unused provider to the root binary.

## Test foundations

Root tests are grouped under `test/core`, `test/bootstrap`, `test/features`,
`test/architecture`, and `test/assets`. Use injected adapters, deterministic
fake clocks/results and behavior assertions. Optional packages own their tests.
Stable golden tests are justified only for visual contracts whose pixels are
intended to remain fixed; semantics/theme/RTL widget tests are preferred for
responsive primitives.
