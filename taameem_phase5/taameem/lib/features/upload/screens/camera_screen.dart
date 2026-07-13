import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';


// â”€â”€ ط£ظٹ ظ„ظˆط­ط© ظ…ظپطھظˆط­ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
enum _Panel { none, category, location, radius, duration, title, attachments }

// â”€â”€ ط£ظ„ظˆط§ظ† ط§ظ„ط°ظ‡ط¨ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _gold     = Color(0xFFC9A84C);
const _goldBg   = Color.fromRGBO(201, 168, 76, 0.18);
const _goldGlow = Color.fromRGBO(201, 168, 76, 0.28);

// â”€â”€ ط£ط¨ط¹ط§ط¯ ط§ظ„ط£ط²ط±ط§ط± (ظ…ط·ط§ط¨ظ‚ط© ظ„ظ„طھطµظ…ظٹظ…) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _btnW  = 105.0;
const _btnH  = 45.0;
const _btnGap = 6.0;
const _btnR  = 5.0;
const _btnRadius = 20.0;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {

  // â”€â”€ state ط§ظ„طھط¹ظ…ظٹظ… â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String?    _type;
  LatLng?    _location;
  double     _radius   = 10;
  Duration   _duration = const Duration(days: 3);
  String     _title    = '';
  List<File> _media    = [];

  // â”€â”€ state ط§ظ„ظˆط§ط¬ظ‡ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  _Panel _panel       = _Panel.none;
  bool   _publishing  = false;

  late AnimationController _animCtrl;
  late Animation<double>   _anim;
  final _titleCtrl = TextEditingController();
  final _picker    = ImagePicker();

  // â”€â”€ ظپط¦ط§طھ ط§ظ„طھط¹ظ…ظٹظ… â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _cats = [
    {'k':'missingPerson',  'n':'ظپظ‚ط¯ط§ظ† ط´ط®طµ',  'e':'ًں‘¤'},
    {'k':'foundItem',      'n':'ط¥ظٹط¬ط§ط¯ ط´ظٹط،',  'e':'ًں“¦'},
    {'k':'lostItem',       'n':'ظپظ‚ط¯ط§ظ† ط´ظٹط،',  'e':'ًں”چ'},
    {'k':'theft',          'n':'ط³ط±ظ‚ط©',         'e':'ًںڑ¨'},
    {'k':'helpRequest',    'n':'ط§ط³طھط؛ط§ط«ط©',      'e':'ًں†ک'},
    {'k':'humanitarian',   'n':'ط¥ظ†ط³ط§ظ†ظٹ',       'e':'ًں¤‌'},
    {'k':'emergency',      'n':'ط·ط§ط±ط¦',         'e':'ًںڑ‘'},
    {'k':'generalWarning', 'n':'طھط­ط°ظٹط±',        'e':'âڑ ï¸ڈ'},
    {'k':'lostAnimal',     'n':'ط­ظٹظˆط§ظ† ظ…ظپظ‚ظˆط¯', 'e':'ًںگ¾'},
    {'k':'inquiry',        'n':'ط§ط³طھظپط³ط§ط±',      'e':'ًں’¬'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchLocation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _titleCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.instance.getCurrentLocation();
    if (mounted) setState(() => _location = loc);
  }

  // â”€â”€ ظپطھط­ / ط¥ط؛ظ„ط§ظ‚ ظ„ظˆط­ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _open(_Panel p) {
    if (_panel == p) { _close(); return; }
    setState(() => _panel = p);
    _animCtrl.forward(from: 0);
  }

  void _close() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _panel = _Panel.none);
    });
  }

  // â”€â”€ ط§ظ„طھظ‚ط§ط· طµظˆط±ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _capture() async {
    final f = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 90);
    if (f != null && mounted) setState(() => _media.add(File(f.path)));
  }

  Future<void> _pickGallery() async {
    final files = await _picker.pickMultipleMedia(imageQuality: 90);
    if (mounted) setState(() => _media.addAll(files.map((f) => File(f.path))));
  }

  // â”€â”€ ظ†ط´ط± ط§ظ„طھط¹ظ…ظٹظ… â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      List<String> urls = [];
      try {
        if (_media.isNotEmpty) {
          final id = '${DateTime.now().millisecondsSinceEpoch}';
          urls = await StorageService.instance
              .uploadImages(_media.where(_isImg).toList(), id);
        }
      } catch (_) {}

      final now = DateTime.now();
      await FirestoreService.instance.uploadTaameem(TaameemModel(
        id: '', userId: 'temp_user', userPhone: '+9665XXXXXXXX',
        type:        _type ?? 'inquiry',
        title:       _title.isNotEmpty
            ? _title
            : AppConstants.categoryNames[_type] ?? 'طھط¹ظ…ظٹظ…',
        description: _title,
        latitude:    _location?.latitude  ?? 24.7136,
        longitude:   _location?.longitude ?? 46.6753,
        imageUrls:   urls,
        createdAt:   now,
        expiresAt:   now.add(_duration),
        status:      'active',
      ));
      if (mounted) _showSuccess();
    } catch (_) {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('âœ…', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text('طھظ… ظ†ط´ط± ط§ظ„طھط¹ظ…ظٹظ…!',
              style: GoogleFonts.cairo(fontSize: 19,
                  fontWeight: FontWeight.w800, color: AppColors.nearBlack)),
            const SizedBox(height: 6),
            Text('ظٹط¸ظ‡ط± ط§ظ„ط¢ظ† ط¹ظ„ظ‰ ط§ظ„ط®ط±ظٹط·ط©',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.forestGreen)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () { Navigator.pop(context); Navigator.pop(context); },
              child: Container(
                width: double.infinity, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.forestGreen]),
                  borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text('ط§ظ„ط¹ظˆط¯ط© ظ„ظ„ط®ط±ظٹط·ط©',
                  style: GoogleFonts.cairo(fontSize: 14,
                      fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  bool _isImg(File f) {
    final e = f.path.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.heic', '.webp'].any(e.endsWith);
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  //  BUILD
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _panel != _Panel.none ? _close : null,
        child: Stack(children: [

          // 1. ط®ظ„ظپظٹط© ط§ظ„ظƒط§ظ…ظٹط±ط§
          const _CamBg(),

          // 2. ط´ط±ظٹط· ط§ظ„ط£ط¹ظ„ظ‰
          _topBar(top),

          // 3. 5 ط£ط²ط±ط§ط± ط§ظ„ظٹظ…ظٹظ†
          _rightButtons(top),

          // 4. ظ…ظ†ط·ظ‚ط© ط§ظ„ظ…ط±ظپظ‚ط§طھ
          _attArea(bot),

          // 5. ط²ط± ط§ظ„طھطµظˆظٹط±
          _shutterBtn(bot),

          // 6. ظ„ظˆط­ط© ط§ظ„طھظ…ط±ظٹط±
          if (_panel != _Panel.none)
            AnimatedBuilder(animation: _anim, builder: (_, __) => _panelLayer()),
        ]),
      ),
    );
  }

  // â”€â”€ ط´ط±ظٹط· ط§ظ„ط£ط¹ظ„ظ‰ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _topBar(double top) => Positioned(
    top: top + 10,
    left: 12, right: 12,
    child: Row(children: [
      // ط¥ط؛ظ„ط§ظ‚
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.58),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ),
      const Spacer(),
      Text('ط±ظپط¹ طھط¹ظ…ظٹظ…',
        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700,
            color: Colors.white)),
      const Spacer(),
      // ظ†ط´ط±
      GestureDetector(
        onTap: _publishing ? null : _publish,
        child: Container(
          height: 36, padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold, width: 1.8)),
          child: Center(
            child: _publishing
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _gold))
              : Text('ظ†ط´ط±', style: GoogleFonts.cairo(
                  fontSize: 14, fontWeight: FontWeight.w800, color: _gold)),
          ),
        ),
      ),
    ]),
  );

  // â”€â”€ 5 ط£ط²ط±ط§ط± ط§ظ„ظٹظ…ظٹظ† â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _rightButtons(double top) => Positioned(
    top: top + 64,
    right: _btnR,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _OBtn(emoji: _catEmoji(), label: 'ظپط¦ط© ط§ظ„طھط¹ظ…ظٹظ…',
          value:  _type != null ? _catName() : null,
          active: _panel == _Panel.category,
          onTap:  () => _open(_Panel.category)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: 'ًں“چ', label: 'ظ…ظˆظ‚ط¹ ط§ظ„طھط¹ظ…ظٹظ…',
          value:  _location != null ? 'ظ…ط­ط¯ط¯ âœ“' : null,
          active: _panel == _Panel.location,
          onTap:  () => _open(_Panel.location)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: 'ًں“،', label: 'ظ†ط·ط§ظ‚ ط§ظ„طھط¹ظ…ظٹظ…',
          value:  '${_radius.round()} ظƒظ…',
          active: _panel == _Panel.radius,
          onTap:  () => _open(_Panel.radius)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: 'âڈ±ï¸ڈ', label: 'ظ…ظڈط¯ط© ط§ظ„طھط¹ظ…ظٹظ…',
          value:  _durLabel(),
          active: _panel == _Panel.duration,
          onTap:  () => _open(_Panel.duration)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: 'âœڈï¸ڈ', label: 'ط¹ظ†ظˆط§ظ† ط§ظ„طھط¹ظ…ظٹظ…',
          value:  _title.isNotEmpty
              ? (_title.length > 10 ? '${_title.substring(0, 10)}â€¦' : _title)
              : null,
          active: _panel == _Panel.title,
          onTap:  () => _open(_Panel.title)),
      ],
    ),
  );

  // â”€â”€ ظ…ظ†ط·ظ‚ط© ط§ظ„ظ…ط±ظپظ‚ط§طھ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // â”€â”€ ط²ط± ط§ظ„ظ…ط±ظپظ‚ط§طھ ط§ظ„ط¬ط§ظ†ط¨ظٹ â€” 25أ—120px ط«ط§ط¨طھ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _attArea(double bot) => Positioned(
    // ظ…ط±ظپظˆط¹ ظ‚ظ„ظٹظ„ط§ظ‹ ط¹ظ† ط§ظ„ط²ط± ط§ظ„ط³ط§ط¨ظ‚
    bottom: bot + 120,
    left: 10,
    child: GestureDetector(
      onTap: () => _open(_Panel.attachments),
      child: Container(
        // ط§ظ„ط­ط¬ظ… ط«ط§ط¨طھ ظ„ط§ ظٹطھط؛ظٹط± ظ…ظ‡ظ…ط§ ظƒط§ظ† ط¹ط¯ط¯ ط§ظ„طµظˆط±
        width: 25,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold, width: 1.5),
          // ط®ظ„ظپظٹط©: ط£ط³ظˆط¯ ظƒط«ظٹظپ ط£ط¹ظ„ظ‰ â†’ ط´ظپط§ظپ ط£ط³ظپظ„
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.82),
              Colors.black.withOpacity(0.50),
              Colors.black.withOpacity(0.18),
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [

            // â”€â”€ ط·ط¨ظ‚ط§طھ ط§ظ„طµظˆط± ط§ظ„ظ…طھط±ط§ظƒظ…ط© (ط§ظ„ط¬ط²ط، ط§ظ„ط¹ظ„ظˆظٹ ط«ط§ط¨طھ) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned(
              top: 4, left: 2, right: 2,
              // ط§ط±طھظپط§ط¹ ظ…ظ†ط·ظ‚ط© ط§ظ„طµظˆط± ط«ط§ط¨طھ â€” 78px
              height: 78,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: _media.take(3).toList().reversed
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final i   = e.key;   // 0=ط£ظ‚ط¯ظ…طŒ 2=ط£ط­ط¯ط«
                  final f   = e.value;
                  // ط§ظ„طµظˆط±ط© ط§ظ„ط£ط­ط¯ط« (i=2) طھظƒظˆظ† ظپظٹ ط§ظ„ط£ظ…ط§ظ… ظ…ط¹ offset ط£ظ‚ظ„
                  final offset = (2 - i) * 4.0;
                  return Positioned(
                    top: offset,
                    left: 0, right: 0,
                    child: Opacity(
                      opacity: 1.0 - (2 - i) * 0.18,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 21,
                          height: 70 - offset,
                          child: _isImg(f)
                            ? Image.file(f, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.videocam_rounded,
                                  color: Colors.white54,
                                  size: 12)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // â”€â”€ ط¹ط¯ط§ط¯ ط§ظ„طµظˆط± â€” ط«ط§ط¨طھ ط£ط¹ظ„ظ‰ ط§ظ„ظٹظ…ظٹظ† â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_media.isNotEmpty)
              Positioned(
                top: 2, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_media.length > 9 ? '9+' : _media.length}',
                      style: const TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // â”€â”€ ط£ظٹظ‚ظˆظ†ط© ط§ظ„ظ…ط´ط¨ظƒ â€” ط«ط§ط¨طھط© ط¯ط§ط¦ظ…ط§ظ‹ ظپظٹ ط§ظ„ط£ط³ظپظ„ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const Positioned(
              bottom: 6,
              left: 0, right: 0,
              child: Center(
                child: Icon(
                  Icons.attach_file_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          ],
        ),
      ),
    ),
  );

  // â”€â”€ ط²ط± ط§ظ„طھطµظˆظٹط± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _shutterBtn(double bot) => Positioned(
    bottom: bot + 26,
    left: 0, right: 0,
    child: Center(
      child: GestureDetector(
        onTap: _capture,
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withOpacity(0.88), width: 3.5)),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    ),
  );

  // â”€â”€ ط·ط¨ظ‚ط© ط§ظ„ظ„ظˆط­ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _panelLayer() {
    final fromLeft = _panel == _Panel.attachments;
    final w = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _close,
      child: Stack(children: [
        // طھط¯ط±ط¬ ط§ظ„ط®ظ„ظپظٹط©
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: fromLeft
                    ? Alignment.centerLeft : Alignment.centerRight,
                end: fromLeft
                    ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.black.withOpacity(0.90 * _anim.value),
                  Colors.black.withOpacity(0.50 * _anim.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // ظ…ط­طھظˆظ‰ ط§ظ„ظ„ظˆط­ط©
        Positioned(
          top: 0, bottom: 0,
          right: fromLeft ? null : 0,
          left:  fromLeft ? 0 : null,
          width: w * 0.74,
          child: Transform.translate(
            offset: Offset(
              fromLeft
                ? -w * (1 - _anim.value)
                : w  * (1 - _anim.value),
              0),
            child: GestureDetector(
              onTap: () {},
              child: _panelContent(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _panelContent() {
    final top = MediaQuery.of(context).padding.top;
    switch (_panel) {
      case _Panel.category:
        return _CatPanel(cats: _cats, selected: _type,
          topPad: top,
          onSave: (k) { setState(() => _type = k); _close(); });
      case _Panel.location:
        return _LocPanel(location: _location, topPad: top,
          onSave: (l) { setState(() => _location = l); _close(); });
      case _Panel.radius:
        return _RadPanel(radius: _radius, topPad: top,
          onSave: (r) { setState(() => _radius = r); _close(); });
      case _Panel.duration:
        return _DurPanel(duration: _duration, topPad: top,
          onSave: (d) { setState(() => _duration = d); _close(); });
      case _Panel.title:
        return _TitlePanel(ctrl: _titleCtrl, initial: _title, topPad: top,
          onSave: (t) { setState(() => _title = t); _close(); });
      case _Panel.attachments:
        return _AttPanel(media: _media, topPad: top,
          onCapture: () { _close(); _capture(); },
          onGallery: _pickGallery,
          onRemove:  (i) => setState(() => _media.removeAt(i)));
      default: return const SizedBox.shrink();
    }
  }

  // â”€â”€ ظ…ط³ط§ط¹ط¯ط§طھ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _catEmoji() => _type != null
    ? (_cats.firstWhere((c) => c['k'] == _type,
        orElse: () => const {'e': 'ًںڈ·ï¸ڈ'})['e'] as String)
    : 'ًںڈ·ï¸ڈ';

  String _catName() => _cats
    .firstWhere((c) => c['k'] == _type, orElse: () => const {'n': ''})['n'] as String;

  String _durLabel() {
    final d = _duration;
    if (d.inDays >= 365) return 'ط³ظ†ط©';
    if (d.inDays >= 30)  return '${d.inDays ~/ 30} ط´ظ‡ط±';
    if (d.inDays >= 7)   return '${d.inDays ~/ 7} ط£ط³ط§ط¨ظٹط¹';
    if (d.inDays >= 1)   return '${d.inDays} ظٹظˆظ…';
    return '${d.inHours} ط³ط§ط¹ط©';
  }
}

// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
//  _OBtn â€” ط²ط± ط§ظ„ط®ظٹط§ط± (ط§ظ„ط£ط¨ط¹ط§ط¯ ط§ظ„ظ…ظڈط­ط¯ط¯ط©)
// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
class _OBtn extends StatelessWidget {
  final String emoji, label;
  final String? value;
  final bool active;
  final VoidCallback onTap;

  const _OBtn({required this.emoji, required this.label,
    this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _btnW,
      height: _btnH,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_btnRadius),
        border: Border.all(color: _gold, width: 1.8),
        color: active ? _goldBg : Colors.transparent,
        boxShadow: active ? [BoxShadow(
          color: _goldGlow, blurRadius: 14)] : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ظ†طµ ط§ظ„ظٹط³ط§ط±
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(
                  fontSize: 8.5, color: Colors.white.withOpacity(0.58)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (value != null)
                  Text(value!, style: GoogleFonts.cairo(
                    fontSize: 10.5, fontWeight: FontWeight.w800, color: _gold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // ط¥ظٹظ…ظˆط¬ظٹ ط§ظ„ظٹظ…ظٹظ†
          Text(emoji, style: const TextStyle(fontSize: 17)),
        ],
      ),
    ),
  );
}

// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
//  ط®ظ„ظپظٹط© ط§ظ„ظƒط§ظ…ظٹط±ط§ ط§ظ„ظ…طھط­ط±ظƒط©
// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
class _CamBg extends StatefulWidget {
  const _CamBg();
  @override State<_CamBg> createState() => _CamBgState();
}

class _CamBgState extends State<_CamBg> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(seconds: 10))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(_c.value * 0.4 - 0.2, _c.value * 0.3 - 0.15),
          radius: 1.2,
          colors: const [
            Color(0xFF1A3520), Color(0xFF0C1A10), Color(0xFF050D07)],
        ),
      ),
      child: CustomPaint(size: Size.infinite, painter: _GridP()),
    ),
  );
}

