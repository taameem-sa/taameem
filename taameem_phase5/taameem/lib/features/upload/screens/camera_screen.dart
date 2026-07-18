import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../widgets/category_side_panel.dart';
import '../widgets/radius_side_panel.dart';
import '../widgets/duration_side_panel.dart';

// ── أي لوحة مفتوحة ────────────────────────────────────────────────────────
enum _Panel { none, category, location, radius, duration, title, attachments }

// ── ألوان الذهب ────────────────────────────────────────────────────────────
const _gold     = Color(0xFFC9A84C);
const _goldBg   = Color.fromRGBO(201, 168, 76, 0.18);
const _goldGlow = Color.fromRGBO(201, 168, 76, 0.28);

// ── أبعاد الأزرار (مطابقة للتصميم) ────────────────────────────────────────
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

  // ── state التعميم ─────────────────────────────────────────────────────────
  String?    _type;
  LatLng?    _location;
  double     _radius   = 10;
  Duration   _duration = const Duration(days: 3);
  String     _title    = '';
  List<File> _media    = [];

  // ── state الواجهة ─────────────────────────────────────────────────────────
  _Panel _panel       = _Panel.none;
  bool   _publishing  = false;

  late AnimationController _animCtrl;
  late Animation<double>   _anim;
  final _titleCtrl = TextEditingController();
  final _picker    = ImagePicker();

  // ── فئات التعميم ──────────────────────────────────────────────────────────
  static const _cats = [
    {'k':'missingPerson',  'n':'فقدان شخص',  'e':'👤'},
    {'k':'foundItem',      'n':'إيجاد شيء',  'e':'📦'},
    {'k':'lostItem',       'n':'فقدان شيء',  'e':'🔍'},
    {'k':'theft',          'n':'سرقة',         'e':'🚨'},
    {'k':'helpRequest',    'n':'استغاثة',      'e':'🆘'},
    {'k':'humanitarian',   'n':'إنساني',       'e':'🤝'},
    {'k':'emergency',      'n':'طارئ',         'e':'🚑'},
    {'k':'generalWarning', 'n':'تحذير',        'e':'⚠️'},
    {'k':'lostAnimal',     'n':'حيوان مفقود', 'e':'🐾'},
    {'k':'inquiry',        'n':'استفسار',      'e':'💬'},
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

  // ── فتح / إغلاق لوحة ─────────────────────────────────────────────────────
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

  // ── التقاط صورة ──────────────────────────────────────────────────────────
  Future<void> _capture() async {
    final f = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 90);
    if (f != null && mounted) setState(() => _media.add(File(f.path)));
  }

  Future<void> _pickGallery() async {
    final files = await _picker.pickMultipleMedia(imageQuality: 90);
    if (mounted) setState(() => _media.addAll(files.map((f) => File(f.path))));
  }

  // ── نشر التعميم ──────────────────────────────────────────────────────────
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
            : AppConstants.categoryNames[_type] ?? 'تعميم',
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
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text('تم نشر التعميم!',
              style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 19,
                  fontWeight: FontWeight.w800, color: AppColors.nearBlack)),
            const SizedBox(height: 6),
            Text('يظهر الآن على الخريطة',
              style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 13, color: AppColors.forestGreen)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () { Navigator.pop(context); Navigator.pop(context); },
              child: Container(
                width: double.infinity, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.forestGreen]),
                  borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text('العودة للخريطة',
                  style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 14,
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

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bot = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _panel != _Panel.none ? _close : null,
        child: Stack(children: [

          // 1. خلفية الكاميرا
          const _CamBg(),

          // 2. شريط الأعلى
          _topBar(top),

          // 3. 5 أزرار اليمين
          _rightButtons(top),

          // 4. منطقة المرفقات
          _attArea(bot),

          // 5. زر التصوير
          _shutterBtn(bot),

          // 6. لوحة التمرير
          if (_panel != _Panel.none)
            AnimatedBuilder(animation: _anim, builder: (_, __) => _panelLayer()),
        ]),
      ),
    );
  }

  // ── شريط الأعلى ──────────────────────────────────────────────────────────
  Widget _topBar(double top) => Positioned(
    top: top + 10,
    left: 12, right: 12,
    child: Row(children: [
      // إغلاق
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
      Text('رفع تعميم',
        style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 16, fontWeight: FontWeight.w700,
            color: Colors.white)),
      const Spacer(),
      // نشر
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
              : Text('نشر', style: TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 14, fontWeight: FontWeight.w800, color: _gold)),
          ),
        ),
      ),
    ]),
  );

  // ── 5 أزرار اليمين ───────────────────────────────────────────────────────
  Widget _rightButtons(double top) => Positioned(
    top: top + 64,
    right: _btnR,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _OBtn(emoji: _catEmoji(), label: 'فئة التعميم',
          value:  _type != null ? _catName() : null,
          active: _panel == _Panel.category,
          onTap:  () => _open(_Panel.category)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: '📍', label: 'موقع التعميم',
          value:  _location != null ? 'محدد ✓' : null,
          active: _panel == _Panel.location,
          onTap:  () => _open(_Panel.location)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: '📡', label: 'نطاق التعميم',
          value:  '${_radius.round()} كم',
          active: _panel == _Panel.radius,
          onTap:  () => _open(_Panel.radius)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: '⏱️', label: 'مُدة التعميم',
          value:  _durLabel(),
          active: _panel == _Panel.duration,
          onTap:  () => _open(_Panel.duration)),
        const SizedBox(height: _btnGap),
        _OBtn(emoji: '✏️', label: 'عنوان التعميم',
          value:  _title.isNotEmpty
              ? (_title.length > 10 ? '${_title.substring(0, 10)}…' : _title)
              : null,
          active: _panel == _Panel.title,
          onTap:  () => _open(_Panel.title)),
      ],
    ),
  );

  // ── منطقة المرفقات ────────────────────────────────────────────────────────
  // ── زر المرفقات الجانبي — 25×120px ثابت ──────────────────────────────────
  Widget _attArea(double bot) => Positioned(
    // مرفوع قليلاً عن الزر السابق
    bottom: bot + 120,
    left: 10,
    child: GestureDetector(
      onTap: () => _open(_Panel.attachments),
      child: Container(
        // الحجم ثابت لا يتغير مهما كان عدد الصور
        width: 25,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold, width: 1.5),
          // خلفية: أسود كثيف أعلى → شفاف أسفل
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

            // ── طبقات الصور المتراكمة (الجزء العلوي ثابت) ──────────────────
            Positioned(
              top: 4, left: 2, right: 2,
              // ارتفاع منطقة الصور ثابت — 78px
              height: 78,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: _media.take(3).toList().reversed
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final i   = e.key;   // 0=أقدم، 2=أحدث
                  final f   = e.value;
                  // الصورة الأحدث (i=2) تكون في الأمام مع offset أقل
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

            // ── عداد الصور — ثابت أعلى اليمين ──────────────────────────────
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

            // ── أيقونة المشبك — ثابتة دائماً في الأسفل ──────────────────────
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

  // ── زر التصوير ───────────────────────────────────────────────────────────
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

  // ── طبقة اللوحة ──────────────────────────────────────────────────────────
  Widget _panelLayer() {
    final fromLeft = _panel == _Panel.attachments;
    final w = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _close,
      child: Stack(children: [
        // تدرج الخلفية
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
        // محتوى اللوحة
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
          onSave: (d) {
            setState(() {
              _location = d['location'] as LatLng?;
            });
            _close();
          });
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

  // ── مساعدات ───────────────────────────────────────────────────────────────
  String _catEmoji() => _type != null
    ? (_cats.firstWhere((c) => c['k'] == _type,
        orElse: () => const {'e': '🏷️'})['e'] as String)
    : '🏷️';

  String _catName() => _cats
    .firstWhere((c) => c['k'] == _type, orElse: () => const {'n': ''})['n'] as String;

  String _durLabel() {
    final d = _duration;
    if (d.inDays >= 365) return 'سنة';
    if (d.inDays >= 30)  return '${d.inDays ~/ 30} شهر';
    if (d.inDays >= 7)   return '${d.inDays ~/ 7} أسابيع';
    if (d.inDays >= 1)   return '${d.inDays} يوم';
    return '${d.inHours} ساعة';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _OBtn — زر الخيار (الأبعاد المُحددة)
// ══════════════════════════════════════════════════════════════════════════════
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
          // نص اليسار
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 8.5, color: Colors.white.withOpacity(0.58)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (value != null)
                  Text(value!, style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 10.5, fontWeight: FontWeight.w800, color: _gold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // إيموجي اليمين
          Text(emoji, style: const TextStyle(fontSize: 17)),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  خلفية الكاميرا المتحركة
// ══════════════════════════════════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════════════════════════════════
//  لوحة مشتركة
// ══════════════════════════════════════════════════════════════════════════════
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
      Text(title, style: TextStyle(fontFamily: 'NotoNaskhArabic',
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
      child: Center(child: Text('حفظ',
        style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 14,
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

// ── لوحة الفئة ────────────────────────────────────────────────────────────
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
    title: 'فئة التعميم', topPad: widget.topPad,
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
            Expanded(child: Text(c['n']!, style: TextStyle(fontFamily: 'NotoNaskhArabic',
              fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              color: Colors.white))),
            if (sel) const Icon(Icons.check_rounded, color: _gold, size: 15),
          ]),
        ),
      );
    }).toList()),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  لوحة الموقع — خريطة كبيرة + crosshair + اختيار نوع العلامة
// ══════════════════════════════════════════════════════════════════════════════
enum MarkerStyle { photo, category }

class _LocPanel extends StatefulWidget {
  final LatLng? location;
  final double topPad;
  final ValueChanged<Map<String, dynamic>> onSave;
  const _LocPanel({
    required this.location,
    required this.topPad,
    required this.onSave,
  });
  @override State<_LocPanel> createState() => _LocPanelState();
}

class _LocPanelState extends State<_LocPanel> {
  LatLng        _loc        = LocationService.defaultLocation;
  MarkerStyle   _style      = MarkerStyle.photo;
  bool          _hintShown  = true;
  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.location != null) _loc = widget.location!;
  }

  void _onMapEvent(MapEvent _) {
    final c = _mapCtrl.camera.center;
    setState(() {
      _loc = c;
      _hintShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, widget.topPad + 50, 0, 0),
      child: Column(children: [

        // ── رأس ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('موقع التعميم',
                style: TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 17, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onSave(
                    {'location': _loc, 'markerStyle': _style}),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold, width: 1.8)),
                  child: Text('حفظ',
                    style: TextStyle(fontFamily: 'NotoNaskhArabic',
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: _gold)),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            // إحداثيات دقيقة
            Text(
              '${_loc.latitude.toStringAsFixed(6)}°  '
              '${_loc.longitude.toStringAsFixed(6)}°',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFFC9A84C),
                letterSpacing: 0.3,
              ),
            ),
          ]),
        ),

        // ── الخريطة الكبيرة ─────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _gold.withOpacity(0.4), width: 1.5)),
                child: Stack(children: [

                  // الخريطة
                  FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _loc,
                      initialZoom: 16, // دقة عالية
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all),
                      onMapEvent: _onMapEvent,
                      onTap: (_, pt) {
                        setState(() { _loc = pt; _hintShown = false; });
                        _mapCtrl.move(pt, _mapCtrl.camera.zoom);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.taameem.app',
                        maxZoom: 19,
                      ),
                    ],
                  ),

                  // Crosshair ذهبي ثابت في المركز
                  const Center(child: _Crosshair()),

                  // تلميح يختفي بعد أول تفاعل
                  if (_hintShown)
                    Positioned(
                      bottom: 8, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _gold.withOpacity(0.3))),
                          child: Text(
                            'اسحب الخريطة أو اضغط لتحديد الموقع',
                            style: TextStyle(fontFamily: 'NotoNaskhArabic',
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                      ),
                    ),

                ]),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── اختيار نوع العلامة ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _gold.withOpacity(0.25), width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نوع العلامة على الخريطة',
                  style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 10, color: Colors.white.withOpacity(0.45))),
                const SizedBox(height: 8),
                Row(children: [

                  // نوع 1: صورة
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _style = MarkerStyle.photo),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _style == MarkerStyle.photo
                              ? _gold : _gold.withOpacity(0.3),
                          width: _style == MarkerStyle.photo ? 2 : 1.5),
                        color: _style == MarkerStyle.photo
                            ? _goldBg : Colors.transparent),
                      child: Column(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white, width: 2),
                            color: Colors.grey.shade800),
                          child: const Icon(Icons.image_rounded,
                              color: Colors.white70, size: 20)),
                        const SizedBox(height: 6),
                        Text('صورة من المرفقات',
                          style: TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: _style == MarkerStyle.photo
                                ? _gold : Colors.white70),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        if (_style == MarkerStyle.photo)
                          const Icon(Icons.check_circle_rounded,
                              color: _gold, size: 14),
                      ]),
                    ),
                  )),

                  const SizedBox(width: 10),

                  // نوع 2: علامة الفئة
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _style = MarkerStyle.category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _style == MarkerStyle.category
                              ? _gold : _gold.withOpacity(0.3),
                          width: _style == MarkerStyle.category ? 2 : 1.5),
                        color: _style == MarkerStyle.category
                            ? _goldBg : Colors.transparent),
                      child: Column(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.missingPerson,
                            border: Border.all(
                                color: Colors.white, width: 2.5)),
                          child: Center(
                            child: Text('مفقود',
                              style: TextStyle(fontFamily: 'NotoNaskhArabic',
                                fontSize: 8, fontWeight: FontWeight.w800,
                                color: Colors.white),
                              textAlign: TextAlign.center)),
                        ),
                        const SizedBox(height: 6),
                        Text('علامة فئة التعميم',
                          style: TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: _style == MarkerStyle.category
                                ? _gold : Colors.white70),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        if (_style == MarkerStyle.category)
                          const Icon(Icons.check_circle_rounded,
                              color: _gold, size: 14),
                      ]),
                    ),
                  )),

                ]),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── زر موقعي الحالي ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: GestureDetector(
            onTap: () async {
              final loc = await LocationService.instance.getCurrentLocation();
              if (mounted) {
                setState(() => _loc = loc);
                _mapCtrl.move(loc, 17);
              }
            },
            child: Container(
              width: double.infinity, height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _gold.withOpacity(0.45), width: 1.5)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: _gold, size: 14),
                  const SizedBox(width: 8),
                  Text('موقعي الحالي',
                    style: TextStyle(fontFamily: 'NotoNaskhArabic',
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _gold)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// Crosshair ذهبي في مركز الخريطة
class _Crosshair extends StatelessWidget {
  const _Crosshair();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 44,
      child: Stack(alignment: Alignment.center, children: [
        // خط عمودي
        Container(
          width: 1.5, height: 44,
          color: const Color(0xFFC9A84C)),
        // خط أفقي
        Container(
          width: 44, height: 1.5,
          color: const Color(0xFFC9A84C)),
        // نقطة المركز
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: const Color(0xFFC9A84C).withOpacity(0.8),
              blurRadius: 8)]),
        ),
      ]),
    );
  }
}

