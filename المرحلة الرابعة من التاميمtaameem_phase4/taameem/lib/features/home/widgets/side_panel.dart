import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

class SidePanel extends StatelessWidget {
  final bool isOpen;
  final List<Map<String, dynamic>> taameems;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onTaameemTap;

  const SidePanel({
    super.key,
    required this.isOpen,
    required this.taameems,
    required this.onClose,
    required this.onTaameemTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      top: 0,
      bottom: 0,
      right: isOpen ? 0 : -280,
      width: 280,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              border: Border(
                left: BorderSide(color: AppColors.glassBorder, width: 1),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 16),

                // ─── رأس القائمة ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'التعميمات القريبة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warmBeige,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(0),
                        AppColors.gold,
                        AppColors.gold.withOpacity(0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                // ─── قائمة التعميمات ────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: taameems.length,
                    itemBuilder: (context, index) {
                      final t = taameems[index];
                      return _SidePanelCard(
                        taameem: t,
                        onTap: () => onTaameemTap(t),
                      )
                          .animate(delay: Duration(milliseconds: 80 * index))
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.3, end: 0);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidePanelCard extends StatelessWidget {
  final Map<String, dynamic> taameem;
  final VoidCallback onTap;

  const _SidePanelCard({required this.taameem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warmBeige.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            // نقطة اللون
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: taameem['color'],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (taameem['color'] as Color).withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  taameem['label'],
                  style: GoogleFonts.cairo(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taameem['title'],
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.nearBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    taameem['time'],
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_left_rounded,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
