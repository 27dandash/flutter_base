---
name: api-create-api
description: Entry-point prompt for generating Postman Collection + API services from existing Flutter screens. Sets inputs, gates on the question of "do you have a v2.1 collection from the backend?", then delegates the full workflow to the `api-design` + `api-pipeline` skills.
---

# API Creation & Service Implementation — Cursor Prompt

> **هذا الملف entry-point في Cursor — بيحدد الـ inputs، يسأل السؤال الفارق، ويوديك للـ canonical workflow.**
> **التفاصيل الكاملة (Postman v2.1 spec، STEP 0-6، Lessons Learned، Flexible Mappers، etc.) موجودة في الـ rules — ممنوع تـ duplicate المحتوى هنا.**

## 📥 Inputs

```
Backend Postman File:  [PATH أو ملف مرفق مثل "Basiet — بسيط.postman_collection.json"]
                       (لو موجود → عقد API = source of truth)
                       (لو مش موجود → نولّد Postman من شاشات Figma)
Project Scope:         [Full app / Single feature / Single endpoint]
Mode:                  [GENERATE_FROM_SCREENS / IMPORT_BACKEND_COLLECTION / SYNC_GAP]
```

---

## ⚠️ FIRST — ASK THE USER (سؤال فارق واحد)

> **قبل ما تبدأ — اسأل:**

### "في ملف `*.postman_collection.json` من الباك اند؟"

- **A) ✅ نعم، عندي ملف من الباك** → الملف = **عقد API** | اقرأه كاملاً | اتبع `api-design.mdc` STEP 0 + STEP 6 (compare + sync). ممنوع تتجاهل أي حقل فيه أو تخمن.
- **B) ❌ لا، الباك لسه ما عملش collection** → هحلل شاشات المشروع شاشة بشاشة، أستنتج الـ endpoints، أعمل **اقتراح Postman Collection JSON** للباك يراجعه. اتبع `api-design.mdc` STEP 1-5.
- **C) ⚠️ نعم لكن الـ collection ناقصة (gap)** → نحلل الـ gap: ما الموجود vs ما الناقص → نعمل Postman يكمّل النقص فقط، مش بدائل. اتبع `api-design.mdc` STEP 6.0 + 6.1.

---

## 🎯 Developer Mindset (الأهم — اقرأها قبل أي شغل)

> **أنت بتشتغل كـ Backend API Designer + Senior Flutter Engineer — مش junior.**

- **الملف اللي بيبعته الباك = source of truth.** أي تخمين = bug.
- **شاشة شاشة، endpoint endpoint.** ممنوع تجمع endpoints لشاشات مختلفة في waste واحد.
- **Unified Entity واحد للـ feature.** التفاصيل في `api-design.mdc` Rule 8.
- **Pagination دائماً للـ list endpoints.** `PaginatedCubit` مش `AsyncCubit<List<T>>`.
- **fromJson مع `?? defaults`** لكل field non-nullable — `String→''`, `int→0`, `bool→false`, `List→[]`, Object → `.initial()`.
- **Flexible Mappers** — الـ entity تتقبل أكتر من شكل response (`{data: {...}}` و `data: [...]`). التفاصيل في `api-design.mdc` STEP 6.3.

---

## ⚡ Quick Tactical Reference (التزم بيها)

### 📋 Postman v2.1 Collection — حقول إلزامية

```
info.name                  → اسم الـ Collection (يطابق تسليم الباك)
info.description           → Markdown: response standard, HTTP codes, headers, pagination,
                             token, validation, enums — انسخها كما هي
variable                   → كل {{key}} / {{value}} / disabled (base_url, lang, user_token, ...)
event (collection level)   → prerequest/test عامة — انسخها
item[] (شجرة مجلدات)       → نفس التسلسل الهرمي User App / {Feature} / {request} — مش تعيد تسمية
request.method             → كما هو
request.header             → Accept, Accept-Language, Authorization — بنفس {{variables}}
request.body               → mode (urlencoded/formdata/raw) + key + type + description (Laravel rules)
request.url                → raw + host + path + variable لو فيه :param
request.description        → عربي + سيناريو النجاح + [figma: ...] لو موجود
```

### 🌐 URL Naming Rules

```
✓ kebab-case في الـ path                  (not snake_case, not camelCase)
✓ plural للـ resources (cities, products)
✓ /api/v1/{resource}/{id}/{action}        — actions في النهاية فقط
✓ /api/v1/{resource}?page=1&limit=10      — pagination via query
✗ /api/getCities                          — verb-prefix ممنوع (REST مش RPC)
✗ /api/v1/city                            — singular ممنوع للـ list
```

### 📦 Response Format Standard

```json
// Success (paginated list) — التفاصيل في api-design.mdc
{
  "status": "success",
  "message": "...",
  "data": {
    "items": [...],
    "current_page": 1,
    "last_page": 5,
    "total": 47
  }
}

// Validation Error (422) — uses data.items NOT errors
{
  "status": "validation_error",
  "data": { "items": { "field": ["msg1", "msg2"] } }
}

// HTTP status codes ONLY: 200, 201, 400, 401, 403, 404, 422, 500
// Status field values: "success" | "validation_error" | "auth_error" | "not_found" | "server_error"
```

