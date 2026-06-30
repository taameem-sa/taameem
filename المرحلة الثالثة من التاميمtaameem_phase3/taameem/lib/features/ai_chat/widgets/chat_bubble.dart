import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isThinking) return _ThinkingBubble();

    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6,
        right: isUser ? 48 : 0,
        left: isUser ? 0 : 48,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isUser) _AiAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: _buildBubble(isUser)),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _UserAvatar(),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildBubble(bool isUser) {
    if (isUser) return _UserBubble(message: message);
    return _AiBubble(message: message);
  }
}

// ─── فقاعة المستخدم ──────────────────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.forestGreen],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(18),
          topLeft: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصور المرفقة
          if (message.images != null && message.images!.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.images!.map((img) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    img,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
            if (message.text != null && message.text!.isNotEmpty)
              const SizedBox(height: 8),
          ],

          if (message.text != null && message.text!.isNotEmpty)
            Text(
              message.text!,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── فقاعة الـ AI ──────────────────────────────────────────────────────────────
class _AiBubble extends StatelessWidget {
  final ChatMessage message;
  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(18),
        topLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            message.text ?? '',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.nearBlack,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── مؤشر "تعميم يكتب" ─────────────────────────────────────────────────────────
class _ThinkingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          _AiAvatar(),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تعميم يكتب',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ThinkingDots(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        final next = (_ctrl.value * 3).floor() % 3;
        if (next != _active) setState(() => _active = next);
      })
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _active == i
                ? AppColors.emerald
                : AppColors.emerald.withOpacity(0.3),
          ),
        );
      }),
    );
  }
}

// ─── أفاتار الـ AI ──────────────────────────────────────────────────────────────
class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.forestGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1),
      ),
      child: Center(
        child: Text(
          'ت',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── أفاتار المستخدم ────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded,
            size: 18, color: AppColors.forestGreen),
      ),
    );
  }
}
