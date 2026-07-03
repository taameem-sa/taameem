import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // رأس الصفحة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 46,
                      child: CustomPaint(painter: _ShieldIconPainter()),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تعميم AI',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.nearBlack,
                          ),
                        ),
                        Text(
                          'مساعدك الذكي',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    showGoldLine: true,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // أيقونة الذكاء الاصطناعي
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emerald.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Center(
                            child: Text(
                              'ت',
                              style: GoogleFonts.cairo(
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              duration: 2000.ms,
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),

                        const SizedBox(height: 24),

                        Text(
                          AppConstants.aiWelcomeMessage,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.nearBlack,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'صفحة الذكاء الاصطناعي ستُبنى في المرحلة الثالثة\nمع Prompt Caching لتوفير التكلفة',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShieldIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.95, size.height * 0.2)
      ..lineTo(size.width * 0.95, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.95, size.height * 0.88, size.width * 0.5, size.height)
      ..quadraticBezierTo(
          size.width * 0.05, size.height * 0.88, size.width * 0.05, size.height * 0.55)
      ..lineTo(size.width * 0.05, size.height * 0.2)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.emerald, AppColors.forestGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_ShieldIconPainter old) => false;
}
