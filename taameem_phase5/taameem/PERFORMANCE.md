# تحسينات الأداء في تعميم

## ما تم تطبيقه بالفعل

### 1. Prompt Caching (توفير 90% API)
في `ai_service.dart` — system prompt مُخزَّن في cache:
```dart
'cache_control': {'type': 'ephemeral'}
```
**النتيجة:** كل رسالة بعد الأولى تدفع 10% فقط من تكلفة الـ system prompt.

### 2. Firestore Real-time Streams
بدلاً من polling كل ثانية — نستخدم Streams:
```dart
FirestoreService.instance.streamActiveTaameems()
```
**النتيجة:** تحديث فوري بدون استهلاك إضافي.

### 3. Marker Clustering
في `home_screen.dart` — تجميع العلامات القريبة:
```dart
MarkerClusterLayerWidget(maxClusterRadius: 80)
```
**النتيجة:** الخريطة سريعة حتى مع 1000+ تعميم.

### 4. Image Caching
```dart
CachedNetworkImage(imageUrl: ...)
```
**النتيجة:** الصور تُحمَّل مرة واحدة وتُخزَّن محلياً.

### 5. Time Decay — Batch Update
في `firestore_service.dart`:
```dart
final batch = _db.batch();
// تحديث المنتهيات دفعة واحدة
await batch.commit();
```
**النتيجة:** عملية واحدة بدلاً من عمليات متعددة.

---

## تحسينات إضافية موصى بها قبل النشر

### أ — Firestore Indexes
أضف في Firebase Console → Firestore → Indexes:
```
Collection: taameems
Fields: status ASC, createdAt DESC
Fields: status ASC, expiresAt ASC, createdAt DESC
Fields: userId ASC, createdAt DESC
```

### ب — Image Compression
في `storage_service.dart` نضغط الصور قبل الرفع:
```dart
imageQuality: 85,  // ← موجود بالفعل
maxWidth: 1280,    // ← موجود بالفعل
```
لمزيد من الضغط: نزّل `flutter_image_compress` وخفّض إلى `imageQuality: 70`.

### ج — Lazy Loading للقائمة
بدلاً من تحميل 100 تعميم دفعة واحدة — استخدم Pagination:
```dart
// في firestore_service.dart أضف:
Future<List<TaameemModel>> getNextPage(DocumentSnapshot? lastDoc) async {
  var query = _taameems.where('status', isEqualTo: 'active').limit(20);
  if (lastDoc != null) query = query.startAfterDocument(lastDoc);
  final snap = await query.get();
  return snap.docs.map(TaameemModel.fromFirestore).toList();
}
```

### د — Widget Caching
استخدم `const` في كل مكان ممكن:
```dart
// بدلاً من:
Text('مرحباً')
// اكتب:
const Text('مرحباً')
```

### هـ — Shimmer Loading
في صفحة البحث موجود بالفعل. أضفه في الخريطة أيضاً.

### و — FCM Background Isolation
```dart
// في main.dart (موجود كـ comment):
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
```
ألغِ التعليق بعد ربط Firebase.

---

## أوامر مفيدة

```bash
# فحص الأداء
flutter analyze

# قياس حجم APK
flutter build apk --release --split-per-abi
ls -lh build/app/outputs/apk/release/

# تشغيل بوضع الإنتاج
flutter run --release

# فحص الأداء المرئي
flutter run --profile
# ثم افتح: http://localhost:9100
```
