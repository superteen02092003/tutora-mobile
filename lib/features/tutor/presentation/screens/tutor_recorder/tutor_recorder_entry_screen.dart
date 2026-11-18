import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

/// Sheet chọn buổi trước khi ghi (prototype: "2 · Auto-detect · 1 buổi" và
/// "3 · Chọn buổi · 2+ buổi").
///
/// Chọn buổi ở ĐẦU buổi học, lúc gia sư đang nhìn thẳng vào học sinh — nhầm
/// người gần như không thể. Client chỉ giữ `lessonId`; tra ra phụ huynh nhận
/// báo cáo là việc của server, nên client không thể gửi nhầm người.
///
/// Route này mở dạng trong suốt (xem app_router) để trang chủ vẫn nằm phía sau.
class TutorRecorderEntryScreen extends ConsumerStatefulWidget {
  const TutorRecorderEntryScreen({super.key});

  @override
  ConsumerState<TutorRecorderEntryScreen> createState() =>
      _TutorRecorderEntryScreenState();
}

class _TutorRecorderEntryScreenState
    extends ConsumerState<TutorRecorderEntryScreen> {
  /// Gia sư bấm "Chọn buổi khác" ở màn xác nhận 1 buổi.
  bool _forceList = false;

  /// Buổi gần giờ hiện tại nhất.
  static TutorTodaySessionDto? _closest(List<TutorTodaySessionDto> sessions) {
    if (sessions.isEmpty) return null;
    final now = DateTime.now();
    TutorTodaySessionDto? best;
    Duration? bestGap;
    for (final s in sessions) {
      final start = DateTime.tryParse(s.scheduledStart)?.toLocal();
      final end = DateTime.tryParse(s.scheduledEnd)?.toLocal();
      if (start == null) continue;
      // Đang diễn ra thì gap = 0: luôn thắng.
      final gap = (end != null && now.isAfter(start) && now.isBefore(end))
          ? Duration.zero
          : start.difference(now).abs();
      if (bestGap == null || gap < bestGap) {
        bestGap = gap;
        best = s;
      }
    }
    return best ?? sessions.first;
  }

  void _start(TutorTodaySessionDto session) {
    final router = GoRouter.of(context);
    // Đóng sheet rồi mới mở màn "Đang ghi": nút quay lại / thu nhỏ trên màn
    // đó phải trả về trang chủ, không trả về sheet này.
    context.pop();
    unawaited(
      router.push(
        AppRoutes.tutorRecording,
        extra: RecordingTarget.fromSession(session),
      ),
    );
  }

  /// Học sinh ngoài nền tảng: đóng sheet rồi đi luồng xác nhận đồng ý + ghi.
  Future<void> _startStudent(RecorderStudentDto student) =>
      startStudentRecording(
        context,
        ref,
        student,
        // Đóng sheet ngay trước khi mở màn "Đang ghi" (giống _start).
        onBeforeStart: () => context.pop(),
      );

  /// Form tự tải lại danh bạ sau khi lưu (reloadRecorderStudentData).
  Future<void> _addStudent() async {
    await TutorStudentFormScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(tutorDashboardProvider);
    final upcoming = dash.data?.todaySessions ?? const <TutorTodaySessionDto>[];
    final offPlatformToday =
        (ref.watch(recorderTodayLessonsProvider).valueOrNull ??
                const <TutorTodaySessionDto>[])
            .where(
              (s) => const {
                'scheduled',
                'recording',
                'uploading',
              }.contains(s.recorderStatus),
            )
            .toList();
    final today = [...sessionsToday(upcoming), ...offPlatformToday];
    // Bản debug: hôm nay không có buổi thì cho chọn buổi SẮP TỚI để test ghi âm —
    // ghi nhãn rõ để không lẫn với buổi hôm nay.
    final debugUpcoming = today.isEmpty && kDebugMode && upcoming.isNotEmpty;
    final sessions = debugUpcoming ? upcoming : today;
    final loading = dash.isLoading && dash.data == null;
    final closest = _closest(sessions);
    final media = MediaQuery.of(context);

    final students =
        ref.watch(recorderStudentsProvider).valueOrNull ??
        const <RecorderStudentDto>[];

    final Widget body;
    if (loading) {
      body = const _Loading();
    } else if (sessions.length == 1 && students.isEmpty && !_forceList) {
      body = _ConfirmOne(
        session: sessions.first,
        canPickOther: false,
        onStart: () => _start(sessions.first),
        onPickOther: () => setState(() => _forceList = true),
      );
    } else if (sessions.isEmpty && students.isEmpty) {
      body = _NoSessionToday(onAddStudent: _addStudent);
    } else {
      body = _PickSession(
        sessions: sessions,
        debugUpcoming: debugUpcoming,
        closest: closest,
        onStart: _start,
        students: students,
        onStartStudent: _startStudent,
        onAddStudent: _addStudent,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Nền mờ — chạm để đóng.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: ColoredBox(color: TutorColors.ink.withValues(alpha: 0.28)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height - media.padding.top - 56,
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: TutorColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F1F2A24),
                      blurRadius: 30,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(bottom: media.padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TutorColors.ink.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(child: body),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mảnh dùng chung trong sheet (V5.6, giống sheet "Sửa buổi học") ──────────

/// Nền hàng/ô trong sheet: sáng hơn mặt sheet một chút.
const Color _rowBg = Color(0xFFFBFAF7);

/// Đầu sheet: tiêu đề Bricolage + "Huỷ" bên phải (đóng sheet như chạm nền).
class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: TutorType.display(size: 20))),
      InkWell(
        onTap: () => context.pop(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text('Huỷ', style: TutorType.rowSub()),
        ),
      ),
    ],
  );
}

