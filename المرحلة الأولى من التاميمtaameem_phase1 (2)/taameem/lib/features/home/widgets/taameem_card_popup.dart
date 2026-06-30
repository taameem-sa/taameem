import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class TaameemCardPopup extends StatelessWidget {
  final Map<String, dynamic> taameem;
  final VoidCallback onClose;

  const TaameemCardPopup({
    super.key,
    required this.taameem,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final Color typeColor = taameem['color'] as Color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── الخط الذهبي العلوي ──────────────────────────────────
              Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      typeColor.withOpacity(0),
                      typeColor,
                      typeColor.withOpacity(0),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── أيقونة النوع ───────────────────────────────────
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: typeColor.withOpacity(0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          taameem['label'],
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ─── المعلومات ───────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            taameem['title'],
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.nearBlack,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            taameem['description'],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.forestGreen,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                taameem['time'],
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ─── زر الإغلاق ─────────────────────────────────────
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── أزرار التفاعل ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'عرض التفاصيل',
                        icon: Icons.open_in_full_rounded,
                        color: AppColors.emerald,
                        onTap: () {
                          // TODO: صفحة التفاصيل الكاملة
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      label: 'مشاركة',
                      icon: Icons.share_rounded,
                      color: AppColors.gold,
                      onTap: () {
                        // TODO: مشاركة
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
