import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_session_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Lịch dạy — design V5.6 (board V55-Lessons / V56-LessonsEmpty).
///
/// - Hàng tháng + dải 7 ngày (ngày chọn là ô tối bo tròn); vuốt dải sang tuần
///   khác → agenda cuộn tới buổi đầu tiên của tuần đó.
/// - Agenda là MỘT danh sách liền mạch mọi buổi (6 tháng trước → 12 tháng
///   sau), nhóm theo ngày, mỗi ngày là một dòng thời gian (cột giờ + chấm);
///   mở ra ở "Hôm nay".
/// - Cuộn agenda sang ngày khác → dải tuần tự trượt theo. Chạm một ngày → agenda
///   cuộn tới ngày đó; ngày trống hiện khối "không có buổi học".
///
/// Điều khiển từ ngoài (nút "Hôm nay" ở header) qua [TutorCalendarAgendaController].
class TutorCalendarAgenda extends ConsumerStatefulWidget {
  const TutorCalendarAgenda({this.controller, super.key});

  final TutorCalendarAgendaController? controller;

  @override
  ConsumerState<TutorCalendarAgenda> createState() =>
      _TutorCalendarAgendaState();
}

class TutorCalendarAgendaController {
  VoidCallback? _goToday;

  void goToday() => _goToday?.call();
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - d.weekday + 1);

/// Số ngày từ [a] tới [b] (theo lịch, không lệch vì giờ mùa hè).
int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

const _dows = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

const _weekdayNames = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

/// "T2 21/9"
String _dayLabel(DateTime d) => '${_dows[d.weekday - 1]} ${d.day}/${d.month}';

/// Chữ chấm xám nhạt (mũi tên, chấm buổi sắp tới).
const Color _soft = Color(0xFFA3A8A2);

/// Chữ của dòng đã xong.
const Color _doneInk = Color(0xFF7E847E);

int? _minutesOf(TutorLessonDto l) {
  final s = l.startDt;
  final e = l.endDt;
  if (s == null || e == null) return null;
  final m = e.difference(s).inMinutes;
  return m > 0 ? m : null;
}

class _TutorCalendarAgendaState extends ConsumerState<TutorCalendarAgenda> {
  late DateTime _today = _dateOnly(DateTime.now());
  late final DateTime _firstMonth = tutorAgendaFirstMonth(_today);
  static const int _monthCount =
      tutorAgendaMonthsBefore + tutorAgendaMonthsAfter + 1;

  late final DateTime _firstWeek = _mondayOf(_firstMonth);
  late final int _weekCount =
      _daysBetween(
            _firstWeek,
            _mondayOf(
              DateTime(_firstMonth.year, _firstMonth.month + _monthCount, 0),
            ),
          ) ~/
          7 +
      1;

  late int _page = _weekIndexOf(_today);
  late DateTime _selected = _today;

  /// Ngày người dùng chủ động chọn (chạm / vuốt tuần). Ngày trống được chọn
  /// vẫn có nhóm riêng trong agenda để hiện khối "không có buổi học".
  DateTime? _picked;

  late final PageController _pages = PageController(initialPage: _page);
  final _scroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<DateTime, GlobalKey> _dayKeys = {};

  /// Agenda đang cuộn do code (chạm ngày / vuốt tuần) → tắt scroll-spy.
  bool _programmatic = false;

  /// Số lần dải tuần đang trượt do code (theo agenda) → không cuộn agenda
  /// ngược lại. Dùng bộ đếm vì animation sau có thể cắt ngang animation trước.
  int _syncingPage = 0;

  bool _didInitialJump = false;

  // ── Hiệu năng ─────────────────────────────────────────────────────────
  // Đổi ngày chọn (scroll-spy) gọi setState liên tục khi cuộn. Danh sách
  // agenda KHÔNG phụ thuộc ngày chọn, nên dựng một lần rồi giữ nguyên đối
  // tượng widget: Flutter thấy cùng instance thì bỏ qua cả cây con.
  Widget? _agendaCache;
  List<TutorLessonDto>? _cacheLessons;
  DateTime? _cacheToday;
  DateTime? _cachePicked;
  bool? _cacheLoading;
  Map<DateTime, List<TutorLessonDto>> _byDay = const {};