/// Nút "Ghi âm" dạng viên thuốc trong hàng: chọn → mực đậm, chưa chọn → sage.
class _RecordPill extends StatelessWidget {
  const _RecordPill({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        backgroundColor: selected ? TutorColors.primary : TutorColors.sage,
        foregroundColor: selected ? Colors.white : TutorColors.ink,
        disabledBackgroundColor: TutorColors.surfaceSunken,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const StadiumBorder(),
      ),
      child: Text(
        'Ghi âm',
        style: TutorType.action(
          color: onPressed == null
              ? TutorColors.ink4
              : selected
              ? Colors.white
              : TutorColors.ink,
        ),
      ),
    ),
  );
}

/// Hàng chọn được: nền sáng; đang chọn → nền sage (như ô radio của sheet).
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? TutorColors.sage : _rowBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: child,
      ),
    ),
  );
}

// ── 1 buổi: xác nhận ───────────────────────────────────────────────────────

class _ConfirmOne extends StatelessWidget {
  const _ConfirmOne({
    required this.session,
    required this.canPickOther,
    required this.onStart,
    required this.onPickOther,
  });

  final TutorTodaySessionDto session;
  final bool canPickOther;
  final VoidCallback onStart;
  final VoidCallback onPickOther;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(session.scheduledStart)?.toLocal();
    final end = DateTime.tryParse(session.scheduledEnd)?.toLocal();
    final now = DateTime.now();
    final live =
        start != null && end != null && now.isAfter(start) && now.isBefore(end);
    final minutes = (start != null && end != null)
        ? end.difference(start).inMinutes
        : null;
    final timeLine = [
      '${session.timeStart} – ${session.timeEnd}',
      if (minutes != null && minutes > 0) '$minutes phút',
    ].join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        14,
        TutorSurface.gutter,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle('Ghi âm buổi học'),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusChip(
              live: live,
              label: live ? 'Buổi đang diễn ra' : 'Buổi hôm nay',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            decoration: BoxDecoration(
              color: _rowBg,
              borderRadius: BorderRadius.circular(TutorSurface.radius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.studentName, style: TutorType.display(size: 24)),
                const SizedBox(height: 4),
                if (session.subjectName.isNotEmpty) ...[
                  Text(session.subjectName, style: TutorType.rowTitle()),
                  const SizedBox(height: 2),
                ],
                Text(timeLine, style: TutorType.rowSub()),
                const SizedBox(height: 12),
                const _RecipientBox(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CanvasCta(
            label: 'Bắt đầu ghi âm',
            icon: const Icon(Icons.mic_none_rounded, size: 18),
            onPressed: onStart,
          ),
          if (canPickOther) ...[
            const SizedBox(height: 6),
            CanvasGhostLink(label: 'Chọn buổi khác', onTap: onPickOther),
          ],
        ],
      ),
    );
  }
}

