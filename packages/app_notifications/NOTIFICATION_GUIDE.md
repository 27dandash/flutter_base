<div dir="rtl" align="right">

# شرح حزمة الإشعارات الاختيارية (FCM + Local Notifications)

> الحزمة دي بتعمل نفس سلوك الإشعارات في تطبيق رحول، لكن من غير أي حاجة خاصة بالمنتج (مفيش order ولا wallet). المنتج هو اللي بيعرّف أنواع الإشعارات والـ routes بتاعته.

## 1. الـ packages المستخدمة

| الـ package | بتعمل إيه |
|---|---|
| `firebase_core` | تهيئة Firebase (لازم تتعمل في التطبيق قبل `initialize`). |
| `firebase_messaging` | استقبال رسائل FCM، الـ token، الصلاحيات، وفتح الإشعار. |
| `flutter_local_notifications` | عرض الإشعار بنفسنا وإحنا في الـ foreground. |

## 2. حالات التطبيق

| الحالة | اللي بيحصل |
|---|---|
| **Foreground** | الـ OS مش بيعرض الرسالة (`setForegroundNotificationPresentationOptions` كلها false). `NotificationManager` هو اللي بيعرضها محليًا. |
| **Background / Terminated** | الـ OS بيعرض رسائل `notification` لوحده. الـ background handler بيتأكد بس إن Firebase اتهيّأ. |
| **الضغط على إشعار** | بيتعمل routing حسب النوع. |

## 3. Flow الـ initialize

الترتيب جوه `NotificationManager.initialize`:

1. `initializeLocalNotifications`: تهيئة الـ plugin وإنشاء الـ channel `high_importance_channel`.
2. `setForegroundPresentationOptions`: إيقاف عرض الـ OS للإشعارات في الـ foreground.
3. تسجيل الـ background handler.
4. الاشتراك في `onMessage` و`onMessageOpenedApp` و`onTokenRefresh`.
5. طلب الصلاحيات (لو `requestPermissionsOnInitialize` = true وده الافتراضي). الطلب بيحصل **مرة واحدة من Firebase بس** (`requestPermission`): بيغطي iOS وكمان `POST_NOTIFICATIONS` على أندرويد 13+. الـ `flutter_local_notifications` مبيطلبش إذن أبدًا، عشان مايظهرش dialog تاني بعد الرفض (مخالف لسياسة جوجل). لو حد نادى `requestPermissions()` في نفس الوقت بيشاركوا نفس الطلب.
6. `getInitialMessage`: لو التطبيق اتفتح من إشعار، بيتعمل routing ليه.
7. قراءة الـ FCM token (من غير ما تعطّل الـ initialize، وبتتعاد لحد 5 محاولات كل 3 ثواني لو فشلت).

الخطوات 2 و5 و6 لو فشلت ما بتوقفش التهيئة. فشل الخطوة 1 بيفشّل التهيئة ويرجّع `false` من غير ما يسيب listeners شغالة.

## 4. الرسالة في الـ Foreground

`_handleForeground` بالترتيب:

1. بتفرد الـ `data` لو جاية متداخلة (`data` جوه `data` أو JSON string).
2. تحدد النوع من `type` (ممكن يبقى string أو object فيه `value`/`key`) وبعدها `resolveType` لو موجود.
3. لو النوع `endsSession`: تعرض الإشعار وبعدها تنفّذ `onSessionEnd` مرة واحدة (single-flight)، وتتخطى الـ gate.
4. غير كده: `canHandle(data)`. لو رجّعت `false` الإشعار بيتجاهل. لو رمت exception بنعتبره مسموح.
5. تنادي الـ listeners المسجلة لنفس النوع.
6. تعرض الإشعار.

### اختيار العنوان والنص

| المنصة | العنوان | النص |
|---|---|---|
| Android | `data.title` ← `data.Title` ← `notification.title` ← `fallbackTitle` | `data.message` ← `body` ← `Body` ← `body_ar` ← `body_en` ← `notification.body` |
| iOS | `notification.title` ← `data.title` ← `data.Title` ← `fallbackTitle` | `notification.body` ← `data.body` ← `Body` ← `message` ← `body_ar` ← `body_en` |

