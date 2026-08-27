# Widget legacy and migration matrix

No widget was deleted during the widget-hardening phase. The classifications
below prevent the old 67-widget inventory from becoming 67 independently
supported design-system contracts. “Safe to remove after proof” still requires
export/dynamic-reference checks, complete migration, passing tests and a fresh
recoverable backup.

## Compatibility-only

| Retained widget | Canonical replacement | Current decision |
| --- | --- | --- |
| `UniversalMediaWidget`, `MediaVideoPlayer`, `MediaSvgViewer`, `MediaImageViewer`, legacy `LoadingIndicator` | `AppMedia` | Wrapper retained; new code must not use the legacy family |
| `ImageView` | `AppMediaViewerPage` | Deprecated adapter now delegates entirely to the canonical viewer; scale/video options and disposal are compatibility-tested |
| `DefaultButton` | `AppButton` | Disabled-state regression fixed; production call site migrated |
| `DefaultScaffold` | `AppPageShell` | Global Back block removed; Products migrated |
| `ArrowWidget`, `TitleWithArrowWidget`, `ButtonClose` | `BackButton`/`CloseButton`/`AppPageShell` | Deprecated; contextual Navigator, directional icon and 48dp keyboard-accessible target are preserved |
| `UploadImageWidget`, static `ImageHelper` UI entry points | `AppImagePickerField` + injected service | Not deleted; notifier leak fixed; new work uses injected contract |
| `LoadingButton`, `LoadingButtonWithIcon`, `CustomAnimatedButton` | `AppButton` | Deprecated; no production call site remains. Legacy animation/progress wrapper is lifecycle-safe and truly disabled |
| `EmptyWidget`, `ErrorView` | `AppStateView.empty/error` | Deprecated wrappers now delegate to canonical named state constructors while preserving optional illustrations |

## Pending migration

| Retained widget | Target | Why it remains |
| --- | --- | --- |
| `CachedImage` | `AppMedia.networkImage` plus feature decoration | Widely used and has decoration/cache-specific API; `ignoreClick` is now honored |
| `ExceptionView` | Remains global build-failure fallback | Different responsibility from API/data states; keep safe localized release fallback |
| `DefaultErrorBody` | Form-field decoration or removal after proof | Form validation decoration is not equivalent to page state rendering |
| `CustomAvatar`, `ImageSlider`, `CustomImageCarousel` | Compose `AppMedia` | Product presentation and carousel policy must be separated first |
| `ButtonClose`, `IconWidget`, `BadgeIconWidget` | Standard accessible `IconButton`/`Badge` where equivalent | Migrate only after matching visuals and semantics |

## Feature-specific; do not promote

`VisitorBody`, `UnAuthenticatedBottomSheet`, `RiyalPriceText`, navigation-bar
presentation widgets, product cards/search/filter/details widgets and custom
HTML/product presentation remain feature or product UI. They may consume the
canonical components, but they are not design-system primitives.

Maps and WebView pages stay in `packages/app_maps` and `packages/app_webview`.
Notifications, Remote Config and sockets do not belong in root UI.

## Safe to remove after proof

Static source search currently finds only their declaration for
`UniversalMediaWidget`, its old media subwidgets, `UploadImageWidget`,
`DefaultScaffold`, `LoadingButton`, `LoadingButtonWithIcon`,
`CustomAnimatedButton`, `TitleWithArrowWidget`, `ErrorView`, `CustomAvatar`,
`ImageSlider`, `CustomImageCarousel`,
`ButtonClose`, `BadgeIconWidget`, `CustomNavigationBar`, `RiyalPriceText`,
`CustomHtmlWidget` and `DefaultErrorBody`. This is evidence for a future
removal pass, not deletion authorization: exports, reflection/dynamic routes,
templates and consuming projects still require proof.
