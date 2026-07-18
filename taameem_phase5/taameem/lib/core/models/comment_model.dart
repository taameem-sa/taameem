import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final int likes;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.likes = 0,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> m) =>
    CommentModel(
      id:        id,
      userId:    m['userId']   ?? '',
      userName:  m['userName'] ?? 'مستخدم',
      text:      m['text']     ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes:     m['likes']    ?? 0,
    );

  Map<String, dynamic> toMap() => {
    'userId':    userId,
    'userName':  userName,
    'text':      text,
    'createdAt': FieldValue.serverTimestamp(),
    'likes':     likes,
  };

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes  < 1)  return 'الآن';
    if (diff.inMinutes  < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours    < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  String get initials => userName.isNotEmpty ? userName[0] : 'م';
}
