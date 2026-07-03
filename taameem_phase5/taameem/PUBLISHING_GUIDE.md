# دليل نشر تعميم على المتاجر

---

## أولاً — App Store (iOS / Apple)

### المتطلبات الأساسية
- حساب Apple Developer ($99/سنة): https://developer.apple.com
- جهاز Mac مع Xcode 15+
- تفعيل 2FA على Apple ID

### الخطوة 1: إعداد المشروع
افتح `ios/Runner.xcworkspace` في Xcode وتحقق من:
```
Bundle Identifier: com.taameem.app
Version: 1.0.0
Build: 1
Deployment Target: iOS 14.0
```

### الخطوة 2: أيقونات التطبيق
ضع أيقونة 1024×1024 PNG في:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```
(Xcode يولّد باقي الأحجام تلقائياً)

### الخطوة 3: الأذونات (Info.plist)
أضف في `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>تعميم يحتاج موقعك لعرض التعميمات القريبة</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>تعميم يحتاج موقعك لإرسال إشعارات التعميمات القريبة</string>

<key>NSCameraUsageDescription</key>
<string>التقط صوراً لإرفاقها بالتعميم</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>اختر صوراً من معرضك لإرفاقها بالتعميم</string>

<key>NSMicrophoneUsageDescription</key>
<string>سجّل ملاحظات صوتية للتعميم</string>
```

### الخطوة 4: بناء للنشر
```bash
flutter build ipa --release
```

### الخطوة 5: رفع على TestFlight
```bash
# باستخدام Xcode Organizer
# أو باستخدام xcrun altool:
xcrun altool --upload-app -f build/ios/ipa/taameem.ipa \
  -u "YOUR_APPLE_ID" -p "APP_SPECIFIC_PASSWORD"
```

### الخطوة 6: App Store Connect
1. اذهب إلى: https://appstoreconnect.apple.com
2. أنشئ تطبيقاً جديداً
3. أضف لقطات الشاشة (Arabic RTL)
4. اكتب الوصف العربي
5. أرسل للمراجعة (مدة: 1-3 أيام)

### نصوص المتجر (العربي)
**الاسم:** تعميم — أمان وتواصل المجتمع
**الوصف:**
```
تعميم — منصتك المجتمعية لنشر التعميمات وتبادل المعلومات بشكل فوري وذكي.

✅ خريطة تفاعلية حية لتعميمات منطقتك
🤖 ذكاء اصطناعي يصنف وينشر التعميم نيابةً عنك
🔔 إشعارات ذكية للأحداث القريبة منك
🔍 بحث دقيق بالنص والصور
🤝 ساهم في أمان مجتمعك

أنواع التعميمات: فقدان أشخاص، سرقة، طوارئ، تحذيرات، إيجاد مفقودات، وأكثر.
```

---

## ثانياً — Google Play (Android)

### المتطلبات
- حساب Google Play Developer ($25 مرة واحدة)
- https://play.google.com/console

### الخطوة 1: توقيع التطبيق
```bash
# إنشاء keystore (مرة واحدة فقط، احتفظ به بأمان)
keytool -genkey -v -keystore ~/taameem-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias taameem

# أضف في android/key.properties:
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=taameem
storeFile=/path/to/taameem-key.jks
```

### الخطوة 2: إعداد build.gradle
في `android/app/build.gradle` أضف:
```gradle
android {
    defaultConfig {
        applicationId "com.taameem.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release { signingConfig signingConfigs.release }
    }
}
```

### الخطوة 3: الأذونات (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### الخطوة 4: بناء AAB للنشر
```bash
flutter build appbundle --release
# الملف: build/app/outputs/bundle/release/app-release.aab
```

### الخطوة 5: رفع على Google Play
1. أنشئ تطبيقاً جديداً في Play Console
2. ارفع الـ AAB
3. أضف لقطات الشاشة العربية (1080×1920)
4. أضف الوصف والفئة: **أدوات / مجتمع**
5. أكمل استبيان محتوى التطبيق
6. أرسل للمراجعة (مدة: ساعات-3 أيام)

---

## ثالثاً — لقطات الشاشة المطلوبة

قائمة اللقطات الضرورية:
1. الشاشة الرئيسية (الخريطة مع تعميمات)
2. صفحة الذكاء الاصطناعي (محادثة)
3. صفحة البحث (نتائج)
4. بطاقة تعميم مفتوحة
5. صفحة رفع التعميم
6. لقطة Onboarding

**للـ iOS:** 6.5 بوصة (iPhone 14 Pro Max) + 5.5 بوصة (iPhone 8 Plus)
**للـ Android:** 1080×1920 px

---

## رابعاً — قائمة التحقق قبل النشر

- [ ] تشغيل التطبيق على iOS حقيقي (ليس Simulator)
- [ ] تشغيل التطبيق على Android حقيقي
- [ ] اختبار تسجيل الدخول برقم هاتف حقيقي
- [ ] اختبار رفع تعميم كامل (صورة + موقع)
- [ ] اختبار إشعار يصل للهاتف
- [ ] اختبار الخريطة والتكبير/التصغير
- [ ] اختبار صفحة الذكاء الاصطناعي
- [ ] قواعد Firestore Security مُفعَّلة
- [ ] مفتاح API محمي (ليس في الكود)
- [ ] App Store / Play Store Listing باللغة العربية
- [ ] Privacy Policy منشورة على رابط خارجي
