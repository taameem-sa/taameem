import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taameem/core/constants/app_colors.dart';
import 'package:taameem/core/widgets/animated_background.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamWhite,
      body: AnimatedBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── شعار تعميم ────────────────────────────────────────────
              _TaameemLogo()
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 28),

              // ─── اسم التطبيق ───────────────────────────────────────────
              Text(
                'تعميم',
                style: GoogleFonts.cairo(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.nearBlack,
                  letterSpacing: 1,
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              Text(
                'T A A M E E M',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.gold,
                  letterSpacing: 4,
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 16),

              Text(
                'أمان وتواصل المجتمع',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.forestGreen,
                ),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// شعار الدرع مع حرف "ت"
class _TaameemLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 140),
      painter: _ShieldPainter(),
      child: SizedBox(
        width: 120,
        height: 140,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'ت',
              style: GoogleFonts.cairo(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // الظل
    final shadowPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // الدرع الرئيسي
    final path = _buildShieldPath(size);
    canvas.drawPath(path, shadowPaint);

    // تدرج أخضر
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.emerald,
        AppColors.forestGreen,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // حدود ذهبية
    final borderPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, borderPaint);

    // ثلاث نقاط ذهبية في الأسفل
    final dotPaint = Paint()..color = AppColors.gold;
    final dotY = size.height * 0.82;
    final dotSpacing = size.width * 0.15;
    final centerX = size.width / 2;

    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(centerX + i * dotSpacing, dotY),
        3.5,
        dotPaint,
      );
    }
  }

  Path _buildShieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.5, 0);
    path.lineTo(w * 0.95, h * 0.18);
    path.lineTo(w * 0.95, h * 0.55);
    path.quadraticBezierTo(w * 0.95, h * 0.85, w * 0.5, h);
    path.quadraticBezierTo(w * 0.05, h * 0.85, w * 0.05, h * 0.55);
    path.lineTo(w * 0.05, h * 0.18);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) => false;
}
