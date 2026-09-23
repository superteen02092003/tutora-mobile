import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_session_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';

/// Lịch dạy dạng "tháng ghim + agenda" (prototype: "8 · Lịch · Tháng ghim +
/// Agenda").
///
/// - Agenda là MỘT danh sách liền mạch mọi buổi (6 tháng trước → 12 tháng
///   sau), nhóm theo ngày; mở ra ở "Hôm nay".
/// - Cuộn agenda sang ngày của tháng khác → lịch tháng ở trên tự trượt ngang
///   sang tháng đó.
/// - Vuốt/bấm mũi tên lịch sang tháng khác → agenda cuộn tới buổi đầu tiên của
///   tháng đó. Chạm một ngày → agenda cuộn tới ngày đó.
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

const _dows = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// "T2 21/9"
String _dayLabel(DateTime d) => '${_dows[d.weekday - 1]} ${d.day}/${d.month}';

const double _cellH = 34;

/// Số hàng tuần của lưới tháng [m].
int _rowsOf(DateTime m) {
  final lead = DateTime(m.year, m.month).weekday - 1;
  final days = DateTime(m.year, m.month + 1, 0).day;
  return ((lead + days) / 7).ceil();
}

class _TutorCalendarAgendaState extends ConsumerState<TutorCalendarAgenda> {
  late DateTime _today = _dateOnly(DateTime.now());
  late final DateTime _firstMonth = tutorAgendaFirstMonth(_today);
  static const _monthCount =
      tutorAgendaMonthsBefore + tutorAgendaMonthsAfter + 1;

  late int _page = _indexOf(_today);
  late DateTime _selected = _today;

  late final PageController _pages = PageController(initialPage: _page);
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final Map<DateTime, GlobalKey> _dayKeys = {};

  /// Agenda đang cuộn do code (chạm lịch / vuốt tháng) → tắt scroll-spy.
  bool _programmatic = false;

  /// Số lần lịch tháng đang trượt do code (theo agenda) → không cuộn agenda
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
  bool? _cacheLoading;
  Map<DateTime, List<TutorLessonDto>> _byDay = const {};

  /// Vị trí (trong nội dung cuộn) của tiêu đề từng ngày, tăng dần. Đo MỘT lần
  /// sau mỗi lần dựng lại danh sách, thay vì đi dò cây render ở mỗi khung hình.
  List<(DateTime, double)> _offsets = const [];
  bool _offsetsDirty = true;

  DateTime _monthAt(int i) => DateTime(_firstMonth.year, _firstMonth.month + i);

