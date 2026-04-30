import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../mock/student_lessons_mock.dart';

// ── Page ───────────────────────────────────────────────────────────────────
class StudentLessonsPage extends StatelessWidget {
  const StudentLessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            _TopBar(),
            _Header(),
            _SummaryStrip(),
            _WeekStrip(),
            _UpcomingSection(),
            _CompletedSection(),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(size: 13),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LỊCH HỌC', style: AppTextStyles.eyebrow(color: AppColors.oxblood)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Buổi học ',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.05,
                    letterSpacing: -0.56,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: 'của bạn.',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 26,
                    color: AppColors.ink2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary strip ──────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          _StatPair(value: '${kMockUpcomingLessons.length}', label: 'sắp tới'),
          _dot(),
          _StatPair(value: '${kMockCompletedLessons.length}', label: 'hoàn tất'),
          _dot(),
          const _StatPair(value: '2', label: 'gia sư'),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.line,
          ),
        ),
      );
}

class _StatPair extends StatelessWidget {
  const _StatPair({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
        ),
      ],
    );
  }
}

// ── Week strip ─────────────────────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final day in kMockWeekDays) _DayPill(day: day),
          ],
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day});
  final WeekDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: day.isToday ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: day.isToday ? AppColors.cream : AppColors.ink3,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            day.date,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: day.isToday ? AppColors.cream : AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.hasSession
                  ? (day.isToday
                      ? AppColors.gold
                      : AppColors.oxblood.withValues(alpha: 0.45))
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming section ───────────────────────────────────────────────────────
class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SẮP TỚI · ${kMockUpcomingLessons.length} buổi',
                style: AppTextStyles.eyebrow(),
              ),
              Text(
                'Xem tất cả',
                style: GoogleFonts.ibmPlexSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < kMockUpcomingLessons.length; i++)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, i < kMockUpcomingLessons.length - 1 ? 8 : 0),
            child: _UpcomingCard(lesson: kMockUpcomingLessons[i], isFirst: i == 0),
          ),
      ],
    );
  }
}

typedef _StatusStyle = ({
  ChipTone chip,
  String? ctaLabel,
  bool ctaDark,
  bool showChipOnly,
});

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.lesson, required this.isFirst});
  final MockLesson lesson;
  final bool isFirst;

  _StatusStyle get _style => switch (lesson.status) {
        LessonStatus.upcoming  => (chip: ChipTone.ox,   ctaLabel: 'Vào lớp',  ctaDark: true,  showChipOnly: false),
        LessonStatus.confirmed => (chip: ChipTone.moss,  ctaLabel: 'Chuẩn bị', ctaDark: false, showChipOnly: false),
        LessonStatus.pending   => (chip: ChipTone.line,  ctaLabel: null,        ctaDark: false, showChipOnly: true),
        LessonStatus.completed => (chip: ChipTone.moss,  ctaLabel: null,        ctaDark: false, showChipOnly: true),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          left: BorderSide(
            color: isFirst ? AppColors.oxblood : AppColors.line,
            width: isFirst ? 3 : 1,
          ),
          top: const BorderSide(color: AppColors.line),
          right: const BorderSide(color: AppColors.line),
          bottom: const BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.dayLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
                    letterSpacing: 0.05,
                  ),
                ),
                Text(
                  lesson.timeLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isFirst ? AppColors.oxblood : AppColors.ink,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.line),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(name: lesson.tutorName, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        lesson.tutorName,
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${lesson.subject} · ${lesson.topic}',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.ink3, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // CTA or status chip
          if (s.showChipOnly)
            StatusChip(
              label: lesson.status == LessonStatus.pending ? 'Chờ xác nhận' : 'Hoàn tất',
              tone: s.chip,
            )
          else
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: s.ctaDark ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: s.ctaDark ? null : Border.all(color: AppColors.line),
                ),
                child: Text(
                  s.ctaLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: s.ctaDark ? AppColors.cream : AppColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Completed section ──────────────────────────────────────────────────────
class _CompletedSection extends StatelessWidget {
  const _CompletedSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ĐÃ HOÀN THÀNH', style: AppTextStyles.eyebrow()),
              Text(
                'Xem tất cả',
                style: GoogleFonts.ibmPlexSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < kMockCompletedLessons.length; i++)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, i < kMockCompletedLessons.length - 1 ? 8 : 0),
            child: _CompletedCard(lesson: kMockCompletedLessons[i]),
          ),
      ],
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.lesson});
  final MockLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${lesson.dayLabel}\n${lesson.timeLabel}',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10.5,
                color: AppColors.ink3,
                height: 1.4,
              ),
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.line),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.tutorName,
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.ink2,
                  ),
                ),
                Text(
                  '${lesson.subject} · ${lesson.topic}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.ink3, height: 1.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const StatusChip(label: 'Hoàn tất', tone: ChipTone.moss),
        ],
      ),
    );
  }
}
