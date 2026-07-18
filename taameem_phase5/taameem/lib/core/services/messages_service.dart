import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessagesService {
  MessagesService._();
  static final instance = MessagesService._();
  final _db = FirebaseFirestore.instance;

  // chatId = الترتيب الأبجدي لـ userId1_userId2 لضمان الاتساق
  String chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // ── تيار الرسائل لحظياً ────────────────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String cId) =>
    _db.collection('chats')
       .doc(cId)
       .collection('messages')
       .orderBy('createdAt', descending: false)
       .snapshots()
       .map((s) => s.docs
           .map((d) => MessageModel.fromMap(d.id, d.data()))
           .toList());

  // ── إرسال رسالة ───────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String taameemTitle,
    required String otherUserName,
  }) async {
    final ref = _db.collection('chats').doc(chatId);

    // أنشئ/حدّث بيانات المحادثة
    await ref.set({
      'taameemTitle':   taameemTitle,
      'participants':   [senderId],
      'lastMessage':    text,
      'lastMessageAt':  FieldValue.serverTimestamp(),
      'otherUserName':  otherUserName,
    }, SetOptions(merge: true));

    // أضف الرسالة
    await ref.collection('messages').add(
      MessageModel(
        id:        '',
        senderId:  senderId,
        text:      text,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  // ── تحديد الرسائل كمقروءة ─────────────────────────────────────────────
  Future<void> markRead(String chatId, String myId) async {
    final unread = await _db
      .collection('chats').doc(chatId)
      .collection('messages')
      .where('isRead', isEqualTo: false)
      .where('senderId', isNotEqualTo: myId)
      .get();

    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
