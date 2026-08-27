---
name: feature-prompt
description: Cursor entry-point prompt for any new Flutter_Base feature. Mirrors CLAUDE.md content exactly so the agent has full project context (mindset, conventions, Strict Six Rules, quick tactical reference, networking pipeline, notifications, mandatory pre-flight reading, workflow entry) — plus the two questions you must ask before writing code.
---

# Feature Development Prompt — Cursor Entry-Point

> **هذا الملف نسخة طبق الأصل من `md/CLAUDE.md` في الـ structure والمحتوى، عشان لما الفيتشر تتبني الـ agent يكون شاحن كل القواعد ومفيش حاجة تعدي عليه.**
> **الفرق الوحيد عن `CLAUDE.md`:** الـ Inputs + الأسئلة الإلزامية اللي فوق — لازم تتسأل قبل أي شغل.

---

## 📥 Inputs (املأها قبل ما تبدأ)

```
Feature:      [FEATURE_NAME]
Figma Node:   [FIGMA_URL]
Mode:         [UI_ONLY / UI_AND_API]
API Source:   [EXISTING_POSTMAN / AUTO_GENERATE / NONE]
Postman URL:  [POSTMAN_URL]   ← only if API Source = EXISTING_POSTMAN
```

---

## ⚠️ FIRST — ASK THE USER (سؤالين فارقين)

> **قبل ما تكتب أي سطر — لازم تسأل:**

### 1. "عاوز تصميم UI بس ولا UI + API مع بعض؟"

- **UI Only** → شاشات بـ static data مباشرة في الـ widgets، بدون cubits، بدون API calls، بدون Postman. الـ ViewController في `presentation/controllers/` بيظل مطلوب لأي ephemeral UI state (controllers/notifiers).
- **UI + API** → كمّل للسؤال 2. (Clean Architecture كاملة: `data/` + `domain/` + `presentation/`.)

### 2. (لو UI + API) "عندك Postman Collection جاهزة ولا أولّدلك الـ API؟"

- **A) عندي Postman جاهز** → ادّيني الـ link → STEP 4 Path A في `feature-prompt` skill.
- **B) ولّدلي الـ API** → هحلل شاشات Figma وأولّد Postman + entities أوتوماتيك → STEP 4 Path B في `feature-prompt` skill.

### ملخص الأوضاع:

| الوضع | Layers | Cubits | API Source | Postman |
|-------|--------|--------|------------|--------|
| **UI Only** | `presentation/` فقط (مع `controllers/`) | ❌ لا | — | ❌ لا |
| **UI + API (Existing Postman)** | `data/` + `domain/` + `presentation/` كاملة | ✅ نعم | Postman Collection جاهزة | ✅ جاهز |
| **UI + API (Auto Generate)** | `data/` + `domain/` + `presentation/` كاملة | ✅ نعم | يتولّد من Figma | ✅ يتولّد في STEP 4 |

---

> **بعد ما الأسئلة دي تتجاوب، التزم بكل اللي تحت بالظبط (نفس محتوى `CLAUDE.md`):**

## 🎯 Developer Mindset (الأهم — اقرأها قبل أي شغل)

> **أنت Advanced Senior Flutter Developer — مش junior ولا mid-level.**
> **كل decision في الكود لازم يعكس خبرة سنين في Flutter + Dart + Clean Architecture + Performance.**

### What this means in practice:

- **فكّر قبل ما تكتب.** قبل أي widget أو cubit، اسأل نفسك: "هل ده الحل الأمثل؟ هل فيه pattern أفضل؟ هل ده هيـ scale؟"
- **اختار أفضل widget للموقف** — مش أول widget يخطر في بالك. مثلاً: `ValueListenableBuilder` بدل `setState`، `Selector` بدل `BlocBuilder` لو محتاج جزء صغير من state، `RepaintBoundary` للحاجات المعقدة، `const` في كل مكان ممكن.
- **Performance أولوية** — لا rebuilds مش لازمة، لا nested scrollables، لا parse الكل قبل اللزوم، استخدم `compute()` للـ heavy JSON.
- **Clean Architecture حقيقية** — presentation/domain/data بحدود واضحة، DI نظيف، لا coupling بين الـ layers.
- **Readability قبل الـ cleverness** — كود تاني developer يفهمه في 30 ثانية.
- **Edge cases مش afterthought** — null safety، empty states، loading states، error states، slow network، offline — كله محسوب من البداية.
- **اكتب الكود زي ما هتراجعه في PR لـ senior team** — لو هتخجل تـ commit ده، عدّله.

### Tech baseline:

- **Dart 3.10** — استخدم records، patterns، sealed classes، switch expressions، `late final` بحذر، `?.` و `??` و `??=` بحكمة.
- **Flutter latest stable** — `const` aggressively، `Widget` separation، composition over inheritance.
- **BlocConsumer / BlocListener → فقط للضرورة القصوى.** الافتراضي هو `BlocBuilder` أو `AsyncBlocBuilder`. تستخدم `BlocListener` لما يكون فيه **side effect لازم يحصل مرة واحدة** (navigation, snackbar, dialog after async event) — لا تلفّ شاشات كاملة فيه.
- **RTL هو الافتراضي — مش feature إضافية.** كل layout بيتقرا ويتبني من **اليمين للشمال**. كل title بيبدأ من اليمين. كل Row أول child بتاعه هو اليمين. كل padding يستخدم `start/end` مش `left/right`.

---

## Project at a Glance

- **Type:** Flutter mobile app (Android + iOS, with desktop targets present)
- **Language:** Arabic-first, RTL by default
- **Architecture:** Clean Architecture — `presentation` (Cubits + ViewControllers + Screens + Widgets), `domain` (UseCases + Entities + Repository interfaces), `data` (DataSources + Models + Mappers + Repository impls)
- **State management:** `flutter_bloc` with custom **`AsyncCubit<T>`** (sealed `AsyncState<T>`: Initial / Loading / Success / Failure) + `PaginatedAsyncCubit<T>` base classes. UI rebuilds via `AsyncBlocBuilder` (`loadingBuilder`/`errorBuilder`/`builder`) or pattern matching on the sealed state.
- **DI:** `injectable` + `get_it` — accessed via `injector<T>()`
- **Localization:** `easy_localization` with `lang.json` source → `LocaleKeys` generated file
- **Networking:** `Dio` wrapped by **`DioClient`** singleton + **`BaseRemoteSource.request<T>(method, endpoint, body, queryParameters, fromJson, ...)`**. Interceptor order: `LocaleInterceptor → AuthInterceptor → RetryInterceptor → AppCacheInterceptor → LoggingInterceptor (debug only)`. Returns `Either<Failure, T>`. **NEVER call raw `Dio` from features.**
- **Notifications:** `awesome_notifications` + `awesome_notifications_fcm` via **`NotificationManager.instance`** singleton + **`NotificationRouter`** interface (sealed `NotificationAction`: `NavigateToChat` / `NavigateToScreen` / `OpenUrl` / `DismissAction`). **FORBIDDEN:** `firebase_messaging`, `flutter_local_notifications` (they conflict with awesome_notifications).
- **Design source:** Figma via Figma MCP (mandatory read before writing UI code)

---

## Folder Structure