  /// Vị trí (trong nội dung cuộn) của tiêu đề từng ngày, tăng dần. Đo MỘT lần
  /// sau mỗi lần dựng lại danh sách, thay vì đi dò cây render ở mỗi khung hình.
  List<(DateTime, double)> _offsets = const [];
  bool _offsetsDirty = true;

  DateTime _weekAt(int i) =>
      DateTime(_firstWeek.year, _firstWeek.month, _firstWeek.day + i * 7);

  int _weekIndexOf(DateTime d) =>
      (_daysBetween(_firstWeek, d) ~/ 7).clamp(0, _weekCount - 1);

  @override
  void initState() {
    super.initState();
    widget.controller?._goToday = _goToday;
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant TutorCalendarAgenda oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._goToday = _goToday;
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _pages.dispose();
    super.dispose();
  }

  // ── Dữ liệu ──────────────────────────────────────────────────────────────

  static DateTime? _dayOf(TutorLessonDto l) {
    final d = (l.calendarDate ?? l.startDt)?.toLocal();
    return d == null ? null : _dateOnly(d);
  }

  static int _byStart(TutorLessonDto a, TutorLessonDto b) {
    final x = a.startDt;
    final y = b.startDt;
    if (x == null || y == null) return 0;
    return x.compareTo(y);
  }

  // ── Điều hướng ───────────────────────────────────────────────────────────

  void _goToday() {
    final now = _dateOnly(DateTime.now());
    setState(() {
      _today = now;
      _selected = now;
      _picked = null;
    });
    unawaited(_syncPageTo(now));
    _scrollToDay(now);
  }

  /// Chọn [day]: đánh dấu, trượt dải tuần tới đó và cuộn agenda tới đó.
  void _select(DateTime day) {
    setState(() {
      _selected = day;
      _picked = day;
    });
    unawaited(_syncPageTo(day));
    _scrollToDay(day);
  }

  /// Trượt dải tuần tới tuần chứa [day] mà không kéo agenda theo.
  Future<void> _syncPageTo(DateTime day) async {
    final target = _weekIndexOf(day);
    if (!_pages.hasClients || target == _page) return;
    _syncingPage++;
    setState(() => _page = target);
    final far = (target - (_pages.page ?? target)).abs() > 3;
    if (far) {
      _pages.jumpToPage(target);
    } else {
      await _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) _syncingPage--;
  }

  /// Người dùng vuốt dải sang tuần khác.
  void _onPageChanged(int i) {
    if (_syncingPage > 0 || i == _page) return;
    final monday = _weekAt(i);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final inWeek = !_today.isBefore(monday) && !_today.isAfter(sunday);
    final days =
        _byDay.keys
            .where((d) => !d.isBefore(monday) && !d.isAfter(sunday))
            .toList()
          ..sort();
    final target = inWeek ? _today : (days.isNotEmpty ? days.first : monday);
    setState(() {
      _page = i;
      _selected = target;
      _picked = target;
    });
    _scrollToDay(target);
  }

  /// Nút tháng trước / tháng sau.
  void _shiftMonth(int delta) {
    final m = DateTime(_selected.year, _selected.month + delta);
    final end = DateTime(_firstMonth.year, _firstMonth.month + _monthCount);
    if (m.isBefore(_firstMonth) || !m.isBefore(end)) return;
    final isCurrent = m.year == _today.year && m.month == _today.month;
    final days =
        _byDay.keys
            .where((d) => d.year == m.year && d.month == m.month)
            .toList()
          ..sort();
    _select(isCurrent ? _today : (days.isNotEmpty ? days.first : m));
  }

