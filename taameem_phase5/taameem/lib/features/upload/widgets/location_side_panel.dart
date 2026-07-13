import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';

enum MarkerStyle { typeCircle, imageSquare }

class LocationSidePanel extends StatefulWidget {
  final LatLng? initialLocation;
  final MarkerStyle markerStyle;
  final File? markerImage;
  final String? taameemType;
  final ValueChanged<Map<String, dynamic>> onSave;

  const LocationSidePanel({
    super.key,
    required this.initialLocation,
    required this.markerStyle,
    required this.markerImage,
    required this.taameemType,
    required this.onSave,
  });

  @override
  State<LocationSidePanel> createState() => _LocationSidePanelState();
}

class _LocationSidePanelState extends State<LocationSidePanel> {
  LatLng? _location;
  MarkerStyle _style = MarkerStyle.typeCircle;
  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation ?? LocationService.defaultLocation;
    _style    = widget.markerStyle;
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (widget.initialLocation != null) return;
    final loc = await LocationService.instance.getCurrentOrDefaultLocation();
    if (mounted) {
      setState(() => _location = loc);
      _mapCtrl.move(loc, 14);
    }
  }

  Color get _typeColor {
    switch (widget.taameemType) {
      case 'missingPerson':  return AppColors.missingPerson;
      case 'theft':          return AppColors.theft;
      case 'emergency':      return AppColors.emergency;
      case 'helpRequest':    return AppColors.helpRequest;
      case 'generalWarning': return AppColors.generalWarning;
      default:               return AppColors.emerald;
    }
  }

  String get _typeLabel {
    switch (widget.taameemType) {
      case 'missingPerson':  return 'مفقود';
      case 'theft':          return 'مسروق';
      case 'emergency':      return 'طارئ';
      case 'helpRequest':    return 'استغاثة';
      case 'generalWarning': return 'تحذير';
      default:               return 'تعميم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.88,
      child: Column(
        children: [
        // رأس + حفظ
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const Text('موقع التعميم',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.onSave({
                    'location': _location,
                    'markerStyle': _style,
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

        // تعليمة
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'اضغط على الخريطة لتحديد موقع التعميم',
              style: TextStyle(fontFamily: 'Tajawal',
                fontSize: 12, color: AppColors.forestGreen)),
          ),
        ),

        // الخريطة
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _location ?? LocationService.defaultLocation,
                  initialZoom: 14,
                  onTap: (_, point) =>
                      setState(() => _location = point),
                  interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.taameem.app',
                  ),
                  if (_location != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _location!,
                        width: 56,
                        height: _style == MarkerStyle.imageSquare ? 70 : 58,
                        child: _buildMarkerPreview(),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ),

        // اختيار شكل العلامة
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('شكل العلامة على الخريطة',
                style: TextStyle(fontFamily: 'Tajawal',
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack)),
              const SizedBox(height: 10),
              Row(
                children: [
                  // الشكل 1 — دائرة
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _style = MarkerStyle.typeCircle),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _style == MarkerStyle.typeCircle
                              ? AppColors.emerald.withValues(alpha: 0.1)
                              : AppColors.warmBeige,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _style == MarkerStyle.typeCircle
                                ? AppColors.emerald : AppColors.glassBorder,
                            width: _style == MarkerStyle.typeCircle ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _typeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2)),
                              child: Center(
                                child: Text(_typeLabel,
                                  style: const TextStyle(fontFamily: 'Tajawal',
                                    fontSize: 8, fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                  textAlign: TextAlign.center),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('دائرة',
                              style: TextStyle(fontFamily: 'Tajawal',
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: _style == MarkerStyle.typeCircle
                                    ? AppColors.emerald : AppColors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // الشكل 2 — مربع بصورة
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _style = MarkerStyle.imageSquare),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _style == MarkerStyle.imageSquare
                              ? AppColors.emerald.withValues(alpha: 0.1)
                              : AppColors.warmBeige,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _style == MarkerStyle.imageSquare
                                ? AppColors.emerald : AppColors.glassBorder,
                            width: _style == MarkerStyle.imageSquare ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _typeColor, width: 2),
                                color: AppColors.warmBeige,
                              ),
                              child: widget.markerImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      widget.markerImage!,
                                      fit: BoxFit.cover))
                                : const Icon(Icons.image_rounded,
                                    color: AppColors.grey, size: 20),
                            ),
                            const SizedBox(height: 6),
                            Text('صورة',
                              style: TextStyle(fontFamily: 'Tajawal',
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: _style == MarkerStyle.imageSquare
                                    ? AppColors.emerald : AppColors.grey)),
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
        ],
      ),
    );
  }

  Widget _buildMarkerPreview() {
    if (_style == MarkerStyle.imageSquare && widget.markerImage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _typeColor, width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(widget.markerImage!, fit: BoxFit.cover),
            ),
          ),
          CustomPaint(
            size: const Size(12, 7),
            painter: _TrianglePainter(_typeColor),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _typeColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(
                color: _typeColor.withValues(alpha: 0.4), blurRadius: 10)],
          ),
          child: Center(
            child: Text(_typeLabel,
              style: const TextStyle(fontFamily: 'Tajawal',
                fontSize: 8, fontWeight: FontWeight.w800,
                color: Colors.white),
              textAlign: TextAlign.center),
          ),
        ),
        CustomPaint(
          size: const Size(12, 7),
          painter: _TrianglePainter(_typeColor),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()..moveTo(0,0)..lineTo(size.width,0)
            ..lineTo(size.width/2,size.height)..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}


