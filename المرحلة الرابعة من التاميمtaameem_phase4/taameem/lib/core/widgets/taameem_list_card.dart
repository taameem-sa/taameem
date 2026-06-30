import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/taameem_model.dart';

class TaameemListCard extends StatelessWidget {
  final TaameemModel taameem;
  final VoidCallback? onTap;
  final bool showActions;

  const TaameemListCard({
    super.key,
    required this.taameem,
    this.onTap,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = taameem.typeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glassShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // خط ملون علوي
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0),
                          color,
                          color.withOpacity(0),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── صورة أو أيقونة النوع ──────────────────────
                        _buildLeading(color),
                        const SizedBox(width: 12),

                        // ─── المحتوى ───────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // شارة النوع
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      taameem.mapLabel,
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (taameem.isExpired)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.grey.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'منتهي',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  Text(
                                    taameem.timeAgo,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // العنوان
                              Text(
                                taameem.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.nearBlack,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // الوصف
                              if (taameem.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  taameem.description,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.forestGreen,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 8),

                              // معلومات سفلية
                              Row(
                                children: [
                                  if (taameem.city.isNotEmpty) ...[
                                    const Icon(Icons.location_on_rounded,
                                        size: 12, color: AppColors.grey),
                                    const SizedBox(width: 3),
                                    Text(
                                      taameem.city,
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  const Icon(Icons.visibility_rounded,
                                      size: 12, color: AppColors.grey),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${taameem.viewCount}',
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

                        // ─── سهم التفاصيل ──────────────────────────────
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: AppColors.grey,
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
      ),
    );
  }

  Widget _buildLeading(Color color) {
    if (taameem.imageUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: taameem.imageUrls.first,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 64,
            height: 64,
            color: AppColors.warmBeige,
          ),
          errorWidget: (_, __, ___) => _colorBox(color),
        ),
      );
    }
    return _colorBox(color);
  }

  Widget _colorBox(Color color) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          taameem.mapLabel,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
