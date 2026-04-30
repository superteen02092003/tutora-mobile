import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

// Typography
abstract final class AppTextStyles {
  // Display (serif, heavy) — headings, hero text
  static TextStyle display({Color color = AppColors.ink}) =>
      GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02,
        height: 1,
        color: color,
      );

  // Heading levels
  static TextStyle h1({Color color = AppColors.ink}) =>
      display(color: color).copyWith(fontSize: 32);
  static TextStyle h2({Color color = AppColors.ink}) =>
      display(color: color).copyWith(fontSize: 24);
  static TextStyle h3({Color color = AppColors.ink}) =>
      display(color: color).copyWith(fontSize: 20);

  // Body
  static TextStyle body({Color color = AppColors.ink2}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodySmall({Color color = AppColors.ink3}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // Label / UI text
  static TextStyle label({Color color = AppColors.ink}) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.01,
  );

  // Eyebrow (uppercase caption)
  static TextStyle eyebrow({Color color = AppColors.ink4}) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.18,
    color: color,
  );

  // Serif italic — for accent quotes / editorial
  static TextStyle serifItalic({
    Color color = AppColors.ink2,
    double fontSize = 16,
  }) => GoogleFonts.ibmPlexSerif(
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    fontSize: fontSize,
    color: color,
  );
}
