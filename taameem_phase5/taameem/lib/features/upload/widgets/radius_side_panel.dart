import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';

class RadiusSidePanel extends StatefulWidget {
  final double radiusKm;
  final String? selectedCity;
  final ValueChanged<Map<String, dynamic>> onSave;

  const RadiusSidePanel({
    super.key,
    required this.radiusKm,
    required this.selectedCity,
    required this.onSave,
  });

  @override
  State<RadiusSidePanel> createState() => _RadiusSidePanelState();
}

class _RadiusSidePanelState extends State<RadiusSidePanel> {
  late double _radius;
  late LatLng _center;
  String? _city;
  bool _allKingdom = false;
  final MapController _mapCtrl = MapController();

  static const List<String> _cities = [
    'الرياض', 'جدة', 'مكة المكرمة', 'المدينة المنورة',
    'الدمام', 'الخبر', 'تبوك', 'أبها', 'القصيم',
    'حائل', 'نجران', 'جيزان', 'الجوف',
  ];

  @override
  void initState() {
    super.initState();
    _radius = widget.radiusKm;
    _city   = widget.selectedCity;
    _center = LocationService.defaultLocation;
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await LocationService.instance.getCurrentOrDefaultLocation();
    if (mounted) {
      setState(() { _center = loc; });
      _mapCtrl.move(_center, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // رأس + حفظ
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('نطاق انتشار التعميم',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack)),
                  Text(_allKingdom
                      ? '📍 المملكة كاملة'
                      : '📍 ${_radius.round()} كم',
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontSize: 12, color: AppColors.emerald)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.onSave({
                    'radius': _radius,
                    'city': _city,
                    'allKingdom': _allKingdom,
                    'center': _center,
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.forestGreen]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('حفظ',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: AppColors.glassBorder),

        // الخريطة مع الدائرة
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // خلفية الخريطة المبسطة
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _MapGridPainter(),
                    ),
                  ),
                  // الدائرة
                  if (!_allKingdom)
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: (_radius / 500 * 160 + 40).clamp(40, 160),
                        height: (_radius / 500 * 160 + 40).clamp(40, 160),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  // نقطة المركز
                  Center(
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.4),
                          blurRadius: 8)],
                      ),
                    ),
                  ),
                  // نص المملكة
                  if (_allKingdom)
                    Center(
                      child: Text(
                        '🇸🇦\nالمملكة كاملة',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: AppColors.error, height: 1.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // زر المملكة كاملة
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: GestureDetector(
            onTap: () => setState(() => _allKingdom = !_allKingdom),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: _allKingdom
                    ? AppColors.error
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇸🇦', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('المملكة كاملة',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: _allKingdom
                          ? Colors.white : AppColors.error)),
                  if (_allKingdom) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ),

        // اختيار المدينة
        if (!_allKingdom) ...[
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.location_city_rounded,
                    size: 14, color: AppColors.grey),
                SizedBox(width: 6),
                Text('أو اختر مدينة:',
                  style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _cities.length,
              itemBuilder: (_, i) {
                final c = _cities[i];
                final isSelected = _city == c;
                return GestureDetector(
                  onTap: () => setState(() =>
                    _city = isSelected ? null : c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.emerald
                          : AppColors.warmBeige,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.emerald : AppColors.glassBorder),
                    ),
                    child: Text(c,
                      style: TextStyle(fontFamily: 'Tajawal',
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white : AppColors.forestGreen)),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // خطوط الطريق
    final roadPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.15)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}


