import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../widgets/category_side_panel.dart';
import '../widgets/location_side_panel.dart';
import '../widgets/radius_side_panel.dart';
import '../widgets/duration_side_panel.dart';

class ComposeTaameemScreen extends StatefulWidget {
  final List<File> mediaFiles;

  const ComposeTaameemScreen({super.key, required this.mediaFiles});

  @override
  State<ComposeTaameemScreen> createState() =>
      _ComposeTaameemScreenState();
}

class _ComposeTaameemScreenState extends State<ComposeTaameemScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _textCtrl = TextEditingController();
  late List<File> _media;

  // إعدادات التعميم
  String?       _type;
  LatLng?       _location;
  MarkerStyle   _markerStyle = MarkerStyle.typeCircle;
  double        _radiusKm   = 10;
  String?       _city;
  bool          _allKingdom = false;
  LatLng?       _scopeCenter;
  Duration      _duration   = const Duration(days: 3);

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _media = List.from(widget.mediaFiles);
    _fetchLocation();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.instance.getCurrentOrDefaultLocation();
    if (mounted) setState(() => _location = loc);
  }

  Future<({String userId, String userPhone})> _resolvePublisherIdentity() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      return (
        userId: existing.uid,
        userPhone: existing.phoneNumber ?? '',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    var guestId = prefs.getString('guest_user_id');
    if (guestId == null || guestId.isEmpty) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('guest_user_id', guestId);
    }

    return (userId: guestId, userPhone: '');
  }

  // ── فتح لوحة جانبية ──────────────────────────────────────────
  void _openPanel(Widget panel) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      barrierDismissible: true,
      barrierLabel: 'close',
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: SafeArea(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.creamWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: panel,
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  // ── نشر التعميم ──────────────────────────────────────────────
  Future<void> _publish() async {
    setState(() => _isPublishing = true);
    try {
      final identity = await _resolvePublisherIdentity();

      List<String> imageUrls = [];
      if (_media.isNotEmpty) {
        final tempId = '${identity.userId}_${DateTime.now().millisecondsSinceEpoch}';
        imageUrls = await StorageService.instance
            .uploadMediaFiles(_media, tempId);
      }

      final fallbackLocation = await LocationService.instance.getDefaultLocation();
      final publishLocation = _location ?? _scopeCenter ?? fallbackLocation;

      final now    = DateTime.now();
      final expiry = now.add(_duration.inSeconds == 0
          ? const Duration(days: 3) : _duration);

      final t = TaameemModel(
        id: '',
        userId: identity.userId,
        userPhone: identity.userPhone,
        type: _type ?? 'inquiry',
        title: _textCtrl.text.trim().isNotEmpty
            ? _textCtrl.text.trim()
            : AppConstants.categoryNames[_type] ?? 'تعميم',
        description: _textCtrl.text.trim(),
        latitude: publishLocation.latitude,
        longitude: publishLocation.longitude,
        imageUrls: imageUrls,
        createdAt: now,
        expiresAt: expiry,
        status: 'active',
        city: _city ?? '',
        radiusKm: _radiusKm,
        allKingdom: _allKingdom,
        scopeCenterLat: _scopeCenter?.latitude,
        scopeCenterLng: _scopeCenter?.longitude,
      );

      await FirestoreService.instance.uploadTaameem(t);

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      final errorText = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorText,
          style: const TextStyle(fontFamily: 'Tajawal',)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✅', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('تم نشر التعميم!',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const SizedBox(height: 8),
              const Text(
                'سيظهر على الخريطة وستصل إشعارات للمستخدمين في النطاق المحدد',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 13, color: AppColors.forestGreen,
                  height: 1.6)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.forestGreen]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('العودة للخريطة',
                      style: TextStyle(fontFamily: 'Tajawal',
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isImage(File f) {
    final ext = f.path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') ||
        ext.endsWith('.png') || ext.endsWith('.heic');
  }

  bool _isVideo(File f) {
    final ext = f.path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm');
  }

  // ── الواجهة ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    // ── حقل النص (Telegram style) ──────────────
                    _buildTextField(),
                    const SizedBox(height: 10),
                    // ── أزرار الإعدادات الأربعة ──────────────
                    _buildOptionsGrid(),
                    const SizedBox(height: 12),
                    // ── معرض الصور ───────────────────────────
                    if (_media.isNotEmpty) _buildMediaBar(),
                  ],
                ),
              ),
            ),
            _buildPublishBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(
                bottom: BorderSide(color: AppColors.glassBorder)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warmBeige,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.forestGreen),
                ),
              ),
              const SizedBox(width: 12),
              const Text('تعميم جديد',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const Spacer(),
              // عدد الوسائط
              if (_media.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.perm_media_rounded,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('${_media.length}',
                        style: const TextStyle(fontFamily: 'Tajawal',
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.gold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: _textCtrl,
        style: const TextStyle(fontFamily: 'Tajawal',
          fontSize: 15, color: AppColors.nearBlack, height: 1.6),
        decoration: const InputDecoration(
          hintText: 'أضف وصفاً أو عنواناً (اختياري)...',
          hintStyle: TextStyle(fontFamily: 'Tajawal',
            fontSize: 14, color: AppColors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          prefixIcon: Padding(
            padding: EdgeInsets.only(right: 12, top: 14),
            child: Icon(Icons.edit_rounded,
                color: AppColors.emerald, size: 18),
          ),
        ),
        maxLines: 4,
        minLines: 2,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _OptionCard(
              icon: Icons.category_rounded,
              label: 'فئة التعميم',
              value: _type != null
                  ? AppConstants.categoryNames[_type] : null,
              color: _typeColor,
              onTap: () => _openPanel(CategorySidePanel(
                selectedType: _type,
                onSave: (t) => setState(() => _type = t),
              )),
            )),
            const SizedBox(width: 10),
            Expanded(child: _OptionCard(
              icon: Icons.location_on_rounded,
              label: 'موقع التعميم',
              value: _location != null ? 'تم التحديد' : null,
              color: AppColors.emerald,
              onTap: () => _openPanel(LocationSidePanel(
                initialLocation: _location,
                markerStyle: _markerStyle,
                markerImage: _media.isNotEmpty && _isImage(_media.first)
                    ? _media.first : null,
                taameemType: _type,
                onSave: (d) => setState(() {
                  _location    = d['location'] as LatLng?;
                  _markerStyle = d['markerStyle'] as MarkerStyle;
                }),
              )),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _OptionCard(
              icon: Icons.radar_rounded,
              label: 'نطاق الانتشار',
              value: _allKingdom
                  ? '🇸🇦 المملكة'
                  : '${_radiusKm.round()} كم',
              color: AppColors.mint,
              onTap: () => _openPanel(RadiusSidePanel(
                radiusKm: _radiusKm,
                selectedCity: _city,
                onSave: (d) => setState(() {
                  _radiusKm   = d['radius']     as double;
                  _city       = d['city']        as String?;
                  _allKingdom = d['allKingdom']  as bool;
                  _scopeCenter = d['center'] as LatLng?;
                }),
              )),
            )),
            const SizedBox(width: 10),
            Expanded(child: _OptionCard(
              icon: Icons.timer_outlined,
              label: 'مدة التعميم',
              value: _durationLabel,
              color: AppColors.gold,
              onTap: () => _openPanel(DurationSidePanel(
                selectedDuration: _duration,
                onSave: (d) => setState(() => _duration = d),
              )),
            )),
          ],
        ),
      ],
    );
  }

  String get _durationLabel {
    final d = _duration;
    if (d.inDays >= 365) return 'سنة';
    if (d.inDays >= 7)   return '${d.inDays ~/ 7} أسبوع';
    if (d.inDays >= 1)   return '${d.inDays} يوم';
    return '${d.inHours} ساعة';
  }

  Color get _typeColor {
    switch (_type) {
      case 'missingPerson':  return AppColors.missingPerson;
      case 'theft':          return AppColors.theft;
      case 'emergency':      return AppColors.emergency;
      case 'helpRequest':    return AppColors.helpRequest;
      case 'generalWarning': return AppColors.generalWarning;
      default:               return AppColors.emerald;
    }
  }

  Widget _buildMediaBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, right: 4),
          child: Text('المرفقات',
            style: TextStyle(fontFamily: 'Tajawal',
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.forestGreen)),
        ),
        SizedBox(
          height: 100,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _media.length,
            onReorder: (old, nw) {
              setState(() {
                final f = _media.removeAt(old);
                _media.insert(nw > old ? nw - 1 : nw, f);
              });
            },
            itemBuilder: (_, i) {
              final f = _media[i];
              final isVideo = _isVideo(f);
              return Stack(
                key: ValueKey(f.path),
                children: [
                  Container(
                    width: 90,
                    margin: const EdgeInsets.only(left: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isImage(f)
                        ? Image.file(f, fit: BoxFit.cover,
                            width: 90, height: 100)
                        : Container(
                            color: AppColors.warmBeige,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isVideo
                                      ? Icons.videocam_rounded
                                      : Icons.description_rounded,
                                  color: AppColors.emerald,
                                  size: 28,
                                ),
                                Text(isVideo ? 'فيديو' : 'ملف',
                                  style: const TextStyle(fontFamily: 'Tajawal',
                                    fontSize: 10,
                                    color: AppColors.forestGreen)),
                              ],
                            )),
                    ),
                  ),
                  Positioned(
                    top: 4, left: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _media.removeAt(i)),
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPublishBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              14, 10, 14,
              MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(
                top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: GestureDetector(
            onTap: _isPublishing ? null : _publish,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.forestGreen]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 14, offset: const Offset(0, 5))
                ],
              ),
              child: Center(
                child: _isPublishing
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('نشر التعميم الآن',
                          style: TextStyle(fontFamily: 'Tajawal',
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── بطاقة خيار ───────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String?  value;
  final Color    color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon, required this.label,
    required this.value, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasValue
              ? color.withValues(alpha: 0.08)
              : AppColors.warmBeige,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? color.withValues(alpha: 0.35)
                : AppColors.glassBorder,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: hasValue ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17,
                  color: hasValue ? color : AppColors.grey),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontSize: 11, color: AppColors.grey)),
                  Text(
                    hasValue ? value! : 'اختياري',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: hasValue
                          ? FontWeight.w700 : FontWeight.w400,
                      color: hasValue ? color : AppColors.grey),
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded,
                size: 16,
                color: hasValue ? color : AppColors.grey),
          ],
        ),
      ),
    );
  }
}


