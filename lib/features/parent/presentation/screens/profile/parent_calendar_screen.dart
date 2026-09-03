import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_page_header.dart';

class ParentCalendarPage extends ConsumerStatefulWidget {
  const ParentCalendarPage({super.key});

  @override
  ConsumerState<ParentCalendarPage> createState() => _ParentCalendarPageState();
}

class _ParentCalendarPageState extends ConsumerState<ParentCalendarPage> {
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() => ref.read(parentDashboardProvider.notifier).load()),
    );
  }

  void _prevMonth() => setState(
    () => _focusedMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month - 1,
    ),
  );

  void _nextMonth() => setState(
    () => _focusedMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
    ),
  );

  List<ParentLessonDto> _lessonsForDay(
    List<ParentLessonDto> all,
    DateTime day,
  ) {
    return all.where((l) {
      final d = l.startDt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(parentDashboardProvider);
    final allLessons = dash.weekLessons;

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    // weekday: 1=Mon…7=Sun, shift so grid starts on Mon
    final startOffset = (firstDay.weekday - 1) % 7;

    const monthNames = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];

    final selectedDay = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ParentPageHeader(title: 'Lịch học tổng hợp'),
            Expanded(
              child: dash.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.ink),
                    )
                  : ListView(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).padding.bottom +
                            AppSpacing.xxl,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              children: [
                                // Month header
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _prevMonth,
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                        color: AppColors.ink,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _nextMonth,
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.ink,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Day-of-week headers
                                Row(
                                  children:
                                      ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                                          .map(
                                            (d) => Expanded(
                                              child: Text(
                                                d,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.ink4,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                                const SizedBox(height: 6),
                                // Calendar grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 4,
                                      ),
                                  itemCount: startOffset + daysInMonth,
                                  itemBuilder: (context, idx) {
                                    if (idx < startOffset) {
                                      return const SizedBox();
                                    }
                                    final day = idx - startOffset + 1;
                                    final date = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month,
                                      day,
                                    );
                                    final isToday =
                                        date.year == selectedDay.year &&
                                        date.month == selectedDay.month &&
                                        date.day == selectedDay.day;
                                    final lessons = _lessonsForDay(
                                      allLessons,
                                      date,
                                    );
                                    final hasLesson = lessons.isNotEmpty;

                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isToday
                                                ? AppColors.ink
                                                : Colors.transparent,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$day',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isToday
                                                  ? AppColors.cream
                                                  : AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        if (hasLesson)
                                          Container(
                                            width: 4,
                                            height: 4,
                                            margin: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.oxblood,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const _SectionHeader('Tất cả buổi học trong tuần'),
                        if (allLessons.isEmpty)
                          const _EmptyState(
                            icon: Icons.event_busy_outlined,
                            message: 'Không có buổi học nào trong tuần này',
                          )
                        else
                          ...allLessons.map(
                            (l) => _CalendarLessonRow(lesson: l),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.12,
          color: AppColors.ink4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.ink4),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodySmall(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CalendarLessonRow extends StatelessWidget {
  const _CalendarLessonRow({required this.lesson});
  final ParentLessonDto lesson;

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime dt) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayLabel = days[(dt.weekday - 1) % 7];
    return '$dayLabel ${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final start = lesson.startDt;
    final end = lesson.endDt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.oxblood,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lesson.studentName ?? 'Học sinh'} · ${lesson.subjectName ?? ''}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtDate(start)}  ${_fmt(start)} – ${_fmt(end)}',
                    style: AppTextStyles.bodySmall(),
                  ),
                  if (lesson.tutorName != null)
                    Text(
                      'Gia sư: ${lesson.tutorName}',
                      style: AppTextStyles.bodySmall(),
                    ),
                ],
              ),
            ),
            _StatusDot(lesson.status),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(this.status);
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppColors.green,
      'checkedin' || 'scheduled' => const Color(0xFF3D6EEA),
      'cancelled' || 'noshow' => AppColors.oxblood,
      _ => AppColors.ink4,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
