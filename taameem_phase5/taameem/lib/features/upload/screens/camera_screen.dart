import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import 'compose_taameem_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<File>  _collected = [];
  CameraController? _cameraCtrl;

  bool _isRecording = false;
  bool _cameraReady = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initLiveCamera();
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLiveCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final selected = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );

      final ctrl = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }

      setState(() {
        _cameraCtrl = ctrl;
        _cameraReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraReady = false);
    }
  }

  // â”€â”€ ط§ظ„طھظ‚ط§ط· طµظˆط±ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _capturePhoto() async {
    try {
      final ctrl = _cameraCtrl;
      if (ctrl == null || !ctrl.value.isInitialized) {
        final picked = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 1920,
        );
        if (picked != null && mounted) {
          setState(() => _collected.add(File(picked.path)));
          _showAddedFeedback();
        }
        return;
      }

      final shot = await ctrl.takePicture();
      if (!mounted) return;
      setState(() => _collected.add(File(shot.path)));
      _showAddedFeedback();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('طھط¹ط°ط± ط§ظ„طھظ‚ط§ط· ط§ظ„طµظˆط±ط©', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // â”€â”€ ط¨ط¯ط، طھط³ط¬ظٹظ„ ظپظٹط¯ظٹظˆ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _startVideoRecording() async {
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized || _isRecording) return;

    try {
      await ctrl.startVideoRecording();
    } catch (_) {
      return;
    }

    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);
  }

  // â”€â”€ ط¥ظٹظ‚ط§ظپ طھط³ط¬ظٹظ„ ظپظٹط¯ظٹظˆ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;

    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      if (mounted) setState(() => _isRecording = false);
      _pulseCtrl.stop();
      return;
    }

    XFile? video;
    try {
      video = await ctrl.stopVideoRecording();
    } catch (_) {
      video = null;
    }

    _pulseCtrl.stop();
    if (mounted) {
      setState(() => _isRecording = false);
      if (video != null) {
        final recordedPath = video.path;
        if (recordedPath.isNotEmpty) {
          setState(() => _collected.add(File(recordedPath)));
          _showAddedFeedback();
        }
      }
    }
  }

  // â”€â”€ ط§ط®طھظٹط§ط± طµظˆط±/ظپظٹط¯ظٹظˆ ظ…ظ† ط§ظ„ظ‡ط§طھظپ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickMediaFromDevice() async {
    final files = await _picker.pickMultipleMedia(
      imageQuality: 90,
    );
    if (files.isNotEmpty && mounted) {
      setState(() {
        for (final f in files) {
          _collected.add(File(f.path));
        }
      });
      _showAddedFeedback();
    }
  }

  // â”€â”€ ط§ط®طھظٹط§ط± ظ…ظ„ظپط§طھ ط¹ط§ظ…ط© (PDF/Docs...) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickDocumentsFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ],
    );

    if (result == null || !mounted) return;
    setState(() {
      for (final item in result.files) {
        if (item.path != null) {
          _collected.add(File(item.path!));
        }
      }
    });
    _showAddedFeedback();
  }

  Future<void> _showAttachSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.creamWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.emerald),
                title: Text(
                  'طµظˆط± ظˆظپظٹط¯ظٹظˆ ظ…ظ† ط§ظ„ظ‡ط§طھظپ',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMediaFromDevice();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_rounded,
                    color: AppColors.forestGreen),
                title: Text(
                  'ظ…ظ„ظپط§طھ (PDF / ظ…ط³طھظ†ط¯ط§طھ)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocumentsFromDevice();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddedFeedback() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'âœ… ${_collected.length} ظˆط³ط§ط¦ط· ظ…ط¶ط§ظپط©',
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.emerald,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 80),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _goToCompose() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            ComposeTaameemScreen(mediaFiles: _collected),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // â”€â”€ ط®ظ„ظپظٹط© ط§ظ„ظƒط§ظ…ظٹط±ط§ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned.fill(
            child: _cameraReady && _cameraCtrl != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraCtrl!.value.previewSize?.height ?? 1080,
                      height: _cameraCtrl!.value.previewSize?.width ?? 1920,
                      child: CameraPreview(_cameraCtrl!),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          AppColors.nearBlack.withValues(alpha: 0.9),
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              color: Colors.white.withValues(alpha: 0.15),
                              size: 120),
                          const SizedBox(height: 16),
                          Text(
                            'ظٹطھظ… طھظ‡ظٹط¦ط© ط§ظ„ظƒط§ظ…ظٹط±ط§...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.3),
                                height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // â”€â”€ ط±ط£ط³ ط§ظ„ط´ط§ط´ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16, right: 16,
            child: Row(
              children: [
                // ط²ط± ط§ظ„ط¥ط؛ظ„ط§ظ‚
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                // ط¹ظ†ظˆط§ظ†
                Text('ط±ظپط¹ طھط¹ظ…ظٹظ…',
                  style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ).animate().fadeIn(duration: 400.ms),
          ),

          // â”€â”€ ظ…ط¹ط±ط¶ ظ…طµط؛ط± ظ„ظ„ظˆط³ط§ط¦ط· ط§ظ„ظ…ط¬ظ…ظ‘ط¹ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_collected.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 16,
              child: SizedBox(
                width: 66,
                height: _collected.length > 3
                    ? 220 : (_collected.length * 70.0),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _collected.length.clamp(0, 3),
                  itemBuilder: (_, i) {
                    final isImage = _isImage(_collected[i]);
                    final isVideo = _isVideo(_collected[i]);
                    return Container(
                      width: 60, height: 65,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isImage
                          ? Image.file(_collected[i],
                              fit: BoxFit.cover)
                          : Container(
                              color: AppColors.nearBlack,
                              child: Icon(
                                  isVideo
                                      ? Icons.videocam_rounded
                                      : Icons.description_rounded,
                                  color: Colors.white, size: 24)),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

          // â”€â”€ ط´ط±ظٹط· ط§ظ„ط£ط¯ظˆط§طھ ط§ظ„ط³ظپظ„ظٹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24,
                  MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  // ط²ط± ط§ظ„ظ…ط¹ط±ط¶ (ظ…ط´ط¨ظƒ)
                  GestureDetector(
                    onTap: _showAttachSheet,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.attach_file_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text('ظ…ط±ظپظ‚ط§طھ',
                          style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  // ط²ط± ط§ظ„طھطµظˆظٹط± ط§ظ„ط±ط¦ظٹط³ظٹ
                  GestureDetector(
                    onTap: _capturePhoto,
                    onLongPressStart: (_) => _startVideoRecording(),
                    onLongPressEnd: (_) => _stopVideoRecording(),
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 78, height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecording
                                ? AppColors.error
                                : Colors.white,
                            width: 3.5,
                          ),
                          boxShadow: _isRecording ? [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 
                                  0.3 + 0.3 * _pulseCtrl.value),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ] : [],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording
                                ? AppColors.error
                                : Colors.white,
                          ),
                          child: _isRecording
                              ? const Icon(Icons.stop_rounded,
                                  color: Colors.white, size: 30)
                              : null,
                        ),
                      ),
                    ),
                  ).animate().scale(
                    begin: const Offset(0.7, 0.7),
                    duration: 500.ms,
                    curve: Curves.easeOutBack),

                  // ط²ط± ط§ظ„ط§ظ†طھظ‚ط§ظ„ ظ„ظ„ظ…ط­ط±ط± (ظٹط¸ظ‡ط± ظپظ‚ط· ط¥ط°ط§ ظٹظˆط¬ط¯ ظˆط³ط§ط¦ط·)
                  AnimatedOpacity(
                    opacity: _collected.isEmpty ? 0.3 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _collected.isEmpty ? null : _goToCompose,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              if (_collected.isNotEmpty)
                                Positioned(
                                  top: -2, right: -2,
                                  child: Container(
                                    width: 20, height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black,
                                          width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_collected.length}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('ط§ظ„طھط§ظ„ظٹ',
                            style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                ],
              ),
            ),
          ),

          // â”€â”€ ظ…ط¤ط´ط± ط§ظ„طھط³ط¬ظٹظ„ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeOut(duration: 600.ms),
                      const SizedBox(width: 8),
                      Text('ط¬ط§ط±ظٹ ط§ظ„طھط³ط¬ظٹظ„...',
                        style: GoogleFonts.cairo(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          // â”€â”€ ط²ط± ط§ظ„ط§ظ†طھظ‚ط§ظ„ ط§ظ„ط³ط±ظٹط¹ (ط¹ط§ط¦ظ…) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (_collected.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 120,
              left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _goToCompose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          blurRadius: 16, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_collected.length}',
                          style: GoogleFonts.cairo(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                        const SizedBox(width: 8),
                        Text('طھط¹ط¯ظٹظ„ ظˆط¥ط±ط³ط§ظ„',
                          style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ).animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.3, end: 0),
            ),
        ],
      ),
    );
  }

  bool _isImage(File f) {
    final ext = f.path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') ||
        ext.endsWith('.png') || ext.endsWith('.heic') ||
        ext.endsWith('.webp');
  }

  bool _isVideo(File f) {
    final ext = f.path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm');
  }
}

