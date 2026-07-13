import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glass_card.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  سياسة الخصوصية
// ──────────────────────────────────────────────────────────────────────────────
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'سياسة الخصوصية',
      icon: Icons.privacy_tip_outlined,
      sections: [
        _LegalSection(
          title: '1. المعلومات التي نجمعها',
          content:
              'نجمع رقم الهاتف عند التسجيل، والموقع الجغرافي عند رفع التعميمات '
              '(بموافقتك)، والصور والوصف التي ترفعها طوعاً.',
        ),
        _LegalSection(
          title: '2. كيف نستخدم معلوماتك',
          content:
              'تُستخدم المعلومات لعرض التعميمات على الخريطة، وإرسال الإشعارات '
              'للمستخدمين القريبين، وتحسين جودة التطبيق.',
        ),
        _LegalSection(
          title: '3. مشاركة البيانات',
          content:
              'لا نبيع بياناتك لأي طرف. قد تُشارك البيانات مع الجهات الأمنية '
              'عند وجود مخالفات قانونية مثبتة وفق أنظمة المملكة.',
        ),
        _LegalSection(
          title: '4. تخزين البيانات وأمانها',
          content:
              'تُخزَّن بياناتك على خوادم Firebase في منطقة الشرق الأوسط '
              '(me-central1). نستخدم تشفير SSL لكل الاتصالات.',
        ),
        _LegalSection(
          title: '5. حقوقك',
          content:
              'يحق لك طلب حذف حسابك وجميع بياناتك في أي وقت عبر صفحة الإعدادات. '
              'يتم تنفيذ الطلب خلال 30 يوماً.',
        ),
        _LegalSection(
          title: '6. ملفات الارتباط (Cookies)',
          content:
              'لا يستخدم التطبيق ملفات ارتباط. نستخدم SharedPreferences محلياً '
              'لحفظ تفضيلاتك على جهازك فقط.',
        ),
        _LegalSection(
          title: '7. تحديثات السياسة',
          content:
              'قد يُحدَّث هذا السياسة بإشعار مسبق داخل التطبيق. '
              'استمرار استخدامك بعد الإشعار يُعدّ موافقة.',
        ),
        _LegalSection(
          title: '8. التواصل',
          content:
              'للاستفسار عن بياناتك: privacy@taameem.sa',
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  شروط الاستخدام
// ──────────────────────────────────────────────────────────────────────────────
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'شروط الاستخدام',
      icon: Icons.gavel_outlined,
      sections: [
        _LegalSection(
          title: '1. القبول بالشروط',
          content:
              'بمجرد تحميل أو استخدام تطبيق تعميم، فإنك توافق بشكل كامل '
              'على هذه الشروط. إذا لم توافق، يُرجى التوقف عن الاستخدام فوراً.',
        ),
        _LegalSection(
          title: '2. طبيعة الخدمة',
          content:
              'تعميم منصة تفاعلية مجتمعية تعتمد على الذكاء الاصطناعي '
              'والخرائط لنشر التعميمات. لا تتحمل إدارة التطبيق مسؤولية '
              'دقة أو صحة ما ينشره المستخدمون.',
        ),
        _LegalSection(
          title: '3. المحظورات',
          content:
              'يُحظر تماماً:\n'
              '• نشر تعميمات كاذبة أو مضللة أو كيدية\n'
              '• انتهاك خصوصية الآخرين أو التشهير بهم\n'
              '• نشر محتوى يخالف الأنظمة السعودية\n'
              '• محاولة اختراق التطبيق أو التلاعب بـ API',
        ),
        _LegalSection(
          title: '4. العقوبات',
          content:
              'عند المخالفة: حذف التعميم، إيقاف الحساب، وتسليم البيانات '
              'للجهات الأمنية عند الاقتضاء.',
        ),
        _LegalSection(
          title: '5. الملكية الفكرية',
          content:
              'تطبيق تعميم وشعاره وتصميمه محمية بموجب قوانين الملكية الفكرية. '
              'المحتوى الذي ترفعه يبقى ملكاً لك مع منحنا ترخيصاً لعرضه.',
        ),
        _LegalSection(
          title: '6. التلاشي الزمني',
          content:
              'تنتهي التعميمات تلقائياً بعد المدة المحددة لكل نوع. '
              'يُرسَل تنبيه قبل الانتهاء لتجديد التعميم إذا رغبت.',
        ),
        _LegalSection(
          title: '7. إخلاء المسؤولية',
          content:
              'الذكاء الاصطناعي قد يُخطئ في التصنيف. لا تعتمد على التطبيق '
              'كمصدر وحيد في حالات الطوارئ. اتصل بالجهات الرسمية عند الحاجة.',
        ),
        _LegalSection(
          title: '8. القانون المطبّق',
          content:
              'تخضع هذه الشروط لأنظمة المملكة العربية السعودية '
              'وتُحسم النزاعات أمام المحاكم السعودية المختصة.',
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  قالب مشترك للصفحات القانونية
// ──────────────────────────────────────────────────────────────────────────────
class _LegalScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_LegalSection> sections;

  const _LegalScreen({
    required this.title,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // رأس الصفحة
              Padding(
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
                    Icon(icon, size: 22, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: sections.length,
                  itemBuilder: (_, i) => GlassCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sections[i].title,
                          style: const TextStyle(fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sections[i].content,
                          style: const TextStyle(fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: AppColors.forestGreen,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: 60 * i))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String content;
  const _LegalSection({required this.title, required this.content});
}

