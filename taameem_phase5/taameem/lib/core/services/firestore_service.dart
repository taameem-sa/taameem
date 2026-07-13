import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:taameem/core/constants/app_constants.dart';
import 'package:taameem/core/models/taameem_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── مرجع مجموعة التعميمات ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _taameems =>
      _db.collection('taameems');

  // ──────────────────────────────────────────────────────────────────────────
  //  رفع تعميم جديد
  // ──────────────────────────────────────────────────────────────────────────
  Future<String> uploadTaameem(TaameemModel taameem) async {
    try {
      final docRef = await _taameems
          .add(taameem.toFirestore())
          .timeout(const Duration(seconds: 20));
      return docRef.id;
    } on TimeoutException {
      throw Exception(
          'انتهت مهلة الاتصال بـ Firestore. تحقق من الشبكة ثم أعد المحاولة.');
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'فشل رفع التعميم إلى Firestore (${e.code}).',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  بث التعميمات النشطة في الوقت الفعلي
  // ──────────────────────────────────────────────────────────────────────────
  Stream<List<TaameemModel>> streamActiveTaameems() {
    return _taameems
        .where('status', isEqualTo: 'active')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaameemModel.fromFirestore(doc))
            .toList());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  بث تعميمات مستخدم معين
  // ──────────────────────────────────────────────────────────────────────────
  Stream<List<TaameemModel>> streamUserTaameems(String userId) {
    return _taameems
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaameemModel.fromFirestore(doc))
            .toList());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  جلب تعميم واحد
  // ──────────────────────────────────────────────────────────────────────────
  Future<TaameemModel?> getTaameem(String id) async {
    final doc = await _taameems.doc(id).get();
    if (!doc.exists) return null;
    return TaameemModel.fromFirestore(doc);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  تحديث حالة التعميم
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateStatus(String id, String status) async {
    await _taameems.doc(id).update({'status': status});
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  تجديد عمر التعميم (إعادة تنشيطه)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> renewTaameem(String id, String type) async {
    final days = AppConstants.decayDays[type] ?? 3;
    final newExpiry = DateTime.now().add(Duration(days: days));
    await _taameems.doc(id).update({
      'expiresAt': Timestamp.fromDate(newExpiry),
      'status': 'active',
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  زيادة عدد المشاهدات
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> incrementView(String id) async {
    await _taameems.doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  البحث النصي
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<TaameemModel>> searchTaameems(String query) async {
    // بحث بالعنوان (Firestore لا يدعم full-text ، لذا نستخدم range query)
    final snapshot = await _taameems
        .where('status', isEqualTo: 'active')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) => TaameemModel.fromFirestore(doc)).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  البحث حسب النوع
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<TaameemModel>> getTaameemsByType(String type) async {
    final snapshot = await _taameems
        .where('status', isEqualTo: 'active')
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => TaameemModel.fromFirestore(doc)).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  تشغيل آلية التلاشي الزمني (يُستدعى عند فتح التطبيق)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> runTimeDecay() async {
    final now = Timestamp.now();

    // البحث عن التعميمات المنتهية الصلاحية
    final expired = await _taameems
        .where('status', isEqualTo: 'active')
        .where('expiresAt', isLessThan: now)
        .get();

    // تحديثها دفعة واحدة
    final batch = _db.batch();
    for (final doc in expired.docs) {
      batch.update(doc.reference, {'status': 'expired'});
    }
    await batch.commit();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  حذف تعميم (المالك فقط)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteTaameem(String id) async {
    await _taameems.doc(id).delete();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  تحديث الموقع الافتراضي للمستخدم (لاستهداف الإشعارات الجغرافية)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> upsertUserDefaultLocation(String userId, LatLng location) async {
    await _db.collection('users').doc(userId).set({
      'defaultLocationLat': location.latitude,
      'defaultLocationLng': location.longitude,
      'defaultLocationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

