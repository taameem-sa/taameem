import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/comments_service.dart';
import '../../messages/screens/direct_message_screen.dart';
import '../widgets/taameem_action_buttons.dart';

class TaameemDetailScreen extends StatelessWidget {
  final TaameemModel taameem;
  const TaameemDetailScreen({super.key, required this.taameem});

  @override
  Widget build(BuildContext context) {
    final color       = taameem.typeColor;
    final hasLocation = taameem.latitude  != 0 && taameem.longitude != 0;
    final hasMedia    = taameem.imageUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: CustomScrollView(slivers: [

        // ── AppBar ───────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.creamWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.glassBorder)),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.forestGreen)),
          ),
          title: Text(taameem.typeName,
            style: GoogleFonts.cairo(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack)),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3))),
              child: Text(taameem.mapLabel,
                style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
            child: Column(children: [

              // 1. الناشر
              _PublisherCard(taameem: taameem)
                .animate().fadeIn(duration: 350.ms).slideY(begin: 0.15),

              const SizedBox(height: 12),

              // 2. المحتوى
              _TaameemContent(taameem: taameem, color: color)
                .animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15),

              // 3. المعرض
              if (hasMedia) ...[
                const SizedBox(height: 12),
                _MediaGallery(urls: taameem.imageUrls)
                  .animate(delay: 120.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15),
              ],

              // 4. الخريطة
              if (hasLocation) ...[
                const SizedBox(height: 12),
                _MiniMapCard(taameem: taameem, color: color)
                  .animate(delay: 180.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15),
              ],

              const SizedBox(height: 12),

              // 5. الأزرار
              TaameemActionButtons(
                taameem:         taameem,
                currentUserId:   'current_user',
                currentUserName: 'أنت',
                isOwner:         taameem.userId == 'current_user',
              ).animate(delay: 240.ms).fadeIn(duration: 350.ms),

              const SizedBox(height: 16),

              // 6. التعليقات
              _CommentsSection(taameemId: taameem.id)
                .animate(delay: 300.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15),

            ]),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  بطاقة الناشر
// ════════════════════════════════════════════════════════════
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
          decoration: BoxDecoration(
            color: AppColors.warmBeige.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.forestGreen]),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4), width: 1.5)),
                  child: const Center(child: Text('👤',
                      style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taameem.userPhone.isNotEmpty
                          ? taameem.userPhone : 'مستخدم تعميم',
                      style: GoogleFonts.cairo(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text('نشر ${taameem.timeAgo}',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppColors.grey)),
                      if (taameem.city.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppColors.grey),
                        const SizedBox(width: 2),
                        Text(taameem.city,
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: AppColors.grey)),
                      ],
                    ]),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))),
                  child: Text('عضو',
                    style: GoogleFonts.cairo(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
                ),
              ]),
            ),

            // زر المراسلة
            GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DirectMessageScreen(
                  myUserId:      'current_user',
                  myUserName:    'أنت',
                  otherUserId:   taameem.userId,
                  otherUserName: taameem.userPhone.isNotEmpty
                      ? taameem.userPhone : 'ناشر التعميم',
                  taameemId:    taameem.id,
                  taameemTitle: taameem.title,
                ))),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppColors.emerald, size: 15),
                    const SizedBox(width: 8),
                    Text('مراسلة الناشر مباشرة',
                      style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.emerald)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  محتوى التعميم
