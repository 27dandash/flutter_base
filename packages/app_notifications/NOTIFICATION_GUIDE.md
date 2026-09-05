<div dir="rtl" align="right">

# 📚 شرح تفصيلي لحزمة الإشعارات الاختيارية FCM

> **الهدف من الملف ده:** نشرح كل سطر كود في الـ Notification System، إيه استخدمناه، ليه استخدمناه، وكل keyword بتعمل إيه — حتى لو إنت مبتدئ.

---

## 📑 جدول المحتويات

1. [نظرة عامة على النظام](#1-نظرة-عامة-على-النظام)
2. [الـ Packages المستخدمة](#2-الـ-packages-المستخدمة)
3. [شرح الـ Keywords الأساسية في Dart/Flutter](#3-شرح-الـ-keywords-الأساسية)
4. [شرح كل ملف بالتفصيل](#4-شرح-كل-ملف-بالتفصيل)
5. [الـ Flow الكامل](#5-الـ-flow-الكامل)
6. [Android/iOS Configuration](#6-androidios-configuration)

---

## 1. نظرة عامة على النظام

الـ FCM (Firebase Cloud Messaging) هو نظام بيخلي السيرفر يبعت إشعارات للموبايل بتاع المستخدم. عندنا 3 حالات للتطبيق لما الإشعار يجي:

| الحالة | يعني إيه؟ |
|--------|----------|
| **Foreground** | التطبيق مفتوح والمستخدم شايفه |
| **Background** | التطبيق شغال بس مش ظاهر (المستخدم خرج منه بس ما قفلهوش) |
| **Terminated** | التطبيق مقفول تماماً (closed/killed) |

السيرفر بيبعت **data-only messages** يعني JSON فيه `data` بس مفيش `notification` key. ده بيخلينا نقدر نتحكم في شكل الإشعار من الموبايل نفسه.

---

## 2. الـ Packages المستخدمة

### Firebase Core
- التطبيق المستهلك لازم يعمل `Firebase.initializeApp()` قبل تهيئة الحزمة.
- رقم الإصدار بيتحدد في التطبيق المستهلك، مش في الحزمة دي، عشان ما نربطش الـbase بنسخة Firebase بدون داعي.

### `awesome_notifications: ^0.12.1`
- **بيعمل إيه؟** بيظهر الإشعارات المحلية (local notifications) — يعني الإشعار اللي بيطلع في الـ notification tray.
- **ليه؟** عشان السيرفر بيبعت data بس، وإحنا اللي بنبني الإشعار شكله ونعرضه بـ awesome_notifications.

### `awesome_notifications_fcm: ^0.12.0`
- **بيعمل إيه؟** ده الـ bridge بين Firebase Messaging و awesome_notifications. بيستلم الـ data messages من FCM ويسلمها لينا.
- **ليه؟** بديل كامل لـ `firebase_messaging`. لو استخدمت الـ 2 مع بعض هيتعارضوا.

### فتح الروابط والتنقل
- الحزمة بترجع `OpenUrl` أو `NavigateToScreen` للـ`NotificationRouter` فقط.
- التطبيق المستهلك هو اللي يختار package التنقل أو فتح الروابط، لذلك الحزمة لا تضيف `url_launcher` ولا تعتمد على Router التطبيق.
- `NotificationUrlPolicy.secureDefault` يرفض أي `open_url` غير HTTPS أو malformed أو host غير مسموح. لا تفتح الروابط داخل الحزمة؛ مرّر `OpenUrl` للـ router بعد ضبط allow-list صريح للـ hosts أو schemes الإضافية فقط عند الحاجة.

```dart
NotificationController.urlPolicy = const NotificationUrlPolicy(
  allowedHttpsHosts: {'links.example.test'},
  approvedExtraSchemes: {'myapp'},
);

// داخل NotificationRouter:
case OpenUrl(:final url):
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
```

> ⚠️ لا تستخدم `Uri.parse` مباشرة على payload السيرفر. استخدم `NotificationController.parseAction` أو `NotificationUrlPolicy.parseAllowedUrl` حتى يفشل الطلب بأمان (`DismissAction`) عند الروابط غير الموثوقة.

> ⚠️ **ممنوع منعاً باتاً تضيف:** `firebase_messaging` أو `flutter_local_notifications` — بيتعارضوا مع awesome_notifications.

---

## 3. شرح الـ Keywords الأساسية

قبل ما نشرح الملفات، خلينا نفهم الـ keywords اللي بنستخدمها كتير:

### `final`
- متغير قيمته بتتحدد مرة واحدة بس ومتتغيرش بعد كده.
- مثال: `final String name = 'Ahmed';` — مينفعش تكتب `name = 'Ali'` بعد كده.

### `const`
- زي `final` بس القيمة لازم تكون معروفة وقت الـ compile (يعني قبل ما البرنامج يشتغل).
- بيستخدم لـ **Performance** — Flutter بيعمل reuse للـ widgets الـ const بدل ما يعيد بنائها.
- مثال: `const Text('Hello')` أسرع من `Text('Hello')`.

### `late`
- يعني "هحدد القيمة دي بعدين بس مش `null`".
- مثال: `late NotificationRouter router;` — هحدد قيمته في الـ `initialize` method.

### `static`
- المتغير/الـ method بيبقى مرتبط بالـ class نفسه مش بـ instance منه.
- يعني تقدر تستدعيه كده: `NotificationController.mySilentDataHandle(...)` بدون `new`.
- **ليه استخدمناه هنا؟** عشان `awesome_notifications` بتنادي على الـ handlers من الـ native code، ومش هتقدر تعمل instance.

### `async` / `await`
- `async`: بيقول إن الـ function دي مش بترجع نتيجة فوراً، دي operation بتاخد وقت (زي API call).
- `await`: انتظر العملية دي تخلص قبل ما تكمل.
- ترجع `Future<T>` — يعني "وعد إن النتيجة هتيجي بعدين".

### `sealed class`
- (Dart 3.0+) كلاس مقفول، يعني أنواعه محدودة ومحدّدة.
- لما تعمل `switch` عليه، الـ compiler يجبرك تغطي كل الأنواع (exhaustive).
- **ليه استخدمناه؟** عشان الـ actions اللي ممكن تيجي من الإشعار محدودة (chat, screen, url, dismiss)، فبدل ما نتعامل بـ Strings (اللي ممكن تتكتب غلط) بنستخدم types.

### `abstract interface class`
- (Dart 3.0+) كلاس بيحدد **العقد** (contract) بس بدون implementation.
- زي ما تقول: "أي حاجة تنفذ ده لازم تعمل method اسمه `route`".
- **ليه؟** عشان نقدر نغيّر الـ router (مثلاً للـ testing) بدون ما نغير باقي الكود.

### `factory`
- نوع خاص من الـ constructors بيرجع object — مش لازم يعمل instance جديد، ممكن يرجع موجود.
- مثال: `NotificationPayload.fromMap(data)` — بياخد Map ويرجع object منظف.

### `@pragma('vm:entry-point')`
- ده **annotation** بيقول للـ Dart compiler: "متمسحش الـ function دي من الـ release build حتى لو شكلها مش مستخدمة".
- **ليه ضروري هنا؟** عشان الـ functions دي بتتنادى من **native code** (Android/iOS) مش من Dart، فالـ compiler ميعرفش إنها مستخدمة.

### `@override`
- بيقول إن الـ method دي بتعمل override لـ method موجودة في الـ parent class أو الـ interface.
- بيساعد الـ compiler يكتشف الأخطاء (لو غيرت الاسم في الـ parent بالغلط).

### `?` و `??` و `?.`
- `String?` → متغير ممكن يكون `null`.
- `data ?? 'default'` → لو `data` null، استخدم `'default'`.
- `data?.name` → لو `data` مش null، رجّع `.name`. لو null، رجع `null`.

### `Map<String, dynamic>`
- زي JSON في JavaScript — مجموعة key-value pairs.
- `String` هو نوع الـ key، `dynamic` يعني القيمة ممكن تكون أي نوع.

### `enum`
- نوع بيمثل مجموعة قيم محدودة ومحدّدة.
- مثال: `enum NotificationType { message, media, call, alert }` — الإشعار من نوع واحد بس من دول.

### `switch expression` (Dart 3.0+)
```dart
final layout = switch (payload.type) {
  NotificationType.media => NotificationLayout.BigPicture,
  NotificationType.message => NotificationLayout.BigText,
  _ => NotificationLayout.Default,
};
```
- ده شكل جديد للـ switch بيرجع قيمة. أنظف من الـ if/else الطويل.
- `_` معناها "أي قيمة تانية".

### `Pattern matching` (Dart 3.0+)
```dart
case NavigateToChat(:final chatId):
```
- بيستخرج الـ `chatId` من الـ object مباشرة في الـ case.

---

## 4. شرح كل ملف بالتفصيل

### 📄 الملف 1: `models/notification_enums.dart`

```dart
enum NotificationType { message, media, call, alert }

enum NotificationChannel { messaging, general, system }
```

**شرح:**
- `NotificationType`: نوع الإشعار — رسالة، صورة/فيديو، مكالمة، تنبيه. ده بيحدد شكل الإشعار في الـ tray.
- `NotificationChannel`: قناة الإشعار — في Android، كل قناة لها صوت/أهمية/اهتزاز مختلف. المستخدم يقدر يقفل قناة معينة من الـ Settings.

**ليه enums؟**
- بدل ما نستخدم Strings (`"chat"`, `"call"`) اللي ممكن تتكتب غلط، الـ enum بيحمينا — لو كتبت `NotificationType.mesage` الـ compiler هيقولك غلط فوراً.

---

### 📄 الملف 2: `models/notification_payload.dart`

ده الـ **value object** اللي بيمثل الإشعار جواه في تطبيقنا.

```dart
import 'package:awesome_notifications/awesome_notifications.dart'
    hide NotificationChannel;
```

**شرح الـ `hide NotificationChannel`:**
- في `awesome_notifications` فيه class اسمه `NotificationChannel`، وإحنا عندنا `enum` بنفس الاسم.
- `hide` بتقول: "استورد من الـ package ده كل حاجة **ما عدا** `NotificationChannel`".
- ده عشان نتجنب الـ ambiguous import error.

```dart
final class NotificationPayload {
  final String id;
  final String title;
  // ...
}
```

**شرح:**
- `final class` (Dart 3.0): الكلاس ده **محدش يقدر يـ extend منه**. ده بيحمينا من الـ inheritance بدون داعي.
- كل الـ properties `final` — يعني الـ object بمجرد ما يتعمل، قيمه متتغيرش (Immutable). ده بيمنع bugs غريبة.

```dart
const NotificationPayload({
  required this.id,
  required this.title,
  // ...
});
```

**شرح:**
- `const constructor` — يعني نقدر نعمل instances `const` (أسرع وأخف على الذاكرة).
- `required this.id`: المعامل ده **إلزامي** لما تعمل instance.
- `this.id` shorthand — معناها `id` parameter بياخد قيمته ويحطها في الـ field `id` بتاع الـ class.

```dart
factory NotificationPayload.fromMap(Map<String, dynamic> data) {
  return NotificationPayload(
    id: (data['id']?.toString()) ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    // ...
  );
}
```

**شرح كل سطر:**
- `factory`: مش constructor عادي، ده بيـ return object. ممكن يعمل validation أو يعدّل البيانات قبل ما يـ return.
- `data['id']?.toString()`:
  - `data['id']` بيجيب القيمة من الـ Map.
  - `?.toString()` يعني "لو القيمة مش null، حولها لـ String".
- `?? DateTime.now()...`: لو الـ id جاي null من السيرفر، استخدم الـ timestamp الحالي كـ id (عشان متعدل ما يكونش فاضي).
- **ليه ده؟** عشان لو السيرفر نسي يبعت `id`، التطبيق ميـ crash ـش.

```dart
type: _parseEnum(
  NotificationType.values,
  data['type']?.toString(),
  NotificationType.message,
),
```

**شرح:**
- `NotificationType.values`: list فيها كل قيم الـ enum.
- بنبعت الـ `String` اللي جاي من السيرفر (مثلاً `"call"`) ويحوله لـ `NotificationType.call`.
- لو الـ String مش موجود في الـ enum، يرجع `NotificationType.message` (الـ default).
- **ليه helper method؟** عشان نتجنب الـ exception لو السيرفر بعت قيمة غريبة.

```dart
static T _parseEnum<T extends Enum>(List<T> values, String? raw, T fallback) {
```

**شرح:**
- `static`: method تابعة للكلاس مش للـ instance.
- `T extends Enum`: ده **Generic type** يعني الـ method تقدر تشتغل مع أي enum.
- `T fallback`: القيمة اللي ترجع لو ما لقيناش match.

---

### 📄 الملف 3: `notification_router.dart`

ده اللي بيقرر "لما المستخدم يدوس على إشعار، نوديه فين؟".

```dart
sealed class NotificationAction {
  const NotificationAction();
}
```

**شرح:**
- `sealed class`: كلاس أب مقفول، أنواعه محصورة في اللي تحت بس.
- بدل ما نستخدم `enum` (اللي مبيقدرش يحمل بيانات)، الـ sealed class بيحمل بيانات لكل action.

```dart
final class NavigateToChat extends NotificationAction {
  final String chatId;
  const NavigateToChat(this.chatId);
}
```

**شرح:**
- نوع من الـ action: روح لشاشة الشات بتاع chatId معين.
- بياخد `chatId` لازم.

```dart
final class OpenUrl extends NotificationAction {
  final Uri url;
  const OpenUrl(this.url);
}
```

**شرح:**
- `Uri` نوع built-in في Dart يمثل URL.
- بنستخدم `Uri` بدل `String` عشان validation تلقائي (الـ URL لو غلط هيتعرف فوراً).

```dart
abstract interface class NotificationRouter {
  Future<void> route(NotificationAction action);
}
```

**شرح:**
- **Interface**: عقد بيقول "أي router لازم يعمل method اسمها `route` بياخد `NotificationAction` ويرجع `Future<void>`".
- **ليه interface ومش implementation مباشرة؟**
  1. **Testability**: لو عاوز تعمل unit test، ممكن تعمل `FakeRouter` تنفذ نفس الـ interface.
  2. **Flexibility**: لو حبيت تغير من Navigator لـ GoRouter لـ AutoRoute، تغير الـ implementation بس.

```dart
final class AppNotificationRouter implements NotificationRouter {
  final GlobalKey<NavigatorState> navigatorKey;

  AppNotificationRouter({required this.navigatorKey});

  NavigatorState? get _navigator => navigatorKey.currentState;
```

**شرح:**
- `implements NotificationRouter`: بيقول إن الكلاس ده بينفذ الـ interface.
- `GlobalKey<NavigatorState>`: ده "مفتاح" بيوصلنا للـ Navigator في الـ app.
- **ليه GlobalKey؟** لأن الـ handlers بتشتغل خارج أي `BuildContext`، فمش هنقدر نعمل `Navigator.of(context)`. الـ GlobalKey بتوصلنا للـ Navigator بدون context.
- `get _navigator => ...`: ده **getter** — كأنه property بس قيمته بتتحسب كل مرة.

```dart
@override
Future<void> route(NotificationAction action) async {
  switch (action) {
    case NavigateToChat(:final chatId):
      await _navigator?.pushNamed('/chat', arguments: chatId);
    case NavigateToScreen(:final route):
      await _navigator?.pushNamed(route);
    case OpenUrl(:final url):
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    case DismissAction():
      break;
  }
}
```

**شرح:**
- `@override`: بنعمل override للـ method اللي في الـ interface.
- `switch (action)`: بسبب إن `NotificationAction` sealed، الـ compiler بيـ verify إن كل الأنواع متغطية.
- `case NavigateToChat(:final chatId)`: **pattern matching** — لو الـ action من نوع `NavigateToChat`، اطلع منه الـ `chatId`.
- `_navigator?.pushNamed`: لو الـ navigator موجود، روح للـ route. الـ `?.` بيمنع crash لو الـ navigator مش متعمل.
- `LaunchMode.externalApplication`: افتح في المتصفح، مش جوه التطبيق.

---

### 📄 الملف 4: `notification_controller.dart`

ده الـ "عقل" بتاع النظام — فيه كل الـ handlers.

```dart
import 'dart:ui';
import 'package:flutter/material.dart' hide DismissAction;
```

**شرح:**
- `dart:ui`: library فيه `IsolateNameServer` (هنتكلم عنه تحت).
- `hide DismissAction`: في `flutter/material` فيه class اسمه `DismissAction` (للـ keyboard shortcuts)، وإحنا عندنا واحد بنفس الاسم.

```dart
class NotificationController {
  static const String _isolatePortName = 'notification_action_port';
```

**شرح:**
- `_isolatePortName`: الاسم اللي هنستخدمه نسجل/نلاقي بيه الـ isolate port (هنشرحه تحت).
- `_` قبل الاسم يعني `private` — مش متاح خارج الملف.

#### Method 1: `initializeLocalNotifications`

```dart
static Future<void> initializeLocalNotifications({bool debug = false}) async {
  await AwesomeNotifications().initialize(
    'resource://drawable/ic_launcher',
    [
      NotificationChannel(
        channelKey: app_enums.NotificationChannel.messaging.name,
        channelName: 'Messaging',
        channelDescription: 'Chat and message notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        playSound: true,
        enableVibration: true,
      ),
      // ...
    ],
    debug: debug,
  );
}
```

**شرح:**
- `'resource://drawable/ic_launcher'`: الـ icon اللي هيظهر في الإشعار. ده الـ launcher icon بتاع التطبيق.
- `channelKey`: مفتاح القناة (لازم unique). بنستخدم `name` من الـ enum.
- `importance: High`: درجة أهمية القناة:
  - `Max`: صوت + اهتزاز + يطلع فوق الشاشة
  - `High`: صوت + اهتزاز
  - `Default`: صوت بس
  - `Low`: مفيش صوت
- `defaultColor`/`ledColor`: لون الإشعار واللمبة (في Android).

**ليه 3 قنوات مختلفة؟**
- الـ Messaging قناة بأعلى أولوية للرسائل المهمة.
- الـ General قناة عادية.
- الـ System قناة للتنبيهات المهمة من النظام.
- المستخدم يقدر يقفل أي قناة من Settings بدون ما يقفل الكل.

#### Method 2: `initializeRemoteNotifications`

```dart
static Future<void> initializeRemoteNotifications({bool debug = false}) async {
  await AwesomeNotificationsFcm().initialize(
    onFcmTokenHandle: myFcmTokenHandle,
    onNativeTokenHandle: myNativeTokenHandle,
    onFcmSilentDataHandle: mySilentDataHandle,
    licenseKeys: null,
    debug: debug,
  );
}
```

**شرح:**
- بنبعت **references** للـ methods اللي هتتنادى:
  - `onFcmTokenHandle`: لما الـ FCM token يتولد/يتجدد.
  - `onNativeTokenHandle`: الـ native token (APN في iOS).
  - `onFcmSilentDataHandle`: لما data message يجي.
- الإصدارات الحالية لا تحتاج `licenseKeys`؛ لا تضف مفاتيح قديمة من أمثلة
  سابقة. راجع ترخيص الحزمة وقت تجهيز التطبيق التجاري.

#### Method 3: `mySilentDataHandle` — أهم method

```dart
@pragma('vm:entry-point')
static Future<void> mySilentDataHandle(FcmSilentData silentData) async {
  try {
    final data = silentData.data;
    if (data == null || data.isEmpty) return;

    final payload = NotificationPayload.fromMap(
      Map<String, dynamic>.from(data),
    );
    final content = _buildContent(payload);

    await AwesomeNotifications().createNotification(
      content: content,
      actionButtons: _buildActionButtons(payload),
    );
  } catch (_) {
    // لا تطبع الـexception أو payload؛ قد يحتويان بيانات شخصية أو tokens.
    if (kDebugMode) debugPrint('Notification data handler failed');
  }
}
```

**شرح خطوة بخطوة:**

1. `@pragma('vm:entry-point')`: ده **حيوي** — بدونه الـ method هتتمسح في الـ release build لأن الـ compiler ميعرفش إنها بتتنادى من native.
2. `FcmSilentData silentData`: الـ object اللي جاي من Firebase فيه الـ data.
3. `if (data == null || data.isEmpty) return;`: defensive — لو مفيش data، اخرج بدون ما تعمل حاجة.
4. `Map<String, dynamic>.from(data)`: بنحول الـ Map من النوع الـ awesome_notifications بتاعه لـ Map عادي عشان نقدر نستخدمها في `fromMap`.
5. `_buildContent(payload)`: بنبني شكل الإشعار من الـ payload.
6. `createNotification(...)`: بنأمر awesome_notifications إنها تظهر الإشعار.
7. `try/catch`: يمنع خطأ الـplugin/payload من إسقاط الـhandler، ويسجل حدثًا
   عامًا في debug فقط بدون exception أو payload خام.

**هنا الـ Magic:** الـ method دي بتشتغل **في الـ 3 حالات**:
- Foreground → بتشتغل في الـ main isolate.
- Background → بتشتغل في background isolate (Flutter بيعمل isolate جديد للـ FCM).
- Terminated → نفس الشيء، Flutter بيشغل isolate جديد.

#### Method 4: `onActionReceivedMethod` — لما المستخدم يدوس

```dart
@pragma('vm:entry-point')
static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  try {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      await _handleSilentAction(receivedAction);
      return;
    }

    final sendPort = IsolateNameServer.lookupPortByName(_isolatePortName);
    if (sendPort != null) {
      sendPort.send(receivedAction);
      return;
    }

    await routeAction(receivedAction);
  } catch (_) {
    // لا تطبع action/payload/route/exception خام.
    if (kDebugMode) debugPrint('Notification action handler failed');
  }
}
```

**شرح المنطق:**

1. **Silent action؟** يعني action مش محتاج navigation (زي "Mark as read"). نعالجه في الـ background بدون UI.
2. **isolate check**: ده الجزء المهم. لما المستخدم يدوس على الإشعار والتطبيق في background، الـ method بتشتغل في **isolate تاني** غير الـ main isolate.
   - الـ isolates في Dart زي threads بس مفيش shared memory بينهم.
   - عشان نوصل للـ Navigator (اللي في الـ main isolate)، لازم نبعت رسالة عبر **SendPort**.
   - `IsolateNameServer.lookupPortByName`: نلاقي الـ port اللي سجلناه في الـ main isolate.
   - لو لقيناه → نبعت الـ action للـ main → الـ main يـ route.
   - لو ما لقيناهوش (يعني إحنا في main أصلاً) → نـ route مباشرة.

**ليه الـ isolate communication كده معقد؟**
- الـ Navigator وكل الـ UI موجودين في الـ main isolate.
- لو حاولنا نعمل navigation من background isolate → crash.
- الحل: نبعت الـ data للـ main isolate ونخليه يعمل الـ navigation.

#### Method 5: `_buildContent`

```dart
static NotificationContent _buildContent(NotificationPayload payload) {
  final layout = switch (payload.type) {
    app_enums.NotificationType.media => NotificationLayout.BigPicture,
    app_enums.NotificationType.message => NotificationLayout.BigText,
    app_enums.NotificationType.call => NotificationLayout.Default,
    app_enums.NotificationType.alert => NotificationLayout.Default,
  };

  return NotificationContent(
    id: payload.id.hashCode,
    channelKey: payload.channel.name,
    title: payload.title,
    body: payload.body,
    notificationLayout: layout,
    bigPicture: payload.imageUrl,
    largeIcon: payload.imageUrl,
    // ...
  );
}
```

**شرح:**
- `switch expression`: بيرجع `NotificationLayout` حسب نوع الإشعار.
  - `BigPicture`: عرض كبير مع صورة (للـ media).
  - `BigText`: عرض كبير مع نص طويل (للـ messages).
  - `Default`: عرض عادي.
- `id: payload.id.hashCode`: الـ awesome_notifications محتاج `int` كـ id. الـ `hashCode` بيحول الـ String لـ int.
- `channelKey: payload.channel.name`: **لازم** يتطابق مع المسجل في `initialize`. لو غلط، الإشعار مش هيظهر.
- `bigPicture` و `largeIcon`: الصورة الكبيرة والـ thumbnail.

#### Method 6: `_buildActionButtons`

```dart
static List<NotificationActionButton>? _buildActionButtons(
  NotificationPayload payload,
) {
  return switch (payload.type) {
    app_enums.NotificationType.call => [
        NotificationActionButton(key: 'ACCEPT', label: 'قبول', color: Colors.green),
        NotificationActionButton(
          key: 'REJECT',
          label: 'رفض',
          color: Colors.red,
          actionType: ActionType.DismissAction,
        ),
      ],
    _ => null,
  };
}
```

**شرح:**
- لو نوع الإشعار `call`، نضيف زرارين: قبول/رفض.
- باقي الأنواع → null (مفيش buttons).
- `actionType: ActionType.DismissAction`: زر الرفض بيقفل الإشعار بعد الدوس.

#### Method 7: `_parseAction`

```dart
static NotificationAction _parseAction(Map<String, String?> data) {
  return switch (data['action_type']) {
    'navigate_chat' => NavigateToChat(data['chat_id'] ?? ''),
    'navigate_screen' => NavigateToScreen(data['route'] ?? '/'),
    'open_url' => _parseOpenUrl(data['url'], policy: urlPolicy),
    _ => const DismissAction(),
  };
}
```

**شرح:**
- `open_url` يمر عبر `NotificationUrlPolicy` قبل إنشاء `OpenUrl`.
- الروابط `http` أو malformed أو hosts غير المسموحة ترجع `DismissAction` بدل فتح رابط غير آمن.
- التطبيق المستهلك يضبط `NotificationController.urlPolicy` ويفتح الرابط داخل `NotificationRouter` فقط.

---

### 📄 الملف 5: `notification_manager.dart`

ده الـ **Singleton** اللي بيدير النظام كله.

```dart
final class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();
```

**شرح Singleton Pattern:**
- `NotificationManager._()`: constructor خاص بـ `_` — مينفعش حد يستدعيه من برة.
- `static final NotificationManager instance`: instance واحد بس بيتعمل، ومتاح لكل التطبيق.
- **ليه Singleton؟** عشان نظام الإشعارات لازم يكون **مرة واحدة** في التطبيق كله. لو عملنا instances كتير → مشاكل في الـ listeners.

```dart
ReceivePort? _receivePort;
late NotificationRouter router;
```

**شرح:**
- `ReceivePort`: المستقبل اللي بيستقبل الرسايل من الـ isolates التانية.
- `late NotificationRouter router`: الـ router هيتحدد في `initialize`.

#### Method: `initialize`

```dart
Future<void> initialize({
  required NotificationRouter router,
  bool debug = false,
}) async {
  this.router = router;

  await NotificationController.initializeLocalNotifications(debug: debug);
  await NotificationController.initializeRemoteNotifications(debug: debug);
  await _initializeIsolateReceivePort();
  await NotificationController.startListeningNotificationEvents();
  await _getInitialNotificationAction();
}
```

**شرح ترتيب الخطوات (مهم جداً):**

1. **حفظ الـ router**: نخزن الـ router عشان نقدر نستخدمه لما action تجي.
2. **Local notifications**: نسجل القنوات الأول (Messaging, General, System).
3. **Remote (FCM)**: نسجل الـ handlers مع Firebase.
4. **Isolate port**: نفتح الـ port للتواصل بين الـ isolates.
5. **Start listening**: نبدأ الاستماع للـ events (click, dismiss).
6. **Initial action**: نشوف لو فيه إشعار مفتوح التطبيق بسببه (terminated state).

**ليه الترتيب ده تحديداً؟** عشان الـ listeners ميـ trigger ـش events قبل ما الـ isolate port يكون جاهز.

#### Method: `_initializeIsolateReceivePort`

```dart
Future<void> _initializeIsolateReceivePort() async {
  _receivePort = ReceivePort('notification_main_port');

  IsolateNameServer.removePortNameMapping(_isolatePortName);
  IsolateNameServer.registerPortWithName(
    _receivePort!.sendPort,
    _isolatePortName,
  );

  _receivePort!.listen((receivedAction) {
    if (receivedAction is ReceivedAction) {
      NotificationController.routeAction(receivedAction);
    }
  });
}
```

**شرح خطوة بخطوة:**

1. `ReceivePort('notification_main_port')`: نعمل port جديد. اسم الـ port للـ debugging بس.
2. `removePortNameMapping`: نمسح أي تسجيل قديم بنفس الاسم. ده بيحمينا لو الـ app اتعمل restart.
3. `registerPortWithName`: نسجل الـ `sendPort` بتاعنا بالاسم `notification_action_port` في الـ `IsolateNameServer`.
   - الـ `IsolateNameServer` ده زي "دليل تليفونات" بين الـ isolates.
   - أي isolate تاني يقدر يلاقي الـ port بتاعنا بالاسم ده ويبعتلنا.
4. `_receivePort!.listen(...)`: نبدأ نسمع لأي رسالة جاية على الـ port.
5. `if (receivedAction is ReceivedAction)`: **type check** — لو الـ رسالة من النوع المتوقع، نعالجها.
6. `routeAction(...)`: نعمل routing للـ action.

#### Method: `_getInitialNotificationAction`

```dart
Future<void> _getInitialNotificationAction() async {
  final receivedAction = await AwesomeNotifications()
      .getInitialNotificationAction(removeFromActionEvents: true);

  if (receivedAction == null) return;
  await NotificationController.routeAction(receivedAction);
}
```

**شرح:**
- **السيناريو**: التطبيق كان مقفول، الإشعار جه، المستخدم دوس عليه، التطبيق اتفتح.
- `getInitialNotificationAction`: بيرجع الـ action اللي فتح التطبيق (لو فيه).
- `removeFromActionEvents: true`: بيمسحه بعد ما ناخده عشان مياخدوش مرتين.
- لو فيه action → نـ route ليها (مثلاً نروح لشاشة الشات مباشرة).

#### Method: `requestToken` و `requestPermissions`

```dart
Future<void> requestToken() async {
  await AwesomeNotificationsFcm().requestFirebaseAppToken();
}

Future<bool> requestPermissions() async {
  return AwesomeNotifications().requestPermissionToSendNotifications();
}
```

**شرح:**
- `requestToken`: نطلب من Firebase يولد لنا FCM token. ده الـ unique identifier للموبايل ده. بنبعته للسيرفر عشان يبعت لينا إشعارات.
- `requestPermissions`: نطلب من المستخدم إذن إنه يتلقى إشعارات. في iOS و Android 13+، ده **مطلوب**.

#### Method: `dispose`

```dart
Future<void> dispose() async {
  await _disposeReceivePort();
  _router = null;
  _initialized = false;
  _clearOwnedFcmTokenCallback();
}
```

**شرح:**
- لما التطبيق يقفل، نفك التسجيل ونقفل الـ port ونمسح callback الـ FCM المملوك للمدير فقط.
- `tokenRefreshes` يبقى stream عام قابل لإعادة الاستخدام بعد `initialize` لاحق.

---

### 📄 الملف 6: `main.dart`

```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
```

**شرح:**
- `GlobalKey<NavigatorState>`: مفتاح بنستخدمه نوصل للـ Navigator من أي مكان (حتى من غير context).
- بنحطه على الـ MaterialApp في الـ build.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... Hive init ...

  await Firebase.initializeApp();
  await NotificationManager.instance.initialize(
    router: AppNotificationRouter(navigatorKey: navigatorKey),
    debug: true,
  );

  runApp(const MyApp());
}
```

**شرح:**
- `WidgetsFlutterBinding.ensureInitialized()`: لازم قبل أي async code في `main()`. بيهيئ الـ Flutter framework.
- `Firebase.initializeApp()`: يهيئ Firebase. **لازم** قبل أي حاجة بتستخدم Firebase.
- نمرر الـ `navigatorKey` للـ router عشان يقدر يعمل navigation.
- `debug: true`: نشّط الـ logs (في الـ production خليه `false`).
- `runApp(const MyApp())`: نشغل التطبيق.

```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationManager.instance.requestPermissions();
    NotificationManager.instance.requestToken();
  }
```

**شرح:**
- لما الـ MyApp تتعمل أول مرة، نطلب الـ permissions والـ token.
- ده بيحصل **بعد** ما الـ UI تشتغل، عشان dialog الـ permission تظهر للمستخدم.

---

## 5. الـ Flow الكامل

### السيناريو 1: التطبيق Foreground

```
1. السيرفر يبعت FCM data message
2. Firebase يستلمه ويسلمه لـ awesome_notifications_fcm
3. mySilentDataHandle بتتنادى (في الـ main isolate)
4. نبني NotificationPayload من الـ data
5. نبني NotificationContent (شكل الإشعار)
6. createNotification → الإشعار يظهر في الـ tray
```

### السيناريو 2: التطبيق Background

```
1. السيرفر يبعت FCM data message
2. Flutter بيعمل background isolate
3. mySilentDataHandle بتتنادى في الـ background isolate
4. ★ ده اللي خلانا نحط @pragma('vm:entry-point') ★
5. الإشعار يتعرض
```

### السيناريو 3: التطبيق Terminated (مقفول)

```
1. السيرفر يبعت FCM data message
2. Android/iOS بيوقّظ Flutter
3. Flutter بيشغل isolate جديد
4. mySilentDataHandle بتشتغل
5. الإشعار يتعرض
```

### السيناريو 4: المستخدم يدوس على الإشعار (التطبيق Background)

```
1. onActionReceivedMethod بتتنادى في background isolate
2. نشوف الـ isolate port الـ main isolate سجله
3. نبعت الـ ReceivedAction للـ main isolate عبر SendPort
4. _receivePort في NotificationManager يستلم
5. يستدعي routeAction
6. _parseAction يحول الـ payload لـ NotificationAction
7. router.route(action) → navigation
```

### السيناريو 5: المستخدم يدوس على الإشعار (التطبيق Terminated)

```
1. الـ tap بيفتح التطبيق
2. main() بيشتغل
3. NotificationManager.initialize()
4. _getInitialNotificationAction() بيرجع الـ action
5. routeAction → navigation
```

---

## 6. Android/iOS Configuration

### Android

#### `AndroidManifest.xml` — الـ Permissions

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
- **ليه؟** Android 13+ يفرض permission صريح لإظهار الإشعارات.

```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```
- **ليه؟** عشان الاهتزاز مع الإشعار.

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```
- **ليه؟** عشان أي scheduled notifications تشتغل بعد restart الجهاز.

```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```
- **ليه؟** عشان الجهاز ينور الشاشة لما الإشعار يجي.

```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```
- **ليه؟** للمكالمات الواردة (full screen incoming call UI).

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```
- **ليه؟** Android 12+ يحتاج permission خاص للـ scheduled notifications.

#### `settings.gradle.kts`

```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```
- **ليه؟** الـ plugin اللي بيقرأ `google-services.json` ويهيئ Firebase تلقائياً.

#### `app/build.gradle.kts`

```kotlin
id("com.google.gms.google-services")
```
- **ليه?** نطبق الـ plugin في الـ app module.

### iOS

#### `Podfile`

```ruby
platform :ios, '15.0'
```
- **ليه 15.0؟** الحد الأدنى اللي awesome_notifications يدعمه.

#### Xcode Capabilities

1. **Push Notifications**: عشان iOS يقبل الـ APN notifications.
2. **Background Modes → Remote notifications**: عشان التطبيق يستلم data messages في الـ background.
3. **Background Modes → Background fetch**: عشان الـ background isolate يشتغل.
4. **App Groups**: awesome_notifications يستخدمها للـ shared storage بين الـ app والـ notification extension.

---

## 7. القواعد الذهبية (لازم تعرفها)

| القاعدة | السبب |
|--------|------|
| كل static method بتتنادى من native لازم `@pragma('vm:entry-point')` | عشان الـ tree-shaker ميمسحهاش في الـ release |
| `channelKey` في `NotificationContent` لازم يتطابق مع المسجل في `initialize` | لو غلط، الإشعار مش هيظهر |
| الـ `id` في `NotificationContent` لازم `int` | استخدم `payload.id.hashCode` |
| مفيش `BuildContext` في static methods | استخدم `GlobalKey<NavigatorState>` أو routing instance |
| الـ `IsolateNameServer` هو الطريقة الوحيدة للتواصل بين الـ isolates | الـ isolates مفيهاش shared memory |
| **مفيش** `firebase_messaging` أو `flutter_local_notifications` | بيتعارضوا مع awesome_notifications |

---

## 8. الـ Design Patterns المستخدمة

| Pattern | فين استخدمناه | السبب |
|---------|---------------|------|
| **Singleton** | `NotificationManager.instance` | نظام واحد بس في كل التطبيق |
| **Factory Method** | `NotificationPayload.fromMap()` | تحويل JSON لـ object آمن |
| **Sealed Classes** | `NotificationAction` | exhaustive switch — type safe routing |
| **Strategy** | `NotificationRouter` interface | نقدر نغيّر طريقة الـ routing (testing/production) |
| **Observer** | `ReceivePort` / `IsolateNameServer` | تواصل بين الـ isolates |
| **Switch Expressions** | `_buildContent`, `_parseAction` | كود أنظف وأقصر |

---

## 9. الأسئلة الشائعة

### س: ليه مستخدمناش `firebase_messaging`؟
**ج:** لأنه بيتعارض مع `awesome_notifications`. كمان `awesome_notifications_fcm` بديل كامل ليه ومدعوم بشكل أفضل لـ data-only messages.

### س: إيه الفرق بين `data` و `notification` في FCM payload؟
**ج:**
- `notification`: Firebase يعرض الإشعار تلقائياً (مش بنتحكم في شكله).
- `data`: إحنا اللي بنتحكم. أقوى وأمرن.

### س: ليه الـ id بنحوله لـ hashCode؟
**ج:** عشان `awesome_notifications` بياخد `int` بس، والـ id اللي جاي من السيرفر `String`. الـ `hashCode` بيحول الـ String لـ int unique.

### س: هل ممكن أبعت إشعار محلي بدون FCM؟
**ج:** آه، استخدم `AwesomeNotifications().createNotification(...)` مباشرة. النظام كله متبني عشان يدعم ده.

### س: لو حبيت أضيف نوع جديد من الإشعارات؟
**ج:**
1. ضيفه في `NotificationType` enum.
2. ضيف case في `_buildContent` للـ layout.
3. ضيف case في `_buildActionButtons` لو محتاج buttons.
4. لو محتاج action جديد، ضيفه في `NotificationAction` sealed class.

---

*Made with ❤️ for مبتدئين Flutter*

</div>
