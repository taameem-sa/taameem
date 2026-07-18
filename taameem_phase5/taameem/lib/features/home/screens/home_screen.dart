import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:taameem/core/constants/app_colors.dart';
import 'package:taameem/core/models/taameem_model.dart';
import 'package:taameem/core/services/firestore_service.dart';
import 'package:taameem/core/services/location_service.dart';
import 'package:taameem/core/widgets/taameem_bottom_nav.dart';
import 'package:taameem/features/search/screens/search_screen.dart';
import 'package:taameem/features/ai_chat/screens/ai_chat_screen.dart';
import 'package:taameem/features/notifications/screens/notifications_screen.dart';
import 'package:taameem/features/profile/screens/profile_screen.dart';
import 'package:taameem/features/home/widgets/map_marker_widget.dart';
import 'package:taameem/features/home/widgets/side_panel.dart';
import 'package:taameem/features/home/widgets/taameem_card_popup.dart';
import 'package:taameem/features/home/screens/taameem_detail_screen.dart';
import 'package:taameem/features/upload/screens/camera_screen.dart';
import '../widgets/taameem_map_marker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSidePanelOpen = false;
  final MapController _mapController = MapController();
  TaameemModel? _selectedTaameem;
  LatLng _userLocation = LocationService.defaultLocation;

  // فلتر النوع النشط
  String? _activeFilter;

  TaameemModel? _activePopup;
  Offset _popupOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // تشغيل التلاشي الزمني عند الفتح
    await FirestoreService.instance.runTimeDecay();

    // جلب موقع المستخدم
    final loc = await LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() => _userLocation = loc);
      _mapController.move(loc, 13);
    }
  }

  void _showPopup(BuildContext ctx, TaameemModel t) {
    try {
      final pt = _mapController.camera
          .latLngToScreenPoint(LatLng(t.latitude, t.longitude));
      setState(() {
        _activePopup = t;
        _popupOffset = Offset(pt.x.toDouble(), pt.y.toDouble());
      });
    } catch (_) {}
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
      _selectedTaameem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: _buildBody(),
      extendBody: true,
      bottomNavigationBar: TaameemBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        onAiTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiChatScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildMapScreen();
      case 1: return const SearchScreen();
      case 2: return const NotificationsScreen();
      case 3: return const ProfileScreen();
      default: return _buildMapScreen();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  الخريطة الرئيسية مع بيانات حية من Firestore
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMapScreen() {
    return StreamBuilder<List<TaameemModel>>(
      stream: FirestoreService.instance.streamActiveTaameems(),
      builder: (context, snapshot) {
        final taameems = snapshot.data ?? _mockFallback();

        // تطبيق الفلتر
        final filtered = _activeFilter == null
            ? taameems
            : taameems.where((t) => t.type == _activeFilter).toList();

        return Stack(
          children: [
            // ─── الخريطة ─────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 13,
                onTap: (_, __) =>
                    setState(() => _selectedTaameem = null),
              ),
              children: [
                // طبقة البلاط — OpenStreetMap
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taameem.app',
                  retinaMode: true,
                ),

                // ─── Marker Clustering ────────────────────────────────
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(48, 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: filtered.map((t) {
                      if (t.imageUrls.isNotEmpty) {
                        return Marker(
                          point: LatLng(t.latitude, t.longitude),
                          width: 62, height: 72,
                          child: PhotoMarker(
                            taameem: t,
                            onTap: () => _showPopup(context, t),
                          ),
                        );
                      }
                      return Marker(
                        point: LatLng(t.latitude, t.longitude),
                        width: 50, height: 58,
                        child: CategoryMarker(
                          taameem: t,
                          onTap: () => _showPopup(context, t),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return _ClusterBubble(count: markers.length);
                    },
                  ),
                ),

                // موقع المستخدم
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ─── شريط العنوان ─────────────────────────────────────────
            _buildTopBar(filtered.length),

            if (_activePopup != null)
              GestureDetector(
                onTap: () => setState(() => _activePopup = null),
                child: Container(color: Colors.transparent),
              ),
            if (_activePopup != null)
              TaameemPopupCard(
                taameem: _activePopup!,
                markerScreenPos: _popupOffset,
                onClose: () => setState(() => _activePopup = null),
                onViewDetail: () {
                  final t = _activePopup!;
                  setState(() => _activePopup = null);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TaameemDetailScreen(taameem: t)));
                },
              ),

            Positioned(
              right: 0,
              top: MediaQuery.of(context).size.height * 0.35,
              child: GestureDetector(
                onTap: () => setState(() => _isSidePanelOpen = !_isSidePanelOpen),
                child: Container(
                  width: 28,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: [BoxShadow(
                      color: AppColors.glassShadow,
                      blurRadius: 12,
                    )],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSidePanelOpen
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        size: 16,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(height: 8),
                      const RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'القائمة الجانبية',
                          style: TextStyle(fontFamily: 'Tajawal',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── فلاتر الأنواع ────────────────────────────────────────
            _buildFilterChips(),

            // ─── القائمة الجانبية ─────────────────────────────────────
            SidePanel(
              isOpen: _isSidePanelOpen,
              taameems: filtered
                  .map((t) => {
                        'id': t.id,
                        'type': t.type,
                        'title': t.title,
                        'description': t.description,
                        'lat': t.latitude,
                        'lng': t.longitude,
                        'color': t.typeColor,
                        'label': t.mapLabel,
                        'time': t.timeAgo,
                      })
                  .toList(),
              onClose: () =>
                  setState(() => _isSidePanelOpen = false),
              onTaameemTap: (data) {
                final found = filtered
                    .firstWhere((t) => t.id == data['id'],
                        orElse: () => filtered.first);
                setState(() {
                  _selectedTaameem = found;
                  _isSidePanelOpen = false;
                });
                _mapController.move(
                    LatLng(found.latitude, found.longitude), 15);
              },
            ),

            // ─── بطاقة التعميم المختار ────────────────────────────────
            if (_selectedTaameem != null)
              Positioned(
                bottom: 90,
                left: 16,
                right: 16,
                child: TaameemCardPopup(
                  taameem: {
                    'id': _selectedTaameem!.id,
                    'title': _selectedTaameem!.title,
                    'description': _selectedTaameem!.description,
                    'color': _selectedTaameem!.typeColor,
                    'label': _selectedTaameem!.mapLabel,
                    'time': _selectedTaameem!.timeAgo,
                  },
                  onClose: () =>
                      setState(() => _selectedTaameem = null),
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaameemDetailScreen(
                            taameem: _selectedTaameem!),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.3),
              ),

            // ─── أزرار التحكم بالخريطة ────────────────────────────────
            _buildMapControls(),

            // ─── مؤشر التحميل ─────────────────────────────────────────
            if (snapshot.connectionState == ConnectionState.waiting)
              const Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: LinearProgressIndicator(
                    color: AppColors.emerald,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(int count) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                // الشعار الصغير
                SizedBox(
                  width: 26,
                  height: 30,
                  child: CustomPaint(painter: _MiniShieldPainter()),
                ),
                const SizedBox(width: 8),
                const Text(
                  'تعميم',
                  style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack,
                  ),
                ),

                const SizedBox(width: 8),

                // عداد التعميمات
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count تعميم',
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraScreen(),
                    ),
                  ),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.forestGreen],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text('رفع تعميم',
                            style: TextStyle(fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5),
    );
  }

  // ─── فلاتر أنواع التعميمات ──────────────────────────────────────────────
  Widget _buildFilterChips() {
    final filters = [
      {'key': null, 'label': 'الكل'},
      {'key': 'missingPerson', 'label': 'مفقود', 'color': AppColors.missingPerson},
      {'key': 'theft', 'label': 'سرقة', 'color': AppColors.theft},
      {'key': 'emergency', 'label': 'طارئ', 'color': AppColors.emergency},
      {'key': 'helpRequest', 'label': 'استغاثة', 'color': AppColors.helpRequest},
      {'key': 'generalWarning', 'label': 'تحذير', 'color': AppColors.generalWarning},
    ];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: filters.length,
          itemBuilder: (_, i) {
            final f = filters[i];
            final key = f['key'] as String?;
            final isActive = _activeFilter == key;
            final color = f['color'] as Color? ?? AppColors.emerald;

            return GestureDetector(
              onTap: () => setState(() => _activeFilter = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? color
                        : AppColors.glassBorder,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                          )
                        ]
                      : [],
                ),
                child: Text(
                  f['label'] as String,
                  style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.forestGreen,
                  ),
                ),
              ),
            );
          },
        ),
      ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      left: 12,
      bottom: 90,
      child: Column(
        children: [
          _mapBtn(Icons.add_rounded, () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            );
          }),
          const SizedBox(height: 6),
          _mapBtn(Icons.remove_rounded, () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            );
          }),
          const SizedBox(height: 6),
          _mapBtn(Icons.my_location_rounded, () {
            _mapController.move(_userLocation, 15);
          }),
        ],
      ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.5),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, size: 18, color: AppColors.forestGreen),
          ),
        ),
      ),
    );
  }

  // بيانات تجريبية عند غياب الاتصال
  List<TaameemModel> _mockFallback() => [];
}

// ─── فقاعة التجميع (Cluster) ─────────────────────────────────────────────────
class _ClusterBubble extends StatelessWidget {
  final int count;
  const _ClusterBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.forestGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MiniShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = ui.Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.95, h * 0.2)
      ..lineTo(w * 0.95, h * 0.55)
      ..quadraticBezierTo(w * 0.95, h * 0.88, w * 0.5, h)
      ..quadraticBezierTo(w * 0.05, h * 0.88, w * 0.05, h * 0.55)
      ..lineTo(w * 0.05, h * 0.2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.emerald, AppColors.forestGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_MiniShieldPainter old) => false;
}

