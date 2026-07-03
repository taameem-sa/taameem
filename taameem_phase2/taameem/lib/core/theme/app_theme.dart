import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.creamWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.emerald,
        secondary: AppColors.gold,
        tertiary: AppColors.mint,
        surface: AppColors.warmBeige,
        onPrimary: AppColors.white,
        onSecondary: AppColors.nearBlack,
        onSurface: AppColors.forestGreen,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    final cairoBase = GoogleFonts.cairoTextTheme();
    return cairoBase.copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: AppColors.nearBlack,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.nearBlack,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: AppColors.forestGreen,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.forestGreen,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.forestGreen,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.nearBlack,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.forestGreen,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.nearBlack,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.forestGreen,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.grey,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.creamWhite,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.nearBlack,
      ),
      iconTheme: const IconThemeData(color: AppColors.forestGreen),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        textStyle: GoogleFonts.cairo(
          fontSize: 16, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.warmBeige,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.emerald.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.emerald,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      hintStyle: GoogleFonts.cairo(
        color: AppColors.grey,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.cairo(
        color: AppColors.forestGreen,
        fontSize: 14,
      ),
    );
  }

  static CardTheme _buildCardTheme() {
    return CardTheme(
      color: AppColors.glassBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.creamWhite,
      selectedItemColor: AppColors.emerald,
      unselectedItemColor: AppColors.grey,
      selectedLabelStyle: GoogleFonts.cairo(
        fontSize: 11, fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.cairo(
        fontSize: 11, fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }
}
