import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// بطاقة مراجعة التعميم — تظهر داخل المحادثة قبل النشر
class TaameemPreviewCard extends StatelessWidget {
  final Map<String, dynamic> draft;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const TaameemPreviewCard({
    super.key,
    required this.draft,
    required this.onConfirm,
    required this.onEdit,
  });

  Color get _typeColor {
    switch (draft['type']) {
      case 'missingPerson':  return AppColors.missingPerson;
      case 'foundItem':      return AppColors.foundItem;
      case 'lostItem':       return AppColors.lostItem;
      case 'theft':          return AppColors.theft;
      case 'helpRequest':    return AppColors.helpRequest;
      case 'humanitarian':   return AppColors.humanitarian;
      case 'emergency':      return AppColors.emergency;
      case 'generalWarning': return AppColors.generalWarning;
      case 'lostAnimal':     return AppColors.lostAnimal;
      case 'inquiry':        return AppColors.inquiry;
      default:               return AppColors.emerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final typeName = AppConstants.categoryNames[draft['type']] ?? 'تعميم';
    final mapLabel = AppConstants.mapLabels[draft['type']] ?? 'تعميم';
    final days = AppConstants.decayDays[draft['type']] ?? 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── رأس البطاقة ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: color.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          mapLabel,
                          style: TextStyle(fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _contrastColor(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        typeName,
                        style: TextStyle(fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      // أيقونة المراجعة
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rate_review_rounded,
                          size: 16,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── تسمية المراجعة ───────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.preview_rounded,
                          size: 14, color: AppColors.grey),
                      SizedBox(width: 6),
                      Text(
                        'مراجعة التعميم قبل النشر',
                        style: TextStyle(fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── العنوان ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    draft['title'] ?? '',
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack,
                      height: 1.4,
                    ),
                  ),
                ),

                // ─── الوصف ────────────────────────────────────────────
                if (draft['description'] != null &&
                    draft['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      draft['description'],
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: AppColors.forestGreen,
                        height: 1.6,
                      ),
                    ),
                  ),

                // ─── مدة النشر ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.emerald),
                        const SizedBox(width: 5),
                        Text(
                          'سينتهي خلال $days أيام تلقائياً',
                          style: const TextStyle(fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── أزرار المراجعة ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // زر التعديل
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          height: 44,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppColors.warmBeige,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 15, color: AppColors.forestGreen),
                              SizedBox(width: 4),
                              Text(
                                'تعديل',
                                style: TextStyle(fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // زر النشر
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, _darken(color)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'نشر التعميم الآن',
                                  style: TextStyle(fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.4
        ? AppColors.nearBlack
        : Colors.white;
  }

  Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0, 1)).toColor();
  }
}

