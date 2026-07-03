import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// نموذج الإشعار المحلي
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;       // 'nearby' | 'match' | 'update' | 'expiry' | 'system'
  final String? taameemId;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.taameemId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id:        doc.id,
      title:     d['title'] ?? '',
      body:      d['body'] ?? '',
      type:      d['type'] ?? 'system',
      taameemId: d['taameemId'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isRead:    d['isRead'] ?? false,
    );
  }

  IconData get icon {
    switch (type) {
      case 'nearby':  return Icons.location_on_rounded;
      case 'match':   return Icons.compare_arrows_rounded;
      case 'update':  return Icons.update_rounded;
      case 'expiry':  return Icons.timer_off_rounded;
      default:        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'nearby':  return const Color(0xFF3D8F7E);
      case 'match':   return const Color(0xFFB8943A);
      case 'update':  return const Color(0xFF7BBFB0);
      case 'expiry':  return const Color(0xFFDBA73A);
      default:        return const Color(0xFF9E9E9E);
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24)   return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  // ─── تهيئة الإشعارات ─────────────────────────────────────────────────────
  Future<void> initialize(String userId) async {
    // طلب الإذن
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // الاشتراك في topic الإشعارات العامة
    await _fcm.subscribeToTopic('all_taameems');

    // حفظ FCM token في Firestore
    final token = await _fcm.getToken();
    if (token != null && userId.isNotEmpty) {
      await _db.collection('users').doc(userId).set(
        {'fcmToken': token, 'updatedAt': Timestamp.now()},
        SetOptions(merge: true),
      );
    }

    // تحديث Token عند تغييره
    _fcm.onTokenRefresh.listen((newToken) async {
      if (userId.isNotEmpty) {
        await _db.collection('users').doc(userId).update({'fcmToken': newToken});
      }
    });

    // معالجة الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // معالجة النقر على الإشعار من الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  void _handleForeground(RemoteMessage msg) {
    debugPrint('📩 إشعار مقدمة: ${msg.notification?.title}');
    // TODO: عرض SnackBar أو Dialog
  }

  void _handleTap(RemoteMessage msg) {
    debugPrint('👆 نقر على إشعار: ${msg.data}');
    // TODO: الانتقال للتعميم المعني
  }

  // ─── الاشتراك حسب المدينة ─────────────────────────────────────────────────
  Future<void> subscribeToCity(String city) async {
    await _fcm.subscribeToTopic('city_$city');
  }

  Future<void> unsubscribeFromCity(String city) async {
    await _fcm.unsubscribeFromTopic('city_$city');
  }

  // ─── بث الإشعارات من Firestore (حقيقية) ─────────────────────────────────
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromFirestore).toList());
  }

  // ─── تمييز الإشعار كمقروء ────────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── إشعارات تجريبية للعرض ────────────────────────────────────────────────
  static List<AppNotification> getMockNotifications() => [
    AppNotification(
      id: '1', type: 'nearby',
      title: 'تعميم جديد في منطقتك',
      body: 'تم نشر تعميم سرقة في حي النرجس، على بُعد 2 كم',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: '2', type: 'match',
      title: '🎯 تطابق محتمل وُجد!',
      body: 'تعميم "إيجاد شيء" يتطابق مع تعميمك "فقدان محفظة"',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: '3', type: 'update',
      title: 'تحديث على تعميمك',
      body: 'تم تعليق جديد على تعميم المفقودات الذي نشرته',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: '4', type: 'expiry',
      title: 'تعميمك سينتهي قريباً',
      body: 'تعميم "سيارة كامري مسروقة" سينتهي خلال 24 ساعة. اضغط لتجديده',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: '5', type: 'nearby',
      title: 'تحذير في المنطقة',
      body: 'تم إصدار تحذير عام في حي العليا',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: '6', type: 'match',
      title: '🎯 تطابق في الصور',
      body: 'الذكاء الاصطناعي وجد صورة مشابهة لتعميمك المفقود',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
  ];
}
