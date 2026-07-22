import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/messages_service.dart';

class DirectMessageScreen extends StatefulWidget {
  final String myUserId;
  final String myUserName;
  final String otherUserId;
  final String otherUserName;
  final String taameemId;
  final String taameemTitle;

  const DirectMessageScreen({
    super.key,
    required this.myUserId,
    required this.myUserName,
    required this.otherUserId,
    required this.otherUserName,
    required this.taameemId,
    required this.taameemTitle,
  });

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final _textCtrl    = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _svc         = MessagesService.instance;
  late final String  _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _svc.chatId(widget.myUserId, widget.otherUserId);
    // تحديد الرسائل كمقروءة
    _svc.markRead(_chatId, widget.myUserId);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    await _svc.sendMessage(
      chatId:        _chatId,
      senderId:      widget.myUserId,
      text:          text,
      taameemTitle:  widget.taameemTitle,
      otherUserName: widget.otherUserName,
    );

    // تمرير للأسفل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      appBar: AppBar(
        backgroundColor: AppColors.creamWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warmBeige,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.glassBorder)),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.forestGreen),
          ),
        ),
        title: Column(
          children: [
            Text(widget.otherUserName,
              style: GoogleFonts.cairo(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.nearBlack)),
            Text('متصل الآن',
              style: GoogleFonts.cairo(
                fontSize: 10, color: AppColors.emerald)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.glassBorder)),
      ),
      body: Column(children: [

        // ── مرجع التعميم ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.2))),
          child: Row(children: [
            const Icon(Icons.push_pin_rounded,
                color: AppColors.emerald, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('بخصوص التعميم',
                    style: GoogleFonts.cairo(
                      fontSize: 9, color: AppColors.emerald,
                      fontWeight: FontWeight.w700)),
                  Text(widget.taameemTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.nearBlack,
                      fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        ),

        // ── قائمة الرسائل ──────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: _svc.streamMessages(_chatId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: AppColors.emerald, strokeWidth: 2));
              }
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 52,
                          color: AppColors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 10),
                      Text('ابدأ المحادثة',
                        style: GoogleFonts.cairo(
                          fontSize: 14, color: AppColors.grey)),
                    ],
                  ),
                );
              }

              // تمرير للأسفل عند وصول رسائل جديدة
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.jumpTo(
                      _scrollCtrl.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final isMe = m.senderId == widget.myUserId;
                  return _MessageBubble(
                      message: m, isMe: isMe);
                },
              );
            },
          ),
        ),

        // ── شريط الكتابة ───────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              12, 8, 12,
              MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(
                top: BorderSide(color: AppColors.glassBorder))),
          child: Row(children: [
            // حقل النص
            Expanded(
              child: TextField(
                controller: _textCtrl,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.nearBlack),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 13, color: AppColors.grey),
                  filled: true,
                  fillColor: AppColors.warmBeige,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: AppColors.glassBorder)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: AppColors.glassBorder)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                        color: AppColors.emerald)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                maxLines: 4, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            // زر الإرسال
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.forestGreen]),
                  boxShadow: [BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── فقاعة رسالة ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(colors: [
                      AppColors.emerald, AppColors.forestGreen])
                  : null,
              color: isMe ? null : AppColors.glassBackground,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(18),
                topRight:    const Radius.circular(18),
                bottomLeft:  Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: isMe ? null : Border.all(
                  color: AppColors.glassBorder),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(message.text,
              style: GoogleFonts.cairo(
                fontSize: 13, height: 1.55,
                color: isMe ? Colors.white : AppColors.nearBlack)),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.timeLabel,
                style: GoogleFonts.cairo(
                    fontSize: 9, color: AppColors.grey)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead
                      ? Icons.done_all_rounded
                      : Icons.done_rounded,
                  size: 12,
                  color: message.isRead
                      ? AppColors.emerald
                      : AppColors.grey),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