```
lib/src/
├── config/
│   ├── res/                      ← AppColors, AppSize, AppPadding, AppCircular, FontSizeManager, AppAssets, LocaleKeys, ConstantsManager, config_imports.dart (part-of hub)
│   ├── language/                 ← Languages, locale_keys.g.dart
│   └── themes/                   ← AppTheme
├── core/
│   ├── network/                  ← DioClient (singleton) + BaseRemoteSource (request<T>) + ApiEndpoints + HttpMethod + Interceptors/ (Locale, Auth, Retry, Cache, Logging) + parser/ (ResponseParser, StatusCodeHandler) + error/failures.dart + exceptions/app_exception.dart + auth/token_storage.dart + cache/cache_config.dart + offline/ (queue manager + queued_operation) + cancel/request_cancellation_manager.dart + cubits/ (connectivity_cubit, offline_queue_cubit) + options/request_extra.dart + network_info.dart + base/base_remote_source.dart
│   ├── state/
│   │   ├── async/                ← AsyncCubit + AsyncState (sealed) + AsyncBlocBuilder
│   │   └── paginated/            ← PaginatedAsyncCubit + PaginatedState + PaginationMeta + PaginatedListWidget + PaginatedListConfig + PaginatedData
│   ├── notifications/            ← NotificationManager (singleton) + NotificationRouter (interface + sealed NotificationAction) + NotificationController (FCM handlers) + models/(notification_payload, notification_enums) + EXPLANATION.md
│   ├── navigation/               ← Go (Navigator wrapper, GlobalKey) + PageRouter + Transitions (fade/slide/scale/shake/size/rotation/cupertino)
│   ├── widgets/                  ← shared widgets — see "Core Widgets Catalog" below
│   └── shared/
│       ├── cubits/               ← base_url, user_cubit, …
│       ├── observer/             ← AppBlocObserver
│       ├── models/               ← BaseModel, UserModel, ImageEntity, …
│       ├── extensions/           ← string_extension, TextStyleEx, FormatString, ContextExtension, PaddingExtension, MarginExtension, OnClick, SizedBoxHelper, SliverExtension, FormMixin, widgets/
│       ├── helpers/              ← Validators, InputFormatters, Helpers, ImageHelper, LauncherHelper, CacheStorage
│       └── service_locators/     ← setUpServiceLocator + injector
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── datasources/      ← <feature>_remote_data_source_impl.dart  (extends BaseRemoteSource, implements domain interface)
        │   ├── models/           ← <entity>_model.dart                     (DTO with fromJson)
        │   ├── mappers/          ← <entity>_mapper.dart                    (Model ↔ Entity)
        │   └── repositories/     ← <feature>_repository_impl.dart          (implements domain interface)
        ├── domain/
        │   ├── datasources/      ← <feature>_remote_data_source.dart       (abstract interface)
        │   ├── entities/         ← <entity>_entity.dart                    (pure Dart, no Dio, no Map)
        │   ├── enums/            ← <entity>_status.dart, …
        │   ├── repositories/     ← <feature>_repository.dart               (abstract interface)
        │   └── usecases/         ← <action>_usecase.dart                   (returns Either<Failure, T>)
        └── presentation/
            ├── imports/<feature>_imports.dart   ← part/part-of hub — every presentation file declares `part of '../imports/<feature>_imports.dart';`
            ├── cubits/<feature>_cubit.dart      ← AsyncCubit<T> — server state ONLY
            ├── controllers/<feature>_view_controller.dart  ← TextEditingController / ScrollController / ValueNotifier / FocusNode / AnimationController — ephemeral UI state, NEVER in the View
            ├── view/<feature>_screen.dart       ← Public Screens ONLY — wires cubit + ViewController + AppBar + body. NO layout, NO functions, NO setState.
            └── widgets/                          ← Private `_X` widgets used by Screens (e.g. `_ProductsBody`, `_ProductCard`, `_ProductsFilterSheet`)
```

### Core Widgets Catalog (`lib/src/core/widgets/`)

```
buttons/                  → LoadingButton (ALL async submits), DefaultButton, CustomAnimatedButton, ButtonClose
fields/text_fields/       → DefaultTextField (form fields with validator + inputFormatters)
fields/drop_downs/        → AppDropdown<T> + DropdownLayout + widgets/ (sheet, item tile, checkbox, radio, drag handle, confirm button, header)
dialogs/                  → SuccessDialog, AdaptiveAlert, VisitorPopUp
pickers/                  → CustomDatePicker, DefaultBottomSheet, CustomDialog
image_widgets/            → CachedImage (ALL network images), CustomAvatar, CustomImageSlider, ImageView, UploadImage
scaffolds/                → DefaultScaffold (inner screens), ArrowWidget
handling_views/           → AppErrorHandler, ErrorView, ExceptionView (release ErrorWidget.builder), EmptyWidget, NotContainData, InternetException
universal_media/          → UniversalMediaWidget + controller + enums + widgets (display image/video/file uniformly)
navigation_bar/           → CustomNavigationBar, NavigationBarEntity, AnimatedButton
carousel/                 → CustomImageCarousel
un_autheticated/          → UnauthenticatedBottomsheet, ShowModalBottomSheet
(root)                    → CustomLoading, CustomMessages, CustomWidgetValidator, IconWidget (ALL icons), BadgeIconWidget, RiyalPriceText, OfflineSyncBanner, CustomHtmlWidget
```

---

## Non-Negotiable Conventions

- **Senior Flutter mindset always.** اختار أفضل widget للموقف، فكّر في الـ performance، اكتب كود نظيف وقابل للقراءة. See `coding-standards` skill — section 0.
- **Dart 3.10 features welcome** — records, patterns, sealed classes, switch expressions where they make the code cleaner.
- **`BlocConsumer` / `BlocListener` للضرورة فقط.** الافتراضي `BlocBuilder` / `AsyncBlocBuilder`. See `bloc-patterns` skill — "BlocListener / BlocConsumer — Strict Usage Rules".
- **RTL is the default — العربية يمين → شمال.** Use `start`/`end` directional APIs everywhere. Titles على اليمين، Row first child على اليمين. See `rtl-arabic` skill.
- **No raw values in code.** Colors → `AppColors`, sizes → `AppSize`/`AppPadding`/`AppCircular`, text → `LocaleKeys.*.tr()`, icons → `AppAssets`.
- **Read Figma MCP before writing UI.** If MCP fails → stop. See `figma-mcp-mapping` / `figma-to-flutter`.
- **One cubit per endpoint.** Local update on add/edit/delete (never re-fetch).
- **Per-feature imports hub:** every presentation file declares `part of '../imports/<feature>_imports.dart';` — هذا الاسم **يتغير بحسب اسم الـ feature** (مثلاً `products_imports.dart` لـ products feature). كل الـ imports المشتركة في الـ hub، والـ classes تقدر تبقى private (`_ProductCard`, `_ProductsBody`) لكن متاحة عبر الـ feature.
- **Clean Architecture is the default** for every feature: `data/(datasources, models, mappers, repositories)` + `domain/(entities, enums, usecases, repositories, datasources)` + `presentation/(imports, cubits, controllers, view, widgets)`. الـ Cubit يأخذ `UseCase`s فقط (مش `BaseRemoteSource` مباشرة).
- **ViewController in `presentation/controllers/`** — separate folder. Holds `TextEditingController`, `ScrollController`, `ValueNotifier<T>`, `FocusNode`, `AnimationController`, validators, and small UI handlers. **Never inside the View.** Disposed from the Screen's `dispose()`. See `flutter-patterns` + `coding-standards` (section 22).

---

## 🚨 Strict Six Rules (موصى بها بقوة — تطبّق على كل feature جديد)

