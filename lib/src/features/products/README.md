# Products — reference feature

> **This is the canonical example. Copy this structure for every new feature.**
> If something here disagrees with your habit, the example wins.

It deliberately exercises the whole stack so you can see each rule applied:

| Concern | Where to look |
| --- | --- |
| Clean layering (data / domain / presentation) | the folder tree below |
| `BaseRemoteSource.request<T>()` calls | `data/datasources/` |
| Model ↔ Entity mapping | `data/mappers/`, `data/models/` |
| Safe enum parsing (`fromRaw`) | `domain/enums/product_status.dart` |
| `AsyncCubit` + optimistic CRUD | `presentation/cubits/products_cubit.dart` |
| `AsyncBlocBuilder` (loading/error/empty) | `presentation/widgets/products_body.dart` |
| Debounced search (rxdart) | `presentation/view/products_screen.dart` |
| `ViewController` for non-bloc UI state | `presentation/controllers/` |
| `part`/`part of` presentation hub | `presentation/imports/products_imports.dart` |

## The rules this feature follows (and you must too)

- **No hardcoded strings** — everything goes through `LocaleKeys.*`.
- **No `Icons.*` / `Image.network`** — use `IconWidget` (+ `AppAssets`) and
  `CachedImage`.
- **No `Navigator.*` / `ScaffoldMessenger.*`** — use `Go.*` and
  `MessageUtils.showSnackBar`.
- **No raw `Color()` / `SizedBox(n)` / `EdgeInsets`/`Padding`** — use
  `AppColors`, the `.szH`/`.szW` and `.padding*` extensions, and `AppSize` /
  `AppPadding` / `AppCircular` tokens.
- **No `Theme.of(context).textTheme`** — use the `TextStyle` extension chain
  (`const TextStyle().setMainTextColor.s14.semiBold`).
- **Screens are compose-only** — no methods beyond `build`/`initState`/
  `dispose`; push interaction logic into the `ViewController`.
- **Money is formatted** — `price.toCurrency()` + `LocaleKeys.productsCurrency`.

## Structure

```
products/
├── data/        datasources (extend BaseRemoteSource) · models · mappers · repositories
├── domain/      entities · enums · repositories (abstract) · usecases
└── presentation/
    ├── imports/      products_imports.dart  ← library + all part directives
    ├── view/         ProductsScreen · ProductDetailsScreen (public, provide cubits)
    ├── widgets/      private body/card/sheet/dialog/search widgets
    ├── controllers/  ProductsViewController (TextEditingController, filters, scroll)
    └── cubits/        ProductsCubit · ProductDetailsCubit
```

Need a new feature scaffold fast? Run `./scripts/new_feature.sh <name>`.