// ════════════════════════════════════════════════════════════
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
            color: AppColors.warmBeige.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder)),
          child: Column(children: [
            Container(height: 3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                gradient: LinearGradient(colors: [
                  color.withValues(alpha: 0), color, color.withValues(alpha: 0)]))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taameem.title,
                    style: GoogleFonts.cairo(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack, height: 1.4)),
                  if (taameem.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(taameem.description,
                      style: GoogleFonts.cairo(
                        fontSize: 14, color: AppColors.forestGreen,
                        height: 1.75)),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _InfoChip(icon: Icons.access_time_rounded,
                          label: taameem.timeAgo),
                      _InfoChip(icon: Icons.visibility_rounded,
                          label: '${taameem.viewCount} مشاهدة'),
                      if (!taameem.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.emerald.withValues(alpha: 0.2))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.timer_outlined,
                                size: 11, color: AppColors.emerald),
                            const SizedBox(width: 4),
                            Text('${taameem.timeLeft.inDays} أيام متبقية',
                              style: GoogleFonts.cairo(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppColors.emerald)),
                          ])),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppColors.grey),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.grey)),
    ],
  );
}

// ════════════════════════════════════════════════════════════
//  معرض الصور
// ════════════════════════════════════════════════════════════
class _MediaGallery extends StatefulWidget {
  final List<String> urls;
  const _MediaGallery({required this.urls});
  @override State<_MediaGallery> createState() => _MediaGalleryState();
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
            color: AppColors.warmBeige.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(children: [
                const Icon(Icons.perm_media_rounded,
                    size: 15, color: AppColors.forestGreen),
                const SizedBox(width: 6),
                Text('المرفقات',
                  style: GoogleFonts.cairo(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('${widget.urls.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.emerald))),
              ]),
            ),
            GestureDetector(
              onTap: () => _showFs(context, _active),
              child: Container(
                height: 200, margin: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[_active],
                    fit: BoxFit.cover, width: double.infinity,
                    placeholder: (_, __) => Container(color: AppColors.warmBeige,
                      child: const Center(child: CircularProgressIndicator(
                          color: AppColors.emerald, strokeWidth: 2))),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.warmBeige,
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.grey, size: 40))))),
            ),
            if (widget.urls.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 62,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.urls.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _active = i),
                    child: Container(
                      width: 62, margin: const EdgeInsets.only(left: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _active == i
                              ? AppColors.emerald : Colors.transparent,
                          width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: widget.urls[i], fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.warmBeige),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.warmBeige)))))),
              ),
            ],
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showFs(BuildContext ctx, int index) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) =>
      Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(ctx))),
        body: PageView.builder(
          itemCount: widget.urls.length,
          controller: PageController(initialPage: index),
          itemBuilder: (_, i) => InteractiveViewer(
            child: CachedNetworkImage(
                imageUrl: widget.urls[i], fit: BoxFit.contain))))));
  }
}

// ════════════════════════════════════════════════════════════
//  الخريطة المصغرة
// ════════════════════════════════════════════════════════════
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
            color: AppColors.warmBeige.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder)),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(children: [
                const Icon(Icons.location_on_rounded,
                    size: 15, color: AppColors.emerald),
                const SizedBox(width: 6),
                Text('الموقع',
                  style: GoogleFonts.cairo(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen)),
                const Spacer(),
                Text(
                  '${taameem.latitude.toStringAsFixed(4)}, '
                  '${taameem.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppColors.grey)),
              ]),
            ),
            Container(
              height: 190, margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(taameem.latitude, taameem.longitude),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all)),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.taameem.app'),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(taameem.latitude, taameem.longitude),
                        width: 44, height: 52,
                        child: Column(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [BoxShadow(
                                color: color.withValues(alpha: 0.4), blurRadius: 10)]),
                            child: Center(child: Text(taameem.mapLabel,
                              style: GoogleFonts.cairo(
                                fontSize: 7, fontWeight: FontWeight.w800,
                                color: Colors.white),
                              textAlign: TextAlign.center))),
                          CustomPaint(size: const Size(10, 6),
                            painter: _Tri(color)),
                        ]),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Tri extends CustomPainter {
  final Color c;
  const _Tri(this.c);
  @override
  void paint(Canvas cv, Size s) => cv.drawPath(
    ui.Path()..moveTo(0,0)..lineTo(s.width,0)
          ..lineTo(s.width/2,s.height)..close(),
    Paint()..color = c);
  @override bool shouldRepaint(_Tri o) => o.c != c;
}