> **هذه القواعد هي أساس الجودة في كل feature. أي مخالفة لازم تتبرّر بمبرر فني واضح.**

| # | القاعدة | الـ rationale | المرجع |
|---|--------|--------------|--------|
| 1 | **لا comments زائدة بدون داعي.** الـ Comments تشرح **"لماذا"** (intent, trade-off, gotcha)، مش **"ماذا"** (الكود نفسه يقول ماذا). امسح أي comment بيكرر اسم المتغير/الـ method. | الكود الجيد يشرح نفسه. الـ comments الزائدة تتعفن مع الوقت وتكذب. | `clean-code-and-refactoring` |
| 2 | **لا hardcoded في الـ View.** ممنوع `Text('المنتجات')` / `Color(0xFFFFFFFF)` / `EdgeInsets.all(16)` / `'assets/...'` / `Icons.search` في الـ Screen أو widgets — كله من `LocaleKeys.*.tr()` / `AppColors` / `AppSize/AppPadding/AppCircular` / `AppAssets` / `IconWidget(icon: AppAssets.svg....path)`. | RTL + i18n + theming + design tokens — كله ينكسر لو فيه قيم خام. | `design-tokens`, `coding-standards` |
| 3 | **الـ View clean — لا functions داخل الـ View.** ممنوع أي method جوّا الـ Screen غير `build()` + `initState()` + `dispose()`. كل action handler (onTap, validator, formatter, navigation, sheet opener) متعالج في **Cubit** أو **ViewController** أو في **widget منفصل**. | الـ View = composition فقط. أي logic داخل الـ View = state hidden = bugs + لا testability. | `flutter-patterns`, `bloc-patterns` |
| 4 | **الأداء أولوية قصوى — ممنوع `setState` و rebuild بدون داعي.** الافتراضي: `ValueNotifier<T>` + `ValueListenableBuilder<T>` للـ ephemeral UI state، `BlocSelector` لجزء صغير من cubit state، `BlocBuilder` للـ full state. `setState` فقط في حالات **خاصة جداً** ولا بد من مبرر. | كل `setState` على parent يعيد بناء subtree كاملاً. `ValueListenableBuilder` يحدّث الـ leaf فقط. | `performance-and-memory`, `flutter-patterns` |
| 5 | **معظم الـ classes Stateless.** `StatefulWidget` فقط حين يكون لازم (`AnimationController`, focus management, cubit/controller lifecycle owner). الـ state الفعلي في cubit أو ViewController، مش في الـ widget. | الـ Stateless = predictable + fast + testable. الـ Stateful بدون داعي = source of bugs. | `flutter-patterns` |
| 6 | **ممنوع `Widget _buildSomething()` داخل الـ View.** أي widget داخل الـ View يصير ملفّ منفصل في `widgets/` كـ `private class _Something extends StatelessWidget`. الـ class private (يبدأ بـ `_`) لكن في ملف منفصل، part-of الـ imports hub. | الـ `_build*` functions ما بتاخدش `const`، ولا تستفيد من Flutter rebuild scope، وبتخبّي tree complexity. | `flutter-patterns`, `widget-efficiency` |

**Quick mental check قبل أي commit:**
```
□ Comments: كل comment يقول "لماذا" مش "ماذا"
□ View: مفيش string/color/size خام
□ View: مفيش method غير build/initState/dispose
□ Performance: مفيش setState — استخدم ValueNotifier/BlocSelector
□ Stateless: الـ widget Stateful فقط لو فيه lifecycle حقيقي
□ Widgets: مفيش Widget _buildX() — كله ملفات منفصلة
```

---

## Quick Tactical Reference (التزم بيها بدون ما تفتح skills)

> **القواعد العملية اللي بتتكرر في كل feature. الـ skills فيها التفاصيل والـ edge cases، لكن دي اللي لازم تكون في دماغك دايماً.**

### 🎨 Tokens & Values (No raw values)

```dart
// Colors    →  AppColors.main / .primary / .secondary / .forth / .hintText / .fill / .border / .error
// Sizes     →  AppSize.sH16 / AppSize.sW20 / AppSize.s14
// Padding   →  AppPadding.pH12 / AppPadding.pW16
// Margin    →  AppMargin.mH8 / AppMargin.mW12
// Radius    →  AppCircular.r8 / .r12 / .r16
// Text      →  LocaleKeys.featureKey.tr()         // كل نص في lang.json
// Icons     →  AppAssets.svg.baseSvg.search.path  // مش Icons.*
```

### 📐 Spacing & Padding (Extensions only — مش widgets)

```dart
12.szH  16.szW                            // بدل SizedBox(height/width:)
widget.paddingAll(AppPadding.pH16)        // بدل Padding(...)
widget.paddingStart(AppPadding.pW16)      // ✅ RTL-safe (= physical right)
widget.paddingEnd(AppPadding.pW16)        // ✅ RTL-safe (= physical left)
widget.marginStart(AppMargin.mW12)        // ✅ RTL-safe
widget.onClick(onTap: () => Go.to(...))   // بدل GestureDetector
widget.toSliver()                         // بدل SliverToBoxAdapter(child:)
```

### ✍️ Text Style (Extension chain only)

```dart
const TextStyle().setMainTextColor.s14.semiBold
const TextStyle().setHintColor.s12.regular
const TextStyle().setErrorColor.s12.bold
// Figma sizing: ≤13sp keep as-is | 14-18sp reduce by 1-2 | ≥20sp reduce by 2
```

### 🧩 Core Widgets (use first, never reinvent)

```dart
DefaultScaffold(title: LocaleKeys.x.tr(), body: const _Body())  // inner screens
LoadingButton(title: ..., onTap: () async => ...)              // ALL async submits (spinner runs while onTap's Future is awaited)
CustomTextFiled(title:, hint:, controller:, validator:, ...)    // form fields
AppDropdown<T>(items:, label:, itemAsString:, onChanged:)       // dropdowns
CachedImage(url:, width:, height:, borderRadius:)               // ALL network images
IconWidget(icon: AppAssets.x.path, height: AppSize.sH20)         // ALL icons — NO color, NO IconData
AsyncBlocBuilder<C, T>(builder:, loadingBuilder:, errorBuilder:, onRetry:)  // API state (errorBuilder receives Failure)
AsyncSliverBlocBuilder<C, T>(builder:)                          // sliver version (if available)
PaginatedListWidget<C, T>(itemBuilder:, loadingBuilder:)        // paginated lists
EmptyWidget(title:, desc:, path:)                               // full-screen empty
successDialog(context, title:)  showDefaultBottomSheet(child:)  // dialogs/sheets
MessageUtils.showSnackBar(context:, baseStatus:, message:)      // snackbars
```

### 🎯 AppDropdown with API — NO BlocBuilder Wrapping (CRITICAL)

> **لو الـ AppDropdown بياخد data من API service → لا تلفّه في `BlocBuilder` / `AsyncBlocBuilder` ولا تضيف error UI خاصة بيه.**
> **لو الـ service فشلت → الـ dropdown هيظهر فاضي (بدون items). كده وخلاص.**
> **مفيش retry button، مفيش error state على الـ dropdown، مفيش "Failed to load cities" message.**

