import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_class_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

/// Lịch dạy — hai lối vào cùng dữ liệu: theo lớp và theo ngày. Chỉ để xem.
class TutorScheduleScreen extends ConsumerStatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  ConsumerState<TutorScheduleScreen> createState() =>
      _TutorScheduleScreenState();
}

enum _Tab { classes, calendar }

class _TutorScheduleScreenState extends ConsumerState<TutorScheduleScreen> {
  _Tab _tab = _Tab.classes;

  Future<void> _refresh() async {
    ref.invalidate(tutorClassesProvider);
    await ref.read(tutorScheduleProvider.notifier).loadCurrentMonth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TutorScreenHeader(title: 'Lịch dạy'),
            Padding(
              padding: TutorSurface.screenPadding,
              child: _SegmentedTabs(
                current: _tab,
                onChange: (t) => setState(() => _tab = t),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: TutorColors.primary,
                child: _tab == _Tab.classes
                    ? const _ClassesView()
                    : const _CalendarView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hai nút gạt — viên thuốc trượt, cùng ngôn ngữ với thanh tab dưới cùng.
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.current, required this.onChange});

  final _Tab current;
  final ValueChanged<_Tab> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TutorColors.surfaceSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      // Không có expand + heightFactor thì viên thuốc nở tràn khỏi khung.
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: current == _Tab.classes
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TutorColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: TutorColors.cardShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _segment(_Tab.classes, Icons.folder_copy_rounded, 'Lớp'),
              _segment(_Tab.calendar, Icons.calendar_month_rounded, 'Lịch'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(_Tab tab, IconData icon, String label) {
    final selected = current == tab;
    // ink2 thay ink3: trên nền chìm, ink3 mờ như bị vô hiệu hoá.
    final color = selected ? TutorColors.primary : TutorColors.ink2;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(tab),
        behavior: HitTestBehavior.opaque,
        // strutStyle: chữ có dấu đội chiều cao lên, lệch so với icon.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TutorType.action(color: color),
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab Lớp
class _ClassesView extends ConsumerWidget {
  const _ClassesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorClassesProvider);

    return async.when(
      loading: () => ListView(
        padding: TutorSurface.screenPadding,
        children: const [
          TutorSkeleton(height: 104, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.rowGap),
          TutorSkeleton(height: 104, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.rowGap),
          TutorSkeleton(height: 104, radius: TutorSurface.radius),
        ],
      ),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(tutorClassesProvider),
      ),
      data: (page) {
        // BE không trả 'cancelled' cho lớp nên không lọc gì ở đây.
        final visible = page.items;
        if (visible.isEmpty) {
          return const _EmptyState(message: 'Chưa có lớp nào.');
        }

        // Lớp đang chạy lên trước; lớp đã xong xuống cuối.
        final active = visible.where((c) => !c.isFinished).toList();
        final finished = visible.where((c) => c.isFinished).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: kTutorNavTotalHeight + 16),
          children: [
            for (final c in active)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  0,
                  TutorSurface.gutter,
                  TutorSurface.rowGap,
                ),
                child: _ClassCard(item: c),
              ),
            if (finished.isNotEmpty) ...[
              const SizedBox(height: 8),
              TutorSectionHeader(title: 'Đã kết thúc · ${finished.length}'),
              for (final c in finished)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    0,
                    TutorSurface.gutter,
                    TutorSurface.rowGap,
                  ),
                  child: _ClassCard(item: c),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Thẻ một lớp: học sinh + môn, tiến độ, buổi kế tiếp.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.item});

  final TutorClassDto item;