  /// Cuộn agenda tới nhóm của [day], hoặc nhóm gần nhất sau nó.
  void _scrollToDay(DateTime day, {bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scroll.hasClients) return;
      final keys = _dayKeys.keys.toList()..sort();
      if (keys.isEmpty) return;
      final target = keys.firstWhere(
        (d) => !d.isBefore(day),
        orElse: () => keys.last,
      );
      final ctx = _dayKeys[target]?.currentContext;
      if (ctx == null) return;
      _programmatic = true;
      await Scrollable.ensureVisible(
        ctx,
        duration: animate ? const Duration(milliseconds: 320) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
      _programmatic = false;
    });
  }

  /// Scroll-spy: ngày có tiêu đề nằm cao nhất đã chạm/vượt mép trên agenda.
  void _onScroll() {
    if (_programmatic || !_scroll.hasClients) return;
    if (_offsetsDirty) _measureOffsets();
    if (_offsets.isEmpty) return;

    // Tìm nhị phân ngày cuối cùng có tiêu đề đã chạm/vượt mép trên agenda.
    final y = _scroll.offset + 24;
    var lo = 0;
    var hi = _offsets.length - 1;
    var found = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_offsets[mid].$2 <= y) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    final current = _offsets[found].$1;
    if (current == _selected) return;
    setState(() => _selected = current);
    if (_weekIndexOf(current) != _page) unawaited(_syncPageTo(current));
  }

  /// Đo vị trí tiêu đề các ngày trong nội dung cuộn (không phụ thuộc offset hiện tại).
  void _measureOffsets() {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached || !_scroll.hasClients) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    final list = <(DateTime, double)>[];
    final keys = _dayKeys.keys.toList()..sort();
    for (final d in keys) {
      final box = _dayKeys[d]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      list.add((d, box.localToGlobal(Offset.zero).dy - top + _scroll.offset));
    }
    _offsets = list;
    _offsetsDirty = false;
  }

  // ── Giao diện ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tutorAgendaLessonsProvider);
    final lessons = async.valueOrNull ?? const <TutorLessonDto>[];

    final loadingEmpty = async.isLoading && lessons.isEmpty;
    final rebuild =
        !identical(lessons, _cacheLessons) ||
        _cacheToday != _today ||
        _cachePicked != _picked ||
        _cacheLoading != loadingEmpty ||
        _agendaCache == null;
    if (rebuild) {
      final byDay = <DateTime, List<TutorLessonDto>>{};
      for (final l in lessons) {
        final d = _dayOf(l);
        if (d == null) continue;
        (byDay[d] ??= []).add(l);
      }
      for (final list in byDay.values) {
        list.sort(_byStart);
      }
      _byDay = byDay;

      // Mọi ngày có buổi + "Hôm nay" + ngày vừa chọn luôn có nhóm.
      final days = {
        ...byDay.keys,
        _today,
        if (_picked != null && !loadingEmpty) _picked!,
      }.toList()..sort();
      _dayKeys.removeWhere((d, _) => !days.contains(d));
      for (final d in days) {
        _dayKeys.putIfAbsent(d, GlobalKey.new);
      }

      _agendaCache = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loadingEmpty) const _Message(text: 'Đang tải lịch…'),
          for (final d in days) ...[
            // Mỗi ngày một lớp vẽ riêng: cuộn chỉ dịch ảnh đã vẽ, không vẽ lại.
            RepaintBoundary(
              child: _DayGroup(
                key: _dayKeys[d],
                day: d,
                today: _today,
                lessons: byDay[d] ?? const [],
                loading: loadingEmpty,
              ),
            ),
            const SizedBox(height: 26),
          ],
        ],
      );
      _cacheLessons = lessons;
      _cacheToday = _today;
      _cachePicked = _picked;
      _cacheLoading = loadingEmpty;
      _offsetsDirty = true;
    }
    final byDay = _byDay;

    if (!_didInitialJump && async.hasValue) {
      _didInitialJump = true;
      _scrollToDay(_today, animate: false);
    }

    return Column(
      children: [
        // ── Hàng tháng ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            0,
            TutorSurface.gutter - 6,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tháng ${_selected.month}, ${_selected.year}',
                  style: TutorType.display(
                    size: 16,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_left_rounded,
                label: 'Tháng trước',
                onTap: () => _shiftMonth(-1),
              ),
              _MonthArrow(
                icon: Icons.chevron_right_rounded,
                label: 'Tháng sau',
                onTap: () => _shiftMonth(1),
              ),
            ],
          ),
        ),
        // ── Dải 7 ngày ────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: TutorSurface.rule)),
          child: SizedBox(
            height: 68,
            child: PageView.builder(
              controller: _pages,
              itemCount: _weekCount,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _WeekStrip(
                monday: _weekAt(i),
                today: _today,
                selected: _selected,
                byDay: byDay,
                onPick: _select,
              ),
            ),
          ),
        ),
        // ── Dòng thời gian ────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () => ref.refresh(tutorAgendaLessonsProvider.future),
            child: async.hasError && lessons.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      _Message(
                        text: 'Không tải được lịch. Kéo xuống để thử lại.',
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    key: _viewportKey,
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      14,
                      TutorSurface.gutter,
                      // Chừa chỗ để ngày cuối vẫn cuộn lên được sát mép trên.
                      420,
                    ),
                    child: _agendaCache,
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Hàng tháng · dải tuần ──────────────────────────────────────────────────

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: TutorColors.ink3),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.monday,
    required this.today,
    required this.selected,
    required this.byDay,
    required this.onPick,
  });

  final DateTime monday;
  final DateTime today;
  final DateTime selected;
  final Map<DateTime, List<TutorLessonDto>> byDay;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Builder(
              builder: (_) {
                final day = DateTime(monday.year, monday.month, monday.day + i);
                return _DayTile(
                  day: day,
                  today: today,
                  selected: day == selected,
                  lessons: byDay[day] ?? const [],
                  onTap: onPick,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.today,
    required this.selected,
    required this.lessons,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final bool selected;
  final List<TutorLessonDto> lessons;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;

    // Chấm: có buổi đã qua / hôm nay → chấm đặc; chỉ có buổi sắp tới → vòng.
    final hasLessons = lessons.isNotEmpty;
    final filled = hasLessons && !day.isAfter(today);
    final dotColor = selected ? Colors.white : TutorColors.ink;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        decoration: BoxDecoration(
          color: selected ? TutorColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
          border: isToday && !selected
              ? Border.all(color: const Color(0x331F2A24))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _dows[day.weekday - 1],
              style: TutorType.rowSub(
                color: selected ? const Color(0xFFC8CEC8) : TutorColors.ink3,
              ),
            ),
            Text(
              '${day.day}',
              style: TutorType.display(
                size: 16,
                weight: FontWeight.w500,
                color: selected ? Colors.white : TutorColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasLessons && filled ? dotColor : null,
                border: hasLessons && !filled
                    ? Border.all(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF8A8F89),
                        width: 1.3,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Agenda ─────────────────────────────────────────────────────────────────

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.today,
    required this.lessons,
    required this.loading,
    super.key,
  });

  final DateTime day;
  final DateTime today;
  final List<TutorLessonDto> lessons;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;
    final label = isToday ? 'Hôm nay · ${_dayLabel(day)}' : _dayLabel(day);

    // Buổi "Tiếp theo" của hôm nay = buổi chưa xong đầu tiên.
    TutorLessonDto? next;
    if (isToday) {
      final now = DateTime.now();
      for (final l in lessons) {
        final end = l.endDt?.toLocal();
        if (!l.isFinished && (end == null || end.isAfter(now))) {
          next = l;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: isToday
              ? TutorType.rowTitle().copyWith(fontWeight: FontWeight.w600)
              : TutorType.rowSub(),
        ),
        const SizedBox(height: 10),
        if (lessons.isEmpty) ...[
          if (!loading) _EmptyDay(day: day, today: today),
        ] else ...[
          _Timeline(
            children: [
              for (final l in lessons)
                _TimelineItem(lesson: l, next: identical(l, next)),
            ],
          ),
          const SizedBox(height: 14),
          _DaySummary(isToday: isToday, lessons: lessons),
        ],
      ],
    );
  }
}

/// Dòng thời gian: đường dọc mảnh nối các chấm.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.children});

  final List<Widget> children;

  /// Tâm chấm/đường kẻ tính từ mép trái (cột giờ 44 + nửa cột chấm 7).
  static const double lineX = 51;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (children.length > 1)
          const Positioned(
            left: lineX - 0.5,
            top: 18,
            bottom: 28,
            width: 1,
            child: ColoredBox(color: Color(0x241F2A24)),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ],
    );
  }
}

