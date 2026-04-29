import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

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
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.bricolageGrotesque(fontSize: 57, fontWeight: FontWeight.w800),
          displayMedium: GoogleFonts.bricolageGrotesque(fontSize: 45, fontWeight: FontWeight.w800),
          displaySmall: GoogleFonts.bricolageGrotesque(fontSize: 36, fontWeight: FontWeight.w800),
          headlineLarge: GoogleFonts.bricolageGrotesque(fontSize: 32, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.bricolageGrotesque(fontSize: 28, fontWeight: FontWeight.w700),
          headlineSmall: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w700),
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
            foregroundColor: AppColors.cream,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.line, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
        dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 0),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.paper,
          selectedItemColor: AppColors.ink,
          unselectedItemColor: AppColors.ink4,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
