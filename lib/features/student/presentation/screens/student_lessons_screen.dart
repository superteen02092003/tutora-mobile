import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/presentation/providers/class_provider.dart';
import 'package:tutora/features/student/presentation/screens/student_class_detail_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_session_detail_screen.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/shared/models/class_models.dart';
import 'package:tutora/shared/widgets/app_calendar.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/class_widgets.dart';

/// Trang Lịch học — hai chế độ xem:
///  • Danh sách: lớp học (kỳ học với 1 gia sư), mỗi lớp mở ra danh sách buổi.
///  • Lịch tháng: toàn bộ buổi học của mọi lớp, chấm theo ngày.
class StudentLessonsPage extends ConsumerStatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  ConsumerState<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends ConsumerState<StudentLessonsPage>
    with SingleTickerProviderStateMixin, ScrollToTopMixin {
  late final TabController _tabs;
  final _scrollController = ScrollController();
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    unawaited(
      Future.microtask(() => ref.read(classListProvider.notifier).refresh()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 3, _scrollController);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classListProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              showCalendar: _showCalendar,
              onToggle: () => setState(() => _showCalendar = !_showCalendar),
            ),
            if (state.isLoading && state.items.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (state.error != null && state.items.isEmpty)
              Expanded(
                child: _ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(classListProvider.notifier).refresh(),
                ),
              )
            else if (_showCalendar)
              Expanded(child: _CalendarView(entries: state.allSessions))
            else ...[
              _UpNextCard(summary: state.summary),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SegmentedTabs(
                  selected: _tabs.index,
                  labels: [
                    'Đang học (${state.ongoing.length})',
                    'Đã xong (${state.finished.length})',
                  ],
                  onSelect: _tabs.animateTo,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ClassListView(
                      classes: state.ongoing,
                      scrollController: _scrollController,
                      emptyMessage:
                          'Bạn chưa có lớp học nào đang diễn ra.\nTìm gia sư để bắt đầu lớp đầu tiên nhé.',
                      onRefresh: () =>
                          ref.read(classListProvider.notifier).refresh(),
                    ),
                    _ClassListView(
                      classes: state.finished,
                      emptyMessage: 'Chưa có lớp học nào kết thúc.',
                      onRefresh: () =>
                          ref.read(classListProvider.notifier).refresh(),
                    ),
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

// Top bar

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

// Up-next card: buổi học gần nhất trên toàn bộ lớp

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.summary});
  final StudyProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final next = summary.nextSession;
    if (next == null) return const SizedBox(height: 4);

    final now = DateTime.now();
    final isToday = next.isToday;
    final daysAway = DateTime(
      next.startDt.year,
      next.startDt.month,
      next.startDt.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    final when = isToday
        ? 'Hôm nay'
        : daysAway == 1
        ? 'Ngày mai'
        : '${next.weekdayLabel}, ${next.dateLabel}';

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
                      'BUỔI HỌC TIẾP THEO',
                      style: AppTextStyles.eyebrow(color: AppColors.gold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.nextSessionClassName ?? 'Buổi học',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.15,
                        color: AppColors.cream,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$when · ${next.timeRange}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.cream.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                      '${next.startDt.day}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.gold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TH ${next.startDt.month}',
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

// Segmented tabs

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

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
        children: List.generate(labels.length, (i) {
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
                  labels[i],
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

// Class list

class _ClassListView extends StatelessWidget {
  const _ClassListView({
    required this.classes,
    required this.emptyMessage,
    required this.onRefresh,
    this.scrollController,
  });

  final List<StudentClassDto> classes;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.oxblood,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 40),
            EmptyState(message: emptyMessage),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.oxblood,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: classes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => ClassCard(
          klass: classes[i],
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  StudentClassDetailPage(bookingId: classes[i].bookingId),
            ),
          ),
        ),
      ),
    );
  }
}

// Calendar view

class _CalendarView extends StatefulWidget {
  const _CalendarView({required this.entries});

  final List<({StudentClassDto klass, ClassSessionSlotDto session})> entries;

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _selected = DateTime.now();

  String get _dayHeader {
    final today = DateTime.now();
    final isToday =
        _selected.year == today.year &&
        _selected.month == today.month &&
        _selected.day == today.day;
    final label = DateFormat('dd/MM').format(_selected);
    return isToday ? 'Hôm nay · $label' : 'Ngày $label';
  }

  List<({StudentClassDto klass, ClassSessionSlotDto session})>
  get _selectedEntries => widget.entries.where((e) {
    final d = e.session.startDt;
    return d.year == _selected.year &&
        d.month == _selected.month &&
        d.day == _selected.day;
  }).toList();

  int _sessionCountForDay(int year, int month, int day) => widget.entries
      .where(
        (e) =>
            e.session.startDt.year == year &&
            e.session.startDt.month == month &&
            e.session.startDt.day == day,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    final entries = _selectedEntries;
    return ListView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.xxl + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        const SizedBox(height: 4),
        AppCalendar(
          selectedDate: _selected,
          sessionCountForDay: _sessionCountForDay,
          onSelectDate: (date) => setState(() => _selected = date),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                _dayHeader.toUpperCase(),
                style: AppTextStyles.eyebrow(color: AppColors.ink3),
              ),
              const Spacer(),
              if (entries.isNotEmpty)
                Text(
                  '${entries.length} buổi',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink3,
                  ),
                ),
            ],
          ),
        ),
        if (entries.isEmpty)
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
          for (int i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                i < entries.length - 1 ? 10 : 0,
              ),
              child: SessionCard(
                session: entries[i].session,
                subjectName: entries[i].klass.title,
                tutorName: entries[i].klass.tutorName,
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudentSessionDetailPage(
                      lessonId: entries[i].session.classSessionId,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

// Error view

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Không tải được lớp học',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 140,
              child: PrimaryButton(
                label: 'Thử lại',
                color: AppColors.ink,
                fg: AppColors.cream,
                onTap: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
