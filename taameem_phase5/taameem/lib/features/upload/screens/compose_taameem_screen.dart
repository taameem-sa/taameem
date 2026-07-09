import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
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
  final _textCtrl = TextEditingController();
  late List<File> _media;

  // ط¥ط¹ط¯ط§ط¯ط§طھ ط§ظ„طھط¹ظ…ظٹظ…
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

  // â”€â”€ ظپطھط­ ظ„ظˆط­ط© ط¬ط§ظ†ط¨ظٹط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ ظ†ط´ط± ط§ظ„طھط¹ظ…ظٹظ… â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _publish() async {
    setState(() => _isPublishing = true);
    try {
      List<String> imageUrls = [];
      if (_media.isNotEmpty) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
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
        userId: 'temp_user',
        userPhone: '+9665XXXXXXXX',
        type: _type ?? 'inquiry',
        title: _textCtrl.text.trim().isNotEmpty
            ? _textCtrl.text.trim()
            : AppConstants.categoryNames[_type] ?? 'طھط¹ظ…ظٹظ…',
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ط­ط¯ط« ط®ط·ط£طŒ ط­ط§ظˆظ„ ظ…ط±ط© ط£ط®ط±ظ‰',
          style: GoogleFonts.cairo()),
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
              const Text('âœ…', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text('طھظ… ظ†ط´ط± ط§ظ„طھط¹ظ…ظٹظ…!',
                style: GoogleFonts.cairo(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const SizedBox(height: 8),
              Text(
                'ط³ظٹط¸ظ‡ط± ط¹ظ„ظ‰ ط§ظ„ط®ط±ظٹط·ط© ظˆط³طھطµظ„ ط¥ط´ط¹ط§ط±ط§طھ ظ„ظ„ظ…ط³طھط®ط¯ظ…ظٹظ† ظپظٹ ط§ظ„ظ†ط·ط§ظ‚ ط§ظ„ظ…ط­ط¯ط¯',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
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
                  child: Center(
                    child: Text('ط§ظ„ط¹ظˆط¯ط© ظ„ظ„ط®ط±ظٹط·ط©',
                      style: GoogleFonts.cairo(
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

  // â”€â”€ ط§ظ„ظˆط§ط¬ظ‡ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    // â”€â”€ ط­ظ‚ظ„ ط§ظ„ظ†طµ (Telegram style) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _buildTextField(),
                    const SizedBox(height: 10),
                    // â”€â”€ ط£ط²ط±ط§ط± ط§ظ„ط¥ط¹ط¯ط§ط¯ط§طھ ط§ظ„ط£ط±ط¨ط¹ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    _buildOptionsGrid(),
                    const SizedBox(height: 12),
                    // â”€â”€ ظ…ط¹ط±ط¶ ط§ظ„طµظˆط± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              Text('طھط¹ظ…ظٹظ… ط¬ط¯ظٹط¯',
                style: GoogleFonts.cairo(
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const Spacer(),
              // ط¹ط¯ط¯ ط§ظ„ظˆط³ط§ط¦ط·
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
                        style: GoogleFonts.cairo(
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
        style: GoogleFonts.cairo(
          fontSize: 15, color: AppColors.nearBlack, height: 1.6),
        decoration: InputDecoration(
          hintText: 'ط£ط¶ظپ ظˆطµظپط§ظ‹ ط£ظˆ ط¹ظ†ظˆط§ظ†ط§ظ‹ (ط§ط®طھظٹط§ط±ظٹ)...',
          hintStyle: GoogleFonts.cairo(
            fontSize: 14, color: AppColors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: const Padding(
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
              label: 'ظپط¦ط© ط§ظ„طھط¹ظ…ظٹظ…',
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
              label: 'ظ…ظˆظ‚ط¹ ط§ظ„طھط¹ظ…ظٹظ…',
              value: _location != null ? 'طھظ… ط§ظ„طھط­ط¯ظٹط¯' : null,
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
              label: 'ظ†ط·ط§ظ‚ ط§ظ„ط§ظ†طھط´ط§ط±',
              value: _allKingdom
                  ? 'ًں‡¸ًں‡¦ ط§ظ„ظ…ظ…ظ„ظƒط©'
                  : '${_radiusKm.round()} ظƒظ…',
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
              label: 'ظ…ط¯ط© ط§ظ„طھط¹ظ…ظٹظ…',
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
    if (d.inDays >= 365) return 'ط³ظ†ط©';
    if (d.inDays >= 7)   return '${d.inDays ~/ 7} ط£ط³ط¨ظˆط¹';
    if (d.inDays >= 1)   return '${d.inDays} ظٹظˆظ…';
    return '${d.inHours} ط³ط§ط¹ط©';
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text('ط§ظ„ظ…ط±ظپظ‚ط§طھ',
            style: GoogleFonts.cairo(
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
                                Text(isVideo ? 'ظپظٹط¯ظٹظˆ' : 'ظ…ظ„ظپ',
                                  style: GoogleFonts.cairo(
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('ظ†ط´ط± ط§ظ„طھط¹ظ…ظٹظ… ط§ظ„ط¢ظ†',
                          style: GoogleFonts.cairo(
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

// â”€â”€ ط¨ط·ط§ظ‚ط© ط®ظٹط§ط± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.grey)),
                  Text(
                    hasValue ? value! : 'ط§ط®طھظٹط§ط±ظٹ',
                    style: GoogleFonts.cairo(
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

