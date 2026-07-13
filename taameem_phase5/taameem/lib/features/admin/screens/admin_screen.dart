import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/taameem_list_card.dart';
import '../../home/screens/taameem_detail_screen.dart';
import '../widgets/admin_stats_card.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, int> _stats = {};
  Map<String, int> _typeBreakdown = {};
  bool _loadingStats = true;
  String _taameemFilter = 'active';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final s = await AdminService.instance.getDashboardStats();
    final b = await AdminService.instance.getTypeBreakdown();
    if (mounted) setState(() { _stats = s; _typeBreakdown = b; _loadingStats = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: TabBarView(controller: _tabs, children: [
              _buildDashboard(),
              _buildTaameemMgmt(),
              _buildUserMgmt(),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder)),
          child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.forestGreen),
        ),
      ),
      const SizedBox(width: 14),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('لوحة التحكم', style: TextStyle(fontFamily: 'Tajawal',fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
        Text('صلاحيات المسؤول', style: TextStyle(fontFamily: 'Tajawal',fontSize: 11, color: AppColors.emerald)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _loadStats,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder)),
          child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.forestGreen),
        ),
      ),
    ]).animate().fadeIn(duration: 300.ms),
  );

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Container(
      height: 44,
      decoration: BoxDecoration(color: AppColors.warmBeige,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder)),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.emerald, AppColors.forestGreen]),
          borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.forestGreen,
        labelStyle: const TextStyle(fontFamily: 'Tajawal',fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal',fontSize: 12),
        tabs: const [
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.dashboard_rounded, size: 16), SizedBox(width: 4), Text('إحصائيات')])),
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.article_rounded, size: 16), SizedBox(width: 4), Text('تعميمات')])),
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_rounded, size: 16), SizedBox(width: 4), Text('مستخدمون')])),
        ],
      ),
    ),
  );

  Widget _buildDashboard() {
    if (_loadingStats) return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
    return RefreshIndicator(
      onRefresh: _loadStats, color: AppColors.emerald,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
        const Text('إحصائيات عامة', style: TextStyle(fontFamily: 'Tajawal',fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2,
          children: [
            AdminStatsCard(label: 'إجمالي التعميمات', value: '${_stats['total']??0}', icon: Icons.article_rounded, color: AppColors.emerald, delay: 0),
            AdminStatsCard(label: 'نشطة الآن', value: '${_stats['active']??0}', icon: Icons.radio_button_on_rounded, color: AppColors.missingPerson, delay: 80),
            AdminStatsCard(label: 'تم حلها', value: '${_stats['resolved']??0}', icon: Icons.check_circle_outline_rounded, color: AppColors.gold, delay: 160),
            AdminStatsCard(label: 'المستخدمون', value: '${_stats['users']??0}', icon: Icons.people_outline_rounded, color: AppColors.mint, delay: 240),
            AdminStatsCard(label: 'اليوم', value: '${_stats['today']??0}', icon: Icons.today_rounded, color: AppColors.inquiry, delay: 320),
            AdminStatsCard(label: 'منتهية', value: '${_stats['expired']??0}', icon: Icons.timer_off_outlined, color: AppColors.grey, delay: 400),
          ],
        ),
        if (_typeBreakdown.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('توزيع التعميمات حسب النوع', style: TextStyle(fontFamily: 'Tajawal',fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
          const SizedBox(height: 12),
          GlassCard(
            showGoldLine: true, padding: const EdgeInsets.all(16),
            child: Column(children: _typeBreakdown.entries.map((e) {
              final pct = e.value / (_stats['total'] ?? 1);
              final color = _typeColor(e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_typeName(e.key), style: const TextStyle(fontFamily: 'Tajawal',fontSize: 12, color: AppColors.forestGreen))),
                    Text('${e.value}', style: TextStyle(fontFamily: 'Tajawal',fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                ]),
              );
            }).toList()),
          ),
        ],
      ]),
    );
  }

  Widget _buildTaameemMgmt() => Column(children: [
    SizedBox(height: 44, child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        for (final s in ['active', 'resolved', 'expired'])
          GestureDetector(
            onTap: () => setState(() => _taameemFilter = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _taameemFilter == s ? AppColors.emerald : AppColors.warmBeige,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _taameemFilter == s ? AppColors.emerald : AppColors.glassBorder)),
              child: Center(child: Text(
                {'active':'نشطة','resolved':'محلولة','expired':'منتهية'}[s]!,
                style: TextStyle(fontFamily: 'Tajawal',fontSize: 12, fontWeight: FontWeight.w600,
                  color: _taameemFilter == s ? Colors.white : AppColors.forestGreen),
              )),
            ),
          ),
      ],
    )),
    Expanded(child: StreamBuilder<List<TaameemModel>>(
      stream: AdminService.instance.streamAllTaameems(filterStatus: _taameemFilter),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
        final list = snap.data ?? [];
        if (list.isEmpty) return const Center(child: Text('لا توجد تعميمات', style: TextStyle(fontFamily: 'Tajawal',fontSize: 15, color: AppColors.grey)));
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          itemCount: list.length,
          itemBuilder: (_, i) => Stack(children: [
            TaameemListCard(taameem: list[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaameemDetailScreen(taameem: list[i])))),
            Positioned(top: 14, left: 24, child: Row(children: [
              _adminBtn(Icons.delete_outline_rounded, AppColors.error, () => _confirmDelete(list[i])),
              const SizedBox(width: 6),
              _adminBtn(Icons.check_circle_outline_rounded, AppColors.gold, () => AdminService.instance.setTaameemStatus(list[i].id, 'resolved')),
            ])),
          ]),
        );
      },
    )),
  ]);

  Widget _buildUserMgmt() => StreamBuilder<List<Map<String, dynamic>>>(
    stream: AdminService.instance.streamUsers(),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
      final users = snap.data ?? [];
      if (users.isEmpty) return const Center(child: Text('لا يوجد مستخدمون', style: TextStyle(fontFamily: 'Tajawal',fontSize: 15, color: AppColors.grey)));
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          final banned = u['banned'] as bool? ?? false;
          final phone  = u['phone']  as String? ?? '—';
          final role   = u['role']   as String? ?? 'user';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: banned ? AppColors.error.withValues(alpha: 0.06) : AppColors.glassBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: banned ? AppColors.error.withValues(alpha: 0.3) : AppColors.glassBorder)),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
                child: Text(phone.isNotEmpty ? phone[0] : 'م', style: const TextStyle(fontFamily: 'Tajawal',fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.emerald))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(phone, style: const TextStyle(fontFamily: 'Tajawal',fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.nearBlack)),
                Text(role == 'owner' ? 'مالك' : role == 'admin' ? 'مشرف' : 'مستخدم',
                  style: TextStyle(fontFamily: 'Tajawal',fontSize: 10, color: role != 'user' ? AppColors.gold : AppColors.grey)),
              ])),
              if (role == 'user')
                GestureDetector(
                  onTap: () => AdminService.instance.setUserBanned(u['id'], !banned),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: banned ? AppColors.emerald.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: banned ? AppColors.emerald.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3))),
                    child: Text(banned ? 'رفع الحظر' : 'حظر',
                      style: TextStyle(fontFamily: 'Tajawal',fontSize: 11, fontWeight: FontWeight.w600, color: banned ? AppColors.emerald : AppColors.error)),
                  ),
                ),
            ]),
          ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 300.ms);
        },
      );
    },
  );

  Widget _adminBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Icon(icon, size: 14, color: color),
    ),
  );

  void _confirmDelete(TaameemModel t) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(showGoldLine: true, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_forever_rounded, size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('حذف التعميم', style: TextStyle(fontFamily: 'Tajawal',fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.nearBlack)),
          const SizedBox(height: 8),
          Text('"${t.title}"', style: const TextStyle(fontFamily: 'Tajawal',fontSize: 13, color: AppColors.forestGreen), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 44, decoration: BoxDecoration(color: AppColors.warmBeige, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
                child: const Center(child: Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal',fontSize: 14, color: AppColors.forestGreen)))),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () async { Navigator.pop(context); await AdminService.instance.deleteTaameem(t.id); },
              child: Container(height: 44, decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('حذف', style: TextStyle(fontFamily: 'Tajawal',fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)))),
            )),
          ]),
        ]),
      ),
    ));
  }

  Color _typeColor(String k) { switch (k) { case 'missingPerson': return AppColors.missingPerson; case 'theft': return AppColors.theft; case 'emergency': return AppColors.emergency; case 'helpRequest': return AppColors.helpRequest; case 'generalWarning': return AppColors.generalWarning; case 'lostItem': return AppColors.lostItem; case 'foundItem': return AppColors.foundItem; case 'lostAnimal': return AppColors.lostAnimal; case 'humanitarian': return AppColors.humanitarian; default: return AppColors.inquiry; } }
  String _typeName(String k) { const n = {'missingPerson':'فقدان أشخاص','foundItem':'إيجاد شيء','lostItem':'فقدان شيء','theft':'سرقة','helpRequest':'استغاثة','humanitarian':'إنساني','emergency':'طارئ','generalWarning':'تحذير عام','lostAnimal':'فقدان حيوان','inquiry':'استفسار'}; return n[k] ?? k; }
}