class _GridP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = .8;
    for (double x = 0; x < s.width;  x += 52) c.drawLine(Offset(x,0), Offset(x,s.height), p);
    for (double y = 0; y < s.height; y += 52) c.drawLine(Offset(0,y), Offset(s.width,y), p);
  }
  @override bool shouldRepaint(_GridP o) => false;
}

// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
//  ظ„ظˆط­ط© ظ…ط´طھط±ظƒط©
// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
class _PanelBase extends StatelessWidget {
  final String title;
  final double topPad;
  final Widget child;
  final VoidCallback onSave;

  const _PanelBase({required this.title, required this.topPad,
    required this.child, required this.onSave});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(12, topPad + 56, 12, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.cairo(
        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 14),
      Expanded(child: SingleChildScrollView(child: child)),
      const SizedBox(height: 10),
      _goldSave(onSave),
    ]),
  );

  static Widget _goldSave(VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: double.infinity, height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _gold, width: 1.8)),
      child: Center(child: Text('ط­ظپط¸',
        style: GoogleFonts.cairo(fontSize: 14,
            fontWeight: FontWeight.w800, color: _gold))),
    ),
  );
}

Widget _goldCard(Widget child) => Container(
  padding: const EdgeInsets.all(14),
  margin: const EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _gold, width: 1.8),
    color: Colors.black.withOpacity(0.4)),
  child: child,
);