/// Chip trạng thái buổi: chấm mực trên nền sage khi đang diễn ra.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.live, required this.label});

  final bool live;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: live ? TutorColors.sage : TutorColors.surfaceSunken,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: live ? TutorColors.ink : TutorColors.ink4,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TutorType.caption(
            color: TutorColors.ink,
          ).copyWith(fontSize: 11.5, height: 1),
        ),
      ],
    ),
  );
}

/// "Báo cáo sẽ gửi cho" — server là nơi quyết định người nhận, nên ở đây chỉ
/// nói rõ báo cáo đi tới phụ huynh của học sinh trong buổi này.
class _RecipientBox extends StatelessWidget {
  const _RecipientBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(top: TutorSurface.rule)),
      child: Row(
        children: [
          Text('Báo cáo sẽ gửi cho', style: TutorType.rowSub()),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Phụ huynh của học sinh',
              textAlign: TextAlign.right,
              style: TutorType.rowSub(color: TutorColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2+ buổi: chọn ──────────────────────────────────────────────────────────

class _PickSession extends StatefulWidget {
  const _PickSession({
    required this.sessions,
    required this.closest,
    required this.onStart,
    this.debugUpcoming = false,
    this.students = const [],
    this.onStartStudent,
    this.onAddStudent,
  });

  final List<TutorTodaySessionDto> sessions;

  /// Buổi gần giờ hiện tại nhất — chọn sẵn, gia sư chạm buổi khác để đổi.
  /// So bằng chính đối tượng, không bằng lessonId: buổi ngoài nền tảng đều
  /// có lessonId = 0.
  final TutorTodaySessionDto? closest;
  final ValueChanged<TutorTodaySessionDto> onStart;

  /// [sessions] là buổi SẮP TỚI (không phải hôm nay) — chỉ bản debug.
  final bool debugUpcoming;

  /// Học sinh ngoài nền tảng (danh bạ của gia sư).
  final List<RecorderStudentDto> students;
  final ValueChanged<RecorderStudentDto>? onStartStudent;
  final VoidCallback? onAddStudent;

  @override
  State<_PickSession> createState() => _PickSessionState();
}

class _PickSessionState extends State<_PickSession> {
  /// Buổi (TutorTodaySessionDto) hoặc học sinh (RecorderStudentDto) đang chọn.
  /// Không có buổi nào hôm nay thì chọn sẵn học sinh đầu tiên.
  late Object? _selected =
      widget.closest ??
      (widget.sessions.isEmpty && widget.students.isNotEmpty
          ? widget.students.first
          : null);

  List<TutorTodaySessionDto> get sessions => widget.sessions;
  bool get debugUpcoming => widget.debugUpcoming;
  List<RecorderStudentDto> get students => widget.students;
  VoidCallback? get onAddStudent => widget.onAddStudent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        14,
        TutorSurface.gutter,
        24,
      ),
      children: [
        const _SheetTitle('Chọn buổi học'),
        const SizedBox(height: 4),
        Text(
          sessions.isEmpty || debugUpcoming
              ? 'Hôm nay không có buổi nào theo lịch. Chọn học sinh bạn đang dạy — báo cáo gửi cho phụ huynh của học sinh đó.'
              : 'Có ${sessions.length} buổi hôm nay. Báo cáo gửi theo buổi bạn chọn.',
          style: TutorType.rowSub(),
        ),
        const SizedBox(height: 14),
        if (debugUpcoming) ...[
          const _GroupLabel('Sắp tới · chỉ hiện ở bản debug'),
          const SizedBox(height: 6),
        ] else if (sessions.isNotEmpty && students.isNotEmpty) ...[
          const _GroupLabel('Hôm nay'),
          const SizedBox(height: 6),
        ],
        for (final s in sessions) ...[
          _SessionRow(
            session: s,
            closest: identical(s, widget.closest),
            selected: identical(s, _selected),
            onSelect: () => setState(() => _selected = s),
            onStart: () => widget.onStart(s),
          ),
          const SizedBox(height: 6),
        ],
        if (students.isNotEmpty || onAddStudent != null) ...[
          if (sessions.isNotEmpty) const SizedBox(height: 8),
          const _GroupLabel('Học sinh của tôi'),
          const SizedBox(height: 6),
          for (final st in students) ...[
            _StudentRow(
              student: st,
              selected: identical(st, _selected),
              onSelect: () => setState(() => _selected = st),
              onStart: () => widget.onStartStudent?.call(st),
            ),
            const SizedBox(height: 6),
          ],
          if (onAddStudent != null) _AddStudentRow(onTap: onAddStudent!),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.closest,
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });

  final TutorTodaySessionDto session;

  /// Buổi gần giờ hiện tại nhất — chỉ để gắn nhãn "Gần nhất".
  final bool closest;

  /// Buổi đang được chọn (nền sage + nút Ghi âm tô đậm). Chạm cả thẻ để chọn.
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final sub = [
      session.subjectName,
      _when(session),
    ].where((p) => p.isNotEmpty).join(' · ');

    return _ChoiceTile(
      selected: selected,
      onTap: onSelect,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.studentName,
                        style: TutorType.body(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (closest) ...[
                      const SizedBox(width: 7),
                      CanvasTag('Gần nhất', filled: selected),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(sub, style: TutorType.rowSub()),
                const SizedBox(height: 2),
                Text('Báo cáo → Phụ huynh', style: TutorType.caption()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RecordPill(selected: selected, onPressed: onStart),
        ],
      ),
    );
  }

  /// "07:30", hoặc "T4 23/9 · 07:30" khi buổi không phải hôm nay.
  static String _when(TutorTodaySessionDto s) {
    final d = DateTime.tryParse(s.scheduledStart)?.toLocal();
    if (d == null) return s.timeStart;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return s.timeStart;
    }
    const dows = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return '${dows[d.weekday - 1]} ${d.day}/${d.month} · ${s.timeStart}';
  }
}

// ── Trạng thái khác ───────────────────────────────────────────────────────

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        20,
        TutorSurface.gutter,
        24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TutorSkeleton(height: 92, radius: 14),
          SizedBox(height: 6),
          TutorSkeleton(height: 92, radius: 14),
        ],
      ),
    );
  }
}

