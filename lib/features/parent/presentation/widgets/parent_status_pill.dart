import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

class ParentStatusPill extends StatelessWidget {
  const ParentStatusPill({
    required this.status,
    this.isPendingConfirm = false,
    super.key,
  });

  final String? status;
  final bool isPendingConfirm;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = isPendingConfirm
        ? ('Chờ xác nhận', const Color(0xFFF0E3CA), const Color(0xFF5C3A1A))
        : switch (status) {
            'completed' => (
              'Hoàn thành',
              const Color(0xFFE0E7DF),
              AppColors.green,
            ),
            'in_progress' => (
              'Đang học',
              const Color(0xFFFBE4D8),
              AppColors.oxblood,
            ),
            'pending_confirmation' => (
              'Chờ xác nhận',
              const Color(0xFFF0E3CA),
              const Color(0xFF5C3A1A),
            ),
            'scheduled' => (
              'Đã lên lịch',
              const Color(0xFFF1ECE0),
              AppColors.ink3,
            ),
            'reserved' => (
              'Chờ gia sư nhận',
              const Color(0xFFF0E3CA),
              const Color(0xFF5C3A1A),
            ),
            'disputed' => (
              'Tranh chấp',
              const Color(0xFFFBE4D8),
              AppColors.oxblood,
            ),
            'no_show' => ('Vắng mặt', const Color(0xFFF1ECE0), AppColors.ink4),
            'cancelled' ||
            'cancelled_noshow' ||
            'cancelled_by_staff' ||
            'cancelled_by_dispute' => (
              'Đã huỷ',
              const Color(0xFFF1ECE0),
              AppColors.ink4,
            ),
            _ => ('—', const Color(0xFFF1ECE0), AppColors.ink4),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
