import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/taameem_bottom_nav.dart';
import '../../../core/widgets/glass_card.dart';
import '../../search/screens/search_screen.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/map_marker_widget.dart';
import '../widgets/side_panel.dart';
import '../widgets/taameem_card_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSidePanelOpen = false;
  final MapController _mapController = MapController();

  // بيانات تجريبية للتعميمات
  final List<Map<String, dynamic>> _mockTaameems = [
    {
      'id': '1',
      'type': 'missingPerson',
      'title': 'طفل مفقود في حي النرجس',
      'description': 'طفل عمره 7 سنوات، يرتدي ملابس زرقاء',
      'lat': 24.7136,
      'lng': 46.6753,
      'color': AppColors.missingPerson,
      'label': 'مفقود',
      'time': 'منذ ساعتين',
    },
    {
      'id': '2',
      'type': 'theft',
      'title': 'سيارة مسروقة — كامري 2022',
      'description': 'لوحة: أ ب ج 1234 — اللون أبيض',
      'lat': 24.7200,
      'lng': 46.6900,
      'color': AppColors.theft,
      'label': 'مسروق',
      'time': 'منذ 5 ساعات',
    },
    {
      'id': '3',
      'type': 'emergency',
      'title': 'حادث مروري على طريق الملك فهد',
      'description': 'حادث بين 3 مركبات، يحتاج مساعدة',
      'lat': 24.7050,
      'lng': 46.6600,
      'color': AppColors.emergency,
      'label': 'طارئ',
      'time': 'منذ 20 دقيقة',
    },
    {
      'id': '4',
      'type': 'lostItem',
      'title': 'محفظة مفقودة في الكارفور',
      'description': 'محفظة جلدية بنية تحتوي على بطاقات',
      'lat': 24.7300,
      'lng': 46.7000,
      'color': AppColors.lostItem,
      'label': 'مفقود',
      'time': 'منذ 3 ساعات',
    },
    {
      'id': '5',
      'type': 'generalWarning',
      'title': 'تحذير من ثعبان في الحي',
      'description': 'تم رؤية ثعبان كبير في شارع 15',
      'lat': 24.6950,
      'lng': 46.7100,
      'color': AppColors.generalWarning,
      'label': 'تحذير',
      'time': 'منذ ساعة',
    },
  ];

  Map<String, dynamic>? _selectedTaameem;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: _buildBody(),
      extendBody: true,
      bottomNavigationBar: TaameemBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildMapScreen();
      case 1:
        return const SearchScreen();
      case 2:
        return const AiChatScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildMapScreen();
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
      _selectedTaameem = null;
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  الخريطة الرئيسية
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMapScreen() {
    return Stack(
      children: [
        // ─── الخريطة ────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(24.7136, 46.6753),
            initialZoom: 13,
            onTap: (_, __) => setState(() {
              _selectedTaameem = null;
            }),
          ),
          children: [
            // طبقة الخريطة — OpenStreetMap مجانية
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.taameem.app',
              retinaMode: true,
            ),

            // طبقة العلامات
            MarkerLayer(
              markers: _mockTaameems.map((t) {
                return Marker(
                  point: LatLng(t['lat'], t['lng']),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTaameem = t),
                    child: MapMarkerWidget(
                      color: t['color'],
                      label: t['label'],
                      isSelected: _selectedTaameem?['id'] == t['id'],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // ─── شريط العنوان العلوي ─────────────────────────────────────────────
        _buildTopBar(),

        // ─── القائمة الجانبية ────────────────────────────────────────────────
        SidePanel(
          isOpen: _isSidePanelOpen,
          taameems: _mockTaameems,
          onClose: () => setState(() => _isSidePanelOpen = false),
          onTaameemTap: (t) {
            setState(() {
              _selectedTaameem = t;
              _isSidePanelOpen = false;
            });
            _mapController.move(LatLng(t['lat'], t['lng']), 15);
          },
        ),

        // ─── بطاقة التعميم عند الضغط على العلامة ──────────────────────────
        if (_selectedTaameem != null)
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: TaameemCardPopup(
              taameem: _selectedTaameem!,
              onClose: () => setState(() => _selectedTaameem = null),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.3, end: 0),
          ),

        // ─── أزرار التحكم بالخريطة ───────────────────────────────────────────
        _buildMapControls(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                // شعار صغير
                SizedBox(
                  width: 28,
                  height: 32,
                  child: CustomPaint(painter: _MiniShieldPainter()),
                ),
                const SizedBox(width: 10),
                Text(
                  'تعميم',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack,
                  ),
                ),

                const Spacer(),

                // زر فتح القائمة الجانبية
                GestureDetector(
                  onTap: () =>
                      setState(() => _isSidePanelOpen = !_isSidePanelOpen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'القائمة',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isSidePanelOpen
                              ? Icons.chevron_right_rounded
                              : Icons.chevron_left_rounded,
                          size: 16,
                          color: AppColors.forestGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5, end: 0),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      left: 12,
      bottom: 90,
      child: Column(
        children: [
          _mapControlButton(
            icon: Icons.add_rounded,
            onTap: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
          ),
          const SizedBox(height: 6),
          _mapControlButton(
            icon: Icons.remove_rounded,
            onTap: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
          ),
          const SizedBox(height: 6),
          _mapControlButton(
            icon: Icons.my_location_rounded,
            onTap: () {
              // TODO: انتقل إلى موقع المستخدم
            },
          ),
        ],
      ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideX(begin: -0.5, end: 0),
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
}

class _MiniShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
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