// â”€â”€ ظ„ظˆط­ط© ط§ظ„ظپط¦ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CatPanel extends StatefulWidget {
  final List<Map<String, String>> cats;
  final String? selected;
  final double topPad;
  final ValueChanged<String?> onSave;
  const _CatPanel({required this.cats, required this.selected,
    required this.topPad, required this.onSave});
  @override State<_CatPanel> createState() => _CatPanelState();
}
class _CatPanelState extends State<_CatPanel> {
  String? _tmp;
  @override void initState() { super.initState(); _tmp = widget.selected; }
  @override
  Widget build(BuildContext context) => _PanelBase(
    title: 'ظپط¦ط© ط§ظ„طھط¹ظ…ظٹظ…', topPad: widget.topPad,
    onSave: () => widget.onSave(_tmp),
    child: Column(children: widget.cats.map((c) {
      final sel = _tmp == c['k'];
      return GestureDetector(
        onTap: () => setState(() => _tmp = sel ? null : c['k']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: sel ? _gold : _gold.withOpacity(0.35),
              width: sel ? 2 : 1.5),
            color: sel ? _goldBg : Colors.transparent),
          child: Row(children: [
            Text(c['e']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(c['n']!, style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: Colors.white))),
            if (sel) const Icon(Icons.check_rounded, color: _gold, size: 15),
          ]),
        ),
      );
    }).toList()),
  );
}

