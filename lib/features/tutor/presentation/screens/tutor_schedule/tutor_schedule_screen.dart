import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_booking_detail_screen.dart';
import 'package:tutora/shared/widgets/app_calendar.dart';
import 'package:tutora/shared/widgets/status_chip.dart';

class TutorScheduleScreen extends ConsumerStatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  ConsumerState<TutorScheduleScreen> createState() =>
      _TutorScheduleScreenState();
}

enum _ViewMode { calendar, list }

class _TutorScheduleScreenState extends ConsumerState<TutorScheduleScreen> {
  _ViewMode _viewMode = _ViewMode.calendar;
  DateTime? _selectedDate;

  List<TutorLessonDto> _dayLessons(List<TutorLessonDto> all) {
    final d = _selectedDate;
    if (d == null) return [];
    return all.where((b) => b.isSameDay(d)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final schedState = ref.watch(tutorScheduleProvider);
    final lessons = schedState.lessons;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              viewMode: _viewMode,
              onViewChange: (v) => setState(() {
                _viewMode = v;
                _selectedDate = null;
              }),
            ),
            if (schedState.isLoading && lessons.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(tutorScheduleProvider.notifier)
                      .loadCurrentMonth(),
                  child: _viewMode == _ViewMode.calendar
                      ? _CalendarView(
                          lessons: lessons,
                          selectedDate: _selectedDate,
                          onSelectDate: (d) =>
                              setState(() => _selectedDate = d),
                          dayLessons: _dayLessons(lessons),
                          bottomPad: bottomPad,
                        )
                      : _LessonListView(
                          lessons: lessons,
                          bottomPad: bottomPad,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.viewMode, required this.onViewChange});
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Lịch dạy', style: AppTextStyles.h2())),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconToggleBtn(
                  active: viewMode == _ViewMode.calendar,
                  onTap: () => onViewChange(_ViewMode.calendar),
                  icon: Icons.calendar_month_outlined,
                ),
                _IconToggleBtn(
                  active: viewMode == _ViewMode.list,
                  onTap: () => onViewChange(_ViewMode.list),
                  icon: Icons.format_list_bulleted_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconToggleBtn extends StatelessWidget {
  const _IconToggleBtn({
    required this.active,
    required this.onTap,
    required this.icon,
  });
  final bool active;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 15,
          color: active ? AppColors.cream : AppColors.ink4,
        ),
      ),
    );
  }
}

// ── Calendar View ───────────────────────────────────────────────────────────

class _CalendarView extends StatelessWidget {
  const _CalendarView({
    required this.lessons,
    required this.selectedDate,
    required this.onSelectDate,
    required this.dayLessons,
    required this.bottomPad,
  });

  final List<TutorLessonDto> lessons;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final List<TutorLessonDto> dayLessons;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.xxl),
      children: [
        const SizedBox(height: 12),
        AppCalendar(
          selectedDate: selectedDate,
          sessionCountForDay: (y, m, d) => lessons.where((b) {
            final dt = b.startDt;
            return dt != null && dt.year == y && dt.month == m && dt.day == d;
          }).length,
          onSelectDate: onSelectDate,
        ),
        if (selectedDate != null && dayLessons.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DayStrip(date: selectedDate!, lessons: dayLessons),
        ],
        if (selectedDate != null && dayLessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Text(
              'Không có buổi dạy ngày ${selectedDate!.day}/${selectedDate!.month}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'BUỔI DẠY THÁNG ${now.month}',
            style: AppTextStyles.eyebrow(),
          ),
        ),
        ...lessons.map(
          (b) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _TeachingCard(
              lesson: b,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TutorBookingDetailScreen(lesson: b),
                ),
              ),
            ),
          ),
        ),
        _MonthlySummary(lessons: lessons),
      ],
    );
  }
}

// ── List View (swipeable tabs) ──────────────────────────────────────────────