// ════════════════════════════════════════════════════════════
//  قسم التعليقات
// ════════════════════════════════════════════════════════════
class _CommentsSection extends StatefulWidget {
  final String taameemId;
  const _CommentsSection({required this.taameemId});
  @override State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final _ctrl     = TextEditingController();
  final _svc      = CommentsService.instance;
  final _likedIds = <String>{};

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    await _svc.addComment(
      taameemId: widget.taameemId,
      userId:    'current_user',
      userName:  'أنت',
      text:      text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.warmBeige.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder)),
          child: Column(children: [

            // رأس التعليقات
            StreamBuilder<List<CommentModel>>(
              stream: _svc.streamComments(widget.taameemId),
              builder: (_, snap) {
                final n = snap.data?.length ?? 0;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15, color: AppColors.forestGreen),
                    const SizedBox(width: 6),
                    Text('التعليقات',
                      style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('$n',
                        style: GoogleFonts.cairo(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.emerald))),
                  ]),
                );
              },
            ),

            Divider(height: 1, color: AppColors.glassBorder),

            // قائمة التعليقات
            StreamBuilder<List<CommentModel>>(
              stream: _svc.streamComments(widget.taameemId),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(
                        color: AppColors.emerald, strokeWidth: 2)));
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 42,
                          color: AppColors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text('كن أول من يعلّق',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.grey)),
                    ]),
                  );
                }
                return Column(children: list.map((c) =>
                  _CommentTile(
                    comment: c,
                    isLiked: _likedIds.contains(c.id),
                    onLike: () {
                      if (!_likedIds.contains(c.id)) {
                        setState(() => _likedIds.add(c.id));
                        _svc.likeComment(widget.taameemId, c.id);
                      }
                    },
                  )).toList());
              },
            ),

            Divider(height: 1, color: AppColors.glassBorder),

            // حقل الإضافة
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.emerald, AppColors.forestGreen]),
                    shape: BoxShape.circle),
                  child: const Center(child: Text('أ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.nearBlack),
                    decoration: InputDecoration(
                      hintText: 'أضف تعليقاً...',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.grey),
                      filled: true, fillColor: AppColors.warmBeige,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.glassBorder)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.glassBorder)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.emerald)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(_ctrl.text),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [AppColors.emerald, AppColors.forestGreen]),
                      boxShadow: [BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.35),
                        blurRadius: 8, offset: const Offset(0, 2))]),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 16)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── تعليق واحد ────────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isLiked;
  final VoidCallback onLike;
  const _CommentTile({required this.comment, required this.isLiked, required this.onLike});

  Color get _color {
    const cols = [AppColors.emerald, AppColors.teal,
      Color(0xFF3A8AA8), Color(0xFFB07820),
      Color(0xFFC03030), Color(0xFF7A3A8A)];
    return cols[comment.userName.codeUnits
        .fold(0, (a, b) => a + b) % cols.length];
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(
          color: AppColors.glassBorder.withValues(alpha: 0.5)))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        child: Center(child: Text(
          comment.userName.isNotEmpty ? comment.userName[0] : 'م',
          style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: Colors.white))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(comment.userName,
            style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack)),
          const Spacer(),
          GestureDetector(
            onTap: onLike,
            child: Row(children: [
              Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 13,
                color: isLiked ? AppColors.error : AppColors.grey),
              const SizedBox(width: 3),
              Text('${comment.likes}',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: isLiked ? AppColors.error : AppColors.grey)),
            ]),
          ),
        ]),
        const SizedBox(height: 3),
        Text(comment.text,
          style: GoogleFonts.cairo(
            fontSize: 12, color: AppColors.forestGreen, height: 1.65)),
        const SizedBox(height: 4),
        Text(comment.timeAgo,
          style: GoogleFonts.cairo(fontSize: 10, color: AppColors.grey)),
      ])),
    ]),
  );
}