enum _Kind { done, next, live, needReport, other }

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.lesson, required this.next});

  final TutorLessonDto lesson;
  final bool next;

  _Kind get _kind {
    if (next) return _Kind.next;
    if (lesson.isLive) return _Kind.live;
    if (lesson.isFinished) return _Kind.done;
    if (lesson.isAwaitingReport) return _Kind.needReport;
    return _Kind.other;
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final carded = kind == _Kind.next || kind == _Kind.needReport;
    final dotTop = carded ? 21.0 : 13.0;
    final upcoming = kind == _Kind.other && !_isPast(lesson);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: EdgeInsets.only(top: carded ? 16 : 8),
            child: Text(
              lesson.timeStart.isEmpty ? '—' : lesson.timeStart,
              style: TutorType.rowSub(
                color: kind == _Kind.next ? TutorColors.ink : TutorColors.ink3,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 14,
          child: Padding(
            padding: EdgeInsets.only(top: dotTop - 3),
            child: Center(
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  color: TutorColors.bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: upcoming ? _soft : TutorColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: switch (kind) {
            _Kind.next => _NextCard(lesson: lesson),
            _Kind.needReport => _ReportCard(lesson: lesson),
            _ => _FlatRow(lesson: lesson, kind: kind),
          },
        ),
      ],
    );
  }

  static bool _isPast(TutorLessonDto l) {
    final end = l.endDt;
    return end != null && end.isBefore(DateTime.now());
  }
}

