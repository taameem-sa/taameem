import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/glass_card.dart';

class TaameemDetailScreen extends StatelessWidget {
  final TaameemModel taameem;

  const TaameemDetailScreen({super.key, required this.taameem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ─── بطاقة المعلومات الرئيسية ─────────────────────────
                _buildInfoCard(),

                // ─── الصور ───────────────────────────────────────────
                if (taameem.imageUrls.isNotEmpty) _buildImages(),

                // ─── خريطة مصغرة ─────────────────────────────────────
                _buildMiniMap(),

                // ─── معلومات إضافية ───────────────────────────────────
                _buildMetaInfo(),

                // ─── أزرار التفاعل ────────────────────────────────────
                _buildActions(context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: AppColors.creamWhite,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.forestGreen,
          ),
        ),
      ),
      title: Text(
        taameem.typeName,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.nearBlack,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: taameem.typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: taameem.typeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            taameem.mapLabel,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: taameem.typeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      showGoldLine: true,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Text(
            taameem.title,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
              height: 1.4,
            ),
          ),

          if (taameem.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              taameem.description,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.forestGreen,
                height: 1.7,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // الوقت
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 15, color: AppColors.grey),
              const SizedBox(width: 5),
              Text(
                taameem.timeAgo,
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.grey),
              ),
              const Spacer(),

              // مدة التلاشي المتبقية
              if (!taameem.isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 12, color: AppColors.emerald),
                      const SizedBox(width: 4),
                      Text(
                        'ينتهي خلال ${taameem.timeLeft.inDays} يوم',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildImages() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: taameem.imageUrls.length,
        itemBuilder: (_, i) => Container(
          width: 200,
          margin: const EdgeInsets.only(left: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: taameem.imageUrls[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.warmBeige,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.emerald,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.warmBeige,
                child: const Icon(Icons.broken_image_rounded,
                    color: AppColors.grey),
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildMiniMap() {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 160,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(taameem.latitude, taameem.longitude),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taameem.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(taameem.latitude, taameem.longitude),
                    width: 50,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: taameem.typeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(10, 6),
                          painter: _TrianglePainter(taameem.typeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildMetaInfo() {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _MetaTile(
            icon: Icons.visibility_rounded,
            label: 'مشاهدات',
            value: '${taameem.viewCount}',
          ),
          _divider(),
          _MetaTile(
            icon: Icons.location_on_rounded,
            label: 'المدينة',
            value: taameem.city.isEmpty ? 'غير محدد' : taameem.city,
          ),
          _divider(),
          _MetaTile(
            icon: Icons.category_rounded,
            label: 'النوع',
            value: taameem.typeName,
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppColors.glassBorder,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              label: 'مشاركة',
              icon: Icons.share_rounded,
              color: AppColors.emerald,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionBtn(
              label: 'تم الحل',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.gold,
              onTap: () async {
                await FirestoreService.instance
                    .updateStatus(taameem.id, 'resolved');
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            label: 'الإبلاغ عن مشكلة',
            icon: Icons.flag_outlined,
            color: AppColors.error,
            onTap: () {},
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms);
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.emerald),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.nearBlack)),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 11, color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
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
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
