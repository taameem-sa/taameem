import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';

class TaameemDetailScreen extends StatelessWidget {
  final TaameemModel taameem;
  const TaameemDetailScreen({super.key, required this.taameem});

  @override
  Widget build(BuildContext context) {
    final color = taameem.typeColor;
    final hasLocation = taameem.latitude != 0 && taameem.longitude != 0;
    final hasMedia    = taameem.imageUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: CustomScrollView(
        slivers: [

          // ── AppBar ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.creamWhite,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warmBeige,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.forestGreen),
              ),
            ),
            title: Text(taameem.typeName,
              style: const TextStyle(fontFamily: 'Tajawal',
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.nearBlack)),
            actions: [
              Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(taameem.mapLabel,
                  style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: color)),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── 1. حساب الناشر ──────────────────────────
                  _PublisherCard(taameem: taameem)
                    .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 12),

                  // ── 2. التعميم المكتوب ───────────────────────
                  _TaameemContent(taameem: taameem, color: color)
                    .animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

                  // ── 3. المعرض (فقط إذا يوجد مرفقات) ────────
                  if (hasMedia) ...[
                    const SizedBox(height: 12),
                    _MediaGallery(urls: taameem.imageUrls)
                      .animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ],

                  // ── 4. الخريطة (فقط إذا يوجد موقع) ─────────
                  if (hasLocation) ...[
                    const SizedBox(height: 12),
                    _MiniMapCard(taameem: taameem, color: color)
                      .animate(delay: 240.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                  ],

                  const SizedBox(height: 16),

                  // ── أزرار التفاعل ────────────────────────────
                  _ActionButtons(taameem: taameem, color: color)
                    .animate(delay: 300.ms).fadeIn(duration: 400.ms),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  1 — بطاقة الناشر
// ════════════════════════════════════════════════════════
class _PublisherCard extends StatelessWidget {
  final TaameemModel taameem;
  const _PublisherCard({required this.taameem});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              // أفاتار
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.forestGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '👤',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // معلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taameem.userPhone.isNotEmpty
                          ? taameem.userPhone
                          : 'مستخدم تعميم',
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'نشر ${taameem.timeAgo}',
                          style: const TextStyle(fontFamily: 'Tajawal',
                            fontSize: 11, color: AppColors.grey),
                        ),
                        if (taameem.city.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: AppColors.grey),
                          const SizedBox(width: 2),
                          Text(taameem.city,
                            style: const TextStyle(fontFamily: 'Tajawal',
                              fontSize: 11, color: AppColors.grey)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // شارة عضو
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: const Text('عضو',
                  style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  2 — التعميم المكتوب
// ════════════════════════════════════════════════════════
class _TaameemContent extends StatelessWidget {
  final TaameemModel taameem;
  final Color color;
  const _TaameemContent({required this.taameem, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // خط ملون أعلى البطاقة
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Text(taameem.title,
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.nearBlack,
                        height: 1.4,
                      )),

                    if (taameem.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(taameem.description,
                        style: const TextStyle(fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: AppColors.forestGreen,
                          height: 1.7,
                        )),
                    ],

                    const SizedBox(height: 14),

                    // معلومات سفلية
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: taameem.timeAgo),
                        const SizedBox(width: 10),
                        if (!taameem.isExpired)
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: 'ينتهي خلال ${taameem.timeLeft.inDays} يوم',
                            color: AppColors.emerald),
                        const Spacer(),
                        _InfoChip(
                          icon: Icons.visibility_rounded,
                          label: '${taameem.viewCount} مشاهدة'),
                      ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontFamily: 'Tajawal',fontSize: 11, color: c)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════
//  3 — معرض الصور
// ════════════════════════════════════════════════════════
class _MediaGallery extends StatefulWidget {
  final List<String> urls;
  const _MediaGallery({required this.urls});

  @override
  State<_MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<_MediaGallery> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.perm_media_rounded,
                        size: 16, color: AppColors.forestGreen),
                    const SizedBox(width: 6),
                    const Text('المرفقات',
                      style: TextStyle(fontFamily: 'Tajawal',
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${widget.urls.length}',
                        style: const TextStyle(fontFamily: 'Tajawal',
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.emerald)),
                    ),
                  ],
                ),
              ),

              // الصورة الرئيسية
              GestureDetector(
                onTap: () => _showFullscreen(context, _active),
                child: Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: widget.urls[_active],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: AppColors.warmBeige,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.emerald, strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.warmBeige,
                        child: const Icon(Icons.broken_image_rounded,
                            color: AppColors.grey, size: 40)),
                    ),
                  ),
                ),
              ),

              // مصغّرات
              if (widget.urls.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: widget.urls.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(() => _active = i),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _active == i
                                ? AppColors.emerald
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: widget.urls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.warmBeige),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.warmBeige,
                              child: const Icon(Icons.image_rounded,
                                  size: 20, color: AppColors.grey)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
      Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: PageView.builder(
          itemCount: widget.urls.length,
          controller: PageController(initialPage: index),
          itemBuilder: (_, i) => InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ));
  }
}

// ════════════════════════════════════════════════════════
//  4 — خريطة مُصغّرة مع تحكم كامل
// ════════════════════════════════════════════════════════
class _MiniMapCard extends StatelessWidget {
  final TaameemModel taameem;
  final Color color;
  const _MiniMapCard({required this.taameem, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    const Text('الموقع',
                      style: TextStyle(fontFamily: 'Tajawal',
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen)),
                    const Spacer(),
                    Text(
                      '${taameem.latitude.toStringAsFixed(4)}, '
                      '${taameem.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 10, color: AppColors.grey)),
                  ],
                ),
              ),

              // الخريطة — تدعم التكبير والتصغير والتحريك
              Container(
                height: 200,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                          taameem.latitude, taameem.longitude),
                      initialZoom: 15,
                      // التحكم مفعّل بالكامل
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
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
                            point: LatLng(
                                taameem.latitude, taameem.longitude),
                            width: 44,
                            height: 52,
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(taameem.mapLabel,
                                      style: const TextStyle(fontFamily: 'Tajawal',
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white),
                                      textAlign: TextAlign.center),
                                  ),
                                ),
                                CustomPaint(
                                  size: const Size(10, 6),
                                  painter: _TrianglePainter(color),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
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

// ════════════════════════════════════════════════════════
//  أزرار التفاعل
// ════════════════════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  final TaameemModel taameem;
  final Color color;
  const _ActionButtons({required this.taameem, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Btn(
            label: 'مشاركة',
            icon: Icons.share_rounded,
            color: AppColors.emerald,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Btn(
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
        _Btn(
          label: 'الإبلاغ',
          icon: Icons.flag_outlined,
          color: AppColors.error,
          onTap: () {},
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(fontFamily: 'Tajawal',
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