  @override
  Widget build(BuildContext context) {
    // BE chỉ trả 4 giá trị cho lớp.
    final (Color tone, String label) = switch (item.status) {
      'completed' => (TutorColors.success, 'Đã xong'),
      'in_progress' => (TutorColors.accent, 'Đang dạy'),
      'pending_confirmation' => (TutorColors.warning, 'Chờ xác nhận'),
      _ => (TutorColors.primary, 'Đang học'),
    };

    return TutorCard(
      shadow: TutorColors.cardShadow,
      backgroundImage: const DecorationImage(
        image: AssetImage('assets/images/common/backgroud_tutor_next.png'),
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
        opacity: 0.16,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorClassDetailScreen(item: item),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TutorAvatar(name: item.studentName),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      style: TutorType.rowTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subjectName,
                      style: TutorType.rowSub(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  label,
                  style: TutorType.caption(
                    color: tone,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Nhãn trên, thanh dưới — đặt cạnh chữ thì thanh bị bóp lệch.
          Row(
            children: [
              Text(
                'Tiến độ',
                style: TutorType.caption(color: TutorColors.ink2),
              ),
              const Spacer(),
              Text(
                '${item.completedSessions}/${item.totalSessions} buổi',
                style: TutorType.caption(
                  color: TutorColors.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: TutorColors.surfaceSunken,
              valueColor: AlwaysStoppedAnimation(tone),
            ),
          ),
          if (item.schedule.isNotEmpty || item.nextStartLocal != null) ...[
            const SizedBox(height: 11),
            Container(height: 1, color: TutorColors.line),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  item.nextStartLocal != null
                      ? Icons.schedule_rounded
                      : Icons.repeat_rounded,
                  size: 14,
                  color: TutorColors.ink3,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.nextStartLocal != null
                        ? 'Buổi tới ${_nextLabel(item.nextStartLocal!)}'
                        : item.schedule,
                    style: TutorType.caption(color: TutorColors.ink2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: TutorColors.ink4,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _nextLabel(DateTime dt) {
    final now = DateTime.now();
    final days = DateTime(
      dt.year,
      dt.month,
      dt.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    if (days == 0) return 'hôm nay $time';
    if (days == 1) return 'ngày mai $time';
    return '${dt.day}/${dt.month} · $time';
  }
}

// Tab Lịch
/// Dải ngày + timeline ngày đang chọn, thay danh sách cả tháng của bản cũ.
class _CalendarView extends ConsumerStatefulWidget {
  const _CalendarView();

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  late DateTime _selected = _dateOnly(DateTime.now());
  late DateTime _weekStart = _mondayOf(DateTime.now());

  /// Mở lịch tháng để nhảy xa; mặc định vẫn là dải tuần.
  bool _monthOpen = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _mondayOf(DateTime d) =>
      _dateOnly(d).subtract(Duration(days: d.weekday - 1));

  static const _months = [
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

  List<TutorLessonDto> _on(List<TutorLessonDto> all, DateTime day) =>
      all.where((l) => l.isSameDay(day)).toList()..sort((a, b) {
        final x = a.startDt;
        final y = b.startDt;
        if (x == null || y == null) return 0;
        return x.compareTo(y);
      });

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _selected = _dateOnly(now);
      _weekStart = _mondayOf(now);
      _monthOpen = false;
    });
    _ensureMonthLoaded(now);
  }

  void _pickDay(DateTime day) {
    setState(() {
      _selected = day;
      _weekStart = _mondayOf(day);
      _monthOpen = false;
    });
    _ensureMonthLoaded(day);
  }

  /// Provider chỉ nạp tháng hiện tại; sang tháng khác phải kéo thêm dữ liệu.
  void _ensureMonthLoaded(DateTime d) {
    final from = DateTime(d.year, d.month);
    final to = DateTime(d.year, d.month + 1, 0);
    unawaited(
      ref
          .read(tutorScheduleProvider.notifier)
          .loadRange(from: from.toIso8601String(), to: to.toIso8601String()),
    );
  }

  void _shiftWeek(int weeks) {
    final next = _weekStart.add(Duration(days: 7 * weeks));
    final crossedMonth = next.month != _weekStart.month;

    setState(() {
      _weekStart = next;
      // Giữ cùng thứ trong tuần mới để mắt không phải tìm lại.
      _selected = next.add(Duration(days: _selected.weekday - 1));
    });

    // Provider chỉ nạp tháng hiện tại; sang tháng khác phải kéo thêm dữ liệu.
    if (crossedMonth) {
      final from = DateTime(next.year, next.month);
      final to = DateTime(next.year, next.month + 1, 0);
      unawaited(
        ref
            .read(tutorScheduleProvider.notifier)
            .loadRange(
              from: from.toIso8601String(),
              to: to.toIso8601String(),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorScheduleProvider);
    final all = state.lessons;
    final today = _dateOnly(DateTime.now());
    final week = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final daySessions = _on(all, _selected);

    return ListView(
      padding: const EdgeInsets.only(bottom: kTutorNavTotalHeight + 16),
      children: [
        Padding(
          padding: TutorSurface.screenPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  // Lịch tháng tự in tiêu đề tháng của nó.
                  _monthOpen
                      ? 'Chọn ngày'
                      : '${_months[_weekStart.month - 1]} ${_weekStart.year}',
                  style: TutorType.sectionTitle(),
                ),
              ),
              _TodayBtn(onTap: _goToday),
              const SizedBox(width: 6),
              // Lịch tháng có nút chuyển tháng riêng bên trong nó.
              if (!_monthOpen) ...[
                _ArrowBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _shiftWeek(-1),
                ),
                const SizedBox(width: 6),
                _ArrowBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _shiftWeek(1),
                ),
                const SizedBox(width: 6),
              ],
              _ArrowBtn(
                icon: _monthOpen
                    ? Icons.calendar_view_week_rounded
                    : Icons.calendar_month_rounded,
                active: _monthOpen,
                onTap: () => setState(() => _monthOpen = !_monthOpen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_monthOpen)
          Padding(
            padding: TutorSurface.screenPadding,
            child: _MonthGrid(
              month: _weekStart,
              selected: _selected,
              hasSessions: (d) => _on(all, d).isNotEmpty,
              onPick: _pickDay,
              onShiftMonth: (delta) {
                final next = DateTime(
                  _weekStart.year,
                  _weekStart.month + delta,
                );
                setState(() => _weekStart = _mondayOf(next));
                _ensureMonthLoaded(next);
              },
            ),
          ),
        if (!_monthOpen)
          Padding(
            padding: TutorSurface.screenPadding,
            child: Row(
              children: [
                for (final d in week)
                  Expanded(
                    child: _DayCell(
                      day: d,
                      selected: d == _selected,
                      isToday: d == today,
                      hasSessions: _on(all, d).isNotEmpty,
                      onTap: () => setState(() => _selected = d),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: TutorSurface.screenPadding,
          child: state.isLoading && all.isEmpty
              ? const TutorSkeleton(height: 160, radius: TutorSurface.radius)
              : daySessions.isEmpty
              ? _EmptyDay(isToday: _selected == today)
              : _Timeline(sessions: daySessions),
        ),
      ],
    );
  }
}

/// Nút "Hôm nay" — lối về nhanh sau khi lướt xa.
class _TodayBtn extends StatelessWidget {
  const _TodayBtn({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TutorColors.primaryBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: TutorColors.primaryBorder),
        ),
        child: Text(
          'Hôm nay',
          style: TutorType.action(color: TutorColors.primary),
        ),
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  /// Bản hẹp dùng xen giữa dải ngày, không chiếm chỗ của ô ngày.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: compact ? 22 : 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? TutorColors.primaryBg : TutorColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? TutorColors.primaryBorder : TutorColors.line,
          ),
        ),
        child: Icon(
          icon,
          size: compact ? 16 : 19,
          color: active ? TutorColors.primary : TutorColors.ink2,
        ),
      ),
    );
  }
}

/// Lịch tháng đầy đủ — bật khi cần nhìn tổng quan hoặc nhảy sang ngày xa.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.hasSessions,
    required this.onPick,
    required this.onShiftMonth,
  });

  final DateTime month;
  final DateTime selected;
  final bool Function(DateTime) hasSessions;
  final ValueChanged<DateTime> onPick;
  final ValueChanged<int> onShiftMonth;

  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Ô trống đầu tháng để ngày 1 rơi đúng cột thứ của nó.
    final lead = first.weekday - 1;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return TutorCard(
      shadow: TutorColors.cardShadow,
      child: Column(
        children: [
          Row(
            children: [
              _ArrowBtn(
                icon: Icons.chevron_left_rounded,
                onTap: () => onShiftMonth(-1),
                compact: true,
              ),
              Expanded(
                child: Text(
                  'Tháng ${month.month} · ${month.year}',
                  textAlign: TextAlign.center,
                  style: TutorType.rowTitle(),
                ),
              ),
              _ArrowBtn(
                icon: Icons.chevron_right_rounded,
                onTap: () => onShiftMonth(1),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final l in _labels)
                Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: TutorType.caption(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                _MonthCell(
                  day: DateTime(month.year, month.month, d),
                  selected: DateTime(month.year, month.month, d) == selected,
                  isToday: DateTime(month.year, month.month, d) == todayOnly,
                  marked: hasSessions(DateTime(month.year, month.month, d)),
                  onTap: onPick,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.marked,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool marked;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(day),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? TutorColors.primary
                : (marked ? TutorColors.primaryBg : Colors.transparent),
            border: isToday && !selected
                ? Border.all(color: TutorColors.primary)
                : null,
          ),
          child: Text(
            '${day.day}',
            style: TutorType.caption(
              color: selected ? TutorColors.surface : TutorColors.ink,
            ).copyWith(fontWeight: marked ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasSessions,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasSessions;
  final VoidCallback onTap;

  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? TutorColors.primary : TutorColors.surface,
          borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
          border: Border.all(
            color: selected
                ? TutorColors.primary
                : (isToday ? TutorColors.primary : TutorColors.line),
          ),
        ),
        child: Column(
          children: [
            Text(
              _labels[day.weekday - 1],
              style: TutorType.caption(
                color: selected ? TutorColors.surface : TutorColors.ink4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: TutorType.numeral(
                color: selected ? TutorColors.surface : TutorColors.ink,
              ).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            // Chấm luôn chiếm chỗ để 7 ô không cao thấp lệch nhau.
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasSessions
                    ? (selected ? TutorColors.surface : TutorColors.accent)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline một ngày: trục giờ bên trái, buổi đặt đúng mốc phút của nó.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.sessions});

  final List<TutorLessonDto> sessions;

  static const double _slotHeight = 64;
  static const double _railWidth = 46;

  /// Chiều cao thật của một thẻ buổi — dùng để chống chồng lấn.
  static const double _cardHeight = 58;

  @override
  Widget build(BuildContext context) {
    final withTime = sessions.where((s) => s.startDt != null).toList();
    if (withTime.isEmpty) return const SizedBox.shrink();

    withTime.sort((a, b) => a.startDt!.compareTo(b.startDt!));

    final hours = withTime.map((s) => s.startDt!.hour).toList();
    final startHour = hours.reduce((a, b) => a < b ? a : b);
    final endHour = hours.reduce((a, b) => a > b ? a : b) + 1;

    // Hai buổi cách nhau ít phút sẽ chồng thẻ — đẩy xuống cho đủ chỗ.
    final tops = <double>[];
    for (final s in withTime) {
      final exact =
          ((s.startDt!.hour - startHour) + s.startDt!.minute / 60) *
          _slotHeight;
      final min = tops.isEmpty ? exact : tops.last + _cardHeight + 6;
      tops.add(exact > min ? exact : min);
    }

    // Thẻ cuối có thể bị đẩy quá mốc giờ cuối; nới chiều cao cho vừa.
    final railHeight = (endHour - startHour + 1) * _slotHeight;
    final needed = tops.last + _cardHeight + 8;

    return SizedBox(
      height: railHeight > needed ? railHeight : needed,
      child: Stack(
        children: [
          Column(
            children: [
              for (var h = startHour; h <= endHour; h++)
                SizedBox(
                  height: _slotHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _railWidth,
                        child: Transform.translate(
                          offset: const Offset(0, -6),
                          child: Text(
                            '${h.toString().padLeft(2, '0')}:00',
                            style: TutorType.caption(),
                          ),
                        ),
                      ),
                      const Expanded(child: _DashedLine()),
                    ],
                  ),
                ),
            ],
          ),
          for (var i = 0; i < withTime.length; i++)
            Positioned(
              top: tops[i],
              left: _railWidth + 6,
              right: 0,
              child: _SessionCard(lesson: withTime[i]),
            ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 1),
    painter: _DashPainter(),
  );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TutorColors.line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

/// Thẻ buổi trên timeline — chữ luôn đen đậm, chỉ viền/vạch đổi theo trạng thái.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.lesson});

  final TutorLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    // Phủ đủ trạng thái, không để rơi hết vào nhánh mặc định.
    final (Color tone, String? chip) = switch (lesson) {
      _ when lesson.isDisputed => (TutorColors.danger, 'Tranh chấp'),
      _ when lesson.isNoShow => (TutorColors.danger, 'Vắng mặt'),
      _ when lesson.isAwaitingReport => (TutorColors.warning, 'Chờ báo cáo'),
      _ when lesson.isPendingConfirmation => (
        TutorColors.warning,
        'Chờ xác nhận',
      ),
      _ when lesson.isCompleted => (TutorColors.success, 'Hoàn thành'),
      _ when lesson.isLive => (TutorColors.accent, 'Đang dạy'),
      _ => (TutorColors.primary, null),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 11, 10),
      decoration: BoxDecoration(
        color: TutorColors.surface,
        borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
        boxShadow: TutorColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lesson.studentName,
                  style: TutorType.rowTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${lesson.timeStart}–${lesson.timeEnd}'
                  '${lesson.subjectName.isEmpty ? '' : ' · ${lesson.subjectName}'}',
                  style: TutorType.caption(color: TutorColors.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                chip,
                style: TutorType.caption(
                  color: tone,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// Trạng thái rỗng / lỗi
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      shadow: TutorColors.cardShadow,
      child: Row(
        children: [
          Image.asset(
            'assets/mascot/sample.png',
            width: 46,
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isToday ? 'Hôm nay bạn rảnh.' : 'Không có buổi nào ngày này.',
              style: TutorType.rowSub(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: TutorSurface.screenPadding,
      children: [
        const SizedBox(height: 40),
        Image.asset(
          'assets/mascot/sample.png',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TutorType.rowSub(),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: TutorSurface.screenPadding,
      children: [
        const SizedBox(height: 40),
        TutorCard(
          color: TutorColors.dangerBg,
          borderColor: TutorColors.dangerBorder,
          onTap: onRetry,
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 17,
                color: TutorColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Không tải được danh sách lớp. Chạm để thử lại.',
                  style: TutorType.rowSub(color: TutorColors.danger),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
