import 'dart:io';

enum MessageSender { user, ai }
enum MessageType { text, image, taameemPreview, thinking }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final MessageType type;
  final String? text;
  final List<File>? images;
  final Map<String, dynamic>? taameemDraft; // بيانات التعميم المستخرجة
  final DateTime timestamp;
  final bool isThinking;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    this.text,
    this.images,
    this.taameemDraft,
    required this.timestamp,
    this.isThinking = false,
  });

  factory ChatMessage.userText(String text) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.user,
        type: MessageType.text,
        text: text,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.userWithImages(String text, List<File> images) =>
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.user,
        type: MessageType.image,
        text: text,
        images: images,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.aiText(String text) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.ai,
        type: MessageType.text,
        text: text,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.aiTaameemPreview(Map<String, dynamic> draft) =>
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.ai,
        type: MessageType.taameemPreview,
        taameemDraft: draft,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.thinking() => ChatMessage(
        id: 'thinking',
        sender: MessageSender.ai,
        type: MessageType.thinking,
        timestamp: DateTime.now(),
        isThinking: true,
      );

  // للإرسال إلى Anthropic API (history)
  Map<String, dynamic> toApiMessage() {
    return {
      'role': sender == MessageSender.user ? 'user' : 'assistant',
      'content': text ?? '',
    };
  }
}

