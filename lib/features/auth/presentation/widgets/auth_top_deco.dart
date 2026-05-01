import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

class AuthTopDeco extends StatelessWidget {
  const AuthTopDeco({
    required this.bgColor,
    required this.line1,
    required this.italicWord,
    required this.line2Suffix,
    super.key,
    this.accentColor = AppColors.gold,
  });

  final Color bgColor;
  final String line1;
  final String italicWord;
  final String line2Suffix;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 190 + statusBarH,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: bgColor)),
          Positioned(
            top: -60,
            right: -40,
            child: Transform.rotate(
              angle: -18 * math.pi / 180,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.4, -0.4),
                    colors: [
                      accentColor.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: statusBarH + 20,
            left: 24,
            child: Text(
              'TUTORA.',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 2,
                color: AppColors.cream.withValues(alpha: 0.85),
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$line1\n',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      letterSpacing: -0.75,
                      height: 1.05,
                      color: AppColors.cream,
                    ),
                  ),
                  TextSpan(
                    text: '"$italicWord"',
                    style: AppTextStyles.serifItalic(
                      color: accentColor,
                      fontSize: 28,
                    ),
                  ),
                  TextSpan(
                    text: ' $line2Suffix',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      letterSpacing: -0.75,
                      height: 1.05,
                      color: AppColors.cream,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    for (var i = 0; i < 6; i++) {
      final x = i * 70.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 0; i < 4; i++) {
      final y = i * 65.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