class _TriP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => c.drawPath(
    ui.Path()..moveTo(0,0)..lineTo(s.width,0)
             ..lineTo(s.width/2,s.height)..close(),
    ui.Paint()..color = _gold);
  @override bool shouldRepaint(_TriP o) => false;
}

// ── لوحة النطاق ───────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
//  لوحة نطاق التعميم — خريطة تفاعلية حرة كاملة
// ══════════════════════════════════════════════════════════════════════════════
class _RadPanel extends StatefulWidget {
  final double radius;
  final double topPad;
  final ValueChanged<double> onSave;
  const _RadPanel({
    required this.radius,
    required this.topPad,
    required this.onSave,
  });
  @override State<_RadPanel> createState() => _RadPanelState();
}

class _RadPanelState extends State<_RadPanel> {
  // ── state ─────────────────────────────────────────────────────────────────
  late double  _radiusKm;
  late LatLng  _center;
  bool         _ksaMode = false;
  bool         _draggingCenter = false;
  bool         _draggingEdge   = false;

  final MapController _mapCtrl = MapController();

  // نقطة المركز على الشاشة
  Offset _centerScreen = Offset.zero;
  Offset _edgeScreen   = Offset.zero;

  static const _quickPicks = [2.0, 5.0, 10.0, 25.0, 50.0];
  static const _saCenter   = LatLng(23.8859, 45.0792);

