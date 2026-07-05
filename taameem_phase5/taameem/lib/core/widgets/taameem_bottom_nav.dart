import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class TaameemBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TaameemBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.map_rounded, label: 'الخريطة', routeIndex: 0),
    _NavItem(icon: Icons.grid_view_rounded, label: 'التعاميم', routeIndex: 1),
    _NavItem(icon: Icons.notifications_rounded, label: 'الإشعارات', routeIndex: 3),
    _NavItem(icon: Icons.person_rounded, label: 'حسابي', routeIndex: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              return _buildNavItem(i);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isSelected = currentIndex == item.routeIndex;

    return GestureDetector(
      onTap: () => onTap(item.routeIndex),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: isSelected ? AppColors.emerald : AppColors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.emerald : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _NavItem {
  final IconData? icon;
  final String label;
  final int routeIndex;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.routeIndex,
  });
}