```dart
// ✅ CORRECT — fetch in cubit, pass cubit/items directly to AppDropdown
class _MyForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => injector<GetCitiesCubit>()..fetchCities(),
      child: Builder(
        builder: (ctx) {
          final s = ctx.watch<GetCitiesCubit>().state;
          final cities = s is AsyncSuccess<List<CityEntity>> ? s.data : const <CityEntity>[];
          return AppDropdown<CityEntity>(
            items: cities,                       // ← []  لو فشلت
            label: LocaleKeys.city.tr(),
            itemAsString: (c) => c.name,
            isLoading: s is AsyncLoading,
            onChanged: (c) => params.selectedCity = c,
            validator: Validators.validateDropDown,
          );
        },
      ),
    );
  }
}

// ❌ FORBIDDEN — wrapping dropdown in BlocBuilder/AsyncBlocBuilder + error builder
AsyncBlocBuilder<GetCitiesCubit, List<CityEntity>>(
  errorBuilder: (ctx, err) => ErrorView(...),  // ← لا — مفيش error UI للـ dropdown
  builder: (ctx, cities) => AppDropdown(items: cities, ...),
)
```

**القاعدة:** فشل service الـ dropdown ≠ blocker للـ screen. الـ form يقدر يكمل وخلاص، أو المستخدم يقفل ويرجع.

### 🖼️ Icons — NO Color, NO IconData, NO Wrapper (CRITICAL)

> **استخدم AppAssets فقط. الـ icons موجودة بالألوان والـ borders والـ backgrounds الصحيحة من الديزاينر.**

```dart
// ✅ CORRECT — use AppAssets path, no color override
IconWidget(icon: AppAssets.svg.baseSvg.search.path, height: AppSize.sH20)
IconWidget(icon: AppAssets.svg.featureSvg.notification.path, height: AppSize.sH24)

// ❌ FORBIDDEN — adding color to AppAssets icon
IconWidget(
  icon: AppAssets.svg.baseSvg.search.path,
  color: AppColors.primary,  // ← لا — الـ icon already بلونه الصح
  height: AppSize.sH20,
)

// ❌ FORBIDDEN — using IconData (Material Icons)
Icon(Icons.search, color: AppColors.primary)
IconWidget(icon: Icons.notifications, color: AppColors.main)

// ❌ FORBIDDEN — wrapping AppAssets icon in Container with border/bg
Container(
  decoration: BoxDecoration(
    color: AppColors.fill,                              // ← الـ icon already فيه bg
    borderRadius: BorderRadius.circular(AppCircular.r8),
    border: Border.all(color: AppColors.border),        // ← الـ icon already فيه border
  ),
  child: IconWidget(icon: AppAssets.svg.x.path),         // → double bg/border!
)

// ✅ CORRECT — icon used as-is
IconWidget(icon: AppAssets.svg.x.path, height: AppSize.sH48)
```

**Workflow بعد قراءة Figma (إلزامي):**

```
1. شفت في الديزاين icon داخل border/bg/circle؟
   → افتح AppAssets — الـ icon المفروض موجود **بالـ border/bg already مرسومين فيه**
   → استخدم الـ asset مباشرة، لا تضيف Container
2. شفت icon ملون بلون معين؟
   → الـ icon في AppAssets موجود **باللون الصحيح** من الديزاينر
   → لا تضيف `color:` parameter
3. مفيش icon في AppAssets يطابق المطلوب؟
   → اطلب من المستخدم يضيف الـ asset (مش تستخدم Icons.* fallback)
```

**استثناء وحيد للون:** لو الـ icon موجود في AppAssets كـ template SVG (single-color icon بدون fill defined)، وقتها فقط ضيف `color:`. لكن ده نادر — الغالب الـ icons exported بألوانها.

### 🧭 Navigation (Go only — never Navigator)

```dart
Go.to(const X())  Go.off(const X())  Go.offAll(const X())  Go.back()
Go.toNamed(Routes.x)  Go.offAllNamed(Routes.x)
```

### 🔌 State (AsyncCubit + UseCase + local CRUD updates)

> **الـ Cubit يأخذ UseCases — NOT BaseRemoteSource directly. الـ Repository/UseCase layer لازمة لكل feature.**

```dart
// presentation/cubits/x_cubit.dart  (part of <feature>_imports.dart)
@injectable
class XCubit extends AsyncCubit<List<XEntity>> {
  XCubit(this._getXList, this._createX, this._deleteX);

  final GetXListUseCase _getXList;
  final CreateXUseCase _createX;
  final DeleteXUseCase _deleteX;

  // execute() handles Loading → Success/Failure by folding Either<Failure, T>
  Future<void> fetchX({String? search}) =>
    execute(() => _getXList(search: search));

  // CRUD: NEVER re-fetch — optimistic local update + rollback on failure
  Future<Either<Failure, XEntity>> create(XParams p) async {
    final temp = XEntity.tempFromParams(p);
    final before = lastData ?? const <XEntity>[];
    setData([temp, ...before]);                // optimistic insert

    final result = await _createX(p);
    return result.fold(
      (failure) { setData(before); return Left(failure); },         // rollback
      (saved) {
        setData((lastData ?? before)
          .map((e) => e.id == temp.id ? saved : e).toList());
        return Right(saved);
      },
    );
  }

  void updateLocal(XEntity updated) => setData(
    (lastData ?? const <XEntity>[])
      .map((e) => e.id == updated.id ? updated : e).toList(),
  );

  Future<Either<Failure, Unit>> delete(int id) async {
    final before = lastData ?? const <XEntity>[];
    setData(before.where((e) => e.id != id).toList());
    final result = await _deleteX(id);
    return result.fold(
      (failure) { setData(before); return Left(failure); },
      Right.new,
    );
  }
}
```

**AsyncCubit API (in `core/state/async/`):**
- `execute(() => useCase())` — emits Loading → Success/Failure by folding `Either<Failure, T>`. `CancelledFailure` is silent.
- `setData(T data)` — push a local mutation without re-fetching (CRUD optimism).
- `setFailure(Failure failure)` — force an error state (e.g. local validation failure).
- `lastData` — last successful payload, kept across Loading/Failure so UI can render old data while refreshing.
- `state` is sealed `AsyncState<T>` → exhaustive `switch` in the UI: `AsyncInitial / AsyncLoading(previous) / AsyncSuccess(data) / AsyncFailure(failure, previous)`.

**UI consumption — AsyncBlocBuilder (in `core/state/async/`):**
```dart
AsyncBlocBuilder<XCubit, List<XEntity>>(
  onRetry: () => context.read<XCubit>().fetchX(),
  loadingBuilder: (_) => const _XSkeleton(),           // optional, has default
  errorBuilder:   (_, Failure f) => _XError(failure: f),// optional, has default
  builder: (context, items) => _XList(items: items),
)
```

### 🛡️ Entity Safety (every entity, no exceptions)

```dart
class XEntity {
  final int id; final String name;
  const XEntity({required this.id, required this.name});

  factory XEntity.initial() => const XEntity(id: 0, name: '');  // for Skeletonizer
  factory XEntity.fromJson(Map<String, dynamic> json) => XEntity(
    id: int.tryParse(json['id'].toString()) ?? 0,   // tryParse + ??, NEVER parse
    name: json['name'] ?? '',                        // ?? for all non-nullable
  );
}
```

### 🛡️ Field Validation & InputFormatters (Per-Field Mandatory)

> **كل field في كل شاشة لازم يكون له `validator` + `inputFormatters` يعبروا عن نوع محتواه.**
> **مفيش field بدون validation — كل نوع content له قواعده.**
> **مع الـ numeric fields: max value إلزامي عشان المستخدم ميكتبش 99999999999.**

