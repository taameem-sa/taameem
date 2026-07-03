import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Marble Palette الرئيسية ───────────────────────────────────────────────
  static const Color creamWhite   = Color(0xFFFDFCF8); // الخلفية الرئيسية
  static const Color warmBeige    = Color(0xFFE8E0D0); // خلفيات البطاقات الداخلية
  static const Color gold         = Color(0xFFB8943A); // الشعار والخطوط المضيئة
  static const Color lightGold    = Color(0xFFD4A84B); // التفاصيل والأيقونات
  static const Color mint         = Color(0xFF7BBFB0); // الأكوار الخلفية
  static const Color emerald      = Color(0xFF3D8F7E); // الأزرار والعناصر الرئيسية
  static const Color forestGreen  = Color(0xFF235C4E); // النصوص والعناوين
  static const Color nearBlack    = Color(0xFF1A3028); // العناوين الكبيرة

  // ─── Glassmorphism ────────────────────────────────────────────────────────
  static Color get glassBackground  => const Color(0xFFFDFCF8).withValues(alpha: 0.72);
  static Color get glassBorder      => const Color(0xFF3D8F7E).withValues(alpha: 0.22);
  static Color get glassShadow      => const Color(0xFF3D8F7E).withValues(alpha: 0.08);
  static Color get goldGlow         => const Color(0xFFB8943A).withValues(alpha: 0.15);

  // ─── ألوان أنواع التعميمات ─────────────────────────────────────────────────
  static const Color missingPerson  = Color(0xFFE6D13A); // فقدان أشخاص
  static const Color foundItem      = Color(0xFF9DD49A); // إيجاد شيء (غامق قليلاً للوضوح)
  static const Color lostItem       = Color(0xFFC23A9C); // فقدان شيء
  static const Color theft          = Color(0xFFF2C928); // سرقة واعتداء
  static const Color helpRequest    = Color(0xFFF0651E); // استغاثة
  static const Color humanitarian   = Color(0xFFC8B97C); // إنساني
  static const Color emergency      = Color(0xFFD63B3B); // طارئ
  static const Color generalWarning = Color(0xFFDBA73A); // تحذير عام
  static const Color lostAnimal     = Color(0xFFD4DB3A); // فقدان حيوانات
  static const Color inquiry        = Color(0xFFAA8A38); // استفسار

  // ─── ألوان النظام ──────────────────────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color black       = Color(0xFF000000);
  static const Color grey        = Color(0xFF9E9E9E);
  static const Color lightGrey   = Color(0xFFEEEEEE);
  static const Color error       = Color(0xFFD63B3B);
  static const Color success     = Color(0xFF3D8F7E);

  // ─── Map Overlay ──────────────────────────────────────────────────────────
  static Color get mapOverlay => const Color(0xFF1A3028).withValues(alpha: 0.04);
  static Color get mapCardBg  => const Color(0xFFFDFCF8).withValues(alpha: 0.95);
}
