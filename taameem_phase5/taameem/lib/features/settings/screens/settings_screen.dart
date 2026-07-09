import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _userId = 'temp_user';

  // إعدادات الإشعارات
  bool _notifyNearby     = true;
  bool _notifyMatches    = true;
  bool _notifyExpiry     = true;
  bool _notifyEmergency  = true;

  // نطاق الإشعارات
  double _notifyRadius = 10; // كيلومتر
  LatLng _defaultLocation = LocationService.defaultLocation;

  // إعدادات الخصوصية
  bool _showPhone    = false;
  bool _anonymousMap = false;

  // فئات الإشعارات
  Map<String, bool> _categoryNotifs = {
    'missingPerson':  true,
    'theft':          true,
    'emergency':      true,
    'helpRequest':    true,
    'generalWarning': true,
    'humanitarian':   false,
    'lostItem':       false,
    'foundItem':      false,
    'lostAnimal':     false,
    'inquiry':        false,
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultLoc = await LocationService.instance.getDefaultLocation();
    setState(() {
      _notifyNearby    = prefs.getBool('notifyNearby')    ?? true;
      _notifyMatches   = prefs.getBool('notifyMatches')   ?? true;
      _notifyExpiry    = prefs.getBool('notifyExpiry')    ?? true;
      _notifyEmergency = prefs.getBool('notifyEmergency') ?? true;
      _notifyRadius    = prefs.getDouble('notifyRadius')  ?? 10;
      _showPhone       = prefs.getBool('showPhone')       ?? false;
      _anonymousMap    = prefs.getBool('anonymousMap')    ?? false;
      _defaultLocation = defaultLoc;
    });
  }

  Future<void> _setDefaultToCurrentLocation() async {
    final loc = await LocationService.instance.getPreciseLocation();
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر الوصول للموقع الحالي، تم الإبقاء على الموقع الافتراضي الحالي',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await LocationService.instance.setDefaultLocation(loc);
    await FirestoreService.instance.upsertUserDefaultLocation(_userId, loc);
    if (!mounted) return;
    setState(() => _defaultLocation = loc);
  }

  Future<void> _resetDefaultLocation() async {
    await LocationService.instance.setDefaultLocation(
      LocationService.defaultLocation,
    );
    await FirestoreService.instance.upsertUserDefaultLocation(
      _userId,
      LocationService.defaultLocation,
    );
    if (!mounted) return;
    setState(() => _defaultLocation = LocationService.defaultLocation);
  }

  String get _defaultLocationLabel {
    final lat = _defaultLocation.latitude.toStringAsFixed(4);
    final lng = _defaultLocation.longitude.toStringAsFixed(4);
    return '$lat, $lng';
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)   prefs.setBool(key, value);
    if (value is double) prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _buildSection(
                      'الإشعارات العامة',
                      Icons.notifications_outlined,
                      [
                        _ToggleTile(
                          label: 'تعميمات قريبة',
                          subtitle: 'إشعار عند وجود تعميم جديد في منطقتك',
                          value: _notifyNearby,
                          onChanged: (v) {
                            setState(() => _notifyNearby = v);
                            _savePref('notifyNearby', v);
                          },
                        ),
                        _ToggleTile(
                          label: 'إشعارات التطابق',
                          subtitle: 'عند وجود تطابق محتمل مع تعميمك',
                          value: _notifyMatches,
                          onChanged: (v) {
                            setState(() => _notifyMatches = v);
                            _savePref('notifyMatches', v);
                          },
                        ),
                        _ToggleTile(
                          label: 'انتهاء التعميم',
                          subtitle: 'تنبيه قبل انتهاء صلاحية تعميمك',
                          value: _notifyExpiry,
                          onChanged: (v) {
                            setState(() => _notifyExpiry = v);
                            _savePref('notifyExpiry', v);
                          },
                        ),
                        _ToggleTile(
                          label: 'الطوارئ والتحذيرات',
                          subtitle: 'إشعارات فورية للحالات الحرجة دائماً',
                          value: _notifyEmergency,
                          onChanged: (v) {
                            setState(() => _notifyEmergency = v);
                            _savePref('notifyEmergency', v);
                          },
                          activeColor: AppColors.emergency,
                        ),
                      ],
                    ),

                    _buildSection(
                      'نطاق الإشعارات',
                      Icons.radar_rounded,
                      [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Icon(Icons.place_rounded,
                                  size: 16, color: AppColors.emerald),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الموقع الافتراضي',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                    Text(
                                      _defaultLocationLabel,
                                      style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: AppColors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _setDefaultToCurrentLocation,
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.warmBeige,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.glassBorder),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'تحديث من موقعي الحالي',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: AppColors.forestGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _resetDefaultLocation,
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'إعادة ضبط',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'نصف القطر:',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_notifyRadius.round()} كم',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.emerald,
                                  thumbColor: AppColors.emerald,
                                  overlayColor:
                                      AppColors.emerald.withValues(alpha: 0.1),
                                  inactiveTrackColor:
                                      AppColors.glassBorder,
                                ),
                                child: Slider(
                                  value: _notifyRadius,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  onChanged: (v) {
                                    setState(() => _notifyRadius = v);
                                    _savePref('notifyRadius', v);
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('1 كم',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11, color: AppColors.grey)),
                                  Text('50 كم',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11, color: AppColors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildSection(
                      'فئات التعميمات',
                      Icons.category_outlined,
                      _categoryNotifs.entries.map((e) {
                        final names = {
                          'missingPerson': 'فقدان أشخاص',
                          'theft': 'سرقة واعتداء',
                          'emergency': 'طارئ',
                          'helpRequest': 'استغاثة',
                          'generalWarning': 'تحذير عام',
                          'humanitarian': 'إنساني',
                          'lostItem': 'فقدان شيء',
                          'foundItem': 'إيجاد شيء',
                          'lostAnimal': 'فقدان حيوان',
                          'inquiry': 'استفسار',
                        };
                        return _ToggleTile(
                          label: names[e.key] ?? e.key,
                          value: e.value,
                          onChanged: (v) =>
                              setState(() => _categoryNotifs[e.key] = v),
                        );
                      }).toList(),
                    ),

                    _buildSection(
                      'الخصوصية',
                      Icons.privacy_tip_outlined,
                      [
                        _ToggleTile(
                          label: 'إخفاء رقم الهاتف',
                          subtitle: 'لا يرى الآخرون رقمك في التعميمات',
                          value: !_showPhone,
                          onChanged: (v) {
                            setState(() => _showPhone = !v);
                            _savePref('showPhone', !v);
                          },
                        ),
                        _ToggleTile(
                          label: 'إخفاء الموقع الدقيق على الخريطة',
                          subtitle: 'يظهر موقعك بدقة أقل للمستخدمين',
                          value: _anonymousMap,
                          onChanged: (v) {
                            setState(() => _anonymousMap = v);
                            _savePref('anonymousMap', v);
                          },
                        ),
                      ],
                    ),

                    _buildSection(
                      'الحساب',
                      Icons.manage_accounts_outlined,
                      [
                        _ActionTile(
                          label: 'تغيير رقم الهاتف',
                          icon: Icons.phone_outlined,
                          onTap: () {},
                        ),
                        _ActionTile(
                          label: 'سياسة الخصوصية',
                          icon: Icons.description_outlined,
                          onTap: () {},
                        ),
                        _ActionTile(
                          label: 'شروط الاستخدام',
                          icon: Icons.gavel_outlined,
                          onTap: () {},
                        ),
                        _ActionTile(
                          label: 'تسجيل الخروج',
                          icon: Icons.logout_rounded,
                          color: AppColors.error,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),

                    // معلومات التطبيق
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'تعميم — الإصدار 1.0.0\nجميع الحقوق محفوظة © 2025',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.forestGreen),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'الإعدادات',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.emerald),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.glassBorder),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          showGoldLine: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هل أنت متأكد من تسجيل الخروج؟',
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.warmBeige,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Center(
                          child: Text('إلغاء',
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: AppColors.forestGreen)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: تسجيل خروج Firebase
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('خروج',
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final Function(bool) onChanged;
  final Color? activeColor;

  const _ToggleTile({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.nearBlack)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: AppColors.grey, height: 1.4)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor ?? AppColors.emerald,
            inactiveThumbColor: AppColors.grey,
            inactiveTrackColor: AppColors.glassBorder,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.forestGreen;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c)),
            ),
            Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