// â”€â”€ ظ„ظˆط­ط© ط§ظ„ظ…ظˆظ‚ط¹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LocPanel extends StatefulWidget {
  final LatLng? location;
  final double topPad;
  final ValueChanged<LatLng?> onSave;
  const _LocPanel({required this.location, required this.topPad, required this.onSave});
  @override State<_LocPanel> createState() => _LocPanelState();
}
class _LocPanelState extends State<_LocPanel> {
  LatLng? _loc;
  @override void initState() { super.initState(); _loc = widget.location; }
  @override
  Widget build(BuildContext context) => _PanelBase(
    title: 'ظ…ظˆظ‚ط¹ ط§ظ„طھط¹ظ…ظٹظ…', topPad: widget.topPad,
    onSave: () => widget.onSave(_loc ?? LocationService.defaultLocation),
    child: Column(children: [
      _goldCard(SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _loc ?? LocationService.defaultLocation,
              initialZoom: 14,
              onTap: (_, pt) => setState(() => _loc = pt),
              interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all)),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taameem.app'),
              if (_loc != null)
                MarkerLayer(markers: [Marker(
                  point: _loc!, width: 40, height: 48,
                  child: Column(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _gold, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: _goldGlow, blurRadius: 8)]),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 16)),
                    CustomPaint(size: const Size(10, 6),
                        painter: _TriP()),
                  ]),
                )]),
            ],
          ),
        ),
      )),
      Text(_loc != null
        ? 'ط§ط¶ط؛ط· ط¹ظ„ظ‰ ط§ظ„ط®ط±ظٹط·ط© ظ„طھط؛ظٹظٹط± ط§ظ„ظ…ظˆظ‚ط¹'
        : 'ط§ط¶ط؛ط· ط¹ظ„ظ‰ ط§ظ„ط®ط±ظٹط·ط© ظ„طھط­ط¯ظٹط¯ ط§ظ„ظ…ظˆظ‚ط¹',
        style: GoogleFonts.cairo(fontSize: 11,
            color: Colors.white.withOpacity(0.5))),
    ]),
  );
}

