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
              child: ColoredBox(color: TutorColors.ink.withValues(alpha: 0.34)),
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
                  color: TutorColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.only(bottom: media.padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TutorColors.line,
                        borderRadius: BorderRadius.circular(999),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ghi âm buổi học', style: TutorType.screenTitle()),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TutorColors.surface,
              border: Border.all(color: TutorColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: live ? TutorColors.success : TutorColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      live ? 'Buổi đang diễn ra' : 'Buổi hôm nay',
                      style: TutorType.caption(
                        color: live ? TutorColors.success : TutorColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(session.studentName, style: TutorType.numeralLarge()),
                const SizedBox(height: 5),
                if (session.subjectName.isNotEmpty) ...[
                  Text(session.subjectName, style: TutorType.rowTitle()),
                  const SizedBox(height: 5),
                ],
                Text(timeLine, style: TutorType.rowSub()),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: TutorColors.line),
                const SizedBox(height: 14),
                const _RecipientBox(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Bắt đầu ghi âm',
            icon: Icons.mic_none_rounded,
            onPressed: onStart,
          ),
          if (canPickOther) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: onPickOther,
                child: Text(
                  'Chọn buổi khác',
                  style: TutorType.action(color: TutorColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Báo cáo sẽ gửi cho" — server là nơi quyết định người nhận, nên ở đây chỉ
/// nói rõ báo cáo đi tới phụ huynh của học sinh trong buổi này.
class _RecipientBox extends StatelessWidget {
  const _RecipientBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TutorColors.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Báo cáo sẽ gửi cho', style: TutorType.caption()),
          const SizedBox(height: 7),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TutorColors.surface,
                  border: Border.all(color: TutorColors.line),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: TutorColors.ink,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Phụ huynh của học sinh',
                  style: TutorType.rowTitle(),
                ),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Chọn buổi học', style: TutorType.screenTitle()),
        const SizedBox(height: 5),
        Text(
          sessions.isEmpty || debugUpcoming
              ? 'Hôm nay không có buổi nào theo lịch. Chọn học sinh bạn đang dạy — báo cáo gửi cho phụ huynh của học sinh đó.'
              : 'Có ${sessions.length} buổi hôm nay. Báo cáo gửi theo buổi bạn chọn.',
          style: TutorType.rowSub(),
        ),
        const SizedBox(height: 16),
        if (debugUpcoming) ...[
          const _GroupLabel('SẮP TỚI · CHỈ HIỆN Ở BẢN DEBUG'),
          const SizedBox(height: 10),
        ] else if (sessions.isNotEmpty && students.isNotEmpty) ...[
          const _GroupLabel('HÔM NAY'),
          const SizedBox(height: 10),
        ],
        for (final s in sessions) ...[
          _SessionRow(
            session: s,
            closest: identical(s, widget.closest),
            selected: identical(s, _selected),
            onSelect: () => setState(() => _selected = s),
            onStart: () => widget.onStart(s),
          ),
          const SizedBox(height: 10),
        ],
        if (students.isNotEmpty || onAddStudent != null) ...[
          if (sessions.isNotEmpty) const SizedBox(height: 10),
          const _GroupLabel('HỌC SINH CỦA TÔI'),
          const SizedBox(height: 10),
          for (final st in students) ...[
            _StudentRow(
              student: st,
              selected: identical(st, _selected),
              onSelect: () => setState(() => _selected = st),
              onStart: () => widget.onStartStudent?.call(st),
            ),
            const SizedBox(height: 10),
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

  /// Buổi đang được chọn (viền đỏ đô + nút Ghi âm tô đậm). Chạm cả thẻ để chọn.
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final sub = [
      session.subjectName,
      _when(session),
    ].where((p) => p.isNotEmpty).join(' · ');

    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? TutorColors.primary : TutorColors.line,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                            style: TutorType.rowTitle(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (closest) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TutorColors.primaryBg,
                              border: Border.all(
                                color: TutorColors.primaryBorder,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Gần nhất',
                              style: TutorType.caption(
                                color: TutorColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(sub, style: TutorType.rowSub()),
                    const SizedBox(height: 3),
                    Text('Báo cáo → Phụ huynh', style: TutorType.caption()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: selected
                    ? FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: TutorColors.primary,
                          foregroundColor: TutorColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Ghi âm',
                          style: TutorType.action(color: TutorColors.surface),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onStart,
                        style: OutlinedButton.styleFrom(
                          // Theme app đặt minimumSize rộng vô hạn cho OutlinedButton.
                          minimumSize: const Size(0, 36),
                          backgroundColor: TutorColors.surface,
                          side: const BorderSide(color: TutorColors.line),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Ghi âm', style: TutorType.action()),
                      ),
              ),
            ],
          ),
        ),
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TutorSkeleton(height: 92, radius: 14),
          SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 34,
            color: TutorColors.ink4,
          ),
          const SizedBox(height: 12),
          Text(
            'Hôm nay không có buổi nào trên Tutora',
            style: TutorType.rowTitle(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Dạy học sinh ngoài nền tảng? Thêm học sinh để ghi âm buổi học và '
            'gửi báo cáo cho phụ huynh qua Zalo.',
            style: TutorType.rowSub(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onAddStudent,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: TutorColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Thêm học sinh'),
            ),
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
  Widget build(BuildContext context) => Text(
    text,
    style: TutorType.caption().copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
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

  /// Đang được chọn (viền đỏ đô + nút Ghi âm tô đậm). Chạm cả thẻ để chọn.
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
    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? TutorColors.primary : TutorColors.line,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: student.isDeclined ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              TutorAvatar(name: student.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TutorType.rowTitle(),
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
              SizedBox(
                height: 44,
                child: selected
                    ? FilledButton(
                        onPressed: student.isDeclined ? null : onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: TutorColors.primary,
                          foregroundColor: TutorColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Ghi âm',
                          style: TutorType.action(color: TutorColors.surface),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: student.isDeclined ? null : onStart,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          backgroundColor: TutorColors.surface,
                          side: const BorderSide(color: TutorColors.line),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Ghi âm', style: TutorType.action()),
                      ),
              ),
            ],
          ),
        ),
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
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 18,
                color: TutorColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Thêm học sinh ngoài Tutora',
                style: TutorType.action(color: TutorColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: TutorColors.primary,
          foregroundColor: TutorColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: TutorType.action(color: TutorColors.surface)),
      ),
    );
  }
}
