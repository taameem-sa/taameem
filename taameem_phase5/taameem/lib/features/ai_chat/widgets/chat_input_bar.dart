import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final List<File> attachedImages;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickCamera;
  final VoidCallback onAttachLocation;
  final Function(int) onRemoveImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.attachedImages,
    required this.isLoading,
    required this.onSend,
    required this.onPickImage,
    required this.onPickCamera,
    required this.onAttachLocation,
    required this.onRemoveImage,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final hasText = widget.controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            12, 10,
            12,
            MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(
              top: BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── الصور المرفقة ─────────────────────────────────────
              if (widget.attachedImages.isNotEmpty)
                _buildAttachedImages(),

              // ─── صف الإدخال ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // أزرار الإرفاق
                  _buildAttachButtons(),

                  const SizedBox(width: 8),

                  // حقل النص
                  Expanded(child: _buildTextField()),

                  const SizedBox(width: 8),

                  // زر الإرسال
                  _buildSendButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachedImages() {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: widget.attachedImages.length,
        itemBuilder: (_, i) => Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  widget.attachedImages[i],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                onTap: () => widget.onRemoveImage(i),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButtons() {
    return Row(
      children: [
        _IconBtn(
          icon: Icons.photo_library_outlined,
          onTap: widget.isLoading ? null : widget.onPickImage,
          tooltip: 'الصور',
        ),
        const SizedBox(width: 4),
        _IconBtn(
          icon: Icons.camera_alt_outlined,
          onTap: widget.isLoading ? null : widget.onPickCamera,
          tooltip: 'الكاميرا',
        ),
        const SizedBox(width: 4),
        _IconBtn(
          icon: Icons.location_on_outlined,
          onTap: widget.isLoading ? null : widget.onAttachLocation,
          tooltip: 'الموقع',
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(fontFamily: 'Tajawal',
          fontSize: 14,
          color: AppColors.nearBlack,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: 'اكتب التعميم، بأي شكل تريده...',
          hintStyle: TextStyle(fontFamily: 'Tajawal',
            fontSize: 13,
            color: AppColors.grey,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        maxLines: null,
        textInputAction: TextInputAction.newline,
        enabled: !widget.isLoading,
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = (_hasText || widget.attachedImages.isNotEmpty) &&
        !widget.isLoading;

    return GestureDetector(
      onTap: canSend ? widget.onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canSend
                ? [AppColors.emerald, AppColors.forestGreen]
                : [AppColors.grey.withValues(alpha: 0.5), AppColors.grey.withValues(alpha: 0.5)],
          ),
          shape: BoxShape.circle,
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.warmBeige,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(
          icon,
          size: 17,
          color: onTap != null ? AppColors.forestGreen : AppColors.grey,
        ),
      ),
    );
  }
}