الـ `fallbackTitle` الافتراضي «إشعار جديد» وبيتغير من `NotificationPresentation`.

الـ payload المحلي هو `json.encode(message.toMap())` فبنقدر نرجّع `RemoteMessage` كامل لما المستخدم يضغط.

## 5. الضغط على إشعار

أي ضغطة (إشعار محلي، إشعار الـ system tray، أو الإشعار اللي فتح التطبيق) بتعدّي على نفس الطريق:

1. تفرد الـ `data`.
2. لو النوع مش `endsSession`: تعدّي على `canHandle`. لو `false` بتتجاهل الضغطة.
3. لو النوع مسجّل: `endsSession` ينفّذ `onSessionEnd`، وغير كده ينفّذ `navigate(data)` (ولو `navigate` فاضي مفيش حاجة تحصل).
4. لو النوع مش مسجّل: بيتم الرجوع للـ contract العام `action_type` (`navigate_chat` / `navigate_screen` / `open_url`) عن طريق `NotificationRouter`. الـ `open_url` بيتفحص بـ `NotificationUrlPolicy` (HTTPS بس افتراضيًا).

أي exception جوه `navigate` بيتحصر ومش بيوقع التطبيق.

## 6. تعريف أنواع المنتج

```dart
NotificationTypeRegistry(
  types: [
    NotificationTypeSpec('order_created', navigate: (data) => openOrder(data['order_id'])),
    NotificationTypeSpec('admin_notify'),                       // مفيش navigation
    NotificationTypeSpec('blocked', endsSession: true),         // logout
  ],
  resolveType: (type, payload) =>
      type == 'text' && payload['sender_id'] != null ? 'new_message' : type,
)
```

الـ `data` اللي بتوصل لـ `navigate` هي الـ payload بعد التفريد: لو الـ `id` الخارجي موجود وفي `data` مفيش `id`، بيتنقل لـ `notification_id` ويتشال من `id` (عشان `id` ما يتلخبطش مع id الـ entity).

## 7. الـ Token

* `onFcmToken` بيتنادى بأول token وبعدها عند كل refresh.
* `NotificationManager.instance.deviceToken` فيه آخر token اتقرأ (أو string فاضي).
* `tokenRefreshes` stream بيطلّع كل token جديد.
* `NotificationRegistrationCoordinator` (في `registration/`) مستقل عن الـ plugins ويفصل بين installation id و FCM token والـ user.

## 8. إعدادات النظام

**Android:**
* `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`
* `coreLibraryDesugaring` مفعّل (مطلوب لـ `flutter_local_notifications`).
* الأيقونة الافتراضية `@mipmap/ic_launcher`.
* اختياري: `com.google.firebase.messaging.default_notification_channel_id` = `high_importance_channel` علشان إشعارات الـ tray في الخلفية تستخدم نفس الـ channel.

**iOS:**
* Push Notifications capability و`aps-environment` في الـ entitlements.
* `UIBackgroundModes` فيها `remote-notification`.
* رفع APNs key على Firebase.

## 9. ملاحظات مهمة على الـ server

* في الـ Android، الإشعار في الخلفية بيتعرض بس لو الرسالة فيها `notification`. رسالة **data-only** مش هتتعرض والتطبيق في الخلفية أو مقفول، لأن الـ background handler الافتراضي مش بينشئ إشعار.
* لو السيرفر بيبعت data-only، مرّر `backgroundHandler` بتاعك يعرض الإشعار.
* الـ handler لازم يكون top-level function عليها `@pragma('vm:entry-point')`.

## 10. الاختبار

`NotificationManagerPlatform` هو الـ seam. الاختبارات بتستخدم `test/support/fake_notification_platform.dart` فمفيش native plugin بيتلمس:

```bash
cd packages/app_notifications && flutter analyze && flutter test
```

</div>