  int _indexOf(DateTime d) {
    final first = tutorAgendaFirstMonth(_today);
    return ((d.year - first.year) * 12 + d.month - first.month).clamp(
      0,
      _monthCount - 1,
    );
  }

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
    });
    _syncPageTo(now);
    _scrollToDay(now);
  }

  /// Trượt lịch tháng tới tháng chứa [day] mà không kéo agenda theo.
  Future<void> _syncPageTo(DateTime day) async {
    final target = _indexOf(day);
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

  /// Người dùng vuốt / bấm mũi tên sang tháng khác.
  void _onPageChanged(int i) {
    if (_syncingPage > 0 || i == _page) return;
    final m = _monthAt(i);
    final isCurrent = m.year == _today.year && m.month == _today.month;
    final days =
        _dayKeys.keys
            .where((d) => d.year == m.year && d.month == m.month)
            .toList()
          ..sort();
    setState(() {
      _page = i;
      _selected = isCurrent ? _today : (days.isNotEmpty ? days.first : m);
    });
    _scrollToDay(_selected);
  }

  void _shiftMonth(int delta) {
    final target = (_page + delta).clamp(0, _monthCount - 1);
    if (target == _page) return;
    _pages.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _pickDay(DateTime day) {
    setState(() => _selected = day);
    _scrollToDay(day);
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
    if (_indexOf(current) != _page) _syncPageTo(current);
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

      // Mọi ngày có buổi + "Hôm nay" luôn có tiêu đề.
      final days = {...byDay.keys, _today}.toList()..sort();
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
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      );
      _cacheLessons = lessons;
      _cacheToday = _today;
      _cacheLoading = loadingEmpty;
      _offsetsDirty = true;
    }
    final byDay = _byDay;

    if (!_didInitialJump && async.hasValue) {
      _didInitialJump = true;
      _scrollToDay(_today, animate: false);
    }

    final month = _monthAt(_page);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            0,
            TutorSurface.gutter,
            12,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: TutorColors.surface,
              border: Border.all(color: TutorColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Tháng ${month.month} · ${month.year}',
                      style: TutorType.sectionTitle(),
                    ),
                    const SizedBox(width: 8),
                    Text(_dayLabel(_selected), style: TutorType.caption()),
                    const Spacer(),
                    _SquareBtn(
                      icon: Icons.chevron_left_rounded,
                      label: 'Tháng trước',
                      onTap: () => _shiftMonth(-1),
                    ),
                    const SizedBox(width: 4),
                    _SquareBtn(
                      icon: Icons.chevron_right_rounded,
                      label: 'Tháng sau',
                      onTap: () => _shiftMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final d in _dows)
                      Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TutorType.caption(
                              color: const Color(0xFFA3A3A3),
                            ).copyWith(fontSize: 11, letterSpacing: 0.4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                // Chiều cao nội suy theo số hàng của 2 tháng kề nhau khi vuốt.
                AnimatedBuilder(
                  animation: _pages,
                  builder: (context, child) {
                    final p =
                        _pages.hasClients && _pages.position.haveDimensions
                        ? (_pages.page ?? _page.toDouble())
                        : _page.toDouble();
                    final a = p.floor().clamp(0, _monthCount - 1);
                    final b = p.ceil().clamp(0, _monthCount - 1);
                    final h = lerpDouble(
                      _rowsOf(_monthAt(a)) * _cellH,
                      _rowsOf(_monthAt(b)) * _cellH,
                      p - p.floor(),
                    )!;
                    return SizedBox(height: h, child: child);
                  },
                  child: ClipRect(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _monthCount,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) => OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: 6 * _cellH,
                        child: _MonthGrid(
                          month: _monthAt(i),
                          today: _today,
                          selected: _selected,
                          byDay: byDay,
                          onPick: _pickDay,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                      6,
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

// ── Lịch tháng ─────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.byDay,
    required this.onPick,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Map<DateTime, List<TutorLessonDto>> byDay;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final lead = first.weekday - 1;
    final rows = _rowsOf(month);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var w = 0; w < rows; w++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final day = DateTime(
                        first.year,
                        first.month,
                        1 - lead + w * 7 + i,
                      );
                      return _DayCell(
                        day: day,
                        month: month,
                        today: today,
                        selected: selected,
                        lessons: byDay[day] ?? const [],
                        onTap: onPick,
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SquareBtn extends StatelessWidget {
  const _SquareBtn({
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
      child: Material(
        color: TutorColors.surfaceSunken,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 18, color: TutorColors.ink3),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.today,
    required this.selected,
    required this.lessons,
    required this.onTap,
  });

  final DateTime day;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final List<TutorLessonDto> lessons;
  final ValueChanged<DateTime> onTap;

  static const _navy = TutorColors.ink;
  static const _future = Color(0xFFC4BEB0);
  static const _outside = Color(0xFFC4C0B6);

  @override
  Widget build(BuildContext context) {
    final inMonth = day.month == month.month;
    final isToday = day == today;
    final isSel = inMonth && day == selected;

    var bg = Colors.transparent;
    var fg = inMonth ? TutorColors.ink3 : _outside;
    var bold = false;
    BoxShadow? ring;
    if (isToday && inMonth) {
      bg = TutorColors.primary;
      fg = TutorColors.surface;
      bold = true;
    }
    if (isSel && isToday) {
      ring = BoxShadow(
        color: TutorColors.primary.withValues(alpha: 0.16),
        spreadRadius: 4,
      );
    } else if (isSel) {
      bg = _navy;
      fg = TutorColors.surface;
      bold = true;
      ring = BoxShadow(color: _navy.withValues(alpha: 0.12), spreadRadius: 4);
    }

    // Chấm: hôm nay 2 chấm đỏ đô; buổi cần báo cáo 1 chấm đỏ đô; buổi đã xong
    // chấm navy; buổi sắp tới chấm xám.
    Color? dot1;
    Color? dot2;
    if (inMonth && lessons.isNotEmpty) {
      if (isToday) {
        dot1 = TutorColors.primary;
        if (lessons.length > 1) dot2 = TutorColors.primary;
      } else if (lessons.any((l) => l.isAwaitingReport)) {
        dot1 = TutorColors.primary;
      } else if (day.isBefore(today)) {
        dot1 = _navy;
      } else {
        dot1 = _future;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: inMonth ? () => onTap(day) : null,
      child: SizedBox(
        height: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSel ? 1.12 : 1,
              duration: const Duration(milliseconds: 250),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 23,
                height: 23,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: ring == null ? const [] : [ring],
                ),
                child: Text(
                  '${day.day}',
                  style: TutorType.rowSub(color: fg).copyWith(
                    fontSize: 13,
                    height: 1,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(color: dot1),
                  const SizedBox(width: 2),
                  _Dot(color: dot2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(
      color: color ?? Colors.transparent,
      shape: BoxShape.circle,
    ),
  );
}

// ── Agenda ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.label, required this.color, this.trailing});

  final String label;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          Text(
            label,
            style: TutorType.caption(color: color).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(child: Divider(height: 1, color: TutorColors.line)),
          if (trailing != null) ...[
            const SizedBox(width: 9),
            Text(trailing!, style: TutorType.caption()),
          ],
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.today,
    required this.lessons,
    super.key,
  });

  final DateTime day;
  final DateTime today;
  final List<TutorLessonDto> lessons;

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;
    final isPast = day.isBefore(today);
    final label = isToday
        ? 'HÔM NAY · ${_dayLabel(day).toUpperCase()}'
        : _dayLabel(day).toUpperCase();

    // Buổi "Sắp tới" của hôm nay = buổi chưa xong đầu tiên.
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
        _Header(
          label: label,
          color: isToday ? TutorColors.ink : TutorColors.ink4,
          trailing: isToday ? '${lessons.length} buổi' : null,
        ),
        const SizedBox(height: 10),
        if (lessons.isEmpty)
          Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: TutorColors.surface,
              border: Border.all(color: TutorColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('Hôm nay bạn rảnh.', style: TutorType.rowSub()),
          ),
        for (var i = 0; i < lessons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _LessonRow(
            lesson: lessons[i],
            tag: isToday
                ? _tagFor(lessons[i], next)
                : (isPast && lessons[i].isFinished ? _Tag.done : null),
            accent: identical(lessons[i], next),
            past: isPast && lessons[i].isAwaitingReport,
          ),
        ],
      ],
    );
  }

  static _Tag? _tagFor(TutorLessonDto l, TutorLessonDto? next) {
    if (l.isLive) return _Tag.live;
    if (l.isFinished) return _Tag.done;
    if (l.isAwaitingReport) return _Tag.needReport;
    if (identical(l, next)) return _Tag.next;
    return _Tag.later;
  }
}

enum _Tag { next, later, live, done, needReport }

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    this.tag,
    this.accent = false,
    this.past = false,
  });

  final TutorLessonDto lesson;
  final _Tag? tag;
  final bool accent;

  /// Buổi đã qua, chưa có báo cáo.
  final bool past;

  @override
  Widget build(BuildContext context) {
    final start = lesson.startDt?.toLocal();
    final end = lesson.endDt?.toLocal();
    final minutes = (start != null && end != null)
        ? end.difference(start).inMinutes
        : null;
    final ink = past ? TutorColors.ink3 : TutorColors.ink;

    return Material(
      color: past ? TutorColors.surfaceSunken : TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, lesson),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.timeStart,
                      style: TutorType.rowTitle(color: ink).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      minutes != null && minutes > 0 ? '$minutes phút' : '',
                      style: TutorType.caption().copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 3,
                height: 42,
                decoration: BoxDecoration(
                  color: (accent || past)
                      ? TutorColors.primary
                      : TutorColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TutorType.rowTitle(color: ink),
                    ),
                    const SizedBox(height: 3),
                    if (past)
                      Row(
                        children: [
                          const Icon(
                            Icons.mic_off_outlined,
                            size: 12,
                            color: TutorColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Chưa có báo cáo',
                              style: TutorType.caption(
                                color: TutorColors.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _sub(lesson),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TutorType.rowSub(),
                      ),
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 8),
                _TagChip(tag: tag!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Buổi booking → chi tiết buổi. Buổi ngoài nền tảng → báo cáo (nếu đã ghi)
  /// hoặc hồ sơ học sinh (có nút ghi âm).
  static void _open(BuildContext context, TutorLessonDto l) {
    if (!l.isOffPlatform) {
      TutorSessionDetailScreen.open(context, l);
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

  static String _sub(TutorLessonDto l) {
    final parts = <String>[
      if (l.subjectName.isNotEmpty) l.subjectName,
      if (l.linkLabel != null) l.linkLabel!,
    ];
    return parts.join(' · ');
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final _Tag tag;

  @override
  Widget build(BuildContext context) {
    final (label, bg, border, fg) = switch (tag) {
      _Tag.next => (
        'Sắp tới',
        TutorColors.primaryBg,
        TutorColors.primaryBorder,
        TutorColors.primary,
      ),
      _Tag.later => (
        'Chờ',
        TutorColors.surfaceSunken,
        TutorColors.line,
        TutorColors.ink3,
      ),
      _Tag.live => (
        'Đang dạy',
        TutorColors.successBg,
        TutorColors.successBorder,
        TutorColors.success,
      ),
      _Tag.done => (
        'Xong',
        TutorColors.successBg,
        TutorColors.successBorder,
        TutorColors.success,
      ),
      _Tag.needReport => (
        'Cần báo cáo',
        TutorColors.primaryBg,
        TutorColors.primaryBorder,
        TutorColors.primary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TutorType.caption(color: fg)),
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