```dart
// ✅ Per-field rules table
// Saudi Phone   → Validators.validateSaudiPhone        + [SaudiPhoneFormatter(), ArabicNumbersFormatter(), LengthLimitingTextInputFormatter(13)]
// Generic Phone → Validators.validatePhone             + [PhoneNumberFormatter(), ArabicNumbersFormatter()]
// Email         → Validators.validateEmail             + [EmailFormatter()]
// Password      → Validators.validatePassword          + [] // built-in length/symbol rules
// Name          → Validators.validateEmpty             + [TextOnlyFormatter(allowArabic: true)]
// Commercial Reg→ Validators.validateCommercialReg     + [NumberOnlyFormatter(), ArabicNumbersFormatter(), LengthLimitingTextInputFormatter(10)]
// National ID   → Validators.validateNationalId        + [NumberOnlyFormatter(), ArabicNumbersFormatter(), LengthLimitingTextInputFormatter(10)]
// IBAN (SA)     → Validators.validateIban              + [IbanFormatter(), LengthLimitingTextInputFormatter(24)]
// VAT Number    → Validators.validateVat               + [NumberOnlyFormatter(), LengthLimitingTextInputFormatter(15)]
// OTP           → Validators.validateEmpty             + [NumberOnlyFormatter(), ArabicNumbersFormatter(), LengthLimitingTextInputFormatter(6)]
// Price/Amount  → Validators.validatePrice             + [CurrencyFormatter(), ArabicNumbersFormatter()]  // displays 3,000,000
// Quantity (int)→ Validators.validateEmpty             + [IntegerNumberFormatter(maxValue: 99999), ArabicNumbersFormatter()]
// Decimal       → Validators.validateEmpty             + [DecimalNumberFormatter(decimalPlaces: 2), ArabicNumbersFormatter()]
// Date          → Validators.validateEmpty             + [DateTimeFormatter()]   // auto-formats DD/MM/YYYY
// URL           → Validators.validateUrl               + [NoSpecialCharactersFormatter(allowArabic: false)]
// Dropdown      → Validators.validateDropDown<T>       + —
// Optional      → Validators.noValidate                + (حسب الـ data type)
```

### 💰 Currency / Price Field — Display vs API

> **السعر بيتعرض formatted (`3,000,000`) في الـ UI، لكن بيتبعت للـ API plain (`3000000`).**

```dart
// ✅ Display: comma separators every 3 digits
CustomTextFiled(
  controller: params.priceController,
  validator: Validators.validatePrice,
  inputFormatters: [
    CurrencyFormatter(maxValue: 999_999_999),  // 3000000 → 3,000,000
    ArabicNumbersFormatter(),                   // ٠١٢٣ → 0123
  ],
  textInputType: TextInputType.number,
)

// ✅ Strip commas + convert Arabic numerals BEFORE sending to API
final priceClean = params.priceController.text
  .replaceAll(',', '')
  .toEnglishNumbers();
final amount = double.tryParse(priceClean) ?? 0;
// → use `amount` in body of API call
```

### 📞 Saudi Phone — Canonical Format Before API

```dart
// ✅ Display: accept 05xxxxxxxx, +9665xxxxxxxx, or 9665xxxxxxxx
CustomTextFiled(
  controller: params.phoneController,
  validator: Validators.validateSaudiPhone,
  inputFormatters: [
    SaudiPhoneFormatter(),
    ArabicNumbersFormatter(),
    LengthLimitingTextInputFormatter(13),
  ],
  textInputType: TextInputType.phone,
)

// ✅ Normalize before API: → always 9665xxxxxxxx
final phone = Helpers.normalizeSaudiPhone(
  params.phoneController.text.toEnglishNumbers(),
);
// 05xxxxxxxx     → 9665xxxxxxxx
// +9665xxxxxxxx  → 9665xxxxxxxx
```

### 🔢 Numeric Limits (إلزامي لكل numeric field)

| الـ Field | Max | السبب |
|----------|-----|------|
| Price (amount) | `999_999_999` | تمنع الأرقام الفلكية |
| Quantity (cart) | `999` | معقول لـ shopping cart |
| Quantity (inventory) | `99_999` | warehouse-scale |
| Age | `120` | human limit |
| Year | current + 5 | future-reasonable |
| Discount % | `100` | percentage cap |
| OTP | 4–6 digits | fixed length |
| Phone (Saudi) | 13 chars | with country code |

```dart
// ✅ Always cap numeric inputs
inputFormatters: [
  IntegerNumberFormatter(maxValue: 999),  // hard cap
  ArabicNumbersFormatter(),
]
// OR for prices:
CurrencyFormatter(maxValue: 999_999_999)
```

### ❌ Field Anti-patterns

```dart
// ❌ Field بدون validator
CustomTextFiled(controller: c)  // FORBIDDEN

// ❌ Numeric field بدون max
CustomTextFiled(
  controller: priceController,
  textInputType: TextInputType.number,
  // ← المستخدم ممكن يكتب 99999999999999
)

// ❌ Phone بدون ArabicNumbersFormatter
CustomTextFiled(
  controller: phoneController,
  validator: Validators.validatePhone,
  // ← لو المستخدم كتب ٠٥٠... الـ validation هتفشل
)

// ❌ Price بيتبعت بـ commas
final price = priceController.text;  // "3,000,000" — server هيفشل في parsing!

// ✅ Cleanup قبل API:
final price = priceController.text.replaceAll(',', '').toEnglishNumbers();
```

### 🔧 Missing Helpers? Add Them (Don't Fake It)

> **لو الـ validator/formatter اللي محتاجه (مثلاً `validateSaudiPhone`, `CurrencyFormatter`, `IbanFormatter`, `normalizeSaudiPhone`) مش موجود في الكود → أضفه في `validators.dart` / `input_formatters.dart` / `helpers.dart`.**
> **ممنوع تستخدم `validateEmpty` لـ IBAN أو phone عشان "الـ helper مش موجود". أضف الـ helper الصح ثم استخدمه.**

موجود حالياً في الكود: `validateEmpty/Email/Password/Phone/DropDown`, `PhoneNumberFormatter`, `EmailFormatter`, `NumberOnlyFormatter`, `TextOnlyFormatter`, `TextWithNumberFormatter`, `IntegerNumberFormatter(maxValue:)`, `DecimalNumberFormatter(decimalPlaces:)`, `DateTimeFormatter`, `NoSpecialCharactersFormatter`, `ArabicNumbersFormatter`.

محتاج يتضاف عند أول feature محتاجها: `validateSaudiPhone`, `validateCommercialReg`, `validateNationalId`, `validateIban`, `validateVat`, `validatePrice`, `validateUrl`, `SaudiPhoneFormatter`, `CurrencyFormatter`, `IbanFormatter`, `Helpers.normalizeSaudiPhone`. التفاصيل في `coding-standards` skill section 8.3.6.

### 📋 Field Checklist (لكل field في كل شاشة)

```
□ Validator مناسب لنوع المحتوى (مش validateEmpty لكل حاجة)
□ InputFormatters تمنع المستخدم من كتابة قيم غلط من البداية
□ ArabicNumbersFormatter في numeric/phone/date fields
□ Max value للـ numeric fields (إلزامي)
□ Length limit حيث مناسب (OTP/CR/NID/IBAN/Phone)
□ Display formatting (CurrencyFormatter للـ price، DateTimeFormatter للـ date)
□ Cleanup قبل API: .toEnglishNumbers() + strip commas/dashes حسب الحاجة
□ textInputType مناسب (TextInputType.phone / .number / .emailAddress)
□ textInputAction (.next / .done) للـ form flow
```

