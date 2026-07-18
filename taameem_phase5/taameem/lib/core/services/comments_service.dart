import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentsService {
  CommentsService._();
  static final instance = CommentsService._();
  final _db = FirebaseFirestore.instance;

  // ── تيار التعليقات لحظياً ──────────────────────────────────────────────
  Stream<List<CommentModel>> streamComments(String taameemId) =>
    _db.collection('taameems')
       .doc(taameemId)
       .collection('comments')
       .orderBy('createdAt', descending: false)
       .snapshots()
       .map((s) => s.docs
           .map((d) => CommentModel.fromMap(d.id, d.data()))
           .toList());

  // ── إضافة تعليق ────────────────────────────────────────────────────────
  Future<void> addComment({
    required String taameemId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    await _db.collection('taameems')
             .doc(taameemId)
             .collection('comments')
             .add(CommentModel(
               id:       '',
               userId:   userId,
               userName: userName,
               text:     text,
               createdAt: DateTime.now(),
             ).toMap());
  }

  // ── إعجاب بتعليق ──────────────────────────────────────────────────────
  Future<void> likeComment(String taameemId, String commentId) async {
    await _db.collection('taameems')
             .doc(taameemId)
             .collection('comments')
             .doc(commentId)
             .update({'likes': FieldValue.increment(1)});
  }
}
