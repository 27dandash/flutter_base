<div dir="rtl" markdown="1">

# 📘 شرح تفصيلي للـ Network Layer

> دليل شامل لكل ملف في `lib/core/network/` و الملفات المرتبطة بيها.
> مكتوب للمبتدئ والـ senior — كل keyword مشروحة لما تظهر أول مرة، وكل قرار design ليه سبب موضح.

---

## فهرس

1. [مقدمة عامة](#1-مقدمة-عامة)
2. [مفاهيم Dart 3 المستخدمة](#2-مفاهيم-dart-3-المستخدمة)
3. [Phase 1 — Foundation](#3-phase-1--foundation)
   - [api_result.dart](#31-api_resultdart)
   - [app_exception.dart](#32-app_exceptiondart)
   - [api_endpoints.dart](#33-api_endpointsdart)
4. [Phase 2 — Parser & Status](#4-phase-2--parser--status)
   - [status_code_handler.dart](#41-status_code_handlerdart)
   - [response_parser.dart](#42-response_parserdart)
5. [Phase 3 — Dio Client & Interceptors](#5-phase-3--dio-client--interceptors)
   - [token_storage.dart](#51-token_storagedart)
   - [cache_config.dart](#52-cache_configdart)
   - [auth_interceptor.dart](#53-auth_interceptordart)
   - [retry_interceptor.dart](#54-retry_interceptordart)
   - [cache_interceptor.dart](#55-cache_interceptordart)
   - [logging_interceptor.dart](#56-logging_interceptordart)
   - [dio_client.dart](#57-dio_clientdart)
6. [Phase 4 — Cancel + Offline + Base](#6-phase-4--cancel--offline--base)
   - [request_cancellation_manager.dart](#61-request_cancellation_managerdart)
   - [network_info.dart](#62-network_infodart)
   - [queued_operation.dart](#63-queued_operationdart)
   - [queued_operation.g.dart](#64-queued_operationgdart)
   - [offline_queue_manager.dart](#65-offline_queue_managerdart)
   - [base_remote_source.dart](#66-base_remote_sourcedart)
7. [Phase 5 — UI + Example](#7-phase-5--ui--example)
   - [app_error_handler.dart](#71-app_error_handlerdart)
   - [offline_sync_banner.dart](#72-offline_sync_bannerdart)
   - [user_remote_source.dart](#73-user_remote_sourcedart)
   - [main.dart](#74-maindart)
8. [Flow كامل لـ Request](#8-flow-كامل-لـ-request)
9. [Cheat-sheet: استخدامات سريعة](#9-cheat-sheet)

---

## 1. مقدمة عامة

الـ Network Layer ده **طبقة شبكة production-ready** بتـ handle كل حاجة بين الـ UI والـ backend. لو فكرت في الكود زي بصلة (onion):

```
┌─────────────────────────────────────────────────┐
│  UI Widgets  (Buttons, Lists, Forms)           │
├─────────────────────────────────────────────────┤
│  BLoC / Cubit  (state management)              │
├─────────────────────────────────────────────────┤
│  Repository  (business logic)                  │
├─────────────────────────────────────────────────┤
│  RemoteSource (extends BaseRemoteSource)       │ ← أنت هنا
├─────────────────────────────────────────────────┤
│  Dio + 4 Interceptors                          │
├─────────────────────────────────────────────────┤
│   Auth │ Retry │ Cache │ Logger                │
├─────────────────────────────────────────────────┤
│  Network (HTTP)                                │
└─────────────────────────────────────────────────┘
```

**القواعد الذهبية:**
- ✅ المستخدم **مايشوفش** أي رسالة تقنية — كل error بتترجم لـ `userMessage` عربي.
- ✅ كل request له `cancelKey` عشان نلغي القديم لو دخل جديد.
- ✅ الـ Add/Update/Delete وانت offline → بتتحفظ في Hive وتتنفذ لما النت يرجع.
- ✅ مفيش `throw` في الكود — بنرجع `ApiResult<T>` ودي إما success أو error.

---

## 2. مفاهيم Dart 3 المستخدمة

قبل ما تدخل الكود، خلّيني أشرحلك الـ keywords الجديدة في Dart 3 اللي بستخدمها كتير:

### 🔹 `sealed class`
```dart
sealed class Animal {}
final class Dog extends Animal {}
final class Cat extends Animal {}
```
- **يعني إيه؟** `sealed` بتقفل الـ class — مفيش حد يقدر يـ extend منه إلا في نفس الملف.
- **ليه نستخدمها؟** عشان الـ compiler **يجبرك** تتعامل مع كل الـ subclasses في الـ `switch`. لو نسيت واحد، الكود مايـ compile-ش.

### 🔹 `final class`
- **يعني إيه؟** الـ class مايقدرش حد يـ extend منها (لا في نفس الملف ولا برّه).
- **ليه؟** بتمنع inheritance غلط. لو عندك `ApiSuccess`، مفيش `MySuccess extends ApiSuccess` — هتكون `ApiSuccess` بس.

### 🔹 Switch expression
```dart
// الطريقة القديمة:
String label;
switch (status) {
  case 200: label = 'OK'; break;
  case 404: label = 'Not Found'; break;
  default: label = 'Other';
}

// Dart 3 — switch as expression:
final label = switch (status) {
  200 => 'OK',
  404 => 'Not Found',
  _ => 'Other',
};
```
- **`=>`** يعني "ارجع القيمة دي".
- **`_`** يعني "أي حاجة تانية" (wildcard).
- بترجع قيمة واحدة بدل ما تـ assign.

### 🔹 Pattern matching
```dart
final result = ApiSuccess<int>(42);
final value = switch (result) {
  ApiSuccess(:final data) => data,        // فك الـ object واخد .data
  ApiError(:final exception) => -1,
};
```
- **`:final data`** بيقول: "خد الـ field اسمه `data` وحطه في متغير اسمه `data`".
- ده شبه الـ destructuring في JavaScript.

### 🔹 `late final`
```dart
late final Dio _dio;
```
- **`final`** يعني مرة واحدة بس أقدر أحدد قيمته.
- **`late`** يعني هحدد قيمته بعدين (مش في الـ declaration).
- نستخدمها مع الـ singletons اللي بتـ initialize في الـ constructor.

### 🔹 `?` و `??` و `?.`
- **`String?`** = ممكن تكون null.
- **`x ?? 'default'`** = لو `x` null، استخدم `'default'`.
- **`x?.length`** = لو `x` null، رجّع null؛ غير كده اعمل `.length`.

### 🔹 `unawaited(...)`
```dart
unawaited(_processQueue());
```
- **يعني إيه؟** "أنا عارف إن دي async، بس مش هـ await — كمّل."
- بنستخدمها لما نريد نشغّل حاجة في الـ background ومانـ block-ش الـ caller.

---

## 3. Phase 1 — Foundation

الأساس اللي كل حاجة هتركب عليه. تلات ملفات بس، لكن كل الكود بيرجع لهم.

### 3.1 `api_result.dart`

📁 `lib/core/network/result/api_result.dart`

**الهدف:** بدل ما الكود يـ `throw` exceptions ويسيب الـ caller يـ `try/catch`، كل API call بترجع `ApiResult<T>` — إما `ApiSuccess` أو `ApiError`.

**ليه ده مهم؟** الـ exceptions في Dart مش in the type — يعني الـ compiler مش بيجبرك تـ catch. لو نسيت، الـ app هيـ crash. مع `ApiResult` الـ compiler نفسه بيجبرك تتعامل مع الحالتين.

```dart
sealed class ApiResult<T> {                   // sealed = الـ compiler هيـ track كل الـ subclasses
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>; // is = type check
  bool get isError => this is ApiError<T>;
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;                               // البيانات الراجعة
  const ApiSuccess(this.data);
}

final class ApiError<T> extends ApiResult<T> {
  final AppException exception;                // الخطأ المترجم لرسالة عربية
  const ApiError(this.exception);
}
```

**الـ helpers اللي ضفتهم:**
- `dataOrNull` — يرجع البيانات لو success وإلا `null`.
- `errorOrNull` — العكس.
- `when({success:, error:})` — أحلى طريقة للتعامل، lambda لكل حالة.

**مثال استخدام:**
```dart
final ApiResult<User> result = await userSource.me();
result.when(
  success: (user) => print('Hi ${user.name}'),
  error: (e) => print(e.userMessage),
);
```

---

### 3.2 `app_exception.dart`

📁 `lib/core/network/exceptions/app_exception.dart`

**الهدف:** الـ exceptions كلها — sealed hierarchy فيها 18 type — وكل واحدة فيها:
- `userMessage` — رسالة عربية فاهمة للمستخدم.
- `technicalInfo` — تفاصيل تقنية للـ logging (مش بتظهر للمستخدم).
- `statusCode` — HTTP status لو فيه.
- `retryable` — هل المستخدم يقدر يضغط "إعادة المحاولة"؟

```dart
sealed class AppException implements Exception {
  final String userMessage;
  final String? technicalInfo;
  final int? statusCode;
  final bool retryable;
  // ...
}
```

**`implements Exception`** — Dart بيعتبر أي كلاس بتـ implements `Exception` exception. ده بيخلي الـ `throw` و `catch` يشتغلوا معاه (لو احتجنا).

**الـ 18 type:**

| الـ Exception | متى تظهر؟ | retryable |
|---|---|---|
| `NetworkException` | مفيش نت | ✅ |
| `ConnectionTimeoutException` | الـ connect طول > 15s | ✅ |
| `SendTimeoutException` | الـ upload طول | ✅ |
| `ReceiveTimeoutException` | الـ server بطيء | ✅ |
| `BadCertificateException` | SSL fail | ❌ |
| `UnauthorizedException` | 401 | ❌ |
| `PermissionException` | 403 | ❌ |
| `ValidationException` | 400 + fields | ❌ |
| `UnprocessableException` | 422 + errors | ❌ |
| `NotFoundException` | 404 | ❌ |
| `ConflictException` | 409 | ❌ |
| `RateLimitException` | 429 + retryAfter | ✅ |
| `PayloadTooLargeException` | 413 | ❌ |
| `InternalServerException` | 500 | ✅ |
| `BadGatewayException` | 502 | ✅ |
| `MaintenanceException` | 503 + retryAfter | ✅ |
| `GatewayTimeoutException` | 504 | ✅ |
| `ServerException` | غير معروف | ❌ |
| `HtmlResponseException` | الـ server رجّع HTML بدل JSON | ❌ |
| `ParseException` | الـ JSON متكسر | ❌ |
| `CancelledRequest` | المستخدم/الكود لغّى الـ request | ❌ |
| `UnknownException` | حاجة تانية | ❌ |

**Keyword pause — `super(...)`:**
```dart
const NetworkException([String? tech])
    : super(userMessage: 'لا يوجد اتصال...', technicalInfo: tech, retryable: true);
```
- **`super(...)`** بتنادي الـ constructor بتاع الـ parent class (`AppException`).
- **`[String? tech]`** الـ `[...]` يعني optional positional parameter (اختياري بدون اسم).

---

### 3.3 `api_endpoints.dart`

📁 `lib/core/network/api_endpoints.dart`

**الهدف:** كل الـ URLs في مكان واحد. مفيش string في الكود `dio.get('/api/users')` — لازم `dio.get(ApiEndpoints.users)`.

```dart
class ApiEndpoints {
  ApiEndpoints._();                          // private constructor — مفيش instance
  static const String baseUrl = 'https://...';
  static const String users = '$apiV1/users';
  static String userById(int id) => '$apiV1/users/$id';
}
```

**`ApiEndpoints._()`** — الـ `_()` يعني private constructor. ده بيمنع أي حد يعمل `ApiEndpoints()`. الكلاس **utility class** بس، كل حاجة فيها `static`.

**ليه `static const`؟**
- **`const`** = compile-time constant — Dart بيـ allocate القيمة دي مرة واحدة بس في الـ memory.
- **`static`** = تابعة للكلاس مش للـ instance.

---

## 4. Phase 2 — Parser & Status

ده اللي بيخلي الـ response من الـ server (مهما كان شكله) يتحول لـ `ApiResult<T>` نظيف.

### 4.1 `status_code_handler.dart`

📁 `lib/core/network/parser/status_code_handler.dart`

**الهدف:** ياخد `statusCode` (مثلاً 404) و `responseData` ويرجع `AppException` مناسبة.

```dart
static AppException handle({required int statusCode, dynamic responseData}) {
  final serverMsg = _extractMessage(responseData);
  return switch (statusCode) {
    400 => ValidationException(serverMsg, fields: _extractValidationFields(responseData)),
    401 => const UnauthorizedException(),
    // ... باقي الـ codes
    _   => ServerException(serverMsg, statusCode: statusCode),
  };
}
```

**`{required int statusCode, dynamic responseData}`**
- الـ `{...}` = named parameters (لازم تكتب الاسم لما تنادي).
- **`required`** = لازم تبعتها، مش optional.
- **`dynamic`** = أي type (Dart مش هيـ enforce). بنستخدمها هنا لأن الـ response ممكن يكون Map أو List أو String.

**`_extractMessage()`** بتجرّب 7 keys معروفين (`message`, `error`, `detail`, ...) عشان معظم الـ APIs مش standardized. لو لقت string فيه قيمة، بترجعها.

**`_extractValidationFields()`** — لما الـ server بيرجع `{"errors": {"email": ["required"]}}` بنحوّلها لـ `Map<String, List<String>>` نقدر نعرضها على الـ fields في الـ form.

**`_extractRetryAfter()`** — لو الـ server بيقول "ارجع تاني بعد 30 ثانية"، بناخد الرقم ده.

---

### 4.2 `response_parser.dart`

📁 `lib/core/network/parser/response_parser.dart`

**الهدف:** يـ parse أي شكل response جاي من الـ server. ده **الجزء الأهم** عشان الـ backend بيرجع أحياناً HTML، أحياناً plain text، أحياناً Content-Type غلط.

**الميثود الرئيسية:**

#### `parse<T>(response, fromJson)`
1. ياخد الـ `response.data` ويـ decode بأمان.
2. لو شاف HTML → `HtmlResponseException` (المستخدم ميشوفش HTML).
3. لو الـ status بين 200-299:
   - لو 204 أو body فاضي → success بـ data فاضي.
   - غير كده → يـ call `fromJson(data)`.
4. غير كده → `StatusCodeHandler.handle()`.

#### `parseDioError(DioException e)`
بياخد الـ DioException ويرجع `AppException`.

```dart
return switch (e.type) {
  DioExceptionType.connectionTimeout => ConnectionTimeoutException(e.message),
  DioExceptionType.sendTimeout       => SendTimeoutException(e.message),
  DioExceptionType.receiveTimeout    => ReceiveTimeoutException(e.message),
  DioExceptionType.badCertificate    => BadCertificateException(e.message),
  DioExceptionType.cancel            => const CancelledRequest(),
  // ...
};
```

**`DioExceptionType`** هو enum من dio فيه كل أنواع الأخطاء اللي ممكن تحصل (timeout, cancel, SSL، إلخ).

#### `_looksLikeHtml(data)`
بتـ check لو الـ string بيبدأ بـ `<!doctype html` أو فيه `<html`. ده بيحصل لما nginx بيـ crash والـ server بيرجع error page بدل JSON.

#### `_safeDecode(raw)`
- لو الـ raw `Map` أو `List` → رجعها زي ما هي.
- لو `String` → جرّب `jsonDecode`. لو فشل، اعتبرها رسالة plain text: `{'message': text}`.
- لو فاضي → `null`.

**Keyword pause — `jsonDecode`:**
```dart
import 'dart:convert';
final map = jsonDecode('{"name": "Ali"}');  // → Map
```
بتحوّل JSON string لـ Map/List/etc.

**Keyword pause — `dart:io` و `SocketException`:**
```dart
import 'dart:io';
// SocketException = خطأ شبكة فعلي (الـ device مش متصل)
```

---

## 5. Phase 3 — Dio Client & Interceptors

### 5.1 `token_storage.dart`

📁 `lib/core/network/auth/token_storage.dart`

**الهدف:** يحفظ الـ access و refresh tokens. النسخة دي **in-memory** — يعني لما الـ app يقفل، الـ tokens بتروح. في production لازم تبدّلها بـ `flutter_secure_storage` أو Hive.

```dart
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();
}
```

**Singleton pattern:**
- `TokenStorage._()` = constructor private (مفيش `TokenStorage()`).
- `static final instance` = نسخة واحدة بس في الـ app كله.
- **ليه؟** عشان مايبقاش عندي tokens مختلفة في كذا instance.

---

### 5.2 `cache_config.dart`

📁 `lib/core/network/cache/cache_config.dart`

**الهدف:** يـ setup الـ Hive store اللي هيخزن فيه الـ Dio responses (للـ GET requests).

```dart
static Future<void> init() async {
  final dir = await getApplicationDocumentsDirectory();
  _store = HiveCacheStore(dir.path, hiveBoxName: storeBoxName);
}
```

**`getApplicationDocumentsDirectory()`** من package `path_provider`. بترجع مكان فولدر بياخده الـ OS للـ app data (في iOS: Documents/، في Android: /data/data/.../files/).

**`CacheOptions`:**
```dart
CacheOptions(
  store: store,
  policy: CachePolicy.refreshForceCache,    // اطلب الـ network، لو فشل ارجع للـ cache
  hitCacheOnErrorExcept: const [],          // قائمة الـ codes اللي ميرجعش cache فيها (فاضية = ارجع cache في كل error)
  maxStale: const Duration(days: 7),        // بعد 7 أيام، الـ cache يتعتبر قديم
  priority: CachePriority.normal,
  allowPostMethod: false,                   // الـ POST مفيش cache (عمل تعديل في الـ server)
);
```

**ليه مش بنـ cache POST/PUT/DELETE؟** لأنهم بيـ change حاجة في الـ server — لو cached، الـ user هياخد response قديم وفجأة الـ data في الـ server اتغيرت.

---

### 5.3 `auth_interceptor.dart`

📁 `lib/core/network/interceptors/auth_interceptor.dart`

**الهدف:** يضيف Bearer token لكل request، ولو الـ server رجّع 401 يحاول refresh الـ token مرة واحدة.

```dart
class AuthInterceptor extends QueuedInterceptor {
  // ...
}
```

**`QueuedInterceptor`** بدل `Interceptor` العادي:
- العادي = الـ interceptors بتشتغل في parallel.
- `QueuedInterceptor` = بتشتغل بالـ trتيب (one-by-one). نستخدمها هنا عشان مايبقاش 10 requests كلهم بيـ refresh في نفس الوقت.

#### الـ 3 methods الرئيسية:

##### `onRequest(options, handler)`
بتـ trigger قبل ما الـ request يطلع. بنضيف الـ token:
```dart
options.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
handler.next(options);    // كمّل
```

`handler.next()` = "خلاص اشتغلت، كمّل للـ interceptor اللي بعدي."

##### `onResponse(response, handler)`
بتـ trigger لما الـ server يرد. **بنـ override الميثود دي** عشان في الـ `DioClient` بنخلي `validateStatus < 500` — يعني 401 بيوصل هنا (مش في `onError`).

لو شاف 401 وفي refresh token:
1. حاول refresh.
2. لو نجح → retry الـ request الأصلي.
3. لو فشل → call `onAuthFailure()` (المفروض الـ app يـ navigate للـ login).

##### `onError(err, handler)`
بتـ trigger لو الـ Dio نفسها رمت exception (مثلاً timeout). نفس الـ logic بس على `DioException`.

#### الـ refresh logic:
```dart
final res = await _refreshClient.post(
  ApiEndpoints.refreshToken,
  data: {'refresh_token': refreshToken},
  options: Options(extra: {_skipAuthFlag: true}),    // ميـ injectش token قديم!
);
```

**ليه `_refreshClient` منفصل عن `_dio` الرئيسي؟** لو استخدمت الـ Dio الرئيسي، هيـ trigger AuthInterceptor تاني (recursion infinite).

**`_retriedFlag`** و **`_skipAuthFlag`** كلاهما keys في `requestOptions.extra` — `extra` هو `Map<String, dynamic>` بتلصق فيه بيانات الـ request اللي بتحب تنقلها بين الـ interceptors.

---

### 5.4 `retry_interceptor.dart`

📁 `lib/core/network/interceptors/retry_interceptor.dart`

**الهدف:** لو الـ request فشل بسبب error مؤقت (timeout, 5xx, 429)، حاول تاني بـ **exponential backoff**.

**Exponential backoff** = كل محاولة بتاخد ضعف اللي قبلها:
- المحاولة 1 → استنى 2 ثواني
- المحاولة 2 → استنى 4 ثواني
- المحاولة 3 → استنى 8 ثواني

ليه؟ لو الـ server overloaded، لو كل العملاء حاولوا تاني فوراً، هيـ crash تاني. بنخفف الـ load.

```dart
final delay = baseDelay * (1 << count);    // 1 << count = 2^count
await Future.delayed(delay);
```

**`1 << count`** = bitwise shift left = `2^count`.
- `1 << 0` = 1
- `1 << 1` = 2
- `1 << 2` = 4
- `1 << 3` = 8

**`_isRetryable(err)`** — بنـ retry بس لو:
- timeout (connect/send/receive)
- connection error
- status code: 408, 429, 500, 502, 503, 504

**مش بنـ retry على:**
- 400/401/403/404 → الـ user/data غلط، الإعادة مش هتنفع.
- `cancel` → المستخدم نفسه لغاها.
- `badCertificate` → SSL مكسور، الإعادة مش هتفرق.

---

### 5.5 `cache_interceptor.dart`

📁 `lib/core/network/interceptors/cache_interceptor.dart`

**الهدف:** wrapper حول `DioCacheInterceptor` من package. كده باقي الكود مش محتاج يـ import الـ package مباشرة.

```dart
class AppCacheInterceptor {
  static Interceptor build() {
    return DioCacheInterceptor(options: CacheConfig.defaultOptions);
  }
}
```

---

### 5.6 `logging_interceptor.dart`

📁 `lib/core/network/interceptors/logging_interceptor.dart`

**الهدف:** يطبع كل request/response في الـ console — **بس في debug mode**.

```dart
return PrettyDioLogger(
  requestHeader: kDebugMode,
  requestBody: kDebugMode,
  responseBody: kDebugMode,
  // ...
);
```

**`kDebugMode`** = constant من Flutter. `true` في debug build، `false` في release. ده بيخلي الـ logs ماتظهرش في production.

**ليه ده مهم؟** الـ logs ممكن فيها tokens, passwords, personal data. لو طبعت في production، أي حد يقدر يفتح الـ logcat ويشوف.

---

### 5.7 `dio_client.dart`

📁 `lib/core/network/dio_client.dart`

**الهدف:** يجمع كل حاجة. Singleton.

```dart
class DioClient {
  DioClient._() {
    _dio = Dio(_baseOptions);
    _dio.interceptors.addAll([
      AuthInterceptor(),
      RetryInterceptor(),
      AppCacheInterceptor.build(),
      if (kDebugMode) LoggingInterceptor.build(),
    ]);
  }
  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;
}
```

**`factory DioClient() => _instance;`**
- **`factory`** = constructor مش بيـ create instance جديد. بترجع instance موجودة.
- ده الـ Singleton pattern — كل `DioClient()` بيرجع نفس الـ object.

**ترتيب الـ interceptors مهم جداً:**
1. **Auth** — يضيف token (لازم قبل أي حاجة).
2. **Retry** — لو فشل، حاول تاني.
3. **Cache** — قبل ما يطلع network، شوف الـ cache.
4. **Logger** — آخر حاجة عشان يطبع الشكل النهائي.

**`BaseOptions`:**
```dart
BaseOptions(
  baseUrl: ApiEndpoints.baseUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
  sendTimeout: const Duration(seconds: 15),
  responseType: ResponseType.json,
  headers: const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  validateStatus: (status) => status != null && status < 500,
);
```

**`validateStatus: (status) => status != null && status < 500`**
- الـ Dio بيـ throw `DioException` لو الـ status مش "valid".
- بنحدد إن أي status أقل من 500 = valid (مش error).
- ده بيخلي 401, 404, 422 يوصلوا للـ `onResponse` بدل `onError`، وده اللي خلانا نضيف logic في `onResponse` في AuthInterceptor.

---

## 6. Phase 4 — Cancel + Offline + Base

### 6.1 `request_cancellation_manager.dart`

📁 `lib/core/network/cancel/request_cancellation_manager.dart`

**الهدف:** يدير الـ `CancelToken`s — لو المستخدم بيكتب في search field سريع، نلغي الـ requests القديمة ونعمل واحدة بس.

```dart
class RequestCancellationManager {
  final Map<String, CancelToken> _tokens = {};

  CancelToken getToken(String key, {bool cancelPrevious = true}) {
    if (cancelPrevious) {
      _tokens.remove(key)?.cancel('superseded:$key');
    }
    final token = CancelToken();
    _tokens[key] = token;
    return token;
  }
}
```

**`CancelToken`** من dio. بتـ pass-ها مع الـ request، ولما تنادي `.cancel()`، الـ request بيتقفل فوراً.

**`?.cancel(...)`** = لو الـ old null، اـ skip. لو موجود، اعمل `.cancel()`.

**مثال practical:**
```dart
// search field — كل ما المستخدم بيكتب حرف:
final token = manager.getToken('search:users');    // بيلغي اللي قبله
dio.get('/users?q=$query', cancelToken: token);
```

**`cancelAll()`** مفيدة لما المستخدم بيـ logout — تلغي كل الـ requests الشغّالة.

---

### 6.2 `network_info.dart`

📁 `lib/core/network/network_info.dart`

**الهدف:** يقول لو في نت ولا لأ، ويـ broadcast لما الحالة تتغير.

```dart
class NetworkInfo {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;
}
```

**`StreamController<bool>.broadcast()`:**
- **`Stream`** = sequence من events ناتجة over time.
- **`broadcast`** = أكتر من listener يقدر يشترك (مش one-to-one).
- بنستخدمها هنا لأن أكتر من widget محتاج يعرف الحالة (OfflineSyncBanner + OfflineQueueManager).

**`Connectivity().onConnectivityChanged`** من package `connectivity_plus` — stream بيـ emit لما النت يتغير (wifi → mobile → none).

**`_emit()`** بيـ filter — لو الحالة لسه زي ما هي، ما يـ emit-ش (عشان مايعملش rebuild زيادة).

---

### 6.3 `queued_operation.dart`

📁 `lib/core/network/offline/queued_operation.dart`

**الهدف:** Model للعملية اللي اتحفظت offline.

```dart
@HiveType(typeId: 10)
class QueuedOperation extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String endpoint;
  // ...
}
```

**`@HiveType(typeId: 10)`** = annotation من package `hive`. بتقول للـ Hive: "ده class أنا عايز أخزنه. اعمله TypeAdapter."

**`typeId: 10`** — كل class له رقم فريد. لو عندك 5 classes في Hive، يبقى 1, 2, 3, 4, 5. الـ 10 هنا عشان نسيب 0-9 للـ classes الأساسية في المشروع.

**`@HiveField(0)`** = ترتيب الحقل لما الـ Hive يـ serialize. **مينفعش تغيرها بعدين** — لو غيرت `0` لـ `2`، الـ data القديمة المحفوظة هتتكسر.

**`extends HiveObject`** — بتدي للـ class methods زي `.save()` و `.delete()` بتعمل update مباشرة على الـ box.

---

### 6.4 `queued_operation.g.dart`

📁 `lib/core/network/offline/queued_operation.g.dart`

**الهدف:** ملف auto-generated من `build_runner`. **مينفعش تـ edit-ه يدوي.**

بيتولد بـ:
```bash
dart run build_runner build --delete-conflicting-outputs
```

محتواه `QueuedOperationAdapter` — بيقول للـ Hive ازاي يحول الـ `QueuedOperation` لـ bytes والعكس.

```dart
class QueuedOperationAdapter extends TypeAdapter<QueuedOperation> {
  @override
  QueuedOperation read(BinaryReader reader) { /* ... */ }
  @override
  void write(BinaryWriter writer, QueuedOperation obj) { /* ... */ }
}
```

**لما تعدل في `queued_operation.dart`** (تضيف field مثلاً) لازم تشغل build_runner تاني.

---

### 6.5 `offline_queue_manager.dart`

📁 `lib/core/network/offline/offline_queue_manager.dart`

**الهدف:** أهم class في الـ offline-first story. بيـ:
1. يحفظ الـ Add/Update/Delete في Hive لما المستخدم offline.
2. لما النت يرجع، ينفذهم بالترتيب (FIFO).
3. لو فشلت، يجرب 5 مرات. بعد كده يحذفها.

```dart
class OfflineQueueManager {
  late final Box<QueuedOperation> _box;

  Future<void> init() async {
    Hive.registerAdapter(QueuedOperationAdapter());    // عرّف الـ Hive بالـ adapter
    _box = await Hive.openBox<QueuedOperation>(_boxName);    // افتح/أنشئ الـ box

    _netSub = _network.onStatusChange.listen((online) {
      if (online) _processQueue();    // النت رجع → اشتغل!
    });
  }
}
```

**`Box<QueuedOperation>`** = الـ Hive equivalent لـ table. زي `Map<String, QueuedOperation>` لكن persistent.

**`Hive.openBox()`** بترجع `Future` لأن قراءة من القرص بتاخد وقت.

#### `enqueue(...)`:
```dart
final op = QueuedOperation(id: _uuid.v4(), endpoint: ..., method: ...);
await _box.put(op.id, op);
```

**`_uuid.v4()`** بيولد UUID فريد (مثلاً `f47ac10b-58cc-4372-a567-0e02b2c3d479`).

#### `_processQueue()`:
```dart
final ops = _box.values.toList()
  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));    // FIFO

for (final op in ops) {
  if (!_network.isOnline) break;
  await _runOne(op);
}
```

**`..sort()`** الـ `..` = cascade operator. بيـ apply الـ operation على الـ object ويرجعه نفسه. هنا = "خد الـ list، sort-ها، ورجعهالي."

#### `_runOne(op)`:
1. ابعت الـ request بالـ method والـ body المحفوظين.
2. لو نجح (2xx) → احذف من الـ box.
3. لو 4xx → احذف (مش هيتصلح).
4. لو 5xx → زود `retryCount`.
5. لو وصلت 5 → احذف وـ call `onOperationFailed`.

#### الـ callbacks:
- **`onOperationSucceeded(op, response)`** — مفيدة لو عندك local DB. لما تـ create record offline، بتديله local ID مؤقت. لما الـ server يرجعلك الـ real ID، تـ update الـ local DB.
- **`onOperationFailed(op, error)`** — اعرض للمستخدم إن العملية فشلت بشكل دائم.

---

### 6.6 `base_remote_source.dart`

📁 `lib/core/network/base/base_remote_source.dart`

**الهدف:** الـ base class اللي كل remote source هيرث منه. بيـ wrap أي call في:
1. cancel management.
2. error parsing.
3. unified return type (`ApiResult<T>`).

```dart
abstract class BaseRemoteSource {
  BaseRemoteSource({Dio? dio, RequestCancellationManager? cancelManager})
      : _dio = dio ?? DioClient().dio,
        _cancelManager = cancelManager ?? RequestCancellationManager();

  Future<ApiResult<T>> safeApiCall<T>({
    required String cancelKey,
    required Future<Response> Function(CancelToken token) call,
    required T Function(dynamic json) fromJson,
    bool cancelPrevious = true,
  }) async {
    final token = _cancelManager.getToken(cancelKey, cancelPrevious: cancelPrevious);
    try {
      final response = await call(token);
      _cancelManager.release(cancelKey);
      return ResponseParser.parse<T>(response, fromJson);
    } on DioException catch (e) {
      _cancelManager.release(cancelKey);
      if (CancelToken.isCancel(e)) return ApiError<T>(const CancelledRequest());
      return ApiError<T>(ResponseParser.parseDioError(e));
    } catch (e) {
      _cancelManager.release(cancelKey);
      return ApiError<T>(ResponseParser.parseUnknownError(e));
    }
  }
}
```

**`abstract class`** = مش لاحدش يقدر يعمل `BaseRemoteSource()` مباشرة. لازم تـ extends منها.

**`Future<Response> Function(CancelToken token)`** — ده الـ signature:
- function بتاخد `CancelToken`.
- بترجع `Future<Response>`.
- اللي بيـ inherit بيـ pass فيها lambda زي `(token) => dio.get('/users', cancelToken: token)`.

**`T Function(dynamic json)`** = function بتاخد JSON وترجع object من نوع `T`.

**`on DioException catch (e)`** = catch بس النوع ده من exception.

**`CancelToken.isCancel(e)`** = static method تـ check لو الـ exception سببه إن الـ cancel happened.

---

## 7. Phase 5 — UI + Example

### 7.1 `app_error_handler.dart`

📁 `lib/presentation/widgets/app_error_handler.dart`

**الهدف:** widget واحد بيعرض أي `AppException` بشكل مناسب.

```dart
class AppErrorHandler extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final bool compact;

  static IconData _iconFor(AppException e) => switch (e) {
    NetworkException() => Icons.wifi_off_rounded,
    UnauthorizedException() => Icons.lock_outline,
    // ...
  };
}
```

**`switch (e)` على sealed class** = الـ compiler هيـ verify إنك غطيت كل الـ types. لو زودت exception جديدة في `app_exception.dart`، الـ widget ده مايـ compile-ش لحد ما تضيفها هنا. ده الـ safety net اللي بنبني عشانه.

**`if (exception is CancelledRequest) return SizedBox.shrink();`** — مفيش UI للـ cancel. المستخدم اللي عمل الـ cancel أصلاً.

**`exception.retryable && onRetry != null`** — زر "إعادة المحاولة" بيظهر بس لو:
1. النوع ده من الأخطاء قابل للإعادة (network, 5xx, timeout).
2. الـ caller بعت `onRetry` callback.

---

### 7.2 `offline_sync_banner.dart`

📁 `lib/presentation/widgets/offline_sync_banner.dart`

**الهدف:** banner بيظهر فوق الـ app بيقول:
- 🔴 أحمر = مفيش نت
- 🟠 برتقالي = بيـ sync الـ pending operations
- 🚫 مختفي = كله تمام

3 `StreamBuilder`s nested:
```dart
StreamBuilder<bool>(stream: _network.onStatusChange,
  builder: (_, netSnap) {
    return StreamBuilder<SyncStatus>(stream: _queue.statusStream,
      builder: (_, syncSnap) {
        return StreamBuilder<int>(stream: _queue.pendingStream,
          builder: (_, pendingSnap) {
            // اختار banner مناسب
          });
      });
  });
```

**`StreamBuilder`** = widget بيعيد build كل ما الـ stream يـ emit. الـ snapshot فيه آخر قيمة.

**ليه 3 streams؟**
1. الـ network status — online/offline.
2. الـ sync status — idle/syncing.
3. الـ pending count — عدد العمليات اللي بتنتظر.

كل واحدة منهم ممكن تتغير independently.

**`SafeArea(bottom: false)`** = sub-widget بيـ pad الـ children بحيث ما يـ overlap-وا الـ notch/status bar. `bottom: false` لأن الـ banner فوق فقط.

---

### 7.3 `user_remote_source.dart`

📁 `lib/data/remote/user_remote_source.dart`

**الهدف:** مثال كامل ازاي تستخدم `BaseRemoteSource`. عندي 4 endpoints (`me`, `list`, `getById`, `updateProfile`).

```dart
class UserRemoteSource extends BaseRemoteSource {
  Future<ApiResult<UserEntity>> me() {
    return safeApiCall<UserEntity>(
      cancelKey: 'GET:${ApiEndpoints.me}',
      call: (token) => dio.get(ApiEndpoints.me, cancelToken: token),
      fromJson: (json) {
        final data = json is Map<String, dynamic>
            ? (json['data'] ?? json) as Map<String, dynamic>
            : <String, dynamic>{};
        return UserEntity.fromJson(data);
      },
    );
  }
}
```

**`UserEntity.fromJson`** بيـ follow القاعدة من CLAUDE.md:
```dart
factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
  id: int.tryParse(json['id'].toString()) ?? 0,    // ✅ tryParse + ??
  name: json['name'] ?? '',
  email: json['email'] ?? '',
);
```

**`int.tryParse(x) ?? 0`** = جرب تحوّلها لـ int، لو فشل خد 0.
- ✅ آمن لو الـ server بعت `"5"` (string) أو `5` (int) أو `null`.
- ❌ **مينفعش `int.parse()`** — بيـ throw لو فشل.

**`factory UserEntity.initial()`** = constructor للـ Skeletonizer (placeholder قبل ما الـ data توصل).

---

### 7.4 `main.dart`

📁 `lib/main.dart`

**الهدف:** الـ entry point. بيـ initialize كل حاجة بالترتيب الصح قبل ما الـ app يـ run.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();   // لازم قبل أي حاجة async
  await Hive.initFlutter();                    // 1. Hive
  await CacheConfig.init();                    // 2. Cache store
  await OfflineQueueManager().init();          // 3. Offline queue
  await NetworkInfo().check();                 // 4. Warm connectivity
  // Firebase + Notifications (مضافة من الـ linter)
  runApp(const MyApp());
}
```

**`WidgetsFlutterBinding.ensureInitialized()`** — لازم لو هتعمل async حاجة قبل `runApp`. بيـ initialize الـ Flutter engine.

**ترتيب الـ init مهم:**
1. `Hive.initFlutter()` لازم قبل أي حد يستخدم Hive.
2. `CacheConfig` و `OfflineQueueManager` كلاهما بيستخدم Hive.
3. `NetworkInfo().check()` قبل الـ banner يبني (عشان يعرف يبدأ من حالة صحيحة).

**`builder: (context, child) { ... OfflineSyncBanner() ... }`** في `MaterialApp` — ده الـ trick لتقدم الـ banner فوق كل الـ screens بدون ما تكرره في كل scaffold.

---

## 8. Flow كامل لـ Request

خلّينا نشوف الحياة الكاملة لـ request واحد:

```
1. UI / BLoC ينادي:
   userSource.me()

2. userSource.me() داخل UserRemoteSource:
   → ينادي safeApiCall(cancelKey, call, fromJson)

3. safeApiCall في BaseRemoteSource:
   → ياخد CancelToken من RequestCancellationManager
   → ينادي call(token) → اللي بدوره ينادي dio.get(...)

4. Dio بيـ trigger الـ interceptors بالترتيب:
   AuthInterceptor.onRequest:
     → يضيف "Authorization: Bearer ..."
   RetryInterceptor: (مش بيـ trigger في onRequest)
   CacheInterceptor:
     → يـ check الـ cache. لو موجود وما-انتهاش → يرجع من cache.
     → غير كده يكمل للـ network.
   LoggingInterceptor (debug only):
     → يطبع الـ request في الـ console.

5. Network call فعلية → الـ server بيرد.

6. الـ response بيرجع للـ interceptors (reverse order):
   Logger → Cache (يحفظ) → Retry (يـ skip لو ناجح) → Auth (يـ check 401).

7. AuthInterceptor.onResponse:
   → لو 401 → حاول refresh → retry → ارجع response جديدة.
   → لو غير كده → خلي الـ response تكمل.

8. الـ response بيوصل لـ safeApiCall:
   → ResponseParser.parse(response, fromJson):
     → لو HTML → HtmlResponseException.
     → لو 2xx → fromJson(data) → ApiSuccess.
     → لو error code → StatusCodeHandler → ApiError.

9. UserRemoteSource بيرجع ApiResult<UserEntity>.

10. الـ BLoC/UI:
    result.when(
      success: (user) => emit(LoadedState(user)),
      error: (e) => emit(ErrorState(e)),
    );
```

**في حالة المستخدم offline:**
- خطوة 5 → الـ network call بتفشل بـ `SocketException`.
- خطوة 6 → AuthInterceptor → Retry → Cache (يحاول cache fallback).
- لو الـ cache فاضي → Dio بيـ throw DioException بـ type `connectionError`.
- safeApiCall بيمسكها ويـ return `ApiError(NetworkException)`.

**في حالة الـ mutation (POST/PUT/DELETE) وانت offline:**
- الـ Repository بيـ check `NetworkInfo().isOnline`.
- لو offline → `OfflineQueueManager.enqueue(endpoint, method, body)`.
- الـ user بيشوف "تم" optimistically.
- لما النت يرجع، الـ queue بيـ sync تلقائياً.

---

## 9. Cheat-sheet

### استخدام BaseRemoteSource:
```dart
class ProductRemoteSource extends BaseRemoteSource {
  Future<ApiResult<List<Product>>> list() {
    return safeApiCall<List<Product>>(
      cancelKey: 'GET:products',
      call: (t) => dio.get(ApiEndpoints.products, cancelToken: t),
      fromJson: (json) => (json['data'] as List)
          .map((e) => Product.fromJson(e))
          .toList(),
    );
  }
}
```

### استخدام في BLoC:
```dart
Future<void> load() async {
  emit(LoadingState());
  final result = await source.list();
  result.when(
    success: (data) => emit(LoadedState(data)),
    error: (e) {
      if (e is CancelledRequest) return;     // تجاهل الـ cancel
      emit(ErrorState(e));
    },
  );
}
```

### عرض الـ error في الـ UI:
```dart
if (state is ErrorState) {
  return AppErrorHandler(
    exception: state.exception,
    onRetry: () => cubit.load(),
  );
}
```

### Offline mutation:
```dart
if (NetworkInfo().isOnline) {
  await source.create(product);
} else {
  await OfflineQueueManager().enqueue(
    endpoint: ApiEndpoints.products,
    method: 'POST',
    body: product.toJson(),
    localId: tempId,
  );
}
```

### Cancel كل الـ requests عند logout:
```dart
RequestCancellationManager().cancelAll('logout');
await TokenStorage.instance.clear();
```

### حفظ token بعد login:
```dart
await TokenStorage.instance.save(
  access: response.accessToken,
  refresh: response.refreshToken,
);
```

---

## 10. ملاحظات مهمة

- **`validateStatus < 500`** يعني الـ 4xx بتيجي في `onResponse` مش `onError`. عشان كده AuthInterceptor و RetryInterceptor عندهم الـ logic في الـ method-ين.
- **`TokenStorage` in-memory** — استبدلها بـ `flutter_secure_storage` في production.
- **الـ cache** بتـ store في Hive في الـ Documents directory.
- **`build_runner`** لازم يتشغل لما تعدل أي class عليه `@HiveType`.
- **`CancelledRequest.userMessage`** فاضي — UI ميـ render-ش أي حاجة لما يشوفها.

---

## 11. الـ Packages المستخدمة

| Package | الدور |
|---|---|
| `dio` | HTTP client |
| `pretty_dio_logger` | logs جميلة في debug |
| `dio_cache_interceptor` | HTTP cache |
| `dio_cache_interceptor_hive_store` | Hive backend للـ cache |
| `hive` + `hive_flutter` | local storage (queue + cache) |
| `hive_generator` + `build_runner` | TypeAdapter generation |
| `connectivity_plus` | network connection state |
| `uuid` | unique IDs للـ queued operations |
| `path_provider` | الـ documents directory |

---

✅ **هذا الـ layer دلوقتي جاهز للاستخدام — كل feature جديدة تحتاج بس تـ extends `BaseRemoteSource` وتستخدم `ApiResult<T>` في الـ BLoC.**

</div>