### 📝 Forms (FormMixin + validateAndScroll + LoadingButton)

```dart
class XParams with FormMixin {
  final phoneController = TextEditingController();
}
Form(key: params.formKey, child: Column(children: [
  CustomTextFiled(controller: params.phoneController,
    validator: Validators.validatePhone,
    inputFormatters: [PhoneNumberFormatter(), ArabicNumbersFormatter()]),
]))
// Submit:
if (params.validateAndScroll()) {
  final phone = params.phoneController.text.toEnglishNumbers();  // mandatory
  await cubit.submit(phone);
}
```

### 📜 Scrolling (multi-section → Slivers)

```dart
// >1 scrollable section → CustomScrollView + slivers (NEVER SingleChildScrollView+nested ListView+shrinkWrap)
CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
  const _Header().toSliver(),
  AsyncSliverBlocBuilder<XCubit, List<XEntity>>(builder: (_, items) =>
    SliverList.builder(itemCount: items.length, itemBuilder: (_, i) => _Card(item: items[i]))),
])
```

### 🌐 RTL Quick Checklist

```
✓ Column → CrossAxisAlignment.start   (نصوص تبدأ يمين)
✓ Row    → first child = اليمين، last = الشمال
✓ Align  → AlignmentDirectional.centerStart/centerEnd
✓ Stack  → PositionedDirectional(start/end:)  NEVER Positioned(left/right:)
✓ Padding/Margin → .paddingStart/.paddingEnd NEVER paddingLeft/paddingRight
✓ TextAlign.start  NEVER TextAlign.left/right
✗ Directionality حوالين layout/screen (مسموح فقط حوالين widget داخلي محدد)
```

### 🎮 ViewController (في `presentation/controllers/` — ممنوع setState في الـ View)

> **مكانه ثابت:** `presentation/controllers/<feature>_view_controller.dart` — part of `<feature>_imports.dart`.
> **محتواه:** كل الـ ephemeral UI state اللي لازمة الـ View ومش server data (server data → cubit).

```dart
// presentation/controllers/products_view_controller.dart
part of '../imports/products_imports.dart';

class ProductsViewController {
  ProductsViewController({required this.onSearch});

  final ValueChanged<String> onSearch;

  // الـ controllers + notifiers + focus nodes + animations
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<ProductStatus?> statusFilter = ValueNotifier(null);
  final FocusNode searchFocus = FocusNode();

  // الـ handlers اللي بتعالج interactions صغيرة (UI-only)
  void setStatusFilter(ProductStatus? s) => statusFilter.value = s;
  void clearSearch() { searchController.clear(); onSearch(''); }

  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    statusFilter.dispose();
    searchFocus.dispose();
  }
}
```

```dart
// presentation/view/products_screen.dart  (Screen owns lifecycle)
class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsCubit _cubit;
  late final ProductsViewController _vc;

  @override
  void initState() {
    super.initState();
    _cubit = injector<ProductsCubit>()..fetchProducts();
    _vc = ProductsViewController(onSearch: _searchSubject.add);
  }

  @override
  void dispose() {
    _vc.dispose();
    _cubit.close();
    super.dispose();
  }
}
```

**Rules:**
- الـ widgets الجوّانيّة تستمع بـ `ValueListenableBuilder<T>(valueListenable: _vc.statusFilter, builder: ...)` — تحدّث leaf فقط، لا تعيد بناء الـ Screen.
- ممنوع `TextEditingController` / `ScrollController` / `ValueNotifier` ينعمل في الـ View نفسه — كلهم في الـ ViewController.
- ممنوع `setState` — استخدم `ValueNotifier` + `ValueListenableBuilder`.

### 🌍 Localization (lang.json format)

```json
{ "feature_title #$ Feature Title": "عنوان الميزة",
  "welcome #$ Welcome {name}": "أهلا {name}" }
```
بعد التعديل: `dart run generate/strings/main.dart` → استعمل `LocaleKeys.featureTitle.tr()` فقط.

### 🌐 Networking — `BaseRemoteSource.request<T>` (single entry point)

> **لا `Dio()` خام في الـ features.** كل remote call يمر عبر `BaseRemoteSource.request<T>(...)`. الـ datasource يـ `extends BaseRemoteSource`، والـ repository يستدعيه. الـ UI ما يعرفش عن Dio.

```dart
// data/datasources/x_remote_data_source_impl.dart
@LazySingleton(as: XRemoteDataSource)
class XRemoteDataSourceImpl extends BaseRemoteSource implements XRemoteDataSource {
  @override
  Future<Either<Failure, List<XEntity>>> getList({int page = 1, String? search}) =>
    request<List<XEntity>>(
      method: HttpMethod.get,
      endpoint: ApiEndpoints.x,
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      fromJson: _parseList,
    );

  @override
  Future<Either<Failure, XEntity>> create({required String name, required double price}) =>
    request<XEntity>(
      method: HttpMethod.post,
      endpoint: ApiEndpoints.x,
      body: {'name': name, 'price': price},
      fromJson: _parseOne,
    );

  @override
  Future<Either<Failure, Unit>> delete(int id) =>
    request<Unit>(
      method: HttpMethod.delete,
      endpoint: ApiEndpoints.xById(id),
      fromJson: (_) => unit,
    );

  // Public endpoints — skip Bearer token
  Future<Either<Failure, AuthToken>> login(String email, String pwd) =>
    request<AuthToken>(
      method: HttpMethod.post,
      endpoint: ApiEndpoints.login,
      body: {'email': email, 'password': pwd},
      skipAuth: true,
      fromJson: (j) => AuthToken.fromJson(j),
    );

  // Multipart upload
  Future<Either<Failure, UploadResult>> upload(String path, String note) =>
    request<UploadResult>(
      method: HttpMethod.post,
      endpoint: ApiEndpoints.upload,
      body: {'file': await MultipartFile.fromFile(path), 'note': note},
      asFormData: true,
      fromJson: (j) => UploadResult.fromJson(j),
    );

  static List<XEntity> _parseList(dynamic j) =>
    ((j is Map ? j['data'] : j) as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(XModel.fromJson).map((m) => m.toEntity()).toList();
  static XEntity _parseOne(dynamic j) =>
    XModel.fromJson(((j is Map ? j['data'] ?? j : j) as Map<String, dynamic>)).toEntity();
}
```

**`request<T>` Parameters (الـ unified entry):**
| Param | Purpose |
|---|---|
| `method` | `HttpMethod.get / post / put / patch / delete` |
| `endpoint` | relative path (DioClient prepends `baseUrl`) |
| `queryParameters` | `?key=value&...` map |
| `body` | request body (Map / List / String / FormData / MultipartFile-bearing Map) |
| `headers` | extra request headers merged on top of globals |
| `fromJson` | `T Function(dynamic json)` — parser (use `unit` for void) |
| `skipAuth` | skip Bearer token (login/register/public) |
| `asFormData` | wrap Map body in `FormData.fromMap(...)` automatically |
| `normalizeArabicDigits` | (default `true`) convert ٠١٢٣ → 0123 in body & query strings |
| `cancelKey` | dedupe key (default `"$METHOD:$endpoint"`) — auto-cancels previous in-flight |
| `cancelPrevious` | (default `true`) cancel previous in-flight with same key |
| `responseType` | override Dio response parsing (rarely needed) |

