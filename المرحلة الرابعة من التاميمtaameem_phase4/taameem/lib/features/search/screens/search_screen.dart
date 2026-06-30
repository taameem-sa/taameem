import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedType;
  List<TaameemModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  static const List<Map<String, dynamic>> _filters = [
    {'key': null,             'label': 'الكل',         'icon': Icons.apps_rounded},
    {'key': 'missingPerson',  'label': 'فقدان أشخاص', 'icon': Icons.person_search_rounded},
    {'key': 'theft',          'label': 'سرقة',          'icon': Icons.car_crash_rounded},
    {'key': 'lostItem',       'label': 'فقدان شيء',    'icon': Icons.search_off_rounded},
    {'key': 'foundItem',      'label': 'إيجاد شيء',    'icon': Icons.find_in_page_rounded},
    {'key': 'emergency',      'label': 'طارئ',          'icon': Icons.emergency_rounded},
    {'key': 'generalWarning', 'label': 'تحذير',         'icon': Icons.warning_amber_rounded},
    {'key': 'helpRequest',    'label': 'استغاثة',       'icon': Icons.sos_rounded},
    {'key': 'lostAnimal',     'label': 'فقدان حيوان',  'icon': Icons.pets_rounded},
    {'key': 'inquiry',        'label': 'استفسار',       'icon': Icons.help_outline_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      // تحميل كل التعميمات النشطة أولاً
      final stream = FirestoreService.instance.streamActiveTaameems();
      final taameems = await stream.first;
      if (mounted) {
        setState(() {
          _results = taameems;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    setState(() { _query = query; _isLoading = true; });

    try {
      List<TaameemModel> results;

      if (query.trim().isEmpty && _selectedType == null) {
        final stream = FirestoreService.instance.streamActiveTaameems();
        results = await stream.first;
      } else if (query.trim().isNotEmpty) {
        results = await FirestoreService.instance.searchTaameems(query.trim());
      } else {
        results = await FirestoreService.instance.getTaameemsByType(_selectedType!);
      }

      // تطبيق فلتر النوع إذا كان مختاراً مع البحث النصي
      if (_selectedType != null && query.trim().isNotEmpty) {
        results = results.where((t) => t.type == _selectedType).toList();
      }

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyTypeFilter(String? type) async {
    setState(() => _selectedType = type);
    await _search(_query);
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
              _buildSearchBar(),
              _buildFilterRow(),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            'البحث',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(width: 10),
          if (_hasSearched && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_results.length} نتيجة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.cairo(
                fontSize: 14, color: AppColors.nearBlack),
              decoration: InputDecoration(
                hintText:
                    'ابحث بالعنوان، الوصف، رقم اللوحة...',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13, color: AppColors.grey),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.emerald, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _search('');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.grey, size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (v) {
                if (v.length > 2 || v.isEmpty) _search(v);
                setState(() => _query = v);
              },
              onSubmitted: _search,
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final key = f['key'] as String?;
          final isActive = _selectedType == key;
          final color = _colorForType(key);

          return GestureDetector(
            onTap: () => _applyTypeFilter(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8, bottom: 4, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? color : AppColors.glassBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : AppColors.glassBorder,
                ),
                boxShadow: isActive
                    ? [BoxShadow(
                        color: color.withOpacity(0.3), blurRadius: 8)]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: 14,
                    color: isActive ? Colors.white : AppColors.forestGreen,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  Widget _buildResults() {
    if (_isLoading) return _buildShimmer();

    if (_hasSearched && _results.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 90),
      itemCount: _results.length,
      itemBuilder: (_, i) => TaameemListCard(
        taameem: _results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaameemDetailScreen(taameem: _results[i]),
          ),
        ),
      ).animate(delay: Duration(milliseconds: 60 * i))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.15, end: 0),
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب كلمات بحث مختلفة\nأو اختر فئة أخرى',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.grey.withOpacity(0.7),
              height: 1.6,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Color _colorForType(String? key) {
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
}