/// Môn · nhãn buổi phụ / ngoài TopTutor.
String _sub(TutorLessonDto l) {
  final parts = <String>[
    if (l.subjectName.isNotEmpty) l.subjectName,
    if (l.linkLabel != null) l.linkLabel!,
  ];
  return parts.join(' · ');
}

/// Buổi booking → chi tiết buổi. Buổi ngoài nền tảng → báo cáo (nếu đã ghi)
/// hoặc hồ sơ học sinh (có nút ghi âm).
void _open(BuildContext context, TutorLessonDto l) {
  if (!l.isOffPlatform) {
    unawaited(TutorSessionDetailScreen.open(context, l));
    return;
  }
  const recorded = {'processing', 'awaiting_approval', 'failed', 'sent'};
  if (recorded.contains(l.recorderStatus)) {
    unawaited(
      TutorRecordingDetailScreen.open(
        context,
        RecordingDetailArgs(
          recordingId: l.recorderLessonId!,
          studentName: l.studentName,
        ),
      ),
    );
  } else if (l.recorderStudentId != null) {
    unawaited(TutorStudentDetailScreen.open(context, l.recorderStudentId!));
  }
}

/// Mức 0: dòng phẳng trên nền giấy (đã xong có dấu tick).
class _FlatRow extends StatelessWidget {
  const _FlatRow({required this.lesson, required this.kind});

  final TutorLessonDto lesson;
  final _Kind kind;

  @override
  Widget build(BuildContext context) {
    final done = kind == _Kind.done;
    final status = done
        ? (lesson.isCompleted ? 'Đã hoàn thành' : 'Chờ xác nhận')
        : null;
    final sub = [_sub(lesson), ?status].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      onTap: () => _open(context, lesson),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
        child: Row(
          children: [
            if (done) ...[const _Tick(), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.body(
                      color: done ? _doneInk : TutorColors.ink,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TutorType.rowSub(),
                    ),
                ],
              ),
            ),
            if (kind == _Kind.live) ...[
              const SizedBox(width: 8),
              const CanvasTag('Đang dạy', filled: true),
            ] else if (!done)
              const CanvasChevron(),
          ],
        ),
      ),
    );
  }
}

