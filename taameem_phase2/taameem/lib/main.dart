import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

// ملاحظة: firebase_options.dart يُنشأ تلقائياً عند تشغيل: flutterfire configure
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد شريط الحالة الشفاف
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // تثبيت الاتجاه العمودي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Firebase (سيعمل بعد تشغيل flutterfire configure)
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // تجاهل الخطأ أثناء التطوير قبل ربط Firebase
    debugPrint('Firebase init: $e');
  }

  runApp(const TaameemApp());
}

class TaameemApp extends StatelessWidget {
  const TaameemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تعميم',
      debugShowCheckedModeBanner: false,

      // ─── اتجاه RTL كامل ───────────────────────────────────────────────────
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // ─── Theme ────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,

      // ─── الشاشة الأولى ────────────────────────────────────────────────────
      home: const SplashScreen(),
    );
  }
}
