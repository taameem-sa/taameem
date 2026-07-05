import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/matching_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';
import 'map_location_picker.dart';
import '../widgets/category_selector_widget.dart';
import '../widgets/image_picker_widget.dart';

class UploadTaameemScreen extends StatefulWidget {
  const UploadTaameemScreen({super.key});

  @override
  State<UploadTaameemScreen> createState() => _UploadTaameemScreenState();
}

class _UploadTaameemScreenState extends State<UploadTaameemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedType;
  List<File> _images = [];
  LatLng? _location;
  bool _isLoading = false;
  String? _locationText;

  // مراحل العرض
  int _currentStep = 0; // 0: النوع | 1: التفاصيل | 2: الموقع | 3: المراجعة

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.instance.getPreciseLocation();
    if (mounted) {
      setState(() {
        _location = loc;
        _locationText = loc != null
            ? 'تم تحديد موقعك تلقائياً'
            : 'تعذر تحديد موقعك تلقائياً. استخدم التحديد اليدوي على الخريطة.';
      });
    }
  }

  Future<void> _pickLocationManually() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLocation: _location ?? LocationService.defaultLocation,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _location = result;
        _locationText =
            'تم تحديد الموقع يدوياً (${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)})';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= 4) return;
    final images = await StorageService.instance.pickMultipleImages();
    setState(() => _images = [..._images, ...images].take(4).toList());
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= 4) return;
    final image = await StorageService.instance.pickImage(fromCamera: true);
    if (image != null) setState(() => _images.add(image));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedType != null;
      case 1:
        return _titleController.text.trim().isNotEmpty;
      case 2:
        return _location != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_canProceed && _currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitTaameem() async {
    if (!_canProceed) return;
    setState(() => _isLoading = true);

    try {
      final userId = 'temp_user'; // TODO: Firebase Auth UID
      final userPhone = '+9665XXXXXXXX'; // TODO: Firebase Auth Phone

      // رفع الصور أولاً
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls = await StorageService.instance.uploadImages(_images, tempId);
      }

      // حساب تاريخ الانتهاء
      final days = AppConstants.decayDays[_selectedType!] ?? 3;
      final now = DateTime.now();
      final expiry = now.add(Duration(days: days));

      // إنشاء نموذج التعميم
      final taameem = TaameemModel(
        id: '',
        userId: userId,
        userPhone: userPhone,
        type: _selectedType!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        imageUrls: imageUrls,
        createdAt: now,
        expiresAt: expiry,
        status: 'active',
      );

      // رفع في Firestore
      final uploadedId = await FirestoreService.instance.uploadTaameem(taameem);

      final publishedTaameem = TaameemModel(
        id: uploadedId,
        userId: taameem.userId,
        userPhone: taameem.userPhone,
        type: taameem.type,
        title: taameem.title,
        description: taameem.description,
        latitude: taameem.latitude,
        longitude: taameem.longitude,
        imageUrls: taameem.imageUrls,
        createdAt: taameem.createdAt,
        expiresAt: taameem.expiresAt,
        status: taameem.status,
        city: taameem.city,
        neighborhood: taameem.neighborhood,
        viewCount: taameem.viewCount,
      );

      final matches =
          await MatchingService.instance.findMatches(publishedTaameem);
      for (final match in matches.take(5)) {
        await MatchingService.instance.saveMatch(uploadedId, match.id);
      }

      if (!mounted) return;

      // نجاح
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          showGoldLine: true,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.emerald,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تم نشر التعميم بنجاح',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيظهر تعميمك على الخريطة الآن\nوسيُرسل إشعار للمستخدمين القريبين',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.forestGreen,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.forestGreen],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'رائع، عودة للخريطة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStep(),
                ),
              ),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── رأس الصفحة ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final titles = [
      'اختر نوع التعميم',
      'التفاصيل',
      'الموقع والصور',
      'مراجعة ونشر'
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevStep,
            child: Container(
              padding: const EdgeInsets.all(8),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titles[_currentStep],
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.nearBlack,
              ),
            ),
          ),
          Text(
            '${_currentStep + 1}/4',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── شريط التقدم ───────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(left: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.emerald : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── محتوى الخطوة الحالية ──────────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepType();
      case 1:
        return _buildStepDetails();
      case 2:
        return _buildStepLocationAndMedia();
      case 3:
        return _buildStepReview();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── الخطوة 1: النوع ───────────────────────────────────────────────────────
  Widget _buildStepType() {
    return GlassCard(
      showGoldLine: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ما طبيعة التعميم الذي تريد نشره؟',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 16),
          CategorySelectorWidget(
            selectedType: _selectedType,
            onSelected: (type) => setState(() => _selectedType = type),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── الخطوة 2: التفاصيل ────────────────────────────────────────────────────
  Widget _buildStepDetails() {
    return GlassCard(
      showGoldLine: true,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('العنوان *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style:
                  GoogleFonts.cairo(fontSize: 15, color: AppColors.nearBlack),
              decoration: InputDecoration(
                hintText: 'مثال: سيارة كامري بيضاء مسروقة',
                hintStyle:
                    GoogleFonts.cairo(color: AppColors.grey, fontSize: 13),
                filled: true,
                fillColor: AppColors.warmBeige,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.emerald, width: 1.5),
                ),
              ),
              maxLength: 80,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _fieldLabel('الوصف التفصيلي'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              style:
                  GoogleFonts.cairo(fontSize: 14, color: AppColors.nearBlack),
              decoration: InputDecoration(
                hintText:
                    'أضف أي تفاصيل مفيدة: اللون، العلامات المميزة، آخر مكان...',
                hintStyle:
                    GoogleFonts.cairo(color: AppColors.grey, fontSize: 12),
                filled: true,
                fillColor: AppColors.warmBeige,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.emerald, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── الخطوة 3: الموقع والصور ───────────────────────────────────────────────
  Widget _buildStepLocationAndMedia() {
    return Column(
      children: [
        GlassCard(
          showGoldLine: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('الموقع الجغرافي'),
              const SizedBox(height: 12),
              Column(
                children: [
                  // زر الموقع التلقائي
                  GestureDetector(
                    onTap: _fetchLocation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _location != null
                            ? AppColors.emerald.withOpacity(0.08)
                            : AppColors.warmBeige,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _location != null
                              ? AppColors.emerald.withOpacity(0.3)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _location != null
                                ? Icons.location_on_rounded
                                : Icons.location_off_rounded,
                            color: _location != null
                                ? AppColors.emerald
                                : AppColors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationText ?? 'اضغط لتحديد موقعك تلقائياً',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: _location != null
                                    ? AppColors.forestGreen
                                    : AppColors.grey,
                              ),
                            ),
                          ),
                          if (_location != null)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.emerald, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // زر التحديد اليدوي على الخريطة
                  GestureDetector(
                    onTap: _pickLocationManually,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warmBeige,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                            const Icon(Icons.map_rounded,
                              color: AppColors.emerald, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'تحديد الموقع يدوياً على الخريطة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('الصور (اختياري — حتى 4 صور)'),
              const SizedBox(height: 12),
              ImagePickerWidget(
                images: _images,
                onPickFromGallery: _pickFromGallery,
                onPickFromCamera: _pickFromCamera,
                onRemove: _removeImage,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── الخطوة 4: المراجعة ────────────────────────────────────────────────────
  Widget _buildStepReview() {
    final typeColor =
        _selectedType != null ? _colorForType(_selectedType!) : AppColors.grey;

    return GlassCard(
      showGoldLine: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة التعميم قبل النشر',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 20),

          // نوع التعميم
          _ReviewRow(
            label: 'النوع',
            value: AppConstants.categoryNames[_selectedType] ?? '',
            color: typeColor,
          ),

          _ReviewRow(
            label: 'العنوان',
            value: _titleController.text.trim(),
          ),

          if (_descController.text.isNotEmpty)
            _ReviewRow(
              label: 'الوصف',
              value: _descController.text.trim(),
            ),

          _ReviewRow(
            label: 'الموقع',
            value: _locationText ?? 'غير محدد',
            icon: Icons.location_on_rounded,
          ),

          _ReviewRow(
            label: 'الصور',
            value: '${_images.length} صورة',
            icon: Icons.photo_rounded,
          ),

          _ReviewRow(
            label: 'مدة النشر',
            value: '${AppConstants.decayDays[_selectedType] ?? 3} أيام',
            icon: Icons.timer_outlined,
          ),

          const SizedBox(height: 20),

          // تنبيه
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بعد النشر ستتلقى إشعاراً إذا وجد تطابق مع تعميمات أخرى',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.forestGreen,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── أزرار الأسفل ──────────────────────────────────────────────────────────
  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 3;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: GestureDetector(
            onTap:
                _isLoading ? null : (isLastStep ? _submitTaameem : _nextStep),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _canProceed
                      ? [AppColors.emerald, AppColors.forestGreen]
                      : [AppColors.grey, AppColors.grey],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canProceed
                    ? [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isLastStep ? 'نشر التعميم الآن' : 'التالي',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.forestGreen,
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'missingPerson':
        return AppColors.missingPerson;
      case 'foundItem':
        return AppColors.foundItem;
      case 'lostItem':
        return AppColors.lostItem;
      case 'theft':
        return AppColors.theft;
      case 'helpRequest':
        return AppColors.helpRequest;
      case 'humanitarian':
        return AppColors.humanitarian;
      case 'emergency':
        return AppColors.emergency;
      case 'generalWarning':
        return AppColors.generalWarning;
      case 'lostAnimal':
        return AppColors.lostAnimal;
      case 'inquiry':
        return AppColors.inquiry;
      default:
        return AppColors.grey;
    }
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: color ?? AppColors.forestGreen),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color ?? AppColors.nearBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
