# تعميم — TAAMEEM
### منصة التواصل المجتمعي لأمن وسلامة المجتمع السعودي

---

## هيكل المشروع

```
lib/
├── main.dart                          ← نقطة البداية
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            ← Marble Palette + ألوان التعميمات
│   │   └── app_constants.dart         ← ثوابت التطبيق
│   ├── models/
│   │   ├── taameem_model.dart         ← نموذج التعميم
│   │   └── chat_message.dart          ← نموذج رسائل AI
│   ├── services/
│   │   ├── firestore_service.dart     ← قاعدة البيانات
│   │   ├── ai_service.dart            ← Anthropic API + Prompt Caching
│   │   ├── notification_service.dart  ← Firebase Cloud Messaging
│   │   ├── location_service.dart      ← الموقع الجغرافي
│   │   ├── storage_service.dart       ← رفع الصور
│   │   ├── matching_service.dart      ← ربط التعميمات تلقائياً
│   │   └── admin_service.dart         ← صلاحيات المسؤول
│   ├── theme/
│   │   └── app_theme.dart             ← Theme + خط Cairo + RTL
│   └── widgets/
│       ├── animated_background.dart   ← خلفية الأكوار المتحركة
│       ├── glass_card.dart            ← بطاقة Glassmorphism
│       ├── taameem_bottom_nav.dart    ← شريط التنقل السفلي
│       └── taameem_list_card.dart     ← بطاقة التعميم (قائمة)
└── features/
    ├── auth/                          ← تسجيل الدخول + OTP
    ├── onboarding/                    ← شاشات التعريف (4 شاشات)
    ├── home/                          ← الخريطة الرئيسية
    ├── ai_chat/                       ← واجهة الذكاء الاصطناعي
    ├── upload/                        ← رفع التعميمات
    ├── search/                        ← البحث المتقدم
    ├── notifications/                 ← الإشعارات
    ├── profile/                       ← الملف الشخصي
    ├── achievements/                  ← الإنجازات
    ├── settings/                      ← الإعدادات
    ├── admin/                         ← لوحة تحكم المسؤول
    └── legal/                         ← الخصوصية والشروط
```

---

## التشغيل السريع

```bash
# 1. تثبيت الحزم
flutter pub get

# 2. تشغيل (بدون Firebase مؤقتاً)
flutter run

# 3. ربط Firebase (بعد إنشاء المشروع)
flutterfire configure

# 4. إضافة مفتاح AI
# في lib/core/services/ai_service.dart:
# static const String _apiKey = 'sk-ant-...';
```

---

## الملفات الإرشادية

| الملف | الغرض |
|-------|--------|
| `SETUP_GUIDE.md` | تثبيت Flutter وتشغيل التطبيق |
| `FIREBASE_SETUP.md` | ربط Firebase خطوة بخطوة |
| `AI_SETUP.md` | إعداد Anthropic API + Prompt Caching |
| `PUBLISHING_GUIDE.md` | نشر على App Store و Google Play |
| `PERFORMANCE.md` | تحسينات الأداء |

---

## التقنيات المستخدمة

| الغرض | التقنية |
|--------|---------|
| Framework | Flutter 3.22+ |
| قاعدة البيانات | Firebase Firestore |
| التخزين | Firebase Storage |
| المصادقة | Firebase Auth (Phone) |
| الإشعارات | Firebase Cloud Messaging |
| الخريطة | flutter_map + OpenStreetMap |
| التجميع | flutter_map_marker_cluster |
| الذكاء الاصطناعي | Anthropic Claude (Haiku + Sonnet) |
| الخط | Google Fonts - Cairo |
| الرسوم المتحركة | flutter_animate |
| الصور | CachedNetworkImage |
| الموقع | geolocator |

---

## نظام الألوان — Marble Palette

| اللون | الكود | الاستخدام |
|-------|-------|-----------|
| أبيض كريمي | `#FDFCF8` | الخلفية الرئيسية |
| بيج دافئ | `#E8E0D0` | خلفيات البطاقات |
| ذهبي | `#B8943A` | الشعار والتفاصيل |
| زمردي | `#3D8F7E` | الأزرار الرئيسية |
| أخضر غابي | `#235C4E` | النصوص |
| شبه أسود | `#1A3028` | العناوين |