class _TriP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => c.drawPath(
    ui.Path()..moveTo(0,0)..lineTo(s.width,0)
             ..lineTo(s.width/2,s.height)..close(),
    ui.Paint()..color = _gold);
  @override bool shouldRepaint(_TriP o) => false;
}

// â”€â”€ ظ„ظˆط­ط© ط§ظ„ظ†ط·ط§ظ‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RadPanel extends StatefulWidget {
  final double radius; final double topPad; final ValueChanged<double> onSave;
  const _RadPanel({required this.radius, required this.topPad, required this.onSave});
  @override State<_RadPanel> createState() => _RadPanelState();
}
class _RadPanelState extends State<_RadPanel> {
  late double _r; bool _ksa = false;
  @override void initState() { super.initState(); _r = widget.radius; }
  @override
  Widget build(BuildContext context) => _PanelBase(
    title: 'ظ†ط·ط§ظ‚ ط§ظ„طھط¹ظ…ظٹظ…', topPad: widget.topPad,
    onSave: () => widget.onSave(_ksa ? 999 : _r),
    child: Column(children: [
      _goldCard(Column(children: [
        Text('${_r.round()} ظƒظ…', style: GoogleFonts.cairo(
          fontSize: 30, fontWeight: FontWeight.w800, color: _gold)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _gold, thumbColor: _gold,
            inactiveTrackColor: Colors.white24,
            overlayColor: _goldGlow),
          child: Slider(value: _r, min: 1, max: 500,
            onChanged: (v) => setState(() => _r = v))),
      ])),
      GestureDetector(
        onTap: () => setState(() => _ksa = !_ksa),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _ksa ? Colors.red : Colors.red.withOpacity(0.45)),
            color: _ksa ? Colors.red.withOpacity(0.2) : Colors.transparent),
          child: Center(child: Text('ًں‡¸ًں‡¦  ط§ظ„ظ…ظ…ظ„ظƒط© ظƒط§ظ…ظ„ط©',
            style: GoogleFonts.cairo(fontSize: 14,
                fontWeight: FontWeight.w800, color: Colors.red.shade300))),
        ),
      ),
    ]),
  );
}