/// Mức 1: buổi đã dạy xong nhưng chưa có báo cáo.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.lesson});

  final TutorLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: TutorSurface.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context, lesson),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const _IconWell(icon: Icons.mic_off_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TutorType.body(),
                      ),
                      Text(
                        'Chưa có báo cáo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TutorType.rowSub(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const CanvasTag('Cần báo cáo'),
                const CanvasChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mức 2: thẻ sage nổi cho buổi tiếp theo của hôm nay.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.lesson});

  final TutorLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final minutes = _minutesOf(lesson);
    final sub = [
      _sub(lesson),
      if (minutes != null) '$minutes phút',
    ].where((s) => s.isNotEmpty).join(' · ');
    // Như nút ghi âm ở chi tiết buổi: chỉ buổi booking, chưa dạy xong.
    final canRecord =
        !lesson.isOffPlatform && !lesson.isFinished && !lesson.isAwaitingReport;

    return DecoratedBox(
      decoration: TutorSurface.sage(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context, lesson),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const _IconWell(
                      icon: Icons.mic_none_rounded,
                      color: Color(0xFFF8F7F4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  lesson.studentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TutorType.body(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CanvasTag(
                                lesson.isLive ? 'Đang dạy' : 'Tiếp theo',
                                filled: true,
                              ),
                            ],
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TutorType.rowSub(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (canRecord) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () => unawaited(
                        GoRouter.of(context).push(
                          AppRoutes.tutorRecording,
                          extra: RecordingTarget(
                            lessonId: lesson.lessonId,
                            studentName: lesson.studentName,
                            subjectName: lesson.subjectName,
                            timeStart: lesson.timeStart,
                            timeEnd: lesson.timeEnd,
                            scheduledEnd: lesson.endDt?.toLocal(),
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: TutorColors.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: TutorType.action(),
                      ),
                      icon: const Icon(Icons.mic_none_rounded, size: 18),
                      label: const Text('Bắt đầu ghi âm'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon, this.color = TutorColors.surfaceSunken});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
    ),
    child: Icon(icon, size: 18, color: TutorColors.ink),
  );
}

class _Tick extends StatelessWidget {
  const _Tick();

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: const BoxDecoration(
      color: TutorColors.ink,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
  );
}

/// "Hôm nay: 2 buổi · 3 giờ dạy · 1 cần báo cáo"
class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.isToday, required this.lessons});

  final bool isToday;
  final List<TutorLessonDto> lessons;

  static String _duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m phút';
    return m == 0 ? '$h giờ' : '$h giờ $m phút';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = lessons.fold<int>(0, (a, l) => a + (_minutesOf(l) ?? 0));
    final reports = lessons.where((l) => l.isAwaitingReport).length;
    final parts = [
      '${lessons.length} buổi',
      if (minutes > 0) '${_duration(minutes)} dạy',
      if (reports > 0) '$reports cần báo cáo',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(border: Border(top: TutorSurface.rule)),
      child: Text(
        isToday ? 'Hôm nay: $parts' : parts,
        style: TutorType.rowSub(),
      ),
    );
  }
}

/// Ngày trống (board V56-LessonsEmpty).
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final who = day == today ? 'Hôm nay' : _weekdayNames[day.weekday - 1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Column(
        children: [
          const CanvasHand('Một ngày rảnh rỗi', size: 22),
          const SizedBox(height: 18),
          Text(
            '$who không có buổi học',
            textAlign: TextAlign.center,
            style: TutorType.sectionTitle(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'Thêm học sinh hoặc buổi học để lên lịch cho tuần.',
              textAlign: TextAlign.center,
              style: TutorType.rowSub(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TutorType.rowSub(),
      ),
    );
  }
}
