# إعداد الذكاء الاصطناعي في تعميم

## الخطوة 1: الحصول على مفتاح Anthropic API

1. اذهب إلى: https://console.anthropic.com
2. أنشئ حساباً أو سجّل الدخول
3. من القائمة: **API Keys → Create Key**
4. انسخ المفتاح واحتفظ به

---

## الخطوة 2: وضع المفتاح في التطبيق

افتح الملف:
```
lib/core/services/ai_service.dart
```

ابحث عن هذا السطر:
```dart
static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
```

استبدله بمفتاحك:
```dart
static const String _apiKey = 'sk-ant-api03-XXXXXXXXXX';
```

---

## ⚠️ تنبيه أمني مهم

**لا تضع مفتاح API في الكود مباشرة عند النشر على المتاجر.**

### الحل الآمن — Firebase Remote Config:

```dart
// في ai_service.dart — بديل آمن
import 'package:firebase_remote_config/firebase_remote_config.dart';

Future<String> _getApiKey() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();
  return remoteConfig.getString('anthropic_api_key');
}
```

### الحل الأكثر أماناً — Cloud Functions:
اجعل التطبيق يرسل الطلب إلى Firebase Cloud Function،
والـ Function هي التي تتصل بـ Anthropic API مع المفتاح المخزّن في البيئة.

---

## كيف يعمل Prompt Caching

### المشكلة بدون Caching:
- كل رسالة ترسل System Prompt (≈ 1500 token) + رسالة المستخدم
- 100 رسالة × 1500 token = 150,000 token تُحسب وتُدفع

### مع Prompt Caching:
- System Prompt يُرسل ويُخزَّن في أول رسالة فقط
- كل رسالة بعدها تقرأ من الـ cache بتكلفة 10% فقط
- 100 رسالة × 150 token بدلاً من 1500 = توفير 90%

### كيف فعّلناه في الكود:
```dart
// في ai_service.dart
headers: {
  'anthropic-beta': 'prompt-caching-2024-07-31', // ← تفعيل الميزة
},
body: {
  'system': [
    {
      'type': 'text',
      'text': _systemPrompt,
      'cache_control': {'type': 'ephemeral'}, // ← تخزين System Prompt
    }
  ],
}
```

---

## اختيار النموذج

في `ai_service.dart`:

| النموذج | الاستخدام | التكلفة |
|---------|-----------|---------|
| `claude-haiku-4-5-20251001` | المحادثة اليومية والتصنيف | الأرخص |
| `claude-sonnet-4-6` | تحليل الصور والمهام المعقدة | متوسط |

---

## اختبار الذكاء الاصطناعي

بعد إضافة المفتاح، جرّب هذه العبارات في المحادثة:

1. "سرقت سيارتي كامري بيضاء" — يجب أن يصنّف كسرقة ويطلب تفاصيل
2. "فقدت قطتي" — يجب أن يصنّف كفقدان حيوان
3. "وجدت محفظة" — يجب أن يصنّف كإيجاد شيء
4. "هل أنت بخير؟" — يجب أن يرفض ويقول أنه مختص بالتطبيق فقط