  // ── init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _radiusKm = widget.radius.clamp(1, 500);
    _center   = LocationService.defaultLocation;

    // نستمع لحركة الخريطة لتحديث مواضع العلامات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapCtrl.mapEventStream.listen((_) => _recalcScreenPositions());
    });
  }

  // ── حساب نقطة الحافة الشرقية ──────────────────────────────────────────────
  LatLng get _edgeLatLng {
    final lngOffset = (_radiusKm / 111.32) /
        math.cos(_center.latitude * math.pi / 180);
    return LatLng(_center.latitude, _center.longitude + lngOffset);
  }

  // ── تحديث إحداثيات الشاشة ────────────────────────────────────────────────
  void _recalcScreenPositions() {
    if (!mounted) return;
    try {
      final cam = _mapCtrl.camera;
      final c = cam.latLngToScreenPoint(_center);
      final e = cam.latLngToScreenPoint(_edgeLatLng);
      setState(() {
        _centerScreen = Offset(c.x.toDouble(), c.y.toDouble());
        _edgeScreen   = Offset(e.x.toDouble(), e.y.toDouble());
      });
    } catch (_) {}
  }

  // ── تحويل نقطة شاشة إلى latLng ───────────────────────────────────────────
  LatLng? _screenToLatLng(Offset pos) {
    try {
      return _mapCtrl.camera.pointToLatLng(
          math.Point(pos.dx, pos.dy));
    } catch (_) { return null; }
  }

  // ── تحديث كل شيء ─────────────────────────────────────────────────────────
  void _updateRadius(double km, {bool moveMap = false}) {
    setState(() => _radiusKm = km.clamp(0.5, 900));
    if (moveMap && km < 200) {
      final zoom = km < 2  ? 13.0 : km < 5  ? 12.0 : km < 12 ? 11.0
                 : km < 30 ? 10.0 : km < 70 ?  9.0 : km < 150 ? 8.0 : 7.0;
      _mapCtrl.move(_center, zoom);
    }
  }

  // ── المملكة كاملة ────────────────────────────────────────────────────────
  void _toggleKSA() {
    setState(() => _ksaMode = !_ksaMode);
    if (_ksaMode) {
      _center = _saCenter;
      _radiusKm = 900;
      _mapCtrl.move(_saCenter, 5);
    } else {
      _radiusKm = 10;
      _updateRadius(10, moveMap: true);
    }
  }

  // ── zoom مناسب للنطاق ─────────────────────────────────────────────────────
  double _zoomFor(double km) {
    if (km < 2)   return 13;
    if (km < 5)   return 12;
    if (km < 12)  return 11;
    if (km < 30)  return 10;
    if (km < 70)  return 9;
    if (km < 150) return 8;
    return 7;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad = widget.topPad;
    final radTxt = _ksaMode
        ? '🇸🇦 المملكة كاملة'
        : '${_radiusKm < 10
            ? _radiusKm.toStringAsFixed(1)
            : _radiusKm.round()} كم';

    return Container(
      padding: EdgeInsets.fromLTRB(0, topPad + 50, 0, 0),
      child: Column(children: [

        // ── رأس اللوحة ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نطاق التعميم',
              style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 17,
                  fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            Row(children: [
              Text('سيصل للمستخدمين داخل ',
                style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 10,
                    color: Colors.white.withOpacity(0.45))),
              Text(radTxt,
                style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 11,
                    fontWeight: FontWeight.w800, color: _gold)),
            ]),
          ]),
        ),

        // ── الخريطة التفاعلية ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                ),
                child: Stack(children: [

                  // ── الخريطة ─────────────────────────────────────────────
                  FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _zoomFor(_radiusKm),
                      // تمكين كل أنواع التفاعل
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all),
                      onMapReady: () =>
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            _recalcScreenPositions),
                      onMapEvent: (_) => _recalcScreenPositions(),
                    ),
                    children: [
                      // طبقة الخريطة الداكنة
                      TileLayer(
                        urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.taameem.app',
                      ),
                      // دائرة النطاق
                      CircleLayer(circles: [
                        CircleMarker(
                          point: _center,
                          radius: _radiusKm * 1000,
                          useRadiusInMeter: true,
                          color: _gold.withOpacity(0.10),
                          borderColor: _gold.withOpacity(0.65),
                          borderStrokeWidth: 2.5,
                        ),
                      ]),
                    ],
                  ),

                  // ── علامة المركز (قابلة للسحب) ──────────────────────────
                  Positioned(
                    left: _centerScreen.dx - 14,
                    top:  _centerScreen.dy - 14,
                    child: GestureDetector(
                      onPanStart: (_) =>
                          setState(() => _draggingCenter = true),
                      onPanUpdate: (d) {
                        final ll = _screenToLatLng(
                            _centerScreen + d.delta);
                        if (ll != null) {
                          setState(() => _center = ll);
                          _recalcScreenPositions();
                        }
                      },
                      onPanEnd: (_) =>
                          setState(() => _draggingCenter = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _draggingCenter
                              ? _gold.withOpacity(0.5)
                              : _gold.withOpacity(0.25),
                          border: Border.all(color: _gold, width: 2),
                          boxShadow: [BoxShadow(
                            color: _gold.withOpacity(0.6),
                            blurRadius: 10)],
                        ),
                        child: Center(
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: _gold, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── علامة الحافة (لتغيير الحجم) ─────────────────────────
                  Positioned(
                    left: _edgeScreen.dx - 9,
                    top:  _edgeScreen.dy - 9,
                    child: GestureDetector(
                      onPanStart: (_) =>
                          setState(() => _draggingEdge = true),
                      onPanUpdate: (d) {
                        final ll = _screenToLatLng(
                            _edgeScreen + d.delta);
                        if (ll != null) {
                          final dist = const Distance()
                              .as(LengthUnit.Kilometer, _center, ll);
                          _updateRadius(dist, moveMap: false);
                          setState(() => _ksaMode = false);
                          _recalcScreenPositions();
                        }
                      },
                      onPanEnd: (_) =>
                          setState(() => _draggingEdge = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _draggingEdge ? _gold : Colors.white,
                          border: Border.all(
                            color: _draggingEdge ? Colors.white : _gold,
                            width: 2.5),
                          boxShadow: [BoxShadow(
                            color: _gold.withOpacity(0.7),
                            blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),

                  // ── تلميح ───────────────────────────────────────────────
                  Positioned(
                    bottom: 8, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _gold.withOpacity(0.3))),
                        child: Text(
                          '⬤ اسحب المركز • ⬤ اسحب الحافة لتغيير الحجم',
                          style: TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 8.5,
                            color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                    ),
                  ),

                ]),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── شريط التحكم ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _gold.withOpacity(0.25), width: 1.5)),
            child: Column(children: [

              // قيمة النطاق
              Text(radTxt,
                style: TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: _gold,
                  shadows: [Shadow(
                    color: _gold.withOpacity(0.4), blurRadius: 12)],
                )),

              const SizedBox(height: 8),

              // السلايدر
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _gold,
                  thumbColor: _gold,
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  overlayColor: _goldGlow,
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _radiusKm.clamp(1, 200),
                  min: 1, max: 200,
                  onChanged: (v) {
                    setState(() => _ksaMode = false);
                    _updateRadius(v, moveMap: true);
                  },
                ),
              ),

              // أزرار سريعة
              Row(children: _quickPicks.map((km) {
                final sel = !_ksaMode &&
                    (_radiusKm - km).abs() < 0.5;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _ksaMode = false);
                      _updateRadius(km, moveMap: true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(left: 5),
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? _gold
                              : _gold.withOpacity(0.3)),
                        color: sel
                            ? _goldBg
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text('${km < 10 ? km.toInt() : km.toInt()} كم',
                          style: TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: sel ? _gold : Colors.white54)),
                      ),
                    ),
                  ),
                );
              }).toList()),

              const SizedBox(height: 8),

              // المملكة كاملة
              GestureDetector(
                onTap: _toggleKSA,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _ksaMode
                          ? Colors.red.shade400
                          : Colors.red.withOpacity(0.4)),
                    color: _ksaMode
                        ? Colors.red.withOpacity(0.18)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text('🇸🇦   المملكة كاملة',
                      style: TextStyle(fontFamily: 'NotoNaskhArabic',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade300)),
                  ),
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 8),

        // ── زر الحفظ ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: GestureDetector(
            onTap: () => widget.onSave(_ksaMode ? 999 : _radiusKm),
            child: Container(
              width: double.infinity, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _gold, width: 1.8)),
              child: Center(
                child: Text('حفظ النطاق',
                  style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: _gold)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── لوحة المدة ────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
//  لوحة مُدة التعميم — عجلات تمرير (من اليمين: ساعات، أيام، أسابيع، سنوات)
// ══════════════════════════════════════════════════════════════════════════════
class _DurPanel extends StatefulWidget {
  final Duration duration;
  final double topPad;
  final ValueChanged<Duration> onSave;
  const _DurPanel({
    required this.duration,
    required this.topPad,
    required this.onSave,
  });
  @override State<_DurPanel> createState() => _DurPanelState();
}

class _DurPanelState extends State<_DurPanel> {
  // ── قيم الأعمدة ───────────────────────────────────────────────────────────
  int _hours = 0, _days = 3, _weeks = 0, _years = 0;

  // ── controllers ───────────────────────────────────────────────────────────
  late FixedExtentScrollController _hCtrl, _dCtrl, _wCtrl, _yCtrl;

  // ── اختصارات سريعة (y, w, d, h) ─────────────────────────────────────────
  static const _quick = [
    {'l': 'ساعة',    'y': 0, 'w': 0, 'd': 0, 'h': 1},
    {'l': 'يوم',     'y': 0, 'w': 0, 'd': 1, 'h': 0},
    {'l': '3 أيام',  'y': 0, 'w': 0, 'd': 3, 'h': 0},
    {'l': 'أسبوع',   'y': 0, 'w': 1, 'd': 0, 'h': 0},
    {'l': 'أسبوعان', 'y': 0, 'w': 2, 'd': 0, 'h': 0},
    {'l': 'شهر',     'y': 0, 'w': 4, 'd': 0, 'h': 0},
    {'l': 'سنة',     'y': 1, 'w': 0, 'd': 0, 'h': 0},
  ];

  @override
  void initState() {
    super.initState();
    // تحليل المدة الأولية
    final d = widget.duration;
    _years  = d.inDays ~/ 365;
    final rem = d.inDays % 365;
    _weeks  = rem ~/ 7;
    _days   = rem % 7;
    _hours  = d.inHours % 24;

    _hCtrl = FixedExtentScrollController(initialItem: _hours);
    _dCtrl = FixedExtentScrollController(initialItem: _days);
    _wCtrl = FixedExtentScrollController(initialItem: _weeks);
    _yCtrl = FixedExtentScrollController(initialItem: _years);
  }

  @override
  void dispose() {
    _hCtrl.dispose(); _dCtrl.dispose();
    _wCtrl.dispose(); _yCtrl.dispose();
    super.dispose();
  }

  // ── الإجمالي ──────────────────────────────────────────────────────────────
  Duration get _total => Duration(
    hours: _hours,
    days:  _days + _weeks * 7 + _years * 365,
  );

  // ── نص ملخص المدة ────────────────────────────────────────────────────────
  String get _label {
    final p = <String>[];
    if (_years > 0)  p.add('$_years ${_years  == 1 ? "سنة"   : "سنوات"}');
    if (_weeks > 0)  p.add('$_weeks ${_weeks  == 1 ? "أسبوع" : "أسابيع"}');
    if (_days  > 0)  p.add('$_days  ${_days   == 1 ? "يوم"   : "أيام"}');
    if (_hours > 0)  p.add('$_hours ${_hours  == 1 ? "ساعة"  : "ساعات"}');
    return p.isEmpty ? 'لم تُحدد' : p.join(' و ');
  }

  // ── ضبط سريع ─────────────────────────────────────────────────────────────
  void _applyQuick(Map q) {
    _years = q['y'] as int; _weeks = q['w'] as int;
    _days  = q['d'] as int; _hours = q['h'] as int;
    _hCtrl.animateToItem(_hours, duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut);
    _dCtrl.animateToItem(_days,  duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut);
    _wCtrl.animateToItem(_weeks, duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut);
    _yCtrl.animateToItem(_years, duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut);
    setState(() {});
  }

  // ── بناء عمود عجلة واحدة ─────────────────────────────────────────────────
  Widget _col({
    required String label,
    required int maxVal,
    required int curVal,
    required FixedExtentScrollController ctrl,
    required ValueChanged<int> onChange,
  }) {
    return Expanded(
      child: Column(children: [
        // عنوان العمود
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(label,
            style: TextStyle(fontFamily: 'NotoNaskhArabic',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.45)),
          ),
        ),
        // العجلة
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 52,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            onSelectedItemChanged: (i) {
              onChange(i);
              setState(() {});
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxVal + 1,
              builder: (_, i) {
                final diff = (i - curVal).abs();
                final isActive = diff == 0;
                final isNear   = diff == 1;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(fontFamily: 'NotoNaskhArabic',
                      fontSize: isActive ? 26 : isNear ? 20 : 16,
                      fontWeight: isActive
                          ? FontWeight.w800
                          : FontWeight.w400,
                      color: isActive
                          ? _gold
                          : isNear
                              ? Colors.white.withOpacity(0.55)
                              : Colors.white.withOpacity(0.2),
                    ),
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, widget.topPad + 50, 0, 0),
      child: Column(children: [

        // ── رأس ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('مُدة التعميم',
              style: TextStyle(fontFamily: 'NotoNaskhArabic',
                fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            Row(children: [
              Text('ينتهي التعميم بعد ',
                style: TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 10, color: Colors.white.withOpacity(0.45))),
              Flexible(
                child: Text(_label,
                  style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 11, fontWeight: FontWeight.w800, color: _gold)),
              ),
            ]),
          ]),
        ),

        // ── عجلات التمرير ──────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _gold.withOpacity(0.3), width: 1.5),
              ),
              child: Stack(children: [

                // الصف بالأعمدة
                Positioned.fill(
                  child: Row(
                    children: [
                      // ساعات (يمين)
                      _col(label: 'ساعات', maxVal: 23,
                        curVal: _hours, ctrl: _hCtrl,
                        onChange: (v) => _hours = v),
                      _Divider(),
                      // أيام
                      _col(label: 'أيام', maxVal: 6,
                        curVal: _days, ctrl: _dCtrl,
                        onChange: (v) => _days = v),
                      _Divider(),
                      // أسابيع
                      _col(label: 'أسابيع', maxVal: 51,
                        curVal: _weeks, ctrl: _wCtrl,
                        onChange: (v) => _weeks = v),
                      _Divider(),
                      // سنوات (يسار)
                      _col(label: 'سنوات', maxVal: 1,
                        curVal: _years, ctrl: _yCtrl,
                        onChange: (v) => _years = v),
                    ],
                  ),
                ),

                // إطار العنصر المحدد
                IgnorePointer(
                  child: Center(
                    child: Container(
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _gold.withOpacity(0.09),
                        border: Border(
                          top: BorderSide(
                            color: _gold.withOpacity(0.4), width: 1.5),
                          bottom: BorderSide(
                            color: _gold.withOpacity(0.4), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),

                // تدرج العلوي
                IgnorePointer(
                  child: Positioned(
                    top: 0, left: 0, right: 0, height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // تدرج السفلي
                IgnorePointer(
                  child: Positioned(
                    bottom: 0, left: 0, right: 0, height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── اختصارات سريعة ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختيار سريع',
                style: TextStyle(fontFamily: 'NotoNaskhArabic',
                  fontSize: 10, color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7, runSpacing: 7,
                children: _quick.map((q) {
                  // هل هو محدد؟
                  final sel = _years == q['y'] && _weeks == q['w'] &&
                      _days  == q['d'] && _hours == q['h'];
                  return GestureDetector(
                    onTap: () => _applyQuick(q),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? _gold
                              : _gold.withOpacity(0.3)),
                        color: sel ? _goldBg : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(q['l'] as String,
                          style: TextStyle(fontFamily: 'NotoNaskhArabic',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? _gold
                                : Colors.white.withOpacity(0.65)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── زر الحفظ ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: GestureDetector(
            onTap: () => widget.onSave(_total),
            child: Container(
              width: double.infinity, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _gold, width: 1.8),
              ),
              child: Center(
                child: Text('حفظ المدة',
                  style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: _gold)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// فاصل رفيع بين الأعمدة
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: 20),
    color: const Color(0xFFC9A84C).withOpacity(0.2),
  );
}

// ── لوحة العنوان ──────────────────────────────────────────────────────────
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
      title: 'عنوان التعميم', topPad: topPad,
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
              const Text('✏️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('عنوان / وصف التعميم',
                style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 12, color: Colors.white.withOpacity(0.55))),
            ]),
          ),
          Container(height: 1, color: _gold.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: ctrl,
              style: TextStyle(fontFamily: 'NotoNaskhArabic',fontSize: 14, color: Colors.white),
              maxLines: 4, minLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب عنوان أو وصف التعميم...',
                hintStyle: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 13, color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── لوحة المرفقات ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
//  لوحة المرفقات — عرض عمودي بنسبة 14:22 مع تكبير عند الضغط
// ══════════════════════════════════════════════════════════════════════════════
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

  // ── تكبير الصورة كاملة ─────────────────────────────────────────────────
  void _showFullscreen(BuildContext context, File f) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          body: Stack(children: [
            // الصورة قابلة للتكبير والتصغير
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
                          Text('فيديو',
                            style: TextStyle(color: Colors.white54,
                                fontSize: 14)),
                        ],
                      ),
                    ),
              ),
            ),
            // زر الإغلاق
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

          // ── رأس اللوحة ───────────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.perm_media_outlined,
                color: _gold, size: 18),
            const SizedBox(width: 8),
            Text('المرفقات',
              style: TextStyle(fontFamily: 'NotoNaskhArabic',
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
                  style: TextStyle(fontFamily: 'NotoNaskhArabic',
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              ),
          ]),

          const SizedBox(height: 10),

          // ── أزرار الإضافة ─────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _actionBtn(
              icon: Icons.camera_alt_outlined,
              label: 'التقط',
              onTap: onCapture)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(
              icon: Icons.photo_library_outlined,
              label: 'المعرض',
              onTap: onGallery)),
          ]),

          const SizedBox(height: 10),

          // ── قائمة المرفقات العمودية بنسبة 14:22 ──────────────────────────
          Expanded(
            child: media.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white24, size: 44),
                    const SizedBox(height: 8),
                    Text('لا توجد مرفقات',
                      style: TextStyle(fontFamily: 'NotoNaskhArabic',
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
                      // نسبة 14:22 (عرض:ارتفاع) — صورة طولية مصغّرة
                      child: AspectRatio(
                        aspectRatio: 14 / 22,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // الصورة
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
                                        Text('فيديو',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11)),
                                      ],
                                    ),
                                  ),
                            ),

                            // حدود ذهبية خفيفة
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

                            // أيقونة التكبير (أسفل اليمين)
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

                            // زر الحذف (أعلى اليمين)
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
        Text(label, style: TextStyle(fontFamily: 'NotoNaskhArabic',
          fontSize: 12, fontWeight: FontWeight.w700, color: _gold)),
      ]),
    ),
  );
}