**Interceptor chain (in `DioClient`):**
```
LocaleInterceptor   → adds Accept-Language so retries/refresh share it
AuthInterceptor     → Bearer token + 401 refresh-token cycle (respects skipAuth)
RetryInterceptor    → retries idempotent failures
AppCacheInterceptor → short-circuits with cached payloads (Hive-backed)
LoggingInterceptor  → debug-only; last so it sees the final shape
```
Status-code handling lives in `ResponseParser` / `StatusCodeHandler` — Dio's `validateStatus` accepts <500 so 4xx travel as `Failure` via `Either.Left`.

**Repository → UseCase → Cubit:**
```dart
// domain/repositories/x_repository.dart
abstract interface class XRepository {
  Future<Either<Failure, List<XEntity>>> getList({String? search});
}

// data/repositories/x_repository_impl.dart
@LazySingleton(as: XRepository)
class XRepositoryImpl implements XRepository {
  XRepositoryImpl(this._remote);
  final XRemoteDataSource _remote;
  @override
  Future<Either<Failure, List<XEntity>>> getList({String? search}) =>
    _remote.getList(search: search);
}

// domain/usecases/get_x_list_usecase.dart
@lazySingleton
class GetXListUseCase {
  GetXListUseCase(this._repo);
  final XRepository _repo;
  Future<Either<Failure, List<XEntity>>> call({String? search}) =>
    _repo.getList(search: search);
}
```

### 🔔 Notifications — `NotificationManager` + `NotificationRouter` (FCM via awesome_notifications)

> **النظام كله في `core/notifications/`** — singleton manager + sealed actions router + FCM controller.
> **FORBIDDEN packages:** `firebase_messaging`, `flutter_local_notifications` (يتعارضوا مع `awesome_notifications`).

**bootstrap (in `main.dart`):**
```dart
await Firebase.initializeApp();
await NotificationManager.instance.initialize(
  router: const AppNotificationRouter(),         // routes navigator via Go.navigatorKey
  debug: kDebugMode,
);
NotificationManager.instance.requestPermissions();
NotificationManager.instance.requestToken();
```

**Sealed actions (in `notification_router.dart`):**
```dart
sealed class NotificationAction { const NotificationAction(); }
final class NavigateToChat extends NotificationAction { final String chatId; const NavigateToChat(this.chatId); }
final class NavigateToScreen extends NotificationAction { final String route; const NavigateToScreen(this.route); }
final class OpenUrl extends NotificationAction { final Uri url; const OpenUrl(this.url); }
final class DismissAction extends NotificationAction { const DismissAction(); }
```

**Adding a new notification type:**
1. Add enum case in `models/notification_enums.dart` (`NotificationType`).
2. Add layout case in `NotificationController._buildContent` switch.
3. Add buttons case in `NotificationController._buildActionButtons` (if needed).
4. Add `final class XAction extends NotificationAction` + case in `_parseAction` (if new navigation target).
5. Add case in `AppNotificationRouter.route(...)` switch (compiler enforces exhaustiveness).

**Golden rules:**
| Rule | Why |
|---|---|
| Every static handler called from native MUST have `@pragma('vm:entry-point')` | tree-shaker drops it from release otherwise |
| `channelKey` in `NotificationContent` MUST match a channel registered in `initialize` | else notification silently fails to show |
| `id` in `NotificationContent` MUST be `int` | use `payload.id.hashCode` if id is a String |
| No `BuildContext` in static handlers | use `Go.navigatorKey` (or any `GlobalKey<NavigatorState>`) |
| `IsolateNameServer` is the ONLY way to bridge background isolate → main | isolates have no shared memory |

**See:** `core/notifications/EXPLANATION.md` (detailed walkthrough in Arabic) + `.claude/skills/notifications/SKILL.md`.

### 🔒 Code Hygiene

- `const` على كل widget/constructor ممكن
- Private `_Foo` للـ widgets الخاصة بالفيتشر (في `widgets/` كملف منفصل، مش `_buildX()` داخل الـ View)
- ممنوع `print` / `debugPrint` في الفاينل (استخدم `LoggingInterceptor` للـ network)
- ممنوع unused imports / parameters → شغّل `flutter analyze`
- `compute()` للـ JSON parsing الثقيل (4+ APIs في شاشة واحدة)
- Comments **تشرح "لماذا"** فقط — مش "ماذا". الكود الذي يحتاج comment ليُفهم = كود يحتاج refactor.

### 🧱 Widget Efficiency — Golden Rule (التفاصيل في `widget-efficiency` skill)

> **قبل ما تكتب أي wrapper widget، اسأل نفسك 3 أسئلة بالترتيب:**
> 1. هل الـ **child** عنده الـ attribute ده natively؟
> 2. هل الـ **parent** بيدعم الـ behavior ده من attributes بتاعته؟
> 3. هل فيه **widget أكثر دلالة** متعمل بالظبط للحالة دي؟
>
> لو الـ 3 إجابات `لا` → وقتها فقط الـ wrapper مقبول.

**أسرع 20 anti-pattern لازم تتجنبهم (الباقي في الـ skill):**

```dart
// ❌ Padding wrapper       → ✅ Container/Card/ListTile الـ padding/contentPadding/margin الـ native
// ❌ SizedBox بين children → ✅ Column(spacing:) / Row(spacing:) / Wrap(spacing:, runSpacing:)
// ❌ Expanded(SizedBox())  → ✅ Spacer() أو mainAxisAlignment: spaceBetween
// ❌ Container للـ sizing فقط → ✅ SizedBox / SizedBox.shrink() / SizedBox.expand()
// ❌ MediaQuery للـ % sizing → ✅ Flexible(flex:) / FractionallySizedBox / AspectRatio
// ❌ ClipRRect حوالين Container بـ borderRadius → ✅ Container(clipBehavior: Clip.antiAlias)
// ❌ Stack لـ shadow      → ✅ Container(decoration: BoxDecoration(boxShadow:))
// ❌ Opacity على color/icon → ✅ color.withValues(alpha:) — أرخص بكتير (مفيش saveLayer)
// ❌ Container حول Scaffold body للـ bg → ✅ Scaffold(backgroundColor:)
// ❌ GestureDetector على ListTile/Button → ✅ ListTile(onTap:) / Button(onPressed:) أو .onClick(...)
// ❌ GestureDetector للـ ripple → ✅ InkWell(onTap:, borderRadius:)
// ❌ Custom drag للـ swipe → ✅ Dismissible
// ❌ Row من Text widgets لـ inline styling → ✅ Text.rich(TextSpan(children: [...]))
// ❌ SizedBox/Container حول Image للـ sizing → ✅ Image(width:, height:, fit:)
// ❌ ClipOval + Image → ✅ CircleAvatar
// ❌ Stack + Container لـ image overlay → ✅ Image(color:, colorBlendMode:)
// ❌ ListView بكل الـ items → ✅ ListView.builder / .separated
// ❌ shrinkWrap: true داخل scrollable → ✅ Sliver* family في CustomScrollView
// ❌ Stack + Positioned لـ badge → ✅ Badge(label: Text('3'), child: Icon(...))
// ❌ isVisible ? W : SizedBox → ✅ Visibility(visible:, maintainState:) أو IndexedStack
// ❌ AnimationController boilerplate لـ simple transitions → ✅ AnimatedContainer / AnimatedOpacity / ...
// ❌ Container + shadow بدل Card → ✅ Card / Card.filled / Card.outlined
// ❌ Container + GestureDetector للـ chip → ✅ FilterChip / ChoiceChip / InputChip / ActionChip
// ❌ Container(height: 1, color:) → ✅ Divider() / VerticalDivider()
// ❌ M2 widgets (BottomNavigationBar/DropdownButton/PopupMenuButton) → ✅ M3 (NavigationBar/DropdownMenu/MenuAnchor)
```

