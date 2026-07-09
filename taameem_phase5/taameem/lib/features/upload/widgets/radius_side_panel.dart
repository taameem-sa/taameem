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
  bool _loading = true;
  final MapController _mapCtrl = MapController();

  static const List<String> _cities = [
    'ط§ظ„ط±ظٹط§ط¶', 'ط¬ط¯ط©', 'ظ…ظƒط© ط§ظ„ظ…ظƒط±ظ…ط©', 'ط§ظ„ظ…ط¯ظٹظ†ط© ط§ظ„ظ…ظ†ظˆط±ط©',
    'ط§ظ„ط¯ظ…ط§ظ…', 'ط§ظ„ط®ط¨ط±', 'طھط¨ظˆظƒ', 'ط£ط¨ظ‡ط§', 'ط§ظ„ظ‚طµظٹظ…',
    'ط­ط§ط¦ظ„', 'ظ†ط¬ط±ط§ظ†', 'ط¬ظٹط²ط§ظ†', 'ط§ظ„ط¬ظˆظپ',
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
      setState(() { _center = loc; _loading = false; });
      _mapCtrl.move(_center, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ط±ط£ط³ + ط­ظپط¸
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ظ†ط·ط§ظ‚ ط§ظ†طھط´ط§ط± ط§ظ„طھط¹ظ…ظٹظ…',
                    style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppColors.nearBlack)),
                  Text(_allKingdom
                      ? 'ًں“چ ط§ظ„ظ…ظ…ظ„ظƒط© ظƒط§ظ…ظ„ط©'
                      : 'ًں“چ ${_radius.round()} ظƒظ…',
                    style: GoogleFonts.cairo(
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
                  child: Text('ط­ظپط¸',
                    style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: AppColors.glassBorder),

        // ط§ظ„ط®ط±ظٹط·ط© ظ…ط¹ ط§ظ„ط¯ط§ط¦ط±ط©
        SizedBox(
          height: 240,
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.emerald, strokeWidth: 2))
            : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _allKingdom ? 5 : 10,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.taameem.app',
                      ),
                      if (!_allKingdom)
                        CircleLayer(circles: [
                          CircleMarker(
                            point: _center,
                            radius: _radius * 1000,
                            useRadiusInMeter: true,
                            color: AppColors.emerald.withValues(alpha: 0.18),
                            borderColor: AppColors.emerald.withValues(alpha: 0.6),
                            borderStrokeWidth: 2,
                          ),
                        ]),
                      MarkerLayer(markers: [
                        Marker(
                          point: _center,
                          width: 16, height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.emerald,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),

                  // ط´ط±ظٹط· ظ†طµظپ ط§ظ„ظ‚ط·ط±
                  if (!_allKingdom)
                    Positioned(
                      bottom: 8, left: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.glassBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Text('${_radius.round()} ظƒظ…',
                              style: GoogleFonts.cairo(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: AppColors.emerald)),
                            Expanded(
                              child: Slider(
                                value: _radius,
                                min: 1, max: 500,
                                activeColor: AppColors.emerald,
                                inactiveColor: AppColors.glassBorder,
                                onChanged: (v) =>
                                    setState(() => _radius = v),
                              ),
                            ),
                            Text('500 ظƒظ…',
                              style: GoogleFonts.cairo(
                                fontSize: 11, color: AppColors.grey)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        ),

        // ط²ط± ط§ظ„ظ…ظ…ظ„ظƒط© ظƒط§ظ…ظ„ط©
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
                  Text('ًں‡¸ًں‡¦', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('ط§ظ„ظ…ظ…ظ„ظƒط© ظƒط§ظ…ظ„ط©',
                    style: GoogleFonts.cairo(
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

        // ط§ط®طھظٹط§ط± ط§ظ„ظ…ط¯ظٹظ†ط©
        if (!_allKingdom) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.location_city_rounded,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 6),
                Text('ط£ظˆ ط§ط®طھط± ظ…ط¯ظٹظ†ط©:',
                  style: GoogleFonts.cairo(
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
                      style: GoogleFonts.cairo(
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

