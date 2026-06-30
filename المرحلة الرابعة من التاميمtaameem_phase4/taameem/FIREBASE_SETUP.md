# ربط Firebase بتطبيق تعميم — خطوة بخطوة

## الخطوة 1: إنشاء مشروع Firebase

1. اذهب إلى: https://console.firebase.google.com
2. اضغط **"Add project"**
3. اسم المشروع: `taameem`
4. اختر المنطقة: **me-central1** (الأقرب للسعودية)

---

## الخطوة 2: تفعيل الخدمات المطلوبة

### أ — Authentication (تسجيل الدخول)
1. من القائمة الجانبية: **Authentication → Get started**
2. اضغط **Sign-in method**
3. فعّل: **Phone**

### ب — Firestore (قاعدة البيانات)
1. **Firestore Database → Create database**
2. اختر: **Start in test mode** (للتطوير)
3. المنطقة: **me-central1**

### ج — Storage (رفع الصور)
1. **Storage → Get started**
2. اختر: **Start in test mode**

---

## الخطوة 3: ربط التطبيق بـ Firebase

افتح Terminal داخل مجلد `taameem` وشغّل بالترتيب:

```bash
# 1. تثبيت أداة FlutterFire
dart pub global activate flutterfire_cli

# 2. تسجيل الدخول لـ Google
firebase login

# 3. ربط المشروع (يُنشئ firebase_options.dart تلقائياً)
flutterfire configure
```

اختر مشروع `taameem` عند الطلب.

---

## الخطوة 4: فعّل firebase_options في main.dart

بعد تشغيل الأمر، افتح `lib/main.dart` وأزل علامة التعليق عن هذا السطر:

```dart
// قبل:
// import 'firebase_options.dart';

// بعد:
import 'firebase_options.dart';
```

وأيضاً في دالة Firebase.initializeApp:
```dart
// قبل:
await Firebase.initializeApp();

// بعد:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## الخطوة 5: إعداد Android

افتح: `android/app/build.gradle`
تأكد أن `minSdkVersion` = **21** أو أعلى:
```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

---

## الخطوة 6: إعداد iOS

افتح: `ios/Podfile`
تأكد أن السطر الأول هو:
```ruby
platform :ios, '14.0'
```

ثم شغّل:
```bash
cd ios && pod install && cd ..
```

---

## الخطوة 7: قواعد Firestore للأمان

في Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // التعميمات: يقرأها الجميع، يكتبها المسجل فقط
    match /taameems/{taameemId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // المستخدمون: كل مستخدم يرى بياناته فقط
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
    }
  }
}
```

---

## الخطوة 8: قواعد Storage للأمان

في Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /taameems/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null 
        && request.resource.size < 5 * 1024 * 1024; // 5 MB كحد أقصى
    }
  }
}
```

---

## الخطوة 9: تشغيل التطبيق

```bash
flutter pub get
flutter run
```

---

## ملاحظات مهمة

- **رقم الهاتف للاختبار**: في Firebase Console → Authentication → Sign-in method → Phone → Test phone numbers، أضف رقماً تجريبياً مثل `+966500000001` ورمز `123456`

- **تكلفة Firebase**: الباقة المجانية (Spark) كافية للتطوير. ترقية لـ (Blaze) عند الإطلاق الفعلي.

- **Firestore indexes**: إذا ظهر خطأ `index`, افتح الرابط الموجود في الخطأ مباشرة لإنشاء الـ index تلقائياً.
