import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum ChipTone { cream, ink, ox, gold, moss, line }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.cream,
    this.leadingWidget,
  });

  final String label;
  final ChipTone tone;
  final Widget? leadingWidget;

  ({Color bg, Color fg, Border? border}) get _style => switch (tone) {
        ChipTone.cream => (bg: const Color(0xFFF2F0E4), fg: AppColors.ink, border: null),
        ChipTone.ink => (bg: AppColors.ink, fg: AppColors.cream, border: null),
        ChipTone.ox => (bg: AppColors.oxblood, fg: const Color(0xFFFFF1E6), border: null),
        ChipTone.gold => (bg: const Color(0xFFF0E3CA), fg: const Color(0xFF5C3A1A), border: null),
        ChipTone.moss => (bg: const Color(0xFFE0E7DF), fg: AppColors.moss, border: null),
        ChipTone.line => (
            bg: Colors.transparent,
            fg: AppColors.ink,
            border: Border.all(color: AppColors.line),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
        border: s.border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingWidget != null) ...[leadingWidget!, const SizedBox(width: 4)],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 10,
              color: s.fg,
            ),
          ),
        ],
      ),
    );
  }
}
