import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../home/screens/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _isLoading = false;
  bool _isError = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
        _startTimer();
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    // TODO: Firebase verify OTP
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // للتطوير: أي رمز يعمل
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
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
                const SizedBox(height: 24),

                // ─── زر الرجوع ───────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warmBeige,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.forestGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // ─── أيقونة الرسالة ──────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: AppColors.emerald,
                    size: 36,
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fadeIn(),

                const SizedBox(height: 28),

                Text(
                  'التحقق من رقم الهاتف',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.nearBlack,
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 8),

                Text(
                  'تم إرسال رمز التحقق إلى\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.forestGreen,
                    height: 1.6,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 40),

                // ─── بطاقة OTP ────────────────────────────────────────────
                GlassCard(
                  showGoldLine: true,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        textStyle: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nearBlack,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 52,
                          fieldWidth: 44,
                          activeColor: AppColors.emerald,
                          inactiveColor: AppColors.glassBorder,
                          selectedColor: AppColors.gold,
                          activeFillColor: AppColors.warmBeige,
                          inactiveFillColor: AppColors.warmBeige,
                          selectedFillColor: AppColors.warmBeige,
                          errorBorderColor: AppColors.error,
                        ),
                        enableActiveFill: true,
                        hasError: _isError,
                        errorAnimationController: null,
                        onCompleted: (v) {
                          _otp = v;
                          _verifyOTP();
                        },
                        onChanged: (value) {
                          setState(() {
                            _otp = value;
                            _isError = false;
                          });
                        },
                      ),

                      if (_isError) ...[
                        const SizedBox(height: 8),
                        Text(
                          'رمز التحقق غير صحيح، حاول مرة أخرى',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ─── زر التحقق ───────────────────────────────────
                      GestureDetector(
                        onTap: _isLoading ? null : _verifyOTP,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.emerald, AppColors.forestGreen],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withOpacity(0.35),
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
                                    'تحقق وادخل',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // ─── إعادة الإرسال ────────────────────────────────────────
                GestureDetector(
                  onTap: _resendTimer == 0
                      ? () {
                          setState(() => _resendTimer = 60);
                          _startTimer();
                          // TODO: resend OTP
                        }
                      : null,
                  child: Text(
                    _resendTimer > 0
                        ? 'إعادة الإرسال خلال $_resendTimer ثانية'
                        : 'إعادة إرسال الرمز',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: _resendTimer > 0
                          ? AppColors.grey
                          : AppColors.emerald,
                      fontWeight: _resendTimer == 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
