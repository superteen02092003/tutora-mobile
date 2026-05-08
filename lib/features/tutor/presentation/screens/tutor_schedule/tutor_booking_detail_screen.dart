import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_schedule_screen.dart';
import 'package:tutora/shared/widgets/status_chip.dart';

class TutorBookingDetailScreen extends StatelessWidget {
  const TutorBookingDetailScreen({required this.lesson, super.key});

  final TutorLessonDto lesson;

  (String, ChipTone) get _chip => lessonChip(lesson.status);

  Color get _heroColor => switch (lesson.status.toLowerCase()) {
    'scheduled' || 'confirmed' => const Color(0xFFFFF3CD),
    'inprogress' => const Color(0xFFD5EDD9),
    'completed' => const Color(0xFFD5E8F5),
    _ => const Color(0xFFFFDEDE),
  };

  Color get _heroBorder => switch (lesson.status.toLowerCase()) {
    'scheduled' || 'confirmed' => const Color(0xFF7A5900),
    'inprogress' => AppColors.moss,
    'completed' => const Color(0xFF0D3F6B),
    _ => AppColors.oxblood,
  };

  bool get _isDone =>
      lesson.status.toLowerCase() == 'completed' ||
      lesson.status.toLowerCase() == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final (chipLabel, chipTone) = _chip;
    final dt = lesson.startDt;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Text(
                      'Chi tiết buổi dạy',
                      style: AppTextStyles.h3(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 24),
                children: [
                  // Hero card
                  _HeroCard(
                    lesson: lesson,
                    chipLabel: chipLabel,
                    chipTone: chipTone,
                    heroColor: _heroColor,
                    heroBorder: _heroBorder,
                  ),
                  const SizedBox(height: 12),

                  // Student info card
                  _InfoCard(
                    child: Row(
                      children: [
                        _Avatar(name: lesson.studentName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.studentName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Học sinh · ${lesson.subjectName}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.ink4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OutlineBtn(label: 'Nhắn tin', onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timeline
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TIẾN TRÌNH', style: AppTextStyles.eyebrow()),
                        const SizedBox(height: 14),
                        const _TimelineStep(
                          label: 'Đã xếp lịch',
                          done: true,
                          isLast: false,
                        ),
                        _TimelineStep(
                          label: 'Đang diễn ra',
                          done: ['inprogress', 'completed'].contains(
                            lesson.status.toLowerCase(),
                          ),
                          isLast: false,
                        ),
                        _TimelineStep(
                          label: 'Hoàn thành',
                          done: lesson.status.toLowerCase() == 'completed',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date / time info
                  _InfoCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Ngày',
                          value: dt != null
                              ? '${dt.day} tháng ${dt.month}, ${dt.year}'
                              : '—',
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Giờ',
                          value: '${lesson.timeStart} – ${lesson.timeEnd}',
                        ),
                        if (lesson.teachingMode != null) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.cast_for_education_rounded,
                            label: 'Hình thức',
                            value: lesson.teachingMode!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status note
                  if (!_isDone)
                    _InfoCard(
                      color: AppColors.cream2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.ink3,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Học sinh sẽ thanh toán qua escrow. Tiền sẽ được giải ngân sau buổi học hoàn thành.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.ink3,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (lesson.status.toLowerCase() == 'completed')
                    _InfoCard(
                      color: const Color(0xFFD5E8F5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: Color(0xFF0D3F6B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buổi học đã hoàn thành',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D3F6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (lesson.status.toLowerCase() == 'cancelled')
                    _InfoCard(
                      color: const Color(0xFFFFDEDE),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            size: 18,
                            color: AppColors.oxblood,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buổi học đã bị huỷ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.oxblood,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.lesson,
    required this.chipLabel,
    required this.chipTone,
    required this.heroColor,
    required this.heroBorder,
  });

  final TutorLessonDto lesson;
  final String chipLabel;
  final ChipTone chipTone;
  final Color heroColor;
  final Color heroBorder;

  @override
  Widget build(BuildContext context) {
    final dt = lesson.startDt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: heroColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: heroBorder.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(label: chipLabel, tone: chipTone),
          const SizedBox(height: 10),
          Text(
            lesson.subjectName,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.01,
            ),
          ),
          if (dt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${dt.day} tháng ${dt.month}, ${dt.year}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.ink3,
              ),
              const SizedBox(width: 4),
              Text(
                '${lesson.timeStart} – ${lesson.timeEnd}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: color == null ? Border.all(color: AppColors.line) : null,
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.ink3),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          ),
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.done,
    required this.isLast,
  });
  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.ink : AppColors.line,
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.cream,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 20,
                color: done ? AppColors.ink : AppColors.line,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 10),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
              color: done ? AppColors.ink : AppColors.ink4,
            ),
          ),
        ),
      ],
    );
  }
}
