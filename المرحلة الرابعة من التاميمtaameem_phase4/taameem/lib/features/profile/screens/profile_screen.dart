import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/taameem_list_card.dart';
import '../../achievements/screens/achievements_screen.dart';
import '../../home/screens/taameem_detail_screen.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  static const String _userId = 'temp_user';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
              _buildProfileCard(),
              _buildStatsRow(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
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
            'حسابي',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
          ),
          const Spacer(),
          // زر الإعدادات
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 20,
                color: AppColors.forestGreen,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildProfileCard() {
    return GlassCard(
      showGoldLine: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // صورة البروفايل
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.forestGreen],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    'م',
                    style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مستخدم تعميم',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack,
                  ),
                ),
                Text(
                  '+966 5XX XXX XXXX',
                  style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'عضو نشط',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.forestGreen),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatsRow() {
    return StreamBuilder<List<TaameemModel>>(
      stream: FirestoreService.instance.streamUserTaameems(_userId),
      builder: (_, snap) {
        final taameems = snap.data ?? [];
        final active   = taameems.where((t) => t.status == 'active').length;
        final resolved = taameems.where((t) => t.status == 'resolved').length;
        final total    = taameems.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _StatItem(label: 'إجمالي التعميمات', value: '$total',
                    color: AppColors.emerald),
                _vDivider(),
                _StatItem(label: 'نشط الآن', value: '$active',
                    color: AppColors.missingPerson),
                _vDivider(),
                _StatItem(label: 'تم حلها', value: '$resolved',
                    color: AppColors.gold),
              ],
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _vDivider() => Container(
        width: 1, height: 36,
        color: AppColors.glassBorder,
        margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.warmBeige,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: AppColors.emerald,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.forestGreen,
          labelStyle: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: [
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('تعميماتي'),
                ],
              ),
            ),
            Tab(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AchievementsScreen()),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('الإنجازات'),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabs,
      children: [
        _buildMyTaameems(),
        _buildAchievementsPreview(),
      ],
    );
  }

  Widget _buildMyTaameems() {
    return StreamBuilder<List<TaameemModel>>(
      stream: FirestoreService.instance.streamUserTaameems(_userId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.emerald));
        }

        final list = snap.data ?? [];

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add_rounded,
                    size: 60, color: AppColors.grey.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text(
                  'لم تنشر أي تعميم بعد',
                  style: GoogleFonts.cairo(
                      fontSize: 16, color: AppColors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط زر "رفع تعميم" في الشريط السفلي',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: AppColors.grey.withOpacity(0.7)),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: list.length,
          itemBuilder: (_, i) => TaameemListCard(
            taameem: list[i],
            showActions: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TaameemDetailScreen(taameem: list[i])),
            ),
          ).animate(delay: Duration(milliseconds: 60 * i))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildAchievementsPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 60, color: AppColors.gold.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'إنجازاتك',
            style: GoogleFonts.cairo(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: AppColors.nearBlack),
          ),
          const SizedBox(height: 8),
          Text(
            'التعميمات التي أغلقتها بنجاح\nستظهر هنا كإنجازات',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.grey, height: 1.6),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.forestGreen]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'عرض الإنجازات',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
