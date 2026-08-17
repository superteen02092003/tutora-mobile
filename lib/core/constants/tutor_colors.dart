import 'package:flutter/material.dart';

abstract final class TutorColors {
  static const Color bg = Color(0xFFF8F9FC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceSunken = Color(0xFFF1F3F9);

  static const Color ink = Color(0xFF141C2E);
  static const Color ink2 = Color(0xFF3D4759);
  static const Color ink3 = Color(0xFF6B7689);
  static const Color ink4 = Color(0xFF98A1B2);

  static const Color line = Color(0xFFE4E8F0);

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryBg = Color(0xFFEBF2FF);
  static const Color primaryBorder = Color(0xFFD3E2FF);

  static const Color accent = Color(0xFFF97316);
  static const Color accentBg = Color(0xFFFFF1E6);
  static const Color accentBorder = Color(0xFFFFDCC2);

  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFE9F9EF);
  static const Color successBorder = Color(0xFFC7EED6);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF5E7);
  static const Color warningBorder = Color(0xFFFAE3BC);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFDECEC);
  static const Color dangerBorder = Color(0xFFF8CFCF);

  static const Color heroInk = Color(0xFF1B2A52);
  static const Color heroInkBg = Color(0xFFF0F3FF);

  static const Color heroTeal = Color(0xFF0D9488);
  static const Color heroTealBg = Color(0xFFEAF8F6);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF141C2E).withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get raisedCardShadow => [
    BoxShadow(
      color: const Color(0xFF141C2E).withValues(alpha: 0.09),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFF141C2E).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> heroShadow(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static const List<Color> avatarPalette = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFF97316),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF16A34A),
  ];
}
