import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../../core/constants/app_colors.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  String _completePhone = '';
  bool _isLoading = false;

  Future<void> _sendOTP() async {
    if (_completePhone.isEmpty) return;

    setState(() => _isLoading = true);

    // TODO: Firebase Phone Auth
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OtpScreen(phoneNumber: _completePhone),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // ─── الشعار ──────────────────────────────────────────────
                _buildLogo()
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 48),

                // ─── بطاقة تسجيل الدخول ──────────────────────────────────
                GlassCard(
                  showGoldLine: true,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك',
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أدخل رقم هاتفك للمتابعة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.forestGreen,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ─── حقل رقم الهاتف ──────────────────────────────
                      Form(
                        key: _formKey,
                        child: IntlPhoneField(
                          initialCountryCode: 'SA',
                          decoration: InputDecoration(
                            labelText: 'رقم الجوال',
                            labelStyle: GoogleFonts.cairo(
                              color: AppColors.forestGreen,
                            ),
                            filled: true,
                            fillColor: AppColors.warmBeige,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.emerald.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.emerald,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.nearBlack,
                          ),
                          onChanged: (phone) {
                            _completePhone = phone.completeNumber;
                          },
                          onSaved: (phone) {
                            _phoneNumber = phone?.number ?? '';
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ─── زر الإرسال ──────────────────────────────────
                      _buildSubmitButton(),
                    ],
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // ─── نص الشروط ───────────────────────────────────────────
                Text(
                  'بتسجيل دخولك توافق على سياسة الاستخدام والخصوصية',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 105,
          child: CustomPaint(
            painter: _MiniShieldPainter(),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'ت',
                  style: GoogleFonts.cairo(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'تعميم',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.nearBlack,
          ),
        ),
        Text(
          'T A A M E E M',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.gold,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _sendOTP,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [AppColors.grey, AppColors.grey]
                : [AppColors.emerald, AppColors.forestGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'إرسال رمز التحقق',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MiniShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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

    final shadowPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, shadowPaint);

    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.emerald, AppColors.forestGreen],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // نقاط ذهبية
    final dotPaint = Paint()..color = AppColors.gold;
    final dotY = h * 0.82;
    final centerX = w / 2;
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(centerX + i * w * 0.14, dotY), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MiniShieldPainter oldDelegate) => false;
}