// â”€â”€ ظ„ظˆط­ط© ط§ظ„ظ…ط¯ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DurPanel extends StatefulWidget {
  final Duration duration; final double topPad; final ValueChanged<Duration> onSave;
  const _DurPanel({required this.duration, required this.topPad, required this.onSave});
  @override State<_DurPanel> createState() => _DurPanelState();
}
class _DurPanelState extends State<_DurPanel> {
  late int _d;
  static const _picks = [1, 3, 7, 14, 30, 90];
  @override void initState() { super.initState(); _d = widget.duration.inDays.clamp(1, 365); }
  @override
  Widget build(BuildContext context) => _PanelBase(
    title: 'ظ…ظڈط¯ط© ط§ظ„طھط¹ظ…ظٹظ…', topPad: widget.topPad,
    onSave: () => widget.onSave(Duration(days: _d)),
    child: _goldCard(Column(children: [
      Text('$_d ظٹظˆظ…', style: GoogleFonts.cairo(
        fontSize: 28, fontWeight: FontWeight.w800, color: _gold)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: _picks.map((d) {
        final sel = _d == d;
        return GestureDetector(
          onTap: () => setState(() => _d = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? _gold : _gold.withOpacity(0.4)),
              color: sel ? _goldBg : Colors.transparent),
            child: Text('$d ${d == 1 ? 'ظٹظˆظ…' : d < 11 ? 'ط£ظٹط§ظ…' : 'ظٹظˆظ…'}',
              style: GoogleFonts.cairo(fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sel ? _gold : Colors.white70)),
          ),
        );
      }).toList()),
    ])),
  );
}

