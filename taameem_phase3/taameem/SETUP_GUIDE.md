# دليل إعداد تطبيق تعميم — خطوة بخطوة

## المرحلة الأولى مكتملة ✅

---

## ما تم بناؤه في هذه المرحلة:
- ✅ هيكل المشروع الكامل
- ✅ نظام الألوان Marble Palette + Glassmorphism
- ✅ خط Cairo العربي
- ✅ اتجاه RTL كامل
- ✅ شاشة البداية (Splash) مع الشعار المتحرك
- ✅ شاشة تسجيل الدخول برقم الهاتف
- ✅ شاشة رمز التحقق OTP
- ✅ الشاشة الرئيسية مع خريطة تفاعلية
- ✅ علامات الخريطة بألوان التعميمات
- ✅ القائمة الجانبية اليمنى
- ✅ بطاقة التعميم عند الضغط على العلامة
- ✅ شريط التنقل السفلي
- ✅ صفحات placeholder للمراحل القادمة

---

## خطوات التثبيت والتشغيل

### الخطوة 1: تثبيت Flutter
1. اذهب إلى: https://docs.flutter.dev/get-started/install
2. اختر نظامك (Windows / Mac / Linux)
3. حمّل Flutter SDK واتبع التعليمات

### الخطوة 2: تثبيت Android Studio أو Xcode
- **Android**: حمّل Android Studio من https://developer.android.com/studio
- **iOS** (Mac فقط): حمّل Xcode من App Store

### الخطوة 3: ضع ملفات التطبيق
1. أنشئ مجلداً اسمه `taameem`
2. ضع فيه جميع الملفات التي استلمتها

### الخطوة 4: تثبيت الحزم
افتح Terminal داخل مجلد `taameem` وشغّل:
```
flutter pub get
```

### الخطوة 5: تشغيل التطبيق (بدون Firebase مؤقتاً)
```
flutter run
```

---

## إعداد Firebase (مطلوب للتطبيق الكامل)

### الخطوة 1: إنشاء مشروع Firebase
1. اذهب إلى: https://console.firebase.google.com
2. اضغط "Add project"
3. اسم المشروع: taameem

### الخطوة 2: تفعيل Phone Authentication
1. داخل مشروع Firebase → Authentication
2. اضغط "Get started"
3. اختر "Phone" وفعّله

### الخطوة 3: تفعيل Firestore
1. Firestore Database → Create database
2. اختر المنطقة الأقرب (me-central1 للسعودية)

### الخطوة 4: ربط التطبيق بـ Firebase
```
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## ملاحظات مهمة للمرحلة الأولى

1. **الخريطة**: تعمل الآن بـ OpenStreetMap المجانية.
   - يمكن استبدالها بـ ESRI Satellite في أي وقت.

2. **البيانات**: حالياً بيانات تجريبية داخل الكود.
   - ستُستبدل ببيانات Firebase في المرحلة الثانية.

3. **تسجيل الدخول**: يعمل بدون Firebase حالياً (أي رقم يدخل).
   - سيُربط بـ Firebase Auth في المرحلة الثانية.

4. **Prompt Caching**: سيُطبَّق في المرحلة الثالثة مع صفحة الذكاء الاصطناعي.

---

## ما قادم في المرحلة الثانية:
- خريطة حية مرتبطة بـ Firebase
- رفع التعميمات الحقيقية
- Marker Clustering (تجميع العلامات)
- التلاشي الزمني التلقائي
- Firebase Auth الحقيقي
