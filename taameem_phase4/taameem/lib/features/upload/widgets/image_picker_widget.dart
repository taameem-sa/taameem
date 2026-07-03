import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<File> images;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final Function(int) onRemove;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    required this.images,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onRemove,
    this.maxImages = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // أزرار إضافة صورة
          if (images.length < maxImages) ...[
            _AddButton(
              icon: Icons.photo_library_rounded,
              label: 'المعرض',
              onTap: onPickFromGallery,
            ),
            const SizedBox(width: 10),
            _AddButton(
              icon: Icons.camera_alt_rounded,
              label: 'الكاميرا',
              onTap: onPickFromCamera,
            ),
            const SizedBox(width: 10),
          ],

          // الصور المختارة
          ...images.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _ImageTile(
                file: entry.value,
                onRemove: () => onRemove(entry.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.warmBeige,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.emerald),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.forestGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _ImageTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            file,
            width: 90,
            height: 110,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
