import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/presentation/screens/student_session_detail_screen.dart';
import 'package:tutora/mock/student_lessons_mock.dart';
import 'package:tutora/shared/widgets/app_calendar.dart';
import 'package:tutora/shared/widgets/app_logo.dart';

class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Keep segmented control in sync when user swipes
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              showCalendar: _showCalendar,
              onToggle: () => setState(() => _showCalendar = !_showCalendar),
            ),
            if (_showCalendar) ...[
              const Expanded(child: _CalendarView()),
            ] else ...[
              _TodayCard(lessons: kTodayLessons),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SegmentedTabs(
                  selected: _tabs.index,
                  onSelect: (i) => _tabs.animateTo(i),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _SessionListView(lessons: kUpcomingLessons),
                    _SessionListView(lessons: kDoneLessons),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showCalendar, required this.onToggle});
  final bool showCalendar;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(size: 13),
          Expanded(
            child: Text(
              'Lịch học',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSerif(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showCalendar ? AppColors.ink : AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(
                showCalendar
                    ? Icons.view_list_rounded
                    : Icons.calendar_month_outlined,
                size: 16,
                color: showCalendar ? AppColors.cream : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.lessons});
  final List<MockLesson> lessons;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox(height: 4);
    final times = lessons.map((l) => l.timeStart).join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hôm nay · 30 tháng 4',
                      style: AppTextStyles.eyebrow(color: AppColors.gold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lessons.length} buổi học',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.1,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      times,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.cream.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.gold.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '30',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.gold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'T4',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 8,
                        color: AppColors.cream.withValues(alpha: 0.6),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  static const _labels = ['Sắp tới', 'Đã xong'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.cream : AppColors.ink3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SessionListView extends StatelessWidget {
  const _SessionListView({required this.lessons});
  final List<MockLesson> lessons;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Center(
        child: Text(
          'Không có buổi học nào.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, AppSpacing.xxl),
      itemCount: lessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _SessionCard(lesson: lessons[i]),
    );
  }
}

// ── Session card ───────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.lesson});
  final MockLesson lesson;

  Color get _dividerColor => switch (lesson.status) {
    LessonStatus.upcoming => AppColors.oxblood,
    LessonStatus.confirmed => AppColors.moss,
    _ => AppColors.line,
  };

  _ChipStyle get _chipStyle => switch (lesson.status) {
    LessonStatus.upcoming => (
      bg: AppColors.oxblood,
      fg: const Color(0xFFFFF1E6),
      label: 'Sắp diễn ra',
    ),
    LessonStatus.confirmed => (
      bg: AppColors.moss,
      fg: const Color(0xFFE0E7DF),
      label: 'Đã xác nhận',
    ),
    LessonStatus.pending => (
      bg: const Color(0xFFF0E3CA),
      fg: const Color(0xFF5C3A1A),
      label: 'Chờ xác nhận',
    ),
    LessonStatus.done => (
      bg: AppColors.cream2,
      fg: AppColors.ink3,
      label: 'Hoàn thành',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final chip = _chipStyle;
    final isDone = lesson.status == LessonStatus.done;

    return Opacity(
      opacity: isDone ? 0.75 : 1.0,
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => StudentSessionDetailPage(lesson: lesson),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              // Time block
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Text(
                      lesson.timeStart,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.date,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              // Colored vertical divider
              Container(
                width: 2,
                height: 52,
                decoration: BoxDecoration(
                  color: _dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.topic,
                      style: GoogleFonts.ibmPlexSerif(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${lesson.tutorName} · ${lesson.subject}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.ink3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: chip.bg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            chip.label,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: chip.fg,
                              letterSpacing: 0.06,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lesson.priceK}k',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _ChipStyle = ({Color bg, Color fg, String label});

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _selected = DateTime(2026, 4, 30);

  String get _dayHeader {
    final today = DateTime.now();
    if (_selected.year == today.year &&
        _selected.month == today.month &&
        _selected.day == today.day) {
      return 'Hôm nay · ${_selected.day} tháng ${_selected.month}';
    }
    return 'Ngày ${_selected.day} tháng ${_selected.month}';
  }

  List<MockLesson> get _selectedSessions {
    if (_selected.year == 2026 && _selected.month == 4) {
      return kMockAprilSessions[_selected.day] ?? [];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 4),
        AppCalendar(
          selectedDate: _selected,
          sessionCountForDay: (y, m, d) {
            if (y == 2026 && m == 4) return kMockSessionDaysApril[d] ?? 0;
            return 0;
          },
          onSelectDate: (date) => setState(() => _selected = date),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            _dayHeader.toUpperCase(),
            style: AppTextStyles.eyebrow(color: AppColors.ink3),
          ),
        ),
        if (_selectedSessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'Không có buổi học nào ngày này.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
              ),
            ),
          )
        else
          for (int i = 0; i < _selectedSessions.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                i < _selectedSessions.length - 1 ? 8 : 0,
              ),
              child: _SessionCard(lesson: _selectedSessions[i]),
            ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
