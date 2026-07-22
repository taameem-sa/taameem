import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import 'ai_processing_screen.dart';

const _gold = Color(0xFFC9A84C);
const _emerald = Color(0xFF3D8F7E);
const _forest = Color(0xFF235C4E);
const _camBg1 = Color(0xFF0A1A0C);

enum _Panel { cat, loc, rad, dur, ttl, att }

const _cats = [
  {'k': 'missingPerson', 'n': 'فقدان شخص', 'c': Color(0xFFB8A000)},
  {'k': 'foundItem', 'n': 'إيجاد شيء', 'c': Color(0xFF4A9A44)},
  {'k': 'lostItem', 'n': 'فقدان شيء', 'c': Color(0xFFA0287A)},
  {'k': 'theft', 'n': 'سرقة', 'c': Color(0xFFC09010)},
  {'k': 'helpRequest', 'n': 'استغاثة', 'c': Color(0xFFC84C10)},
  {'k': 'humanitarian', 'n': 'إنساني', 'c': Color(0xFF8A7040)},
  {'k': 'emergency', 'n': 'طارئ', 'c': Color(0xFFC03030)},
  {'k': 'generalWarning', 'n': 'تحذير', 'c': Color(0xFFB07820)},
  {'k': 'lostAnimal', 'n': 'حيوان مفقود', 'c': Color(0xFF808010)},
  {'k': 'inquiry', 'n': 'استفسار', 'c': Color(0xFF7A6020)},
];

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  String? _type;
  String _title = '';
  LatLng? _location;
  double _radius = 10;
  Duration _duration = const Duration(days: 3);
  final List<File> _media = [];
  bool _flashOn = false;
  bool _frontCam = false;
  bool _cameraReady = false;
  bool _cameraDenied = false;
  bool _publishing = false;
  _Panel? _panel;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  late AnimationController _bgCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _shutterCtrl;
  late AnimationController _panelCtrl;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _shutterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fetchLocation();
    _initCamera();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _bgCtrl.dispose();
    _glowCtrl.dispose();
    _shutterCtrl.dispose();
    _panelCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() => _location = loc);
    }
  }

  void _openPanel(_Panel panel) {
    setState(() => _panel = panel);
    _panelCtrl.forward(from: 0);
  }

  void _closePanel() {
    _panelCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _panel = null);
      }
    });
  }

  Future<void> _capture() async {
    if (_cameraReady &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      try {
        final shot = await _cameraController!.takePicture();
        if (mounted) {
          setState(() => _media.add(File(shot.path)));
        }
        return;
      } catch (_) {
        _showErr('تعذر التقاط الصورة من الكاميرا');
      }
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showErr('يرجى السماح بالوصول للكاميرا');
      return;
    }

    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (file != null && mounted) {
      setState(() => _media.add(File(file.path)));
    }
  }

  Future<void> _pickGallery() async {
    final files = await _picker.pickMultipleMedia(imageQuality: 90);
    if (mounted) {
      setState(() => _media.addAll(files.map((file) => File(file.path))));
    }
  }

  Future<void> _toggleFlash() async {
    final next = !_flashOn;
    setState(() => _flashOn = next);
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      } catch (_) {
        if (mounted) {
          setState(() => _flashOn = false);
        }
      }
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) {
      _showErr('لا توجد كاميرا أخرى متاحة');
      return;
    }
    setState(() {
      _cameraReady = false;
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    });
    await _initCamera();
    HapticFeedback.lightImpact();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _cameraDenied = true;
          _cameraReady = false;
        });
      }
      return;
    }

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraDenied = true;
            _cameraReady = false;
          });
        }
        return;
      }

      if (_cameraIndex >= _cameras.length) {
        _cameraIndex = 0;
      }

      await _cameraController?.dispose();

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      try {
        await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      } catch (_) {}

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _cameraDenied = false;
        _frontCam = _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraReady = false;
          _cameraDenied = true;
        });
      }
    }
  }

  Future<void> _publish() async {
    if (_media.isEmpty && _title.isEmpty) {
      _showErr('أضف صورة أو عنواناً للتعميم أولاً');
      return;
    }

    final result = await Navigator.push<AiAnalysisResult>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AiProcessingScreen(
          media: _media,
          manualType: _type,
          manualTitle: _title.isNotEmpty ? _title : null,
          location: _location,
          radius: _radius,
          duration: _duration,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _publishing = true);
    try {
      List<String> urls = [];
      if (_media.isNotEmpty) {
        final imageFiles = _media.where(_isImg).toList();
        if (imageFiles.isNotEmpty) {
          final id = '${DateTime.now().millisecondsSinceEpoch}';
          urls = await StorageService.instance.uploadImages(imageFiles, id);
          if (urls.isEmpty) {
            throw Exception('فشل رفع الصور، لم يتم حفظ أي رابط صورة.');
          }
        }
      }

      final now = DateTime.now();
      await FirestoreService.instance.uploadTaameem(
        TaameemModel(
          id: '',
          userId: 'current_user',
          userPhone: '+9665XXXXXXXX',
          type: result.type,
          title: result.title,
          description: result.description,
          latitude: _location?.latitude ?? 24.7136,
          longitude: _location?.longitude ?? 46.6753,
          imageUrls: urls,
          createdAt: now,
          expiresAt: now.add(_duration),
          status: 'active',
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() => _publishing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _SuccessScreen(radius: _radius)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _publishing = false);
      _showErr(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  static bool _isImg(File file) {
    final ext = file.path.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.heic', '.webp'].any(ext.endsWith);
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 15,
            ),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.cairo()),
          ],
        ),
        backgroundColor: const Color(0xFFC03030),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _catLabel {
    if (_type == null) {
      return 'اختياري';
    }
    return _cats.firstWhere(
      (cat) => cat['k'] == _type,
      orElse: () => {'n': 'اختياري'},
    )['n']! as String;
  }

  String get _locLabel => _location != null ? 'محدد ✓' : 'اختياري';

  String get _radLabel => '${_radius.round()} كم';

  String get _durLabel {
    if (_duration.inDays >= 365) {
      return '${_duration.inDays ~/ 365} سنة';
    }
    if (_duration.inDays >= 7) {
      return '${_duration.inDays ~/ 7} أسابيع';
    }
    if (_duration.inDays >= 1) {
      return '${_duration.inDays} أيام';
    }
    return '${_duration.inHours} ساعة';
  }

  String get _ttlLabel {
    if (_title.isEmpty) {
      return 'اختياري';
    }
    return _title.length > 10 ? '${_title.substring(0, 10)}…' : _title;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final top = mq.padding.top;
    final bot = mq.padding.bottom;

    return Scaffold(
      backgroundColor: _camBg1,
      body: Stack(
        children: [
          if (_cameraReady &&
              _cameraController != null &&
              _cameraController!.value.isInitialized &&
              _cameraController!.value.previewSize != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize!.height,
                    height: _cameraController!.value.previewSize!.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            _CamBackground(bg: _bgCtrl, glow: _glowCtrl),
          if (!_cameraReady && _cameraDenied)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      'تعذر فتح الكاميرا',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const _FocusFrame(),
          const _Vignette(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              top: top,
              onClose: () => Navigator.pop(context),
              onPublish: _publish,
            ),
          ),
          Positioned(
            right: 5,
            top: top + 58,
            child: _RightButtons(
              catLabel: _catLabel,
              catActive: _type != null,
              locLabel: _locLabel,
              locActive: _location != null,
              radLabel: _radLabel,
              durLabel: _durLabel,
              ttlLabel: _ttlLabel,
              ttlActive: _title.isNotEmpty,
              onTap: _openPanel,
            ),
          ),
          Positioned(
            left: 10,
            bottom: 120 + bot,
            child: _AttBtn(media: _media, onTap: () => _openPanel(_Panel.att)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              bot: bot,
              flashOn: _flashOn,
              frontCam: _frontCam,
              shutterAnim: _shutterCtrl,
              onFlash: _toggleFlash,
              onFlip: _flipCamera,
              onCapture: _capture,
            ),
          ),
          if (_publishing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        color: _gold,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري نشر التعميم...',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_panel != null) ...[
            GestureDetector(
              onTap: _closePanel,
              child: AnimatedBuilder(
                animation: _panelCtrl,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72 * _panelCtrl.value),
                        Colors.black.withValues(alpha: 0.94 * _panelCtrl.value),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.82,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOut),
                ),
                child: _buildPanel(top),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanel(double top) {
    switch (_panel) {
      case _Panel.cat:
        return _CatPanel(
          top: top,
          selected: _type,
          onSave: (value) {
            setState(() => _type = value);
            _closePanel();
          },
        );
      case _Panel.loc:
        return _LocPanel(
          top: top,
          location: _location,
          onSave: (value) {
            setState(() => _location = value);
            _closePanel();
          },
        );
      case _Panel.rad:
        return _RadPanel(
          top: top,
          radius: _radius,
          center: _location,
          onSave: (value) {
            setState(() => _radius = value);
            _closePanel();
          },
        );
      case _Panel.dur:
        return _DurPanel(
          top: top,
          duration: _duration,
          onSave: (value) {
            setState(() => _duration = value);
            _closePanel();
          },
        );
      case _Panel.ttl:
        return _TtlPanel(
          top: top,
          initial: _title,
          onSave: (value) {
            setState(() => _title = value);
            _closePanel();
          },
        );
      case _Panel.att:
        return _AttPanel(
          top: top,
          media: _media,
          onCapture: () async {
            await _capture();
            setState(() {});
          },
          onGallery: () async {
            await _pickGallery();
            setState(() {});
          },
          onRemove: (index) => setState(() => _media.removeAt(index)),
          onSave: _closePanel,
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}

class _CamBackground extends StatelessWidget {
  final AnimationController bg;
  final AnimationController glow;

  const _CamBackground({required this.bg, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: bg,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.24),
                radius: 1.4,
                colors: [
                  Color.lerp(
                    const Color(0xFF1C3A20),
                    const Color(0xFF142A16),
                    bg.value,
                  )!,
                  const Color(0xFF070F08),
                ],
              ),
            ),
          ),
        ),
        CustomPaint(painter: _GridPainter(), size: Size.infinite),
        AnimatedBuilder(
          animation: glow,
          builder: (_, __) {
            final value = glow.value;
            return Center(
              child: Transform.translate(
                offset: const Offset(0, -80),
                child: Transform.scale(
                  scale: 1 + value * 0.2,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _gold.withValues(alpha: 0.06 * (0.5 + value * 0.5)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.028)
      ..strokeWidth = 1;
    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _FocusFrame extends StatelessWidget {
  const _FocusFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -80),
        child: SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(painter: _FocusPainter()),
        ),
      ),
    );
  }
}

class _FocusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const len = 20.0;
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(len, 0)
        ..lineTo(0, 0)
        ..lineTo(0, len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FocusPainter oldDelegate) => false;
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
            stops: const [0.4, 1],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final double top;
  final VoidCallback onClose;
  final VoidCallback onPublish;

  const _TopBar({
    required this.top,
    required this.onClose,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, top + 12, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'رفع تعميم',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: onPublish,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: Center(
                child: Text(
                  'نشر',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _gold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RightButtons extends StatelessWidget {
  final String catLabel;
  final String locLabel;
  final String radLabel;
  final String durLabel;
  final String ttlLabel;
  final bool catActive;
  final bool locActive;
  final bool ttlActive;
  final ValueChanged<_Panel> onTap;

  const _RightButtons({
    required this.catLabel,
    required this.catActive,
    required this.locLabel,
    required this.locActive,
    required this.radLabel,
    required this.durLabel,
    required this.ttlLabel,
    required this.ttlActive,
    required this.onTap,
  });

  static const _btns = [
    {'p': _Panel.cat, 'lbl': 'فئة التعميم'},
    {'p': _Panel.loc, 'lbl': 'موقع التعميم'},
    {'p': _Panel.rad, 'lbl': 'نطاق التعميم'},
    {'p': _Panel.dur, 'lbl': 'مُدة التعميم'},
    {'p': _Panel.ttl, 'lbl': 'عنوان التعميم'},
  ];

  IconData _icon(_Panel panel) {
    switch (panel) {
      case _Panel.cat:
        return Icons.label_outline_rounded;
      case _Panel.loc:
        return Icons.location_on_outlined;
      case _Panel.rad:
        return Icons.radar_rounded;
      case _Panel.dur:
        return Icons.schedule_rounded;
      case _Panel.ttl:
        return Icons.short_text_rounded;
      case _Panel.att:
        return Icons.attach_file_rounded;
    }
  }

  String _valFor(_Panel panel) {
    switch (panel) {
      case _Panel.cat:
        return catLabel;
      case _Panel.loc:
        return locLabel;
      case _Panel.rad:
        return radLabel;
      case _Panel.dur:
        return durLabel;
      case _Panel.ttl:
        return ttlLabel;
      case _Panel.att:
        return '';
    }
  }

  bool _activeFor(_Panel panel) {
    switch (panel) {
      case _Panel.cat:
        return catActive;
      case _Panel.loc:
        return locActive;
      case _Panel.rad:
        return true;
      case _Panel.dur:
        return true;
      case _Panel.ttl:
        return ttlActive;
      case _Panel.att:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _btns.map((button) {
        final panel = button['p']! as _Panel;
        final active = _activeFor(panel);
        final value = _valFor(panel);
        final label = button['lbl']! as String;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => onTap(panel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: const Cubic(0.34, 1.2, 0.64, 1),
              width: 105,
              height: 45,
              transform: Matrix4.translationValues(active ? -2 : 0, 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: active
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.35),
                border: Border.all(
                  color: active ? _gold : _gold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.15),
                          blurRadius: 0,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: active
                          ? _gold.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Icon(
                      _icon(panel),
                      size: 14,
                      color: active ? _gold : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.45),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          value,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                active ? _gold : Colors.white.withValues(alpha: 0.25),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AttBtn extends StatelessWidget {
  final List<File> media;
  final VoidCallback onTap;

  const _AttBtn({required this.media, required this.onTap});

  static const _bgColors = [
    Color(0xFF1A3520),
    Color(0xFF2A1A35),
    Color(0xFF1A2535),
    Color(0xFF35201A),
    Color(0xFF1A3530),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.82),
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 3,
              right: 3,
              height: 78,
              child: Stack(
                children: List.generate(
                  media.length.clamp(0, 3),
                  (index) => Positioned(
                    top: (4 + index * 4).toDouble(),
                    left: 0,
                    right: 0,
                    height: (70 - index * 4).toDouble(),
                    child: Opacity(
                      opacity: 1 - index * 0.18,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          color: _bgColors[index % _bgColors.length],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (media.isNotEmpty)
              Positioned(
                top: 3,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE53E3E),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      media.length > 9 ? '9+' : '${media.length}',
                      style: const TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 7,
              left: 0,
              right: 0,
              child: Icon(
                Icons.attach_file_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final double bot;
  final bool flashOn;
  final bool frontCam;
  final AnimationController shutterAnim;
  final VoidCallback onFlash;
  final VoidCallback onFlip;
  final VoidCallback onCapture;

  const _BottomControls({
    required this.bot,
    required this.flashOn,
    required this.frontCam,
    required this.shutterAnim,
    required this.onFlash,
    required this.onFlip,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bot + 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CamActionBtn(
                icon:
                    flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                active: flashOn,
                onTap: onFlash,
              ),
              const SizedBox(height: 10),
              _CamActionBtn(
                icon: Icons.flip_camera_ios_rounded,
                active: frontCam,
                onTap: onFlip,
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onCapture,
                child: AnimatedBuilder(
                  animation: shutterAnim,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFE8E8E8)],
                        ),
                      ),
                    ),
                  ),
                  builder: (_, child) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.2 + shutterAnim.value * 0.4,
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child!,
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 46, height: 46),
              SizedBox(height: 10),
              SizedBox(width: 46, height: 46),
            ],
          ),
        ],
      ),
    );
  }
}

class _CamActionBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _CamActionBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? _gold.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.4),
          border: Border.all(
            color: active ? _gold : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? _gold : Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _PanelBase extends StatelessWidget {
  final double top;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onSave;

  const _PanelBase({
    required this.top,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF5050C06),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x18FFFFFF)),
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            child: GestureDetector(
              onTap: onSave,
              child: Container(
                height: 44,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold, width: 1.5),
                  color: _gold.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    'حفظ',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _gold,
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
}

class _CatPanel extends StatefulWidget {
  final double top;
  final String? selected;
  final ValueChanged<String?> onSave;

  const _CatPanel({
    required this.top,
    required this.selected,
    required this.onSave,
  });

  @override
  State<_CatPanel> createState() => _CatPanelState();
}

class _CatPanelState extends State<_CatPanel> {
  String? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return _PanelBase(
      top: widget.top,
      title: 'فئة التعميم',
      subtitle: 'اختر نوع التعميم',
      onSave: () => widget.onSave(_sel),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        children: _cats.map((cat) {
          final key = cat['k']! as String;
          final name = cat['n']! as String;
          final color = cat['c']! as Color;
          final selected = _sel == key;
          return GestureDetector(
            onTap: () => setState(() => _sel = selected ? null : key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected ? color : Colors.white.withValues(alpha: 0.07),
                ),
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
              ),
              child: Row(
                children: [
                  if (selected)
                    Icon(Icons.check_rounded, color: color, size: 13)
                  else
                    const SizedBox(width: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? color : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LocPanel extends StatefulWidget {
  final double top;
  final LatLng? location;
  final ValueChanged<LatLng> onSave;

  const _LocPanel({
    required this.top,
    required this.location,
    required this.onSave,
  });

  @override
  State<_LocPanel> createState() => _LocPanelState();
}

class _LocPanelState extends State<_LocPanel> {
  late LatLng _loc;
  final _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _loc = widget.location ?? const LatLng(24.7136, 46.6753);
  }

  @override
  Widget build(BuildContext context) {
    return _PanelBase(
      top: widget.top,
      title: 'موقع التعميم',
      subtitle: 'حدد الموقع على الخريطة',
      onSave: () => widget.onSave(_loc),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _gold.withValues(alpha: 0.25)),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: _loc,
                          initialZoom: 15,
                          onMapEvent: (_) {
                            final center = _mapCtrl.camera.center;
                            setState(
                              () => _loc = LatLng(center.latitude, center.longitude),
                            );
                          },
                          interactionOptions:
                              const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.taameem.app',
                          ),
                        ],
                      ),
                      const Center(child: _Crosshair()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_loc.latitude.toStringAsFixed(6)}°  ${_loc.longitude.toStringAsFixed(6)}°',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _gold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadPanel extends StatefulWidget {
  final double top;
  final double radius;
  final LatLng? center;
  final ValueChanged<double> onSave;

  const _RadPanel({
    required this.top,
    required this.radius,
    required this.center,
    required this.onSave,
  });

  @override
  State<_RadPanel> createState() => _RadPanelState();
}

class _RadPanelState extends State<_RadPanel> {
  late double _rad;
  late LatLng _center;
  final _mapCtrl = MapController();
  bool _draggingEdge = false;
  bool _ksa = false;

  static const _picks = [2.0, 5.0, 10.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    _rad = widget.radius;
    _center = widget.center ?? const LatLng(24.7136, 46.6753);
  }

  int _zoom(double km) {
    if (km < 2) {
      return 13;
    }
    if (km < 5) {
      return 12;
    }
    if (km < 12) {
      return 11;
    }
    if (km < 30) {
      return 10;
    }
    if (km < 70) {
      return 9;
    }
    if (km < 150) {
      return 8;
    }
    return 7;
  }

  @override
  Widget build(BuildContext context) {
    return _PanelBase(
      top: widget.top,
      title: 'نطاق التعميم',
      subtitle: 'سيصل التعميم لمن داخل هذا النطاق',
      onSave: () => widget.onSave(_ksa ? 900 : _rad),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _gold.withValues(alpha: 0.25)),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: _zoom(_rad).toDouble(),
                          onMapEvent: (_) {
                            final center = _mapCtrl.camera.center;
                            setState(
                              () => _center = LatLng(center.latitude, center.longitude),
                            );
                          },
                          interactionOptions:
                              const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.taameem.app',
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _center,
                                radius: _rad * 1000,
                                useRadiusInMeter: true,
                                color: _gold.withValues(alpha: 0.1),
                                borderColor: _gold.withValues(alpha: 0.65),
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Center(child: _Crosshair()),
                      _EdgeHandle(
                        mapCtrl: _mapCtrl,
                        center: _center,
                        rad: _rad,
                        dragging: _draggingEdge,
                        onDragStart: () => setState(() => _draggingEdge = true),
                        onDragUpdate: (newRad) => setState(() => _rad = newRad),
                        onDragEnd: () => setState(() => _draggingEdge = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_rad.round()} كم',
              style: GoogleFonts.cairo(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _gold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                thumbColor: _gold,
                activeTrackColor: _gold,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                overlayColor: _gold.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: _rad.clamp(1, 200),
                min: 1,
                max: 200,
                onChanged: (value) {
                  setState(() {
                    _rad = value;
                    _ksa = false;
                  });
                  try {
                    _mapCtrl.move(_center, _zoom(value).toDouble());
                  } catch (_) {}
                },
              ),
            ),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _picks.map((value) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rad = value;
                      _ksa = false;
                    });
                    try {
                      _mapCtrl.move(_center, _zoom(value).toDouble());
                    } catch (_) {}
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _rad == value && !_ksa ? _gold : _gold.withValues(alpha: 0.25),
                      ),
                      color: _rad == value && !_ksa
                          ? _gold.withValues(alpha: 0.18)
                          : _gold.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      '${value.round()} كم',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _rad == value && !_ksa
                            ? _gold
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _ksa = true;
                  _rad = 900;
                  _center = const LatLng(23.8859, 45.0792);
                });
                try {
                  _mapCtrl.move(const LatLng(23.8859, 45.0792), 5);
                } catch (_) {}
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _ksa
                        ? const Color(0xFFFC8181)
                        : const Color(0xFFFC8181).withValues(alpha: 0.4),
                  ),
                  color: _ksa
                      ? const Color(0xFFFC8181).withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '🇸🇦  المملكة كاملة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFC8181),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EdgeHandle extends StatelessWidget {
  final MapController mapCtrl;
  final LatLng center;
  final double rad;
  final bool dragging;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final ValueChanged<double> onDragUpdate;

  const _EdgeHandle({
    required this.mapCtrl,
    required this.center,
    required this.rad,
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final dLng = (rad / 111.32) /
          (0.0174533 * center.latitude).abs().clamp(0.01, 1.0);
      final edgePoint = mapCtrl.camera.latLngToScreenPoint(
        LatLng(center.latitude, center.longitude + dLng),
      );
      return Positioned(
        left: edgePoint.x - 10,
        top: edgePoint.y - 10,
        child: GestureDetector(
          onPanStart: (_) => onDragStart(),
          onPanUpdate: (details) {
            final delta = details.delta.dx - details.delta.dy;
            final nextRadius = rad + (delta * 0.12);
            onDragUpdate(nextRadius.clamp(0.5, 500));
          },
          onPanEnd: (_) => onDragEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dragging ? Colors.white : _gold,
              border: Border.all(
                color: dragging ? _gold : Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(color: _gold.withValues(alpha: 0.8), blurRadius: 10),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 44, height: 1.5, color: _gold),
          Container(width: 1.5, height: 44, color: _gold),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold,
              boxShadow: [
                BoxShadow(color: _gold.withValues(alpha: 0.9), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurPanel extends StatefulWidget {
  final double top;
  final Duration duration;
  final ValueChanged<Duration> onSave;

  const _DurPanel({
    required this.top,
    required this.duration,
    required this.onSave,
  });

  @override
  State<_DurPanel> createState() => _DurPanelState();
}

class _DurPanelState extends State<_DurPanel> {
  int _h = 0;
  int _d = 3;
  int _w = 0;
  int _y = 0;
  late final Map<String, FixedExtentScrollController> _ctrl;

  static const _durPicks = [
    {'l': 'ساعة', 'h': 1, 'd': 0, 'w': 0, 'y': 0},
    {'l': 'يوم', 'h': 0, 'd': 1, 'w': 0, 'y': 0},
    {'l': '3 أيام', 'h': 0, 'd': 3, 'w': 0, 'y': 0},
    {'l': 'أسبوع', 'h': 0, 'd': 0, 'w': 1, 'y': 0},
    {'l': 'شهر', 'h': 0, 'd': 0, 'w': 4, 'y': 0},
    {'l': 'سنة', 'h': 0, 'd': 0, 'w': 0, 'y': 1},
  ];

  @override
  void initState() {
    super.initState();
    final duration = widget.duration;
    if (duration.inDays >= 365) {
      _y = duration.inDays ~/ 365;
    } else if (duration.inDays >= 7) {
      _w = duration.inDays ~/ 7;
    } else if (duration.inDays >= 1) {
      _d = duration.inDays;
    } else {
      _h = duration.inHours;
    }
    _ctrl = {
      'h': FixedExtentScrollController(initialItem: _h),
      'd': FixedExtentScrollController(initialItem: _d),
      'w': FixedExtentScrollController(initialItem: _w),
      'y': FixedExtentScrollController(initialItem: _y),
    };
  }

  @override
  void dispose() {
    for (final controller in _ctrl.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Duration get _result {
    final total = _y * 365 + _w * 7 + _d;
    if (total > 0) {
      return Duration(days: total);
    }
    return Duration(hours: _h);
  }

  void _setQuick(int h, int d, int w, int y) {
    setState(() {
      _h = h;
      _d = d;
      _w = w;
      _y = y;
    });
    _ctrl['h']!.jumpToItem(h);
    _ctrl['d']!.jumpToItem(d);
    _ctrl['w']!.jumpToItem(w);
    _ctrl['y']!.jumpToItem(y);
  }

  Widget _wheel(String key, int max, int val, ValueChanged<int> onChanged) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: _ctrl[key]!,
        itemExtent: 48,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (_, index) => Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: GoogleFonts.cairo(
                fontSize: index == val ? 26 : 20,
                fontWeight: index == val ? FontWeight.w800 : FontWeight.w500,
                color: index == val
                    ? _gold
                    : Colors.white.withValues(
                        alpha: index == val - 1 || index == val + 1 ? 0.5 : 0.2,
                      ),
              ),
            ),
          ),
          childCount: max + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PanelBase(
      top: widget.top,
      title: 'مُدة التعميم',
      subtitle: 'ينتهي التعميم تلقائياً بعد هذه المدة',
      onSave: () => widget.onSave(_result),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withValues(alpha: 0.15)),
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _gold.withValues(alpha: 0.07),
                        border: Border(
                          top: BorderSide(color: _gold.withValues(alpha: 0.25)),
                          bottom: BorderSide(color: _gold.withValues(alpha: 0.25)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 72,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0A1A0C), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 72,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF0A1A0C), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _wheel('h', 23, _h, (value) => setState(() => _h = value)),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      _wheel('d', 6, _d, (value) => setState(() => _d = value)),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      _wheel('w', 51, _w, (value) => setState(() => _w = value)),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      _wheel('y', 1, _y, (value) => setState(() => _y = value)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  for (final label in ['ساعات', 'أيام', 'أسابيع', 'سنوات'])
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _durPicks.map((pick) {
                return GestureDetector(
                  onTap: () => _setQuick(
                    pick['h']! as int,
                    pick['d']! as int,
                    pick['w']! as int,
                    pick['y']! as int,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _gold.withValues(alpha: 0.25)),
                      color: _gold.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      pick['l']! as String,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TtlPanel extends StatefulWidget {
  final double top;
  final String initial;
  final ValueChanged<String> onSave;

  const _TtlPanel({
    required this.top,
    required this.initial,
    required this.onSave,
  });

  @override
  State<_TtlPanel> createState() => _TtlPanelState();
}

class _TtlPanelState extends State<_TtlPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelBase(
      top: widget.top,
      title: 'عنوان التعميم',
      subtitle: 'اكتب عنواناً أو وصفاً (اختياري)',
      onSave: () => widget.onSave(_controller.text.trim()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  border: Border(
                    bottom: BorderSide(color: _gold.withValues(alpha: 0.12)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.short_text_rounded, color: _gold, size: 16),
                    const SizedBox(width: 7),
                    Text(
                      'عنوان / وصف التعميم',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.white),
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب عنواناً أو وصفاً...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttPanel extends StatelessWidget {
  final double top;
  final List<File> media;
  final Future<void> Function() onCapture;
  final Future<void> Function() onGallery;
  final ValueChanged<int> onRemove;
  final VoidCallback onSave;

  const _AttPanel({
    required this.top,
    required this.media,
    required this.onCapture,
    required this.onGallery,
    required this.onRemove,
    required this.onSave,
  });

  static bool _isImg(File file) {
    final ext = file.path.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.heic', '.webp'].any(ext.endsWith);
  }

  @override
  Widget build(BuildContext context) {
    return _PanelBase(
      top: top,
      title: 'المرفقات',
      subtitle: media.isEmpty ? 'أضف صوراً أو فيديو' : '${media.length} مرفق',
      onSave: onSave,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          children: [
            Expanded(
              child: media.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: Colors.white.withValues(alpha: 0.25),
                            size: 52,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد مرفقات',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: media.length,
                      itemBuilder: (_, index) => Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _isImg(media[index])
                                  ? Image.file(media[index], fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.play_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => onRemove(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53E3E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _gold, width: 1.5),
                        color: _gold.withValues(alpha: 0.06),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            color: _gold,
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'التقط',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: onGallery,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _gold, width: 1.5),
                        color: _gold.withValues(alpha: 0.06),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.photo_library_rounded,
                            color: _gold,
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'المعرض',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final double radius;

  const _SuccessScreen({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050C06),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, value, __) => Transform.scale(
                    scale: value,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_emerald, _forest],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _emerald.withValues(alpha: 0.5),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'تم النشر!',
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'تعميمك الآن على الخريطة\nوسيصل لمن هم في نطاق ${radius.round()} كم',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white60,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_emerald, _forest],
                      ),
                    ),
                    child: Text(
                      'العودة للخريطة',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
