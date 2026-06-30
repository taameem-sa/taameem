import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class TaameemCardPopup extends StatelessWidget {
  final Map<String, dynamic> taameem;
  final VoidCallback onClose;
  final VoidCallback? onViewDetails;

  const TaameemCardPopup({
    super.key,
    required this.taameem,
    required this.onClose,
    this.onViewDetails,
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
              // خط ملون أعلى البطاقة
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
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونة النوع
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: typeColor.withOpacity(0.4)),
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

                    // المعلومات
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 11, color: AppColors.grey),
                              const SizedBox(width: 4),
                              Text(
                                taameem['time'],
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: AppColors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // إغلاق
                    GestureDetector(
                      onTap: onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: AppColors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              // أزرار
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onViewDetails,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.emerald, AppColors.forestGreen],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'عرض التفاصيل',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.share_rounded,
                            size: 16, color: AppColors.gold),
                      ),
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
