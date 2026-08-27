---
name: di-and-architecture
description: Keep DI usage and high-level layering consistent in Flutter_Base.
---

# Skill: DI & Architecture — Flutter_Base

## When to Use

- عند إضافة Cubit جديد، UseCase، أو Repository.
- عند ملاحظة إنشاء يدوي لـ services داخل الـ UI.

## What to Do

### 1. Service Locator — `injector<T>()`

```dart
// ✅ CORRECT — inside screen
return BlocProvider(
  create: (_) => injector<MyFeatureCubit>()..fetchItems(),
  child: const _MyFeatureBody(),
);

// ❌ WRONG — manual construction
final cubit = MyFeatureCubit(MyRepo(Dio()));
```

- استخدم `injector<T>()` فقط — لا تستخدم `GetIt.instance` مباشرة.
- لا تنشئ instances يدوياً لـ repositories / useCases في الـ UI.

### 2. Injectable + build_runner

```dart
@injectable
class GetOrdersCubit extends AsyncCubit<List<OrderEntity>> {
  GetOrdersCubit(this._useCase) : super([]);
  final GetOrdersUseCase _useCase;
}
```

بعد إضافة أي Cubit أو UseCase:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Layers Responsibility

| Layer | مسؤول عن | يتعامل مع |
|-------|---------|-----------|
| **Presentation** | Widgets + Cubits | `Entity` فقط — لا يعرف Dio/HTTP |
| **Domain** | UseCases + Repository interfaces + Entities | Business logic |
| **Data** | RemoteDatasource + DTOs + Dio | API calls مباشرة |

**قواعد صارمة:**
- أي كلاس فيه `Dio` أو `http.get` → لازم يكون في data layer فقط
- أي كلاس فيه `BuildContext` → لازم يكون في presentation فقط

### 4. Endpoints — `ApiEndpoints` فقط

```dart
// ✅ CORRECT
api: ApiEndpoints.products,

// ❌ WRONG — hardcoded string
api: '/api/v1/products',
```

كل الـ endpoints في `core/network/api_endpoints.dart`.

### 5. Where to Put What

| الملف | المكان |
|-------|--------|
| Cubits | `features/{name}/presentation/cubits/` |
| Entities | `features/{name}/entity/` |
| Endpoints | `core/network/api_endpoints.dart` (ApiConstants) |
| Shared requests/responses | `core/base_crud` أو `core/network` |
| Service locator | `core/shared/service_locators/` |

### Checklist

- [ ] كل Cubit/UseCase جديد معلّم بـ `@injectable`
- [ ] كل Screen تستخدم `injector<MyCubit>()` داخل `BlocProvider`
- [ ] لا يوجد constructor manual لـ repos/usecases في UI
- [ ] HTTP/Dio غير مستخدم في presentation
- [ ] `ApiEndpoints` هو المصدر الوحيد للـ endpoints
- [ ] تم تشغيل `build_runner` بعد إضافة injectable جديد

## Output

بعد تشغيل هذا الـ skill:
- لخّص أي Cubits تم تعديلها لتستخدم `injector`.
- أماكن تم نقل `Dio` منها إلى data layer.
- أي endpoints تم نقلها لـ `ApiEndpoints`.
