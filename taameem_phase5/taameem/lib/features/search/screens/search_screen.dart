import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/taameem_list_card.dart';
import '../../home/screens/taameem_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _viewTabs;
  final _searchController = TextEditingController();
  final _regionController = TextEditingController();

  String _query = '';
  String? _selectedType;
  String? _selectedRegion;
  File? _searchImage;
  List<TaameemModel> _results = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  // أنواع التعميمات للفلتر
  static const List<Map<String, dynamic>> _typeFilters = [
    {'key': null,             'label': 'الكل',         'icon': Icons.apps_rounded},
    {'key': 'missingPerson',  'label': 'فقدان أشخاص', 'icon': Icons.person_search_rounded},
    {'key': 'theft',          'label': 'سرقة',          'icon': Icons.car_crash_rounded},
    {'key': 'lostItem',       'label': 'فقدان شيء',    'icon': Icons.search_off_rounded},
    {'key': 'foundItem',      'label': 'إيجاد شيء',    'icon': Icons.find_in_page_rounded},
    {'key': 'emergency',      'label': 'طارئ',          'icon': Icons.emergency_rounded},
    {'key': 'generalWarning', 'label': 'تحذير',         'icon': Icons.warning_amber_rounded},
    {'key': 'helpRequest',    'label': 'استغاثة',       'icon': Icons.sos_rounded},
    {'key': 'humanitarian',   'label': 'إنساني',        'icon': Icons.volunteer_activism_rounded},
    {'key': 'lostAnimal',     'label': 'فقدان حيوان',  'icon': Icons.pets_rounded},
    {'key': 'inquiry',        'label': 'استفسار',       'icon': Icons.help_outline_rounded},
  ];

  // مناطق الرياض للفلتر
  static const List<String> _regions = [
    'كل المناطق', 'حي النرجس', 'حي العليا', 'حي الياسمين',
    'حي الروضة', 'حي السلامة', 'حي العقيق', 'حي الملقا',
    'حي الورود', 'وسط الرياض', 'شمال الرياض', 'جنوب الرياض',
  ];

  @override
  void initState() {
    super.initState();
    _viewTabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _viewTabs.dispose();
    _searchController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final stream = FirestoreService.instance.streamActiveTaameems();
      final data = await stream.first;
      if (mounted) {
        setState(() {
          _results = data;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasLoaded = true; });
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    try {
      List<TaameemModel> data;
      if (_selectedType != null) {
        data = await FirestoreService.instance.getTaameemsByType(_selectedType!);
      } else {
        final stream = FirestoreService.instance.streamActiveTaameems();
        data = await stream.first;
      }
      // فلتر النص
      if (_query.isNotEmpty) {
        data = data.where((t) =>
          t.title.contains(_query) || t.description.contains(_query)
        ).toList();
      }
      // فلتر المنطقة
      if (_selectedRegion != null && _selectedRegion != 'كل المناطق') {
        data = data.where((t) =>
          t.city.contains(_selectedRegion!) ||
          t.neighborhood.contains(_selectedRegion!)
        ).toList();
      }
      if (mounted) setState(() { _results = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageSearch() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _searchImage = File(picked.path));
    // TODO: إرسال الصورة للـ AI للبحث
    _showSnack('ميزة البحث بالصور ستتصل بـ AI — قريباً');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: AppColors.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Color _typeColor(String? key) {
    switch (key) {
      case 'missingPerson':  return AppColors.missingPerson;
      case 'foundItem':      return AppColors.foundItem;
      case 'lostItem':       return AppColors.lostItem;
      case 'theft':          return AppColors.theft;
      case 'helpRequest':    return AppColors.helpRequest;
      case 'humanitarian':   return AppColors.humanitarian;
      case 'emergency':      return AppColors.emergency;
      case 'generalWarning': return AppColors.generalWarning;
      case 'lostAnimal':     return AppColors.lostAnimal;
      case 'inquiry':        return AppColors.inquiry;
      default:               return AppColors.emerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildTypeFilters(),
              _buildRegionFilter(),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  // ── رأس الصفحة ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('التعاميم', style: GoogleFonts.cairo(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.nearBlack,
          )),
          const SizedBox(width: 10),
          if (_hasLoaded && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_results.length} تعميم',
                style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.emerald,
                )),
            ),
          const Spacer(),
          // زر تحديث
          GestureDetector(
            onTap: _loadAll,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.refresh_rounded,
                size: 18, color: AppColors.forestGreen),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  // ── شريط البحث ──────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                // أيقونة البحث
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded,
                    color: AppColors.emerald, size: 22),
                ),

                // حقل النص
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.cairo(
                      fontSize: 14, color: AppColors.nearBlack),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالنص، العنوان، الوصف...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (v) {
                      setState(() => _query = v);
                      if (v.length > 2 || v.isEmpty) _applyFilters();
                    },
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),

                // زر مسح
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                      _loadAll();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.close_rounded,
                        color: AppColors.grey, size: 18),
                    ),
                  ),

                // فاصل
                Container(width: 1, height: 28, color: AppColors.glassBorder),

                // زر البحث بالصورة
                GestureDetector(
                  onTap: _pickImageSearch,
                  child: Container(
                    width: 46, height: 46,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _searchImage != null
                        ? AppColors.emerald.withOpacity(0.12)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search_rounded,
                          size: 20,
                          color: _searchImage != null
                            ? AppColors.emerald
                            : AppColors.forestGreen),
                        Text('صورة', style: GoogleFonts.cairo(
                          fontSize: 8, color: AppColors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
    );
  }

  // ── فلاتر الأنواع ────────────────────────────────────────────
  Widget _buildTypeFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _typeFilters.length,
        itemBuilder: (_, i) {
          final f = _typeFilters[i];
          final key = f['key'] as String?;
          final isActive = _selectedType == key;
          final color = _typeColor(key);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = key);
              _applyFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8, bottom: 4, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? color : AppColors.warmBeige,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : AppColors.glassBorder),
                boxShadow: isActive ? [BoxShadow(
                  color: color.withOpacity(0.3), blurRadius: 8)] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f['icon'] as IconData,
                    size: 13,
                    color: isActive ? Colors.white : AppColors.forestGreen),
                  const SizedBox(width: 5),
                  Text(f['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.forestGreen,
                    )),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  // ── فلتر المنطقة ─────────────────────────────────────────────
  Widget _buildRegionFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: GestureDetector(
        onTap: _showRegionSheet,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _selectedRegion != null && _selectedRegion != 'كل المناطق'
              ? AppColors.emerald.withOpacity(0.1)
              : AppColors.warmBeige,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedRegion != null && _selectedRegion != 'كل المناطق'
                ? AppColors.emerald.withOpacity(0.4)
                : AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded,
                size: 16,
                color: _selectedRegion != null && _selectedRegion != 'كل المناطق'
                  ? AppColors.emerald
                  : AppColors.grey),
              const SizedBox(width: 8),
              Text(
                _selectedRegion ?? 'تصفية حسب المنطقة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _selectedRegion != null
                    ? AppColors.forestGreen
                    : AppColors.grey,
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.grey),
              if (_selectedRegion != null && _selectedRegion != 'كل المناطق')
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedRegion = null);
                    _applyFilters();
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.close_rounded,
                      size: 15, color: AppColors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  void _showRegionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.creamWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('اختر المنطقة',
                style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack)),
            ),
            const SizedBox(height: 12),
            ...(_regions.map((r) => GestureDetector(
              onTap: () {
                setState(() => _selectedRegion = r == 'كل المناطق' ? null : r);
                Navigator.pop(context);
                _applyFilters();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.glassBorder.withOpacity(0.5)))),
                child: Row(
                  children: [
                    Text(r, style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: _selectedRegion == r
                        ? FontWeight.w700 : FontWeight.w400,
                      color: _selectedRegion == r
                        ? AppColors.emerald : AppColors.forestGreen,
                    )),
                    const Spacer(),
                    if (_selectedRegion == r)
                      const Icon(Icons.check_rounded,
                        color: AppColors.emerald, size: 18),
                  ],
                ),
              ),
            ))).toList(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ── قائمة النتائج ────────────────────────────────────────────
  Widget _buildResults() {
    if (_isLoading) return _buildShimmer();
    if (_hasLoaded && _results.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 90),
      itemCount: _results.length,
      itemBuilder: (_, i) => TaameemListCard(
        taameem: _results[i],
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
            TaameemDetailScreen(taameem: _results[i]))),
      ).animate(delay: Duration(milliseconds: 50 * i))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.warmBeige,
        highlightColor: AppColors.creamWhite,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view_rounded,
            size: 64, color: AppColors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('لا توجد تعاميم',
            style: GoogleFonts.cairo(
              fontSize: 18, fontWeight: FontWeight.w600,
              color: AppColors.grey)),
          const SizedBox(height: 8),
          Text('جرّب تغيير الفلاتر\nأو كن أول من ينشر تعميماً',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13, color: AppColors.grey.withOpacity(0.7),
              height: 1.6)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}