// â”€â”€ ظ„ظˆط­ط© ط§ظ„ط¹ظ†ظˆط§ظ† â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TitlePanel extends StatelessWidget {
  final TextEditingController ctrl;
  final String initial, topPad2 = '';
  final double topPad;
  final ValueChanged<String> onSave;
  const _TitlePanel({required this.ctrl, required this.initial,
    required this.topPad, required this.onSave});
  @override
  Widget build(BuildContext context) {
    if (ctrl.text.isEmpty && initial.isNotEmpty) ctrl.text = initial;
    return _PanelBase(
      title: 'ط¹ظ†ظˆط§ظ† ط§ظ„طھط¹ظ…ظٹظ…', topPad: topPad,
      onSave: () => onSave(ctrl.text.trim()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold, width: 1.8)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14))),
            child: Row(children: [
              const Text('âœڈï¸ڈ', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('ط¹ظ†ظˆط§ظ† / ظˆطµظپ ط§ظ„طھط¹ظ…ظٹظ…',
                style: GoogleFonts.cairo(
                    fontSize: 12, color: Colors.white.withOpacity(0.55))),
            ]),
          ),
          Container(height: 1, color: _gold.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: ctrl,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
              maxLines: 4, minLines: 3,
              decoration: InputDecoration(
                hintText: 'ط§ظƒطھط¨ ط¹ظ†ظˆط§ظ† ط£ظˆ ظˆطµظپ ط§ظ„طھط¹ظ…ظٹظ…...',
                hintStyle: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none),
            ),
          ),
        ]),
      ),
    );
  }
}

// â”€â”€ ظ„ظˆط­ط© ط§ظ„ظ…ط±ظپظ‚ط§طھ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
//  ظ„ظˆط­ط© ط§ظ„ظ…ط±ظپظ‚ط§طھ â€” ط¹ط±ط¶ ط¹ظ…ظˆط¯ظٹ ط¨ظ†ط³ط¨ط© 14:22 ظ…ط¹ طھظƒط¨ظٹط± ط¹ظ†ط¯ ط§ظ„ط¶ط؛ط·
// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
class _AttPanel extends StatelessWidget {
  final List<File> media;
  final double topPad;
  final VoidCallback onCapture, onGallery;
  final ValueChanged<int> onRemove;

  const _AttPanel({
    required this.media,
    required this.topPad,
    required this.onCapture,
    required this.onGallery,
    required this.onRemove,
  });

  bool _isImg(File f) {
    final e = f.path.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.heic', '.webp'].any(e.endsWith);
  }

