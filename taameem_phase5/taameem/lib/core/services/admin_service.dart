import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taameem/core/models/taameem_model.dart';

enum UserRole { user, admin, owner }

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final _db = FirebaseFirestore.instance;

  // ─── جلب دور المستخدم ────────────────────────────────────────────────────
  Future<UserRole> getUserRole(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return UserRole.user;
      final role = doc.data()?['role'] as String? ?? 'user';
      switch (role) {
        case 'owner': return UserRole.owner;
        case 'admin': return UserRole.admin;
        default:      return UserRole.user;
      }
    } catch (_) {
      return UserRole.user;
    }
  }

  // ─── إحصائيات لوحة التحكم ────────────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final taameems = await _db.collection('taameems').get();
      final users    = await _db.collection('users').get();

      final active   = taameems.docs.where((d) => d['status'] == 'active').length;
      final resolved = taameems.docs.where((d) => d['status'] == 'resolved').length;
      final expired  = taameems.docs.where((d) => d['status'] == 'expired').length;

      // تعميمات اليوم
      final today    = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayTaameems = taameems.docs.where((d) {
        final ts = (d['createdAt'] as Timestamp?)?.toDate();
        return ts != null && ts.isAfter(todayStart);
      }).length;

      return {
        'total':    taameems.docs.length,
        'active':   active,
        'resolved': resolved,
        'expired':  expired,
        'today':    todayTaameems,
        'users':    users.docs.length,
      };
    } catch (_) {
      return {'total': 0, 'active': 0, 'resolved': 0,
              'expired': 0, 'today': 0, 'users': 0};
    }
  }

  // ─── إحصائيات التعميمات حسب النوع ───────────────────────────────────────
  Future<Map<String, int>> getTypeBreakdown() async {
    try {
      final snap = await _db.collection('taameems')
          .where('status', isEqualTo: 'active')
          .get();

      final breakdown = <String, int>{};
      for (final doc in snap.docs) {
        final type = doc['type'] as String? ?? 'inquiry';
        breakdown[type] = (breakdown[type] ?? 0) + 1;
      }
      return breakdown;
    } catch (_) {
      return {};
    }
  }

  // ─── بث كل التعميمات (للمسؤول) ──────────────────────────────────────────
  Stream<List<TaameemModel>> streamAllTaameems({String? filterStatus}) {
    var query = _db.collection('taameems')
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (filterStatus != null) {
      query = _db.collection('taameems')
          .where('status', isEqualTo: filterStatus)
          .orderBy('createdAt', descending: true)
          .limit(100);
    }

    return query.snapshots().map(
        (s) => s.docs.map(TaameemModel.fromFirestore).toList());
  }

  // ─── حذف تعميم (مسؤول) ───────────────────────────────────────────────────
  Future<void> deleteTaameem(String id) async {
    await _db.collection('taameems').doc(id).delete();
  }

  // ─── تغيير حالة تعميم (مسؤول) ───────────────────────────────────────────
  Future<void> setTaameemStatus(String id, String status) async {
    await _db.collection('taameems').doc(id).update({'status': status});
  }

  // ─── بث المستخدمين ───────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _db.collection('users')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // ─── حظر/رفع حظر مستخدم ─────────────────────────────────────────────────
  Future<void> setUserBanned(String userId, bool banned) async {
    await _db.collection('users').doc(userId).update({'banned': banned});
  }
}