### 🔌 Entity / fromJson Safety

```dart
class XEntity {
  final int id; final String name; final List<TagEntity> tags;
  const XEntity({required this.id, required this.name, required this.tags});

  factory XEntity.initial() => const XEntity(id: 0, name: '', tags: []);

  // Flexible: يتقبل {data: {...}} أو {...} مباشرة
  factory XEntity.fromJson(Map<String, dynamic> json) {
    final root = (json['data'] is Map) ? json['data'] as Map<String, dynamic> : json;
    return XEntity(
      id: int.tryParse(root['id'].toString()) ?? 0,       // tryParse + ?? NEVER parse
      name: root['name'] ?? '',                            // ?? for non-nullable
      tags: (root['tags'] as List? ?? [])
          .map((e) => TagEntity.fromJson(e))
          .toList(),
    );
  }
}
```

### 🛡️ Bool Safety (CRITICAL)

```dart
// ❌ json['is_active'] ?? false       — backend ممكن يرجع "1" / "true" / 1
// ✅ Helpers.parseBool(json['is_active'])
bool parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return false;
}
```

### 🧪 Service Extraction Rules (sample — full في `api-design.mdc`)

```
1. شاشة فيها sections متعددة → service منفصل لكل section
2. List screens → pagination إلزامي
3. Multi-step forms → validate per step + final create endpoint
4. File uploads → form-data inline (مش endpoint منفصل للـ upload)
5. CRUD → 5 standard services (list, show, create, update, delete)
6. Toggle/Switch → endpoint منفصل (PATCH /{resource}/{id}/toggle)
7. Status change → PATCH /{resource}/{id}/status
8. Unified entity واحد للـ feature كله
```

---

## ⚠️ Mandatory Pre-Flight Reading (إلزامي)

> **قبل ما تكتب أي endpoint أو سطر كود في الـ API layer، اقرأ:**

### 📚 القراءة الإلزامية:

```
1. .cursor/rules/api-design.mdc                    ← الـ workflow الكامل (STEP 0-6) + Postman v2.1 spec
2. .cursor/rules/api-pipeline.mdc                  ← Postman → ApiConstants → Entity → CrudBaseParams → Cubit → UI
3. .cursor/rules/flutter-base-coding-standards.mdc ← Entity safety, fromJson defaults, tryParse, field validation
4. .cursor/rules/bloc-patterns.mdc                 ← AsyncCubit / PaginatedCubit, CRUD local updates
```

### 🎯 القراءة الـ Conditional:

```
لو الفيتشر فيه forms              → .cursor/rules/form-api-pipeline.mdc
لو محتاج UI تربط بالـ API          → .cursor/rules/flutter-patterns.mdc + .cursor/rules/widget-efficiency.mdc
لو error handling / retries        → .cursor/rules/error-handling-and-resilience.mdc
لو DI / @injectable                → .cursor/rules/di-and-architecture.mdc
لو bloc scoping سؤال               → .cursor/rules/bloc-provider-scoping.mdc
```

### ✅ بعد ما تخلص (إلزامي):

```
.cursor/rules/post-feature-review.mdc   ← code review للـ API + entities + cubits
```

---

## 🛠️ Workflow Entry Point

> **الـ STEP 0-6 الكاملة في `.cursor/rules/api-design.mdc` — افتحها وابدأ من STEP 0.**

```
STEP 0 — لو الباك بعت collection → الملف source of truth
STEP 1 — Analyze UI / screens → Service Extraction Rules
STEP 2 — Endpoint Naming Convention (kebab-case, plural, /api/v1/...)
STEP 3 — Postman Collection JSON Structure (single file, multi-app folders)
STEP 4 — Present Analysis (انتظر الموافقة)
STEP 5 — Execute (Postman → ApiConstants → Entities → Cubits → UI)
STEP 6 — Compare & Sync لو الباك بعت updated collection
```

### الـ Workflow الموحد:

```
1. اسأل السؤال الفارق (هل عندك ملف من الباك؟)
2. اقرأ الـ 4 rules الإلزامية (Read tool — مش optional)
3. اقرأ الـ conditional rules حسب الاحتياج
4. اتبع STEP 0-6 من api-design.mdc
5. بعد ما تخلص → post-feature-review.mdc
```

---

## Where to Look First (skill index)

- **Postman generation / API contract?** → `api-design.mdc`
- **Wire endpoint into Flutter?** → `api-pipeline.mdc`
- **Entity safety / fromJson?** → `flutter-base-coding-standards.mdc` section 8.5
- **Cubit patterns?** → `bloc-patterns.mdc`
- **Form + API?** → `form-api-pipeline.mdc`
- **Error handling?** → `error-handling-and-resilience.mdc`
- **DI / @injectable?** → `di-and-architecture.mdc`

---

## ❌ Anti-pattern (ممنوع)

> **ممنوع تكتب endpoints بدون ما تقرأ `api-design.mdc` كاملاً.**
> الـ Quick Tactical Reference فيه الـ 80% — الـ 20% الباقية (unified entities، pagination edge cases، multi-step form validation، file upload inline rules، flexible mappers، bool safety، OTP flows، exam design patterns) في الـ rule، وغلطها بيطلع entities هشة بـ runtime crashes.
