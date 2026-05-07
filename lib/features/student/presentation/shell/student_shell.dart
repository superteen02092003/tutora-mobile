import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/shared/widgets/auth_listener.dart';

// Tab order: Home(0) · Search(1) · Capture/AI(2, center bump) · Lessons(3) · Profile(4)
class StudentShell extends StatelessWidget {
  const StudentShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const double _fabSize = 60;
  static const double _bumpRadius = 40;
  static const double _barFlatHeight = 64;
  static const double _fabLift = 18;
  static const double _fabGap = -6;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final totalHeight = _barFlatHeight + _fabLift + bottomPad;

    return Scaffold(
      extendBody: true,
      body: AuthListener(child: navigationShell),
      bottomNavigationBar: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Painted bar with convex bump
            Positioned.fill(
              child: CustomPaint(
                painter: _BumpBarPainter(
                  fabLift: _fabLift,
                  bumpRadius: _bumpRadius,
                  fabGap: _fabGap,
                  color: AppColors.paper,
                  shadowColor: Colors.black.withValues(alpha: 0.8),
                  borderColor: Colors.black.withValues(alpha: 0.18),
                ),
              ),
            ),
            // Tab row sits on the flat portion of the bar
            Positioned(
              left: 0,
              right: 0,
              top: _fabLift,
              height: _barFlatHeight,
              child: Row(
                children: [
                  _NavTab(
                    index: 0,
                    current: current,
                    onTap: _onTap,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Trang chủ',
                  ),
                  _NavTab(
                    index: 1,
                    current: current,
                    onTap: _onTap,
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search_rounded,
                    label: 'Gia sư',
                  ),
                  // Spacer reserves room for the center bump
                  const Expanded(child: SizedBox()),
                  _NavTab(
                    index: 3,
                    current: current,
                    onTap: _onTap,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    label: 'Lịch học',
                  ),
                  _NavTab(
                    index: 4,
                    current: current,
                    onTap: _onTap,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Hồ sơ',
                  ),
                ],
              ),
            ),
            // Center AI button — pushes outside shell so capture has no bottom bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _AiFab(
                  size: _fabSize,
                  isActive: current == 2,
                  onTap: () => context.push('/student/capture'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BumpBarPainter extends CustomPainter {
  _BumpBarPainter({
    required this.fabLift,
    required this.bumpRadius,
    required this.fabGap,
    required this.color,
    required this.shadowColor,
    required this.borderColor,
  });

  final double fabLift;
  final double bumpRadius;
  final double fabGap; // gap between arc apex and FAB top
  final Color color;
  final Color shadowColor;
  final Color borderColor;

  static const double _cornerR = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final flatTop = fabLift;

    // Arc center: apex = cy - bumpRadius = fabGap → cy = bumpRadius + fabGap
    final cy = bumpRadius + fabGap;
    final dy = flatTop - cy;
    final halfChord = math.sqrt(math.max(0, bumpRadius * bumpRadius - dy * dy));

    final leftX = cx - halfChord;
    final rightX = cx + halfChord;

    final startAngle = math.atan2(dy, -halfChord);
    final endAngle = math.atan2(dy, halfChord);
    final sweep = endAngle - startAngle;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, flatTop + _cornerR)
      ..quadraticBezierTo(0, flatTop, _cornerR, flatTop)
      ..lineTo(leftX, flatTop)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: bumpRadius),
        startAngle,
        sweep,
        false,
      )
      // flat right section
      ..lineTo(rightX, flatTop)
      ..lineTo(size.width - _cornerR, flatTop)
      // rounded top-right corner
      ..quadraticBezierTo(size.width, flatTop, size.width, flatTop + _cornerR)
      // right side down
      ..lineTo(size.width, size.height)
      ..close();

    canvas
      ..drawShadow(path, shadowColor, 8, false)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
  }

  @override
  bool shouldRepaint(covariant _BumpBarPainter old) =>
      old.fabLift != fabLift ||
      old.bumpRadius != bumpRadius ||
      old.fabGap != fabGap ||
      old.color != color ||
      old.shadowColor != shadowColor ||
      old.borderColor != borderColor;
}

class _AiFab extends StatelessWidget {
  const _AiFab({
    required this.size,
    required this.isActive,
    required this.onTap,
  });

  final double size;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.oxblood : AppColors.ink,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive
                    ? Icons.document_scanner
                    : Icons.document_scanner_outlined,
                size: 22,
                color: isActive ? const Color(0xFFFFF1E6) : AppColors.cream,
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Normal nav tab ───────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.current,
    required this.onTap,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 22,
              color: selected ? AppColors.ink : AppColors.ink4,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.ink : AppColors.ink4,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
