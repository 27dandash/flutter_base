<div dir="rtl" markdown="1">

# 📚 EXAMPLES — استخدام الـ Network Layer مع Clean Architecture + Cubit

> دليل عملي بـ 14 سيناريو كامل. كل سيناريو فيه: الـ files بكاملها، شرح القرارات، والـ UI المربوط.

---

## فهرس

1. [الـ Folder Structure](#1-الـ-folder-structure)
2. [Bootstrap التطبيق (main.dart + Providers)](#2-bootstrap-التطبيق)
3. [Base classes: `AsyncState` / `AsyncCubit` / `AsyncBlocBuilder`](#3-base-classes)
4. [**Scenario 1** — GET single (Profile)](#scenario-1--get-single)
5. [**Scenario 2** — GET list مع pagination](#scenario-2--get-list-مع-pagination)
6. [**Scenario 3** — POST (Create) مع offline queue](#scenario-3--post-create-مع-offline-queue)
7. [**Scenario 4** — PUT (Edit) + local update بدون re-fetch](#scenario-4--put-edit--local-update)
8. [**Scenario 5** — DELETE + confirmation + local remove](#scenario-5--delete--confirmation)
9. [**Scenario 6** — Search field بـ debounce + cancel](#scenario-6--search-field)
10. [**Scenario 7** — Form submission + validation errors (422)](#scenario-7--form--validation-errors)
11. [**Scenario 8** — Login + حفظ token](#scenario-8--login)
12. [**Scenario 9** — Logout + `cancelAll`](#scenario-9--logout)
13. [**Scenario 10** — File upload + progress](#scenario-10--file-upload)
14. [**Scenario 11** — Pull-to-refresh + Retry](#scenario-11--pull-to-refresh--retry)
15. [**Scenario 12** — `BlocListener` للـ navigation + snackbar](#scenario-12--bloclistener)
16. [**Scenario 13** — Offline-first read (Cache fallback)](#scenario-13--offline-first-read)
17. [**Scenario 14** — Connectivity-aware UI](#scenario-14--connectivity-aware-ui)
18. [Error handling matrix](#18-error-handling-matrix)
19. [القواعد اللي مينفعش تكسرها](#19-القواعد-اللي-مينفعش-تكسرها)

---

## 1. الـ Folder Structure

كل feature في فولدر مستقل، Clean Architecture بـ 3 layers (data / domain / presentation):

```
lib/
├─ core/                              ← shared infra (مش feature-specific)
│  ├─ network/                        ← الـ network layer كاملة (شفت GUIDE)
│  └─ state/
│     ├─ async_state.dart             ← AsyncState<T> sealed
│     ├─ async_cubit.dart             ← AsyncCubit<T> base
│     └─ async_bloc_builder.dart      ← AsyncBlocBuilder<C, T>
│
└─ features/
   └─ products/                       ← مثال feature
      ├─ data/
      │  ├─ models/
      │  │  └─ product_model.dart         ← DTO (fromJson/toJson)
      │  ├─ datasources/
      │  │  └─ product_remote_source.dart ← extends BaseRemoteSource
      │  └─ repositories/
      │     └─ product_repository_impl.dart
      ├─ domain/
      │  ├─ entities/
      │  │  └─ product.dart                ← pure entity (مفيش JSON)
      │  ├─ repositories/
      │  │  └─ product_repository.dart     ← abstract interface
      │  └─ usecases/
      │     ├─ get_products_usecase.dart
      │     ├─ add_product_usecase.dart
      │     └─ ...
      └─ presentation/
         ├─ cubits/
         │  ├─ products_cubit.dart         ← extends AsyncCubit<List<Product>>
         │  └─ add_product_cubit.dart      ← extends AsyncCubit<Product>
         └─ screens/
            ├─ products_screen.dart
            └─ add_product_screen.dart
```

### ليه الـ 3 layers؟
- **`data/`** = JSON + API + serialization. لو الـ backend غير شكل الـ JSON، تعدل هنا بس.
- **`domain/`** = البزنس. مفيش `dart:io`، مفيش JSON. ينفع تستخدمه في مشروع Flutter web أو CLI.
- **`presentation/`** = الـ UI + Cubits.

### الـ data flow
```
UI → Cubit → UseCase → Repository (interface) → RepositoryImpl → RemoteSource → Dio
                                                     ↑
                                          (data layer wires here)
```

---

## 2. Bootstrap التطبيق

### `main.dart` — مع كل الـ providers على مستوى الـ app

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/network/cache/cache_config.dart';
import 'core/network/cubits/connectivity_cubit.dart';
import 'core/network/cubits/offline_queue_cubit.dart';
import 'core/network/network_info.dart';
import 'core/network/offline/offline_queue_manager.dart';
import 'presentation/widgets/offline_sync_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await CacheConfig.init();
  await OfflineQueueManager().init();
  await NetworkInfo().check();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConnectivityCubit(), lazy: false),
        BlocProvider(create: (_) => OfflineQueueCubit(), lazy: false),
      ],
      child: MaterialApp(
        title: 'App',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Column(
          children: [
            const OfflineSyncBanner(),       // ← يستخدم الـ 2 cubits اللي فوق
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

> **`lazy: false`** = الـ cubit يتـ initialize فوراً مش لما حد يطلبه. مهم للـ ConnectivityCubit عشان يبدأ يـ listen قبل ما الـ user يفتح أول screen.

---

## 3. Base classes

### `AsyncState<T>` (موجود في `core/state/async_state.dart`)

4 states بس:
```dart
sealed class AsyncState<T> {}
final class AsyncInitial<T>  extends AsyncState<T> {}
final class AsyncLoading<T>  extends AsyncState<T> { final T? previous; }
final class AsyncSuccess<T>  extends AsyncState<T> { final T data; }
final class AsyncFailure<T>  extends AsyncState<T> { final AppException exception; final T? previous; }
```

**ليه `previous` في Loading و Failure؟**
> لو عندك list فيها 50 منتج، وعملت refresh، المستخدم مش لازم يشوف spinner ويفقد الـ list. بنخزن آخر نسخة وبنفضل نعرضها مع overlay صغير.

### `AsyncCubit<T>` (موجود في `core/state/async_cubit.dart`)

```dart
abstract class AsyncCubit<T> extends Cubit<AsyncState<T>> {
  AsyncCubit() : super(const AsyncInitial());

  Future<void> execute(Future<ApiResult<T>> Function() call) async { /* ... */ }
  void setData(T data);          // ← local update (بدل re-fetch)
  void setFailure(AppException e);
}
```

### `AsyncBlocBuilder<C, T>` (موجود في `core/state/async_bloc_builder.dart`)

```dart
AsyncBlocBuilder<ProductsCubit, List<Product>>(
  builder: (ctx, products) => ListView(...),
  onRetry: () => ctx.read<ProductsCubit>().fetch(),
);
```
- بيـ map الـ 4 states تلقائياً.
- لو عنده `previous` بيرنده بدل الـ spinner/error.

---

## Scenario 1 — GET single

**الـ goal:** نجيب profile للـ user المسجل ونعرضه.

### الـ Domain — `lib/features/user/domain/entities/user.dart`
```dart
class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.empty() => const User(id: 0, name: '', email: '');
}
```

### الـ Domain — `lib/features/user/domain/repositories/user_repository.dart`
```dart
import '../../../../core/network/result/api_result.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<ApiResult<User>> me();
  Future<ApiResult<User>> updateProfile({required String name, required String email});
}
```

### الـ Data — `lib/features/user/data/models/user_model.dart`
```dart
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.id, required super.name, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}
```

### الـ Data — `lib/features/user/data/datasources/user_remote_source.dart`
```dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/base/base_remote_source.dart';
import '../../../../core/network/result/api_result.dart';
import '../models/user_model.dart';

class UserRemoteSource extends BaseRemoteSource {
  Future<ApiResult<UserModel>> me() {
    return safeApiCall<UserModel>(
      cancelKey: 'GET:${ApiEndpoints.me}',
      call: (token) => dio.get(ApiEndpoints.me, cancelToken: token),
      fromJson: (json) {
        final data = (json is Map ? json['data'] ?? json : {}) as Map<String, dynamic>;
        return UserModel.fromJson(data);
      },
    );
  }
}
```

### الـ Data — `lib/features/user/data/repositories/user_repository_impl.dart`
```dart
import '../../../../core/network/result/api_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remote);
  final UserRemoteSource _remote;

  @override
  Future<ApiResult<User>> me() async {
    final result = await _remote.me();
    // التحويل من ApiResult<UserModel> لـ ApiResult<User> — الـ Model بيرث من Entity فالـ cast مجاني.
    return result.when(
      success: (m) => ApiSuccess<User>(m),
      error: (e) => ApiError<User>(e),
    );
  }

  @override
  Future<ApiResult<User>> updateProfile({required String name, required String email}) {
    // ...
    throw UnimplementedError();
  }
}
```

### الـ Presentation — `lib/features/user/presentation/cubits/profile_cubit.dart`
```dart
import '../../../../core/state/async_cubit.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class ProfileCubit extends AsyncCubit<User> {
  ProfileCubit(this._repo);
  final UserRepository _repo;

  Future<void> fetch() => execute(_repo.me);
}
```

### الـ Presentation — `lib/features/user/presentation/screens/profile_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/state/async_bloc_builder.dart';
import '../../data/datasources/user_remote_source.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../cubits/profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        UserRepositoryImpl(UserRemoteSource()),
      )..fetch(),
      child: Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: AsyncBlocBuilder<ProfileCubit, User>(
          onRetry: () => context.read<ProfileCubit>().fetch(),
          builder: (ctx, user) => ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
        ),
      ),
    );
  }
}
```

> **في production** الـ `BlocProvider(create: ...)` ده هياخد instances من DI (مثلاً `get_it`/`injectable`)، مش manual.

---

## Scenario 2 — GET list مع pagination

**الـ goal:** نعرض list منتجات قابلة للتحميل أكتر (infinite scroll).

### State خاص للـ pagination
```dart
class PaginatedData<T> {
  final List<T> items;
  final int currentPage;
  final bool hasMore;

  const PaginatedData({
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = true,
  });

  PaginatedData<T> copyWith({List<T>? items, int? currentPage, bool? hasMore}) =>
      PaginatedData(
        items: items ?? this.items,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
      );
}
```

### الـ Cubit
```dart
class ProductsCubit extends AsyncCubit<PaginatedData<Product>> {
  ProductsCubit(this._source);
  final ProductRemoteSource _source;

  bool _loadingMore = false;

  Future<void> fetchFirstPage() async {
    await execute(() async {
      final res = await _source.list(page: 1);
      return res.when(
        success: (page) => ApiSuccess(
          PaginatedData(items: page.items, currentPage: 1, hasMore: page.hasMore),
        ),
        error: (e) => ApiError(e),
      );
    });
  }

  Future<void> loadMore() async {
    final s = state;
    if (s is! AsyncSuccess<PaginatedData<Product>>) return;
    if (!s.data.hasMore || _loadingMore) return;

    _loadingMore = true;
    try {
      final res = await _source.list(page: s.data.currentPage + 1);
      res.when(
        success: (page) => setData(s.data.copyWith(
          items: [...s.data.items, ...page.items],
          currentPage: s.data.currentPage + 1,
          hasMore: page.hasMore,
        )),
        error: setFailure,
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() => fetchFirstPage();
}
```

### الـ Screen
```dart
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<ProductsCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(ProductRemoteSource())..fetchFirstPage(),
      child: Scaffold(
        appBar: AppBar(title: const Text('المنتجات')),
        body: RefreshIndicator(
          onRefresh: () => context.read<ProductsCubit>().refresh(),
          child: AsyncBlocBuilder<ProductsCubit, PaginatedData<Product>>(
            builder: (ctx, page) => ListView.builder(
              controller: _scroll,
              itemCount: page.items.length + (page.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= page.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListTile(title: Text(page.items[i].name));
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Scenario 3 — POST (Create) مع offline queue

**الـ goal:** المستخدم يضيف منتج. لو offline → نحفظه في الـ queue وننفذه لما النت يرجع.

### Repository
```dart
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote, this._queue, this._network);
  final ProductRemoteSource _remote;
  final OfflineQueueManager _queue;
  final NetworkInfo _network;

  @override
  Future<ApiResult<Product>> create(Product p) async {
    if (_network.isOnline) {
      return _remote.create(p);
    }

    // offline: queue + optimistic UI
    await _queue.enqueue(
      endpoint: ApiEndpoints.products,
      method: 'POST',
      body: p.toJson(),
      localId: 'local_${DateTime.now().millisecondsSinceEpoch}',
    );

    // نرجع الـ product بشكل optimistic — الـ ID 0 لحد ما الـ server يرجع الـ ID الحقيقي
    return ApiSuccess(p);
  }
}
```

### Cubit
```dart
class AddProductCubit extends AsyncCubit<Product> {
  AddProductCubit(this._repo);
  final ProductRepository _repo;

  Future<void> submit(Product p) => execute(() => _repo.create(p));
}
```

### Screen + Form
```dart
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddProductCubit(/* repo */),
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة منتج')),
        body: BlocConsumer<AddProductCubit, AsyncState<Product>>(
          listener: (ctx, state) {
            if (state is AsyncSuccess<Product>) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('تم الحفظ')),
              );
              Navigator.pop(ctx, state.data);   // ← يرجع الـ product للـ list
            }
            if (state is AsyncFailure<Product>) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.exception.userMessage)),
              );
            }
          },
          builder: (ctx, state) {
            final loading = state is AsyncLoading<Product>;
            return Form(
              key: _form,
              child: Column(children: [
                TextFormField(controller: _name),
                TextFormField(controller: _price),
                FilledButton(
                  onPressed: loading ? null : () {
                    if (!_form.currentState!.validate()) return;
                    ctx.read<AddProductCubit>().submit(Product(
                      id: 0,
                      name: _name.text,
                      price: double.parse(_price.text),
                    ));
                  },
                  child: loading ? const CircularProgressIndicator() : const Text('حفظ'),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
```

> **`BlocConsumer`** = `BlocListener` + `BlocBuilder` في widget واحد. الـ listener للـ side effects (snackbar/navigation)، الـ builder للـ UI.

---

## Scenario 4 — PUT (Edit) + local update

**الـ goal:** المستخدم يعدل منتج موجود في الـ list. بعد النجاح، نـ update الـ list **محلياً** بدون re-fetch.

### الـ Cubit للـ list (نفس `ProductsCubit` من Scenario 2 + method جديدة)
```dart
class ProductsCubit extends AsyncCubit<PaginatedData<Product>> {
  // ... fetchFirstPage / loadMore زي ما هي

  /// تستدعى من screen التعديل بعد النجاح.
  void replaceLocal(Product updated) {
    final s = state;
    if (s is! AsyncSuccess<PaginatedData<Product>>) return;
    setData(s.data.copyWith(
      items: s.data.items.map((p) => p.id == updated.id ? updated : p).toList(),
    ));
  }
}
```

### Edit screen
```dart
class EditProductScreen extends StatelessWidget {
  const EditProductScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    // نمسك الـ ProductsCubit بتاع الـ screen السابقة عشان نـ update الـ list:
    final listCubit = context.read<ProductsCubit>();

    return BlocProvider(
      create: (_) => EditProductCubit(/* repo */),
      child: BlocListener<EditProductCubit, AsyncState<Product>>(
        listener: (ctx, state) {
          if (state is AsyncSuccess<Product>) {
            listCubit.replaceLocal(state.data);   // ← local update
            Navigator.pop(ctx);
          }
        },
        child: /* form widgets */ const SizedBox.shrink(),
      ),
    );
  }
}
```

> ❌ ممنوع تـ `fetchFirstPage()` بعد التعديل — ده هيمسح الـ pagination وهيـ rebuild كل حاجة.
> ✅ `replaceLocal()` بيغير عنصر واحد بس في الـ list.

---

## Scenario 5 — DELETE + confirmation

```dart
class ProductsCubit extends AsyncCubit<PaginatedData<Product>> {
  // ...

  Future<void> delete(int id) async {
    final s = state;
    if (s is! AsyncSuccess<PaginatedData<Product>>) return;

    // optimistic remove
    final backup = s.data;
    setData(s.data.copyWith(
      items: s.data.items.where((p) => p.id != id).toList(),
    ));

    final res = await _repo.delete(id);
    res.when(
      success: (_) {},          // الـ optimistic كان صح
      error: (e) {
        setData(backup);        // rollback
        setFailure(e);
      },
    );
  }
}
```

### الـ tap في الـ UI:
```dart
IconButton(
  icon: const Icon(Icons.delete),
  onPressed: () async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ProductsCubit>().delete(product.id);
    }
  },
),
```

---

## Scenario 6 — Search field

**الـ goal:** المستخدم بيكتب في search field، نعمل debounce 350ms، ونلغي الـ request السابق لو دخل جديد.

### الـ Cubit
```dart
import 'package:rxdart/rxdart.dart';

class ProductsSearchCubit extends AsyncCubit<List<Product>> {
  ProductsSearchCubit(this._source) {
    _query.debounceTime(const Duration(milliseconds: 350))
        .distinct()
        .listen(_runSearch);
  }
  final ProductRemoteSource _source;
  final _query = BehaviorSubject<String>.seeded('');

  void onQueryChanged(String q) => _query.add(q);

  Future<void> _runSearch(String q) async {
    if (q.trim().isEmpty) {
      setData(const []);
      return;
    }
    await execute(() async {
      // الـ cancelKey ثابت → الـ request القديم بيتلغى تلقائياً.
      final res = await _source.search(q);
      return res;
    });
  }

  @override
  Future<void> close() {
    _query.close();
    return super.close();
  }
}
```

### الـ RemoteSource
```dart
Future<ApiResult<List<Product>>> search(String q) {
  return safeApiCall<List<Product>>(
    cancelKey: 'GET:products:search',     // ← key ثابت = old request يتلغى
    call: (t) => dio.get(
      ApiEndpoints.products,
      queryParameters: {'search': q},
      cancelToken: t,
    ),
    fromJson: (j) => /* parse */ const [],
  );
}
```

### الـ UI
```dart
TextField(
  decoration: const InputDecoration(hintText: 'ابحث...'),
  onChanged: context.read<ProductsSearchCubit>().onQueryChanged,
);
```

> **ليه `BehaviorSubject` من rxdart؟** الـ `Stream` العادي عند add/listen مزعج. `BehaviorSubject` بيـ cache آخر قيمة + يـ broadcast.

---

## Scenario 7 — Form + Validation errors (422)

**الـ goal:** الـ server بيرجع 422 مع `{errors: {email: ['البريد مستخدم بالفعل']}}` ونعرض الـ errors تحت كل field.

### الـ Cubit
```dart
class RegisterCubit extends AsyncCubit<User> {
  RegisterCubit(this._repo);
  final AuthRepository _repo;

  Future<void> submit({required String name, required String email}) {
    return execute(() => _repo.register(name: name, email: email));
  }

  /// مستخرج من AsyncFailure للـ UI.
  Map<String, List<String>>? get fieldErrors {
    final s = state;
    if (s is AsyncFailure<User>) {
      final e = s.exception;
      if (e is UnprocessableException) return e.errors;
      if (e is ValidationException) return e.fields;
    }
    return null;
  }
}
```

### الـ TextField بـ error من الـ cubit
```dart
BlocBuilder<RegisterCubit, AsyncState<User>>(
  buildWhen: (a, b) => a.runtimeType != b.runtimeType,
  builder: (ctx, state) {
    final cubit = ctx.read<RegisterCubit>();
    final emailErrors = cubit.fieldErrors?['email'];
    return TextFormField(
      controller: _emailCtrl,
      decoration: InputDecoration(
        labelText: 'البريد الإلكتروني',
        errorText: emailErrors?.first,    // ← الـ error من الـ server
      ),
    );
  },
);
```

> الـ `Validators.validateEmail` بيـ check format محلياً، والـ server error بيـ check business rules (duplicate, blacklist, ...).

---

## Scenario 8 — Login

```dart
class LoginCubit extends AsyncCubit<User> {
  LoginCubit(this._repo);
  final AuthRepository _repo;

  Future<void> login(String email, String password) async {
    await execute(() async {
      final res = await _repo.login(email, password);
      return res.when(
        success: (auth) async {
          // 1. حفظ الـ tokens
          await TokenStorage.instance.save(
            access: auth.accessToken,
            refresh: auth.refreshToken,
          );
          // 2. ارجع الـ user للـ AsyncSuccess
          return ApiSuccess<User>(auth.user);
        },
        error: ApiError<User>.new,
      );
    });
  }
}
```

### الـ Listener في الـ UI
```dart
BlocListener<LoginCubit, AsyncState<User>>(
  listener: (ctx, state) {
    if (state is AsyncSuccess<User>) {
      Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
    if (state is AsyncFailure<User>) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(state.exception.userMessage)),
      );
    }
  },
  child: /* form */ const SizedBox.shrink(),
);
```

---

## Scenario 9 — Logout

```dart
Future<void> logout(BuildContext context) async {
  // 1. لغي كل الـ in-flight requests
  RequestCancellationManager().cancelAll('logout');

  // 2. امسح الـ tokens
  await TokenStorage.instance.clear();

  // 3. امسح الـ offline queue (اختياري — لو الـ user مش هيرجع بنفس الحساب)
  // await OfflineQueueManager().clearAll();

  // 4. navigate
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}
```

---

## Scenario 10 — File upload

### Remote source
```dart
class FileRemoteSource extends BaseRemoteSource {
  Future<ApiResult<String>> upload(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) {
    return safeApiCall<String>(
      cancelKey: 'POST:upload:$filePath',
      call: (token) async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        });
        return dio.post(
          '${ApiEndpoints.apiV1}/upload',
          data: form,
          cancelToken: token,
          onSendProgress: onProgress,
          options: Options(
            sendTimeout: const Duration(seconds: 60),    // override أكبر للملفات
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
      },
      fromJson: (json) => (json as Map)['url'] as String,
    );
  }
}
```

### Cubit + progress
```dart
class UploadCubit extends AsyncCubit<String> {
  UploadCubit(this._source);
  final FileRemoteSource _source;

  final ValueNotifier<double> progress = ValueNotifier(0);

  Future<void> upload(String path) => execute(() async {
    progress.value = 0;
    return _source.upload(path, onProgress: (sent, total) {
      if (total > 0) progress.value = sent / total;
    });
  });

  @override
  Future<void> close() {
    progress.dispose();
    return super.close();
  }
}
```

### UI
```dart
ValueListenableBuilder<double>(
  valueListenable: context.read<UploadCubit>().progress,
  builder: (_, value, __) => LinearProgressIndicator(value: value),
);
```

---

## Scenario 11 — Pull-to-refresh + Retry

```dart
return RefreshIndicator(
  onRefresh: () => context.read<ProductsCubit>().refresh(),
  child: AsyncBlocBuilder<ProductsCubit, PaginatedData<Product>>(
    onRetry: () => context.read<ProductsCubit>().fetchFirstPage(),
    builder: (ctx, page) => ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),   // ← لازم للـ refresh على list فاضية
      itemCount: page.items.length,
      itemBuilder: (_, i) => ListTile(title: Text(page.items[i].name)),
    ),
  ),
);
```

> الـ `AsyncBlocBuilder` بيـ pass الـ `onRetry` للـ `AppErrorHandler`. الـ button بيظهر بس للـ exceptions اللي `retryable == true` (network/5xx/timeout).

---

## Scenario 12 — `BlocListener`

استخدم `BlocListener` للـ **side effects** (مرة واحدة) مش للـ UI:

| المهمة | الأداة |
|---|---|
| رسم state على الشاشة | `BlocBuilder` / `AsyncBlocBuilder` |
| Navigation بعد success | `BlocListener` |
| SnackBar / Toast | `BlocListener` |
| Dialog | `BlocListener` |
| State + side effect | `BlocConsumer` |

**القاعدة:** `BlocListener` listener بيشتغل **مرة واحدة** لكل state change — مثالي للـ navigation.

```dart
BlocListener<DeleteAccountCubit, AsyncState<void>>(
  listenWhen: (a, b) => a.runtimeType != b.runtimeType,
  listener: (ctx, state) {
    switch (state) {
      case AsyncSuccess():
        Navigator.pushNamedAndRemoveUntil(ctx, '/login', (_) => false);
      case AsyncFailure(:final exception):
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(exception.userMessage)),
        );
      case _:
        break;
    }
  },
  child: child,
);
```

---

## Scenario 13 — Offline-first read

الـ Cache interceptor بيـ fallback تلقائياً للـ cache لو الـ network فشل. لكن لو عايز قراءة **من الـ cache دايماً أولاً** ثم refresh:

```dart
Future<ApiResult<List<Product>>> list({CachePolicy? policy}) {
  return safeApiCall<List<Product>>(
    cancelKey: 'GET:products',
    call: (token) => dio.get(
      ApiEndpoints.products,
      cancelToken: token,
      options: Options(
        extra: {
          ...CacheOptions(
            store: CacheConfig.store,
            policy: policy ?? CachePolicy.forceCache,    // ← cache أولاً
            maxStale: const Duration(days: 7),
          ).toExtra(),
        },
      ),
    ),
    fromJson: (json) => /* parse */ const [],
  );
}
```

**Cache policies:**
- `forceCache` = cache فقط، لو مفيش cache → network.
- `refresh` = network فقط، تجاهل الـ cache.
- `refreshForceCache` = network، لو فشل → cache (الـ default بتاعنا).
- `noCache` = مفيش cache.

---

## Scenario 14 — Connectivity-aware UI

**الـ goal:** زر "إضافة" يكون disabled لو offline.

```dart
BlocBuilder<ConnectivityCubit, bool>(
  builder: (_, online) {
    return FilledButton(
      onPressed: online ? _onSubmit : null,
      child: Text(online ? 'حفظ' : 'لا يوجد اتصال'),
    );
  },
);
```

**أو لو عايز تـ allow الـ offline (queue):**
```dart
BlocBuilder<ConnectivityCubit, bool>(
  builder: (_, online) {
    return FilledButton(
      onPressed: _onSubmit,
      child: Text(online ? 'حفظ' : 'حفظ لاحقاً'),
    );
  },
);
```

**أو لو عايز screen كاملة تعرض حالة مختلفة:**
```dart
BlocSelector<ConnectivityCubit, bool, bool>(
  selector: (online) => online,
  builder: (_, online) {
    if (!online) return const _OfflineEmptyState();
    return const _ProductsList();
  },
);
```

> **`BlocSelector`** بيـ rebuild بس لو الـ selector value اتغير — أفضل من BlocBuilder لما عندك state معقد وعايز بس قطعة منه.

---

## 18. Error handling matrix

| الـ Exception | الـ UI المقترح | الـ Action |
|---|---|---|
| `NetworkException` | Banner + Retry button | إعادة المحاولة |
| `ConnectionTimeoutException` | Toast + Retry | إعادة المحاولة |
| `UnauthorizedException` | Redirect → login | `Navigator.pushReplacement(LoginScreen)` |
| `PermissionException` | Dialog | "ليس لديك صلاحية" + back |
| `ValidationException` | Inline field errors | عرض `fields` تحت كل field |
| `UnprocessableException` | Inline + Snackbar | عرض `errors` |
| `NotFoundException` | Empty state | "العنصر غير موجود" |
| `ConflictException` | Toast | "موجود بالفعل" |
| `RateLimitException` | Toast + disabled button + timer | wait `retryAfter` |
| `MaintenanceException` | Full screen | "الخدمة تحت الصيانة" |
| `InternalServerException` | Toast + Retry | إعادة المحاولة |
| `HtmlResponseException` | Generic error | log + report |
| `ParseException` | Generic error | log + report |
| `CancelledRequest` | **مفيش UI** | تجاهل تام |

### Template للتعامل
```dart
Widget _renderError(AppException e, VoidCallback onRetry) => switch (e) {
  CancelledRequest() => const SizedBox.shrink(),
  UnauthorizedException() => _navigateToLogin(),
  ValidationException() => _inlineFieldErrors(e.fields),
  UnprocessableException() => _inlineFieldErrors(e.errors),
  MaintenanceException() => _MaintenanceScreen(retryAfter: e.retryAfter),
  _ => AppErrorHandler(exception: e, onRetry: e.retryable ? onRetry : null),
};
```

---

## 19. القواعد اللي مينفعش تكسرها

### ✅ افعل
- **استخدم `AsyncBlocBuilder`** للـ data loading (مش `BlocBuilder` مباشر).
- **استخدم `setData()`** بعد الـ POST/PUT/DELETE للـ list (مش `fetchFirstPage()`).
- **استخدم `cancelKey` واحد للـ search field** عشان الـ requests القديمة تتلغى.
- **استخدم `BlocListener`** للـ navigation و snackbars.
- **استخدم `read<C>()`** في الـ callbacks، و `watch<C>()` بس في `build`.
- **اـ initialize الـ DioClient** مرة واحدة فقط — singleton.
- **استخدم `unawaited()`** لما تعمل fire-and-forget call.
- **استخدم `if (context.mounted)`** بعد أي `await` قبل ما تستخدم `context`.

### ❌ لا تفعل
- ❌ **لا تـ `throw` exception من الـ remote source** — كل حاجة `ApiResult`.
- ❌ **لا تعرض `e.toString()`** للمستخدم — بس `e.userMessage`.
- ❌ **لا تستخدم `BlocBuilder` للـ navigation** — استخدم `BlocListener`.
- ❌ **لا تستخدم `setState` في screens فيها cubit** — كل state يروح في الـ cubit.
- ❌ **لا تنادي `fetch()` بعد POST/PUT/DELETE** — استخدم local updates.
- ❌ **لا تـ rebuild الـ cubit في `build`** — استخدم `BlocProvider`.
- ❌ **لا تـ ignore `CancelledRequest`** بشكل غلط — لازم تتجاهلها صراحة في الـ listener.
- ❌ **لا تستخدم `StreamBuilder` على Stream من cubit/network** — لفها في `Cubit` واستخدم `BlocBuilder`.

---

## 20. Cheat-sheet

```dart
// 1. Cubit عام
class FooCubit extends AsyncCubit<Foo> {
  Future<void> fetch() => execute(() => repo.getFoo());
  void onLocalEdit(Foo f) => setData(f);
}

// 2. UI
BlocProvider(
  create: (_) => FooCubit(...)..fetch(),
  child: AsyncBlocBuilder<FooCubit, Foo>(
    onRetry: () => context.read<FooCubit>().fetch(),
    builder: (ctx, foo) => Text(foo.name),
  ),
);

// 3. Mutation
context.read<FooCubit>().execute(() => repo.update(foo));

// 4. Local list update بعد success
listCubit.setData(currentList.copyWith(
  items: currentList.items.map((e) => e.id == updated.id ? updated : e).toList(),
));

// 5. Side effects (snackbar/nav)
BlocListener<FooCubit, AsyncState<Foo>>(
  listenWhen: (a, b) => a.runtimeType != b.runtimeType,
  listener: (ctx, state) {
    if (state is AsyncSuccess<Foo>) Navigator.pop(ctx);
    if (state is AsyncFailure<Foo>) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(state.exception.userMessage)),
      );
    }
  },
  child: child,
);
```

---

✅ **خلاص — Network Layer + Clean Arch + Cubit شغّالين معاه. كل feature جديد بياخد نفس الـ pattern: Entity → Model → RemoteSource → Repository → Cubit → Screen.**

</div>
