import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  شريط التنقل السفلي — مع زر AI مركزي بشعار تعميم
// ══════════════════════════════════════════════════════════════════════════════
class TaameemBottomNav extends StatelessWidget {
  final int            currentIndex;   // 0=خريطة 1=تعاميم 2=إشعارات 3=حسابي
  final ValueChanged<int> onTap;
  final VoidCallback   onAiTap;        // زر AI المركزي

  const TaameemBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAiTap,
  });

  static const _left = [               // يمين (RTL)
    _Item(Icons.map_outlined,           Icons.map_rounded,            'الخريطة',   0),
    _Item(Icons.grid_view_outlined,     Icons.grid_view_rounded,      'التعاميم',  1),
  ];
  static const _right = [              // يسار (RTL)
    _Item(Icons.notifications_outlined, Icons.notifications_rounded,  'الإشعارات', 2),
    _Item(Icons.person_outline_rounded, Icons.person_rounded,         'حسابي',     3),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(40, 0, 40, bottom + 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24, offset: const Offset(0, 6)),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,  offset: const Offset(0, 2)),
          ],
          border: Border.all(
              color: Colors.white.withOpacity(0.6), width: 1),
        ),
        child: Row(
          children: [

            // ── أزرار اليمين (خريطة + تعاميم) ───────────────────────────
            ..._left.map((item) => _NavItem(
              item: item,
              currentIndex: currentIndex,
              onTap: onTap)),

            // ── زر AI المركزي ─────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: onAiTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الشعار — درع تعميم مضيء
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.emerald,
                            AppColors.forestGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.45),
                            blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.5),
                          width: 1.5),
                      ),
                      child: const Center(
                        child: Text('ت',
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text('تعميم AI',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald)),
                  ],
                ),
              ),
            ),

            // ── أزرار اليسار (إشعارات + حسابي) ──────────────────────────
            ..._right.map((item) => _NavItem(
              item: item,
              currentIndex: currentIndex,
              onTap: onTap)),

          ],
        ),
      ),
    );
  }
}

// ── بيانات العنصر ─────────────────────────────────────────────────────────────
class _Item {
  final IconData icon, activeIcon;
  final String   label;
  final int      index;
  const _Item(this.icon, this.activeIcon, this.label, this.index);
}

// ── عنصر تنقل ────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _Item item;
  final int   currentIndex;
  final ValueChanged<int> onTap;
  const _NavItem({
    required this.item,
    required this.currentIndex,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = item.index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(item.index),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: a
                  ? AppColors.emerald.withOpacity(0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              a ? item.activeIcon : item.icon,
              size: 21,
              color: a ? AppColors.emerald : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 9.5,
              fontWeight: a ? FontWeight.w700 : FontWeight.w500,
              color: a ? AppColors.emerald : const Color(0xFF9E9E9E),
            ),
            child: Text(item.label),
          ),
        ]),
      ),
    );
  }
}
