import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> m) =>
    MessageModel(
      id:        id,
      senderId:  m['senderId']  ?? '',
      text:      m['text']      ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead:    m['isRead']    ?? false,
    );

  Map<String, dynamic> toMap() => {
    'senderId':  senderId,
    'text':      text,
    'createdAt': FieldValue.serverTimestamp(),
    'isRead':    false,
  };

  String get timeLabel {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
