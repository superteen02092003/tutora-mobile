import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_status_pill.dart';

/// Compact lesson summary row — date block, subject/tutor/time, status pill.
/// Used by the home dashboard, lessons list and calendar day view.
class ParentLessonRow extends StatelessWidget {
  const ParentLessonRow({required this.lesson, this.onTap, super.key});

  final ParentLessonDto lesson;
  final VoidCallback? onTap;

  String _h(int v) => v.toString().padLeft(2, '0');

  bool _isStartingSoon(DateTime start) {
    final diff = start.difference(DateTime.now());
    return !diff.isNegative && diff.inMinutes <= 60;
  }

  @override
  Widget build(BuildContext context) {
    final start = lesson.startDt;
    const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dow = dayNames[(start.weekday - 1) % 7];
    final isPending = lesson.isPendingConfirm;
    final isStarting = _isStartingSoon(start);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              top: const BorderSide(color: AppColors.line),
              right: const BorderSide(color: AppColors.line),
              bottom: const BorderSide(color: AppColors.line),
              left: BorderSide(
                color: isPending
                    ? AppColors.gold
                    : isStarting
                    ? AppColors.oxblood
                    : AppColors.line,
                width: isPending || isStarting ? 3 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dow,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink3,
                      ),
                    ),
                    Text(
                      _h(start.day),
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        height: 1,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.subjectName ?? lesson.studentName ?? 'Buổi học',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${lesson.tutorName ?? '—'} · ${_h(start.hour)}:${_h(start.minute)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(),
                    ),
                  ],
                ),
              ),
              ParentStatusPill(
                status: lesson.status,
                isPendingConfirm: isPending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
