import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Cairo';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Cairo', 'Arial', 'sans-serif'],
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        onPrimary: Colors.white,
        secondary: AppColors.navyDark,
        surface: AppColors.cardWhite,
        onSurface: AppColors.textDark,
        error: AppColors.outOfStock,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textDark, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15),
        titleSmall: TextStyle(fontFamily: fontFamily, color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: AppColors.textDark, fontSize: 14),
        bodyMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textSecondary, fontSize: 13),
        bodySmall: TextStyle(fontFamily: fontFamily, color: AppColors.textSecondary, fontSize: 11),
        labelLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 14),
        labelMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 12),
        labelSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500, fontSize: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardWhite,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardWhite,
        modalBackgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDark,
          foregroundColor: Colors.white,
          elevation: 2,
          minimumSize: const Size(64, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyDark,
          minimumSize: const Size(64, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.navyDark, width: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navyDark,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, color: AppColors.textSecondary),
        labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, color: AppColors.navyDark, fontWeight: FontWeight.bold),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        backgroundColor: AppColors.navyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