const _kTabs = <(String, String?)>[
  ('Tất cả', null),
  ('Chờ', 'scheduled'),
  ('Đang dạy', 'inprogress'),
  ('Hoàn thành', 'completed'),
  ('Đã huỷ', 'cancelled'),
];

class _LessonListView extends StatefulWidget {
  const _LessonListView({
    required this.lessons,
    required this.bottomPad,
  });

  final List<TutorLessonDto> lessons;
  final double bottomPad;

  @override
  State<_LessonListView> createState() => _LessonListViewState();
}

class _LessonListViewState extends State<_LessonListView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _kTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<TutorLessonDto> _forTab(int i) {
    final status = _kTabs[i].$2;
    if (status == null) return widget.lessons;
    return widget.lessons
        .where((l) => l.status.toLowerCase() == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.line, width: 0.8),
            ),
          ),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            indicatorColor: AppColors.ink,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.ink3,
            ),
            dividerColor: Colors.transparent,
            tabs: _kTabs.map((t) => Tab(text: t.$1, height: 40)).toList(),
          ),
        ),
        // Swipeable pages
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: List.generate(_kTabs.length, (i) {
              final items = _forTab(i);
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/common/empty_calendar.png',
                        width: 220,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Không có buổi dạy nào',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  widget.bottomPad + AppSpacing.xxl,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, j) => _TeachingCard(
                  lesson: items[j],
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TutorBookingDetailScreen(lesson: items[j]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

(String, ChipTone) lessonChip(String status) => switch (status.toLowerCase()) {
  'scheduled' || 'confirmed' => ('Sắp diễn ra', ChipTone.gold),
  'inprogress' => ('Đang dạy', ChipTone.moss),
  'completed' => ('Hoàn thành', ChipTone.ink),
  _ => ('Đã huỷ', ChipTone.ox),
};

Color _lessonBarColor(String status) => switch (status.toLowerCase()) {
  'scheduled' || 'confirmed' => const Color(0xFF7A5900),
  'inprogress' => AppColors.moss,
  'completed' => const Color(0xFF0D3F6B),
  _ => AppColors.oxblood,
};

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.date, required this.lessons});
  final DateTime date;
  final List<TutorLessonDto> lessons;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.day} THÁNG ${date.month}',
            style: AppTextStyles.eyebrow(),
          ),
          const SizedBox(height: 10),
          ...lessons.map((b) {
            final (label, tone) = lessonChip(b.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _lessonBarColor(b.status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.subjectName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${b.timeStart}–${b.timeEnd} · ${b.studentName}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.ink4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(label: label, tone: tone),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TeachingCard extends StatelessWidget {
  const _TeachingCard({required this.lesson, this.onTap});
  final TutorLessonDto lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = lessonChip(lesson.status);
    final dt = lesson.startDt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dt != null ? '${dt.day}' : '—',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                  Text(
                    dt != null ? 'Thg${dt.month}' : '',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      color: AppColors.ink4,
                      letterSpacing: 0.04,
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
                    lesson.studentName,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${lesson.subjectName} · ${lesson.timeStart}–${lesson.timeEnd}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(label: label, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.lessons});
  final List<TutorLessonDto> lessons;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final completed = lessons
        .where((l) => l.status.toLowerCase() == 'completed')
        .length;
    final students = lessons.map((l) => l.studentName).toSet().length;
    final totalMinutes = lessons.fold<int>(0, (acc, l) {
      final s = l.startDt;
      final e = l.endDt;
      if (s == null || e == null) return acc;
      return acc + e.difference(s).inMinutes;
    });
    final hours = totalMinutes ~/ 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG KẾT THÁNG ${now.month}',
                style: AppTextStyles.eyebrow(color: AppColors.gold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      value: '${lessons.length}',
                      label: 'Số buổi',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      value: '${hours}h',
                      label: 'Tổng giờ',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      value: '$completed',
                      label: 'Hoàn thành',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      value: '$students',
                      label: 'Học sinh',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.gold,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.cream.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