**التفاصيل + 12 part كامل (layout, decoration, gestures, text, images, lists/slivers, inputs, navigation, visibility, animation, Stack, M3) + جدول M2→M3 migration → `.claude/skills/widget-efficiency/SKILL.md`.**

---

## ⚠️ Mandatory Pre-Flight Reading (إلزامي قبل أي feature جديد)

> **CLAUDE.md ده baseline — لكن التفاصيل والـ edge cases في الـ skills.**
> **قبل ما تكتب أي سطر كود في feature جديد، اقرأ الـ skills دي بـ `Read` tool — مش optional.**
> **ده بيقلل نسبة الخطأ لأقل حد ممكن.**

### 📚 القراءة الإلزامية (لكل feature جديد — اقرأها بالترتيب):

```
1. .claude/skills/feature-prompt/SKILL.md       ← الـ workflow الكامل (STEP 0-8)
2. .claude/skills/coding-standards/SKILL.md     ← Senior mindset + entity safety + 30+ rule
3. .claude/skills/rtl-arabic/SKILL.md           ← RTL layout mirroring + Figma reading direction
4. .claude/skills/flutter-patterns/SKILL.md     ← Senior widget building + file structure
5. .claude/skills/widget-efficiency/SKILL.md    ← اختيار الـ widget الصح + بناء أقل widget tree (no wrappers)
6. .claude/skills/bloc-patterns/SKILL.md        ← BlocConsumer/Listener strict rules + AsyncCubit
```

> **`widget-efficiency` مش optional — هي الـ rulebook لاختيار الـ widget الصح وتجنّب الـ wrappers الزيادة.**
> **قبل ما تكتب `Padding(...)` / `Center(...)` / `Container()` للـ sizing / `GestureDetector` / `Stack` للـ badge / `ClipRRect` حوالين `Image` / `Opacity` على `color` — راجع الـ skill ده.**
> **القاعدة الذهبية: استخدم الـ attribute اللي جوه الـ widget قبل ما تـ wrap.**

### 🎯 القراءة الـ Conditional (حسب نوع الفيتشر):

```
لو الفيتشر فيه API           → .claude/skills/api-pipeline/SKILL.md
لو الفيتشر فيه form          → .claude/skills/form-api-pipeline/SKILL.md
لو فيه Figma design           → .claude/skills/figma-to-flutter/SKILL.md
                                .claude/skills/figma-widget-mapping/SKILL.md
                                .claude/skills/figma-mcp-mapping/SKILL.md
لو navigation معقد            → .claude/skills/navigation-patterns/SKILL.md
                                .claude/skills/multi-screen-flow/SKILL.md
لو search field               → .claude/skills/search-field-debounce/SKILL.md
لو scaffold/status bar        → .claude/skills/scaffold-patterns/SKILL.md
لو bloc scoping سؤال          → .claude/skills/bloc-provider-scoping/SKILL.md
لو DI أو architecture         → .claude/skills/di-and-architecture/SKILL.md
لو design tokens              → .claude/skills/design-tokens/SKILL.md
لو FCM/Push notifications     → .claude/skills/notifications/SKILL.md
لو performance/no-setState    → .claude/skills/performance-and-memory/SKILL.md
```

### ✅ بعد ما تخلص الـ Feature (إلزامي):

```
.claude/skills/post-feature-review/SKILL.md   ← code review checklist + critical/high issues
```

### 🔍 Trigger Rules — متى تقرأ إيه:

| المهمة | الـ skills اللازم قراءتها |
|--------|---------------------------|
| **Feature كامل من Figma + API** | الـ 6 إلزامية + figma + api-pipeline + post-feature-review |
| **Feature UI فقط (لا API)** | الـ 6 إلزامية + figma — تخطي api/bloc لو مفيش cubits |
| **Cubit/Endpoint جديد** | feature-prompt + bloc-patterns + api-pipeline + coding-standards |
| **Form + API submit** | feature-prompt + form-api-pipeline + bloc-patterns + widget-efficiency + coding-standards |
| **Bug في RTL أو layout mirroring** | rtl-arabic فقط |
| **Refactor widget موجود** | flutter-patterns + widget-efficiency + coding-standards |
| **بناء widget جديد في core/widgets** | widget-efficiency + flutter-patterns + coding-standards |
| **تعديل صغير على feature موجود** | CLAUDE.md فقط (الـ Quick Tactical Reference يكفي) |
| **سؤال مفهوم بسيط** | CLAUDE.md فقط |

### ❌ Anti-pattern (ممنوع):

> **ممنوع تبدأ feature جديد وتعتمد على CLAUDE.md فقط.**
> **الـ Quick Tactical Reference فيه الـ 80% من القواعد — الـ 20% الباقية (edge cases، Figma MCP reading direction، entity safety details، CRUD response merge، dropdown isolation، sliver double-wrap، Directionality exceptions، إلخ) في الـ skills، وغلطها بتطلع عيوب في الكود.**

### الـ Workflow الموحد:

```
1. اقرأ الـ 6 skills الإلزامية (Read tool — مش optional)
2. شوف الفيتشر فيه إيه → اقرأ الـ conditional skills المطلوبة
3. اتبع STEP 0-8 من feature-prompt
4. بعد ما تخلص → اقرأ post-feature-review واعمل الـ checklist
```

---

## Workflow Entry Point

For any new feature, the canonical workflow is in **`feature-prompt`** skill (orchestrator).

---

## Skills Sync

Skills live in two mirrored locations:

- `.claude/skills/<name>/SKILL.md` — canonical source
- `.cursor/rules/<name>.mdc` — generated from canonical

After any edit: `bash scripts/sync-cursor.sh` (or rely on the pre-commit hook).
**Never edit `.cursor/rules/*.mdc` directly.**

Cursor metadata (`globs`, `alwaysApply`) lives in `.claude/skills/<name>/.cursor.yaml`.

---

## Where to Look First

- Adding a feature? `feature-prompt`.
- API / Repository / UseCase pipeline? `api-pipeline` (Postman جاهز من فريق الباك إند).
- Form? `form-api-pipeline`.
- RTL? `rtl-arabic`.
- Review finished work? `post-feature-review`.
- Master coding-standards? `coding-standards` (entity safety + Strict Six Rules + slivers + part-of system + pointers to subdomain skills)
- BLoC / AsyncCubit / AsyncBlocBuilder? `bloc-patterns`
- FCM Notifications (NotificationManager + Router + Controller)? `notifications`
- Performance (ValueNotifier-first, no setState, const, slivers, compute)? `performance-and-memory`
- Extensions/helpers? `coding-standards` (section 12 + 13)
- Naming + cleanup? `clean-code-and-refactoring`
- Widget catalog? `flutter-patterns` (Key Widget Quick Reference) + `coding-standards` (section 11)
- ViewController (`presentation/controllers/`)? `flutter-patterns` + `coding-standards` (section 22)
- Localization? `coding-standards` (section 8) + `rtl-arabic`
