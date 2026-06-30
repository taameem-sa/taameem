import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_background.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      emoji: '🗺️',
      title: 'خريطة المجتمع الحية',
      subtitle:
          'تابع التعميمات المحيطة بك على خريطة تفاعلية محدّثة لحظة بلحظة.'
          '\n\nكل حي، كل شارع، كل حدث — في متناول يدك.',
      color: AppColors.emerald,
    ),
    _OnboardPage(
      emoji: '🤖',
      title: 'تعميم AI معك دائماً',
      subtitle:
          'تحدث بشكل طبيعي. أخبر تعميم بما حدث وهو سيصنّف ويرتّب وينشر '
          'التعميم نيابةً عنك.',
      color: AppColors.gold,
    ),
    _OnboardPage(
      emoji: '🔔',
      title: 'إشعارات ذكية وفورية',
      subtitle:
          'تصلك إشعارات للتعميمات القريبة منك فقط، مع إمكانية التحكم '
          'الكامل في النوع والمسافة.',
      color: AppColors.missingPerson,
    ),
    _OnboardPage(
      emoji: '🤝',
      title: 'معاً نحمي مجتمعنا',
      subtitle:
          'كل تعميم تنشره يصل لآلاف المستخدمين القريبين. '
          'معاً نجعل المجتمع أكثر أماناً وتواصلاً.',
      color: AppColors.mint,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // زر تخطي
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                  child: GestureDetector(
                    onTap: _finish,
                    child: Text(
                      'تخطي',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              // صفحات التعريف
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _buildPage(_pages[i], i),
                ),
              ),

              // مؤشرات الصفحة
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _pages[_currentPage].color
                          : AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // زر التالي / البداية
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: GestureDetector(
                  onTap: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _pages[_currentPage].color,
                          _darken(_pages[_currentPage].color),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _pages[_currentPage].color.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'التالي'
                            : 'ابدأ الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الإيموجي الكبير
          Text(
            page.emoji,
            style: const TextStyle(fontSize: 90),
          )
              .animate(key: ValueKey(index))
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 36),

          Text(
            page.title,
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.nearBlack,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('t$index'))
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 20),

          Text(
            page.subtitle,
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: AppColors.forestGreen,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('s$index'))
              .fadeIn(duration: 400.ms, delay: 350.ms),
        ],
      ),
    );
  }

  Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
