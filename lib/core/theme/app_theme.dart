import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.cream,
      secondary: AppColors.oxblood,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.ink,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    // V5.6: snackbar xanh rêu bo tròn, hộp thoại bo 20, nút dạng viên thuốc.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: AppColors.sage,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: AppColors.ink3,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.ink : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.ink : null,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.ink,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 57,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 45,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.bricolageGrotesque(
        fontSize: 36,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.line,
      titleTextStyle: GoogleFonts.bricolageGrotesque(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.paper,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.ink4, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: AppColors.ink3, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.paper,
      selectedItemColor: AppColors.ink,
      unselectedItemColor: AppColors.ink4,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