class _NoSessionToday extends StatelessWidget {
  const _NoSessionToday({required this.onAddStudent});

  final VoidCallback onAddStudent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        14,
        TutorSurface.gutter,
        28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle('Ghi âm buổi học'),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: TutorSurface.well(),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 20,
                color: TutorColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hôm nay không có buổi nào trên TopTutor',
            style: TutorType.body(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Dạy học sinh ngoài nền tảng? Thêm học sinh để ghi âm buổi học và '
            'gửi báo cáo cho phụ huynh qua Zalo.',
            style: TutorType.rowSub(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          CanvasCta(
            label: 'Thêm học sinh',
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            onPressed: onAddStudent,
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TutorType.caption(color: TutorColors.ink3));
}

/// Một học sinh ngoài nền tảng trong sheet chọn buổi.
class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.selected,
    required this.onSelect,
    required this.onStart,
  });

  final RecorderStudentDto student;

  /// Đang được chọn (nền sage + nút Ghi âm tô đậm). Chạm cả thẻ để chọn.
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (student.subtitle.isNotEmpty) student.subtitle,
      if (student.isDeclined)
        'Phụ huynh từ chối ghi âm'
      else if (!student.hasConsent)
        'Chưa có đồng ý ghi âm',
    ].join(' · ');
    return _ChoiceTile(
      selected: selected,
      onTap: student.isDeclined ? null : onSelect,
      child: Row(
        children: [
          TutorAvatar(name: student.fullName, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TutorType.body(),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.rowSub(
                      color: student.hasConsent
                          ? TutorColors.ink3
                          : TutorColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RecordPill(
            selected: selected,
            onPressed: student.isDeclined ? null : onStart,
          ),
        ],
      ),
    );
  }
}

class _AddStudentRow extends StatelessWidget {
  const _AddStudentRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: TutorColors.ink),
              const SizedBox(width: 6),
              Text('Thêm học sinh ngoài TopTutor', style: TutorType.action()),
            ],
          ),
        ),
      ),
    );
  }
}