  // â”€â”€ طھظƒط¨ظٹط± ط§ظ„طµظˆط±ط© ظƒط§ظ…ظ„ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showFullscreen(BuildContext context, File f) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          body: Stack(children: [
            // ط§ظ„طµظˆط±ط© ظ‚ط§ط¨ظ„ط© ظ„ظ„طھظƒط¨ظٹط± ظˆط§ظ„طھطµط؛ظٹط±
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _isImg(f)
                  ? Image.file(f, fit: BoxFit.contain)
                  : Container(
                      width: 260, height: 380,
                      color: Colors.grey.shade900,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_rounded,
                              color: Colors.white54, size: 64),
                          SizedBox(height: 12),
                          Text('ظپظٹط¯ظٹظˆ',
                            style: TextStyle(color: Colors.white54,
                                fontSize: 14)),
                        ],
                      ),
                    ),
              ),
            ),
            // ط²ط± ط§ظ„ط¥ط؛ظ„ط§ظ‚
            Positioned(
              top: 52, right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3))),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, topPad + 52, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // â”€â”€ ط±ط£ط³ ط§ظ„ظ„ظˆط­ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(children: [
            const Icon(Icons.perm_media_outlined,
                color: _gold, size: 18),
            const SizedBox(width: 8),
            Text('ط§ظ„ظ…ط±ظپظ‚ط§طھ',
              style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: Colors.white)),
            const SizedBox(width: 8),
            if (media.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10)),
                child: Text('${media.length}',
                  style: GoogleFonts.cairo(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              ),
          ]),

          const SizedBox(height: 10),

          // â”€â”€ ط£ط²ط±ط§ط± ط§ظ„ط¥ط¶ط§ظپط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(children: [
            Expanded(child: _actionBtn(
              icon: Icons.camera_alt_outlined,
              label: 'ط§ظ„طھظ‚ط·',
              onTap: onCapture)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(
              icon: Icons.photo_library_outlined,
              label: 'ط§ظ„ظ…ط¹ط±ط¶',
              onTap: onGallery)),
          ]),

          const SizedBox(height: 10),

          // â”€â”€ ظ‚ط§ط¦ظ…ط© ط§ظ„ظ…ط±ظپظ‚ط§طھ ط§ظ„ط¹ظ…ظˆط¯ظٹط© ط¨ظ†ط³ط¨ط© 14:22 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: media.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white24, size: 44),
                    const SizedBox(height: 8),
                    Text('ظ„ط§ طھظˆط¬ط¯ ظ…ط±ظپظ‚ط§طھ',
                      style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.white30)),
                  ],
                ))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: media.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => _showFullscreen(ctx, media[i]),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      // ظ†ط³ط¨ط© 14:22 (ط¹ط±ط¶:ط§ط±طھظپط§ط¹) â€” طµظˆط±ط© ط·ظˆظ„ظٹط© ظ…طµط؛ظ‘ط±ط©
                      child: AspectRatio(
                        aspectRatio: 14 / 22,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // ط§ظ„طµظˆط±ط©
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _isImg(media[i])
                                ? Image.file(media[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity)
                                : Container(
                                    color: Colors.grey.shade900,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.videocam_rounded,
                                            color: Colors.white54, size: 28),
                                        SizedBox(height: 4),
                                        Text('ظپظٹط¯ظٹظˆ',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11)),
                                      ],
                                    ),
                                  ),
                            ),

                            // ط­ط¯ظˆط¯ ط°ظ‡ط¨ظٹط© ط®ظپظٹظپط©
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _gold.withOpacity(0.25),
                                    width: 1)),
                              ),
                            ),

                            // ط£ظٹظ‚ظˆظ†ط© ط§ظ„طھظƒط¨ظٹط± (ط£ط³ظپظ„ ط§ظ„ظٹظ…ظٹظ†)
                            Positioned(
                              bottom: 6, right: 6,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6)),
                                child: const Icon(
                                  Icons.open_in_full_rounded,
                                  color: Colors.white70,
                                  size: 12),
                              ),
                            ),

                            // ط²ط± ط§ظ„ط­ط°ظپ (ط£ط¹ظ„ظ‰ ط§ظ„ظٹظ…ظٹظ†)
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => onRemove(i),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withOpacity(0.6), width: 1.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _gold, size: 14),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.cairo(
          fontSize: 12, fontWeight: FontWeight.w700, color: _gold)),
      ]),
    ),
  );
}
