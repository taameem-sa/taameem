import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  علامة الصورة المصغرة على الخريطة
// ══════════════════════════════════════════════════════════════════════════════
class PhotoMarker extends StatelessWidget {
  final TaameemModel taameem;
  final VoidCallback onTap;

  const PhotoMarker({
    super.key,
    required this.taameem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الصورة المصغرة
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12, offset: const Offset(0, 3)),
                BoxShadow(
                  color: taameem.typeColor.withValues(alpha: 0.35),
                  blurRadius: 8),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7.5),
              child: CachedNetworkImage(
                imageUrl: taameem.imageUrls.first,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: taameem.typeColor.withValues(alpha: 0.2),
                  child: Icon(Icons.image_rounded,
                      color: taameem.typeColor, size: 22)),
                errorWidget: (_, __, ___) => Container(
                  color: taameem.typeColor.withValues(alpha: 0.15),
                  child: Icon(Icons.broken_image_rounded,
                      color: taameem.typeColor, size: 20)),
              ),
            ),
          ),
          // ذيل المثلث
          const CustomPaint(
            size: Size(14, 9),
            painter: _TailPainter(Colors.white),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  علامة الفئة الملونة
// ══════════════════════════════════════════════════════════════════════════════
class CategoryMarker extends StatelessWidget {
  final TaameemModel taameem;
  final VoidCallback onTap;

  const CategoryMarker({
    super.key,
    required this.taameem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: taameem.typeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: taameem.typeColor.withValues(alpha: 0.45),
                  blurRadius: 10, spreadRadius: 1),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Text(
                taameem.mapLabel,
                style: const TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(12, 7),
            painter: _TailPainter(taameem.typeColor),
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }
  @override bool shouldRepaint(_TailPainter o) => o.color != color;
}

// ══════════════════════════════════════════════════════════════════════════════
//  البطاقة المنبثقة عند الضغط على العلامة
// ══════════════════════════════════════════════════════════════════════════════
class TaameemPopupCard extends StatelessWidget {
  final TaameemModel taameem;
  final Offset markerScreenPos; // موقع العلامة بالبكسل
  final VoidCallback onClose;
  final VoidCallback onViewDetail;

  const TaameemPopupCard({
    super.key,
    required this.taameem,
    required this.markerScreenPos,
    required this.onClose,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    // حساب موضع البطاقة فوق العلامة
    const cardW = 240.0;
    const cardH = 230.0;
    double left = markerScreenPos.dx - cardW / 2;
    double top  = markerScreenPos.dy - cardH - 76; // فوق العلامة

    // منع الخروج من حدود الشاشة
    left = left.clamp(8.0, sw - cardW - 8);
    top  = math.max(top, 60.0);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(
            scale: v, alignment: Alignment.bottomCenter,
            child: child),
          child: Container(
            width: cardW,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── الصورة (أو خلفية الفئة) ──────────────────────────────
                Stack(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: SizedBox(
                      height: 148, width: cardW,
                      child: taameem.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: taameem.imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(
                              color: taameem.typeColor.withValues(alpha: 0.15)),
                            errorWidget: (_, __, ___) => Container(
                              color: taameem.typeColor.withValues(alpha: 0.15),
                              child: Icon(Icons.image_rounded,
                                  color: taameem.typeColor, size: 40)),
                          )
                        : Container(color: taameem.typeColor.withValues(alpha: 0.2)),
                    ),
                  ),

                  // تدرج فوق الصورة
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: Container(
                      height: 148, width: cardW,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xCC000000),
                          ],
                          stops: [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // زر الإغلاق
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3))),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),

                  // شارة الفئة
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: taameem.typeColor,
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(taameem.mapLabel,
                        style: const TextStyle(fontFamily: 'NotoNaskhArabic',
                          fontSize: 10, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                    ),
                  ),

                  // العنوان والوقت فوق الصورة
                  Positioned(
                    bottom: 10, left: 10, right: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(taameem.title,
                          style: const TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: Colors.white, height: 1.3,
                            shadows: [Shadow(
                              color: Colors.black54, blurRadius: 4)]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppColors.forestGreen, size: 10),
                          const SizedBox(width: 4),
                          Text(taameem.timeAgo,
                            style: const TextStyle(fontFamily: 'NotoNaskhArabic',
                              fontSize: 10, color: AppColors.forestGreen)),
                        ]),
                      ],
                    ),
                  ),
                ]),

                // ── التفاصيل والزر ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.grey, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          taameem.city.isNotEmpty
                              ? taameem.city : 'الرياض',
                          style: const TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 10, color: AppColors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.visibility_rounded,
                          color: AppColors.grey, size: 12),
                      const SizedBox(width: 4),
                      Text('${taameem.viewCount} مشاهدة',
                        style: const TextStyle(fontFamily: 'NotoNaskhArabic',
                          fontSize: 10, color: AppColors.grey)),
                    ]),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onViewDetail,
                      child: Container(
                        width: double.infinity, height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [AppColors.emerald, AppColors.forestGreen])),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                color: Colors.white, size: 13),
                            SizedBox(width: 6),
                            Text('عرض التعميم كاملاً',
                              style: TextStyle(fontFamily: 'NotoNaskhArabic',
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
