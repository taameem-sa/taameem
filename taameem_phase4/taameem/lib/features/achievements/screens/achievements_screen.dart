import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/taameem_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/taameem_list_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const String _userId = 'temp_user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildBadges(),
              Expanded(child: _buildResolvedList()),
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
            'الإنجازات',
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

  Widget _buildBadges() {
    final badges = [
      {'icon': '🥇', 'label': 'أول تعميم',     'desc': 'نشرت أول تعميم لك',       'earned': true},
      {'icon': '🤝', 'label': 'مساعد المجتمع', 'desc': 'ساعدت في 5 قضايا',        'earned': true},
      {'icon': '🔍', 'label': 'المحقق',         'desc': 'بحثت في 10 تعميمات',     'earned': false},
      {'icon': '⚡', 'label': 'الاستجابة السريعة', 'desc': 'أغلقت تعميم خلال ساعة', 'earned': false},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: badges.length,
        itemBuilder: (_, i) {
          final b = badges[i];
          final earned = b['earned'] as bool;
          return Container(
            width: 90,
            margin: const EdgeInsets.only(left: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: earned
                        ? AppColors.gold.withValues(alpha: 0.1)
                        : AppColors.warmBeige.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: earned
                          ? AppColors.gold.withValues(alpha: 0.4)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        earned ? b['icon'] as String : '🔒',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b['label'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: earned
                              ? AppColors.gold
                              : AppColors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: 100 * i))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
        },
      ),
    );
  }

  Widget _buildResolvedList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'التعميمات المُغلقة بنجاح',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TaameemModel>>(
            stream: FirestoreService.instance.streamUserTaameems(_userId),
            builder: (_, snap) {
              final resolved = (snap.data ?? [])
                  .where((t) => t.status == 'resolved')
                  .toList();

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (resolved.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 60, color: AppColors.grey.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد إنجازات بعد',
                        style: GoogleFonts.cairo(
                            fontSize: 16, color: AppColors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'عندما تُغلق تعميماً بنجاح\nسيُضاف إلى إنجازاتك',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.grey.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 40),
                itemCount: resolved.length,
                itemBuilder: (_, i) => TaameemListCard(
                  taameem: resolved[i],
                ).animate(delay: Duration(milliseconds: 60 * i))
                    .fadeIn(duration: 300.ms),
              );
            },
          ),
        ),
      ],
    );
  }
}
