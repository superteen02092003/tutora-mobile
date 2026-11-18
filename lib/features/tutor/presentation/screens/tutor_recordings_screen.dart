import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Bản ghi âm (design V5.6, board V56-Score): màn con mở từ Lộ trình, nút tròn
/// quay lại, không có thanh tab riêng. "Buổi ghi âm tốt" của tuần này
/// (`weeklyRecordingProvider`, phase1-api mục B), các buổi không có bản ghi
/// kèm chip "Chuyện gì đã xảy ra?" (lưu lý do qua điểm danh, mục C), và các
/// bản ghi gần đây.
///
/// Khác board có chủ đích: nút "Ghi âm buổi học" ở đầu màn (mở lại màn "Đang
/// ghi" nếu đang có buổi ghi dở). Khi API tuần lỗi, màn quay về cách cũ: đếm
/// buổi đã ghi trong 7 ngày qua và hàng "không có bản ghi" mở hồ sơ học sinh.
class TutorRecordingsScreen extends ConsumerWidget {
  const TutorRecordingsScreen({super.key});

  static const _recorded = {
    'processing',
    'awaiting_approval',
    'failed',
    'sent',
  };

  void _record(BuildContext context, WidgetRef ref) {
    final recording = ref.read(lessonRecordingProvider);
    final target = ref.read(lessonRecordingProvider.notifier).target;
    if (recording.isRecording && target != null) {
      unawaited(context.push(AppRoutes.tutorRecording, extra: target));
    } else {
      unawaited(context.push(AppRoutes.tutorRecorder));
    }
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tutorPath);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recorderAllLessonsProvider);
    final lessons = async.valueOrNull ?? const <RecorderLessonDto>[];
    final isRecording = ref.watch(lessonRecordingProvider).isRecording;

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final lastWeek = lessons.where((l) {
      final w = l.when;
      return w != null &&
          w.isAfter(weekAgo) &&
          w.isBefore(now) &&
          l.status != 'discarded';
    }).toList();
    final recorded = lastWeek.where((l) => _recorded.contains(l.status)).length;
    final missed = lastWeek.where((l) => l.status == 'scheduled').toList()
      ..sort((a, b) => b.when!.compareTo(a.when!));
    final recent =
        lessons
            .where((l) => _recorded.contains(l.status) && l.when != null)
            .toList()
          ..sort((a, b) => b.when!.compareTo(a.when!));
    final shown = recent.length < 20 ? recent.length : 20;

    // "Ghi âm tốt" theo tuần (API B). Lỗi → số buổi đã ghi 7 ngày qua như cũ.
    final weeklyAsync = ref.watch(weeklyRecordingProvider);
    final weekly = weeklyAsync.valueOrNull;
    final week = weekly?.currentWeek;
    final weeklyLoading = weekly == null && !weeklyAsync.hasError;
    final weekStart = week?.weekStart;
    final subtitle = week != null && weekStart != null
        ? 'Tuần này · ${_d(weekStart)} đến '
              '${_d(weekStart.add(const Duration(days: 6)))}'
        : '7 ngày qua · ${_d(weekAgo)} đến ${_d(now)}';
    final missing = [...?weekly?.missing]
      ..sort((a, b) {
        final x = a.scheduledStart;
        final y = b.scheduledStart;
        if (x == null || y == null) return x == null ? 1 : -1;
        return y.compareTo(x);
      });

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () async => ref
              ..invalidate(recorderAllLessonsProvider)
              ..invalidate(weeklyRecordingProvider),
            child: ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 32,
              ),
              children: [
                // Đầu màn: nút quay lại + tiêu đề, nút bóng đèn "Mẹo ghi âm".
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    20,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Row(
                    children: [
                      CanvasBackButton(onTap: () => _back(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bản ghi âm',
                              style: TutorType.display(size: 24),
                            ),
                            const SizedBox(height: 2),
                            Text(subtitle, style: TutorType.rowSub()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CanvasCircleButton(
                        tooltip: 'Mẹo ghi âm',
                        onTap: () => unawaited(
                          context.push(AppRoutes.tutorRecordingTips),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: TutorColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    18,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: CanvasCta(
                    label: isRecording
                        ? 'Quay lại buổi đang ghi'
                        : 'Ghi âm buổi học',
                    icon: const Icon(Icons.mic_none_rounded, size: 18),
                    onPressed: () => _record(context, ref),
                  ),
                ),
                // Thẻ "Buổi ghi âm tốt" (API tuần); API lỗi → số buổi đã ghi
                // 7 ngày qua như trước.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    14,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: week != null
                      ? _CountCard(
                          label: 'Buổi ghi âm tốt',
                          done: week.usable,
                          total: week.lessonsDue,
                          note: week.lessonsDue == 0
                              ? 'Chưa có buổi nào trong tuần này.'
                              : 'Ghi âm tốt là nền tảng, không cộng điểm.',
                        )
                      : weeklyLoading
                      // Đang tải: chỉ nhãn + thanh trống, không đoán số.
                      ? const _CountCard(label: 'Buổi ghi âm tốt')
                      : _CountCard(
                          label: 'Buổi đã ghi âm',
                          done: recorded,
                          total: lastWeek.length,
                          note: lastWeek.isEmpty
                              ? 'Chưa có buổi nào trong 7 ngày qua.'
                              : 'Ghi âm đều là nền tảng, không cộng điểm. Thế nào là "ghi tốt" vẫn đang được thống nhất.',
                        ),
                ),
                // Buổi không có bản ghi (API tuần): mỗi buổi một thẻ sage có
                // chip lý do.
                if (weekly != null)
                  for (final m in missing)
                    Padding(
                      key: ValueKey('missing-${m.lessonId}'),
                      padding: const EdgeInsets.fromLTRB(
                        TutorSurface.gutter,
                        12,
                        TutorSurface.gutter,
                        0,
                      ),
                      child: _MissingCard(missing: m),
                    ),
                // API tuần lỗi → thẻ cũ (chạm mở hồ sơ học sinh).
                if (weeklyAsync.hasError && weekly == null && missed.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      12,
                      TutorSurface.gutter,
                      0,
                    ),
                    child: _MissedCard(
                      missed: missed,
                      label: (l) => '${_dt(l.when!)} · ${l.studentName}',
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    22,
                    TutorSurface.gutter,
                    4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text('Gần đây', style: TutorType.sectionTitle()),
                      ),
                      if (recent.isNotEmpty)
                        Text(
                          '${recent.length} buổi',
                          style: TutorType.rowSub(),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: TutorSurface.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (async.isLoading && lessons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: TutorColors.primary,
                            ),
                          ),
                        )
                      else if (recent.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Chưa có bản ghi nào.',
                            style: TutorType.rowSub(),
                          ),
                        )
                      else
                        for (var i = 0; i < shown; i++)
                          _RecentRow(
                            lesson: recent[i],
                            first: i == 0,
                            onTap: () => TutorRecordingDetailScreen.open(
                              context,
                              RecordingDetailArgs(
                                recordingId: recent[i].lessonId,
                                studentName: recent[i].studentName,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    18,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: CanvasTipBox(
                    'Gắn việc bấm ghi âm với một việc bạn luôn làm: "Khi học sinh mở vở, mình bấm ghi âm."',
                    bold: 'Một thói quen có ích:',
                  ),
                ),
                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.only(right: 28),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CanvasHand('Học sinh mở vở, bấm ghi', size: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _d(DateTime d) => '${d.day}/${d.month}';

  static String _dt(DateTime d) {
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${wd[d.weekday - 1]} ${d.day}/${d.month} $hh:$mm';
  }
}

/// Thẻ đếm "đạt / tổng", thanh chia ô, một dòng ghi chú. Không có [total]
/// (đang tải) thì chỉ hiện nhãn và thanh trống — không đoán số.
class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, this.done, this.total, this.note});

  final String label;
  final int? done;
  final int? total;
  final String? note;

  @override
  Widget build(BuildContext context) => CanvasOutlineCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TutorType.caption()),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: done == null ? '–' : '$done'),
              if (total != null)
                TextSpan(
                  text: ' / $total',
                  style: TutorType.display(
                    size: 20,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8A8F89),
                  ),
                ),
            ],
          ),
          style: TutorType.display(
            size: 40,
            weight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        _SegmentBar(done: done ?? 0, total: total ?? 0),
        if (note != null) ...[
          const SizedBox(height: 10),
          Text(note!, style: TutorType.rowSub()),
        ],
      ],
    ),
  );
}

/// Chữ của các lý do (`RecorderAbsenceReason`).
const Map<String, String> _reasonLabels = {
  RecorderAbsenceReason.cancelled: 'Buổi bị huỷ',
  RecorderAbsenceReason.pupilAbsent: 'Học sinh vắng',
  RecorderAbsenceReason.forgot: 'Tôi quên',
  RecorderAbsenceReason.battery: 'Hết pin',
  RecorderAbsenceReason.appProblem: 'Lỗi ứng dụng',
  RecorderAbsenceReason.other: 'Lý do khác',
};

/// Chip hiện trên thẻ (board V56-Score; không có "Lý do khác").
const List<String> _reasonChips = [
  RecorderAbsenceReason.cancelled,
  RecorderAbsenceReason.pupilAbsent,
  RecorderAbsenceReason.forgot,
  RecorderAbsenceReason.battery,
  RecorderAbsenceReason.appProblem,
];

/// Thẻ sage "Không có bản ghi · T7 7/11 · Bảo, 17:30 / Chuyện gì đã xảy ra?"
/// kèm chip lý do. Chạm chip → điểm danh vắng với lý do đó rồi hiện "Đã ghi:
/// …". Buổi đã có lý do thì chỉ hiện lý do.
class _MissingCard extends ConsumerStatefulWidget {
  const _MissingCard({required this.missing});

  final MissingRecording missing;

  @override
  ConsumerState<_MissingCard> createState() => _MissingCardState();
}

class _MissingCardState extends ConsumerState<_MissingCard> {
  String? _chosen;
  String? _saving;

  Future<void> _pick(String reason) async {
    if (_saving != null) return;
    setState(() => _saving = reason);
    try {
      await ref
          .read(recorderLessonActionsProvider)
          .setAttendance(
            widget.missing.lessonId,
            RecorderAttendance.absent,
            reason: reason,
          );
      if (mounted) setState(() => _chosen = reason);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa lưu được lý do. Thử lại nhé.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  String get _title {
    final m = widget.missing;
    final w = m.scheduledStart;
    if (w == null) return 'Không có bản ghi · ${m.studentName}';
    const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final hh = w.hour.toString().padLeft(2, '0');
    final mm = w.minute.toString().padLeft(2, '0');
    return 'Không có bản ghi · ${wd[w.weekday - 1]} ${w.day}/${w.month} · '
        '${m.studentName}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final reason = _chosen ?? widget.missing.absenceReason;
    return DecoratedBox(
      decoration: TutorSurface.sage(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: TutorType.caption(color: TutorColors.ink)),
            const SizedBox(height: 6),
            if (reason != null)
              Text(
                'Đã ghi: ${_reasonLabels[reason] ?? reason}',
                style: TutorType.body(),
              )
            else ...[
              Text('Chuyện gì đã xảy ra?', style: TutorType.body()),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in _reasonChips)
                    _ReasonChip(
                      label: _reasonLabels[r]!,
                      busy: _saving == r,
                      onTap: _saving == null ? () => unawaited(_pick(r)) : null,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip lý do: nền sáng trên thẻ sage, cao tối thiểu 36.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, required this.busy, this.onTap});

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: const Color(0xFFF8F7F4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: TutorColors.ink,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(label, style: TutorType.caption(color: TutorColors.ink)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Thanh chia ô: mỗi buổi một ô, ô đã ghi tô mực. Nhiều buổi quá thì dùng một
/// thanh liền.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.done, required this.total});

  final int done;
  final int total;

  static const _off = Color(0x241F2A24);

  @override
  Widget build(BuildContext context) {
    if (total == 0 || total > 14) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : done / total,
          minHeight: 6,
          backgroundColor: _off,
          color: TutorColors.ink,
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < done ? TutorColors.ink : _off,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Thẻ sage "Không có bản ghi" khi API tuần lỗi: mỗi buổi thiếu một hàng, chạm
/// mở hồ sơ học sinh.
class _MissedCard extends StatelessWidget {
  const _MissedCard({required this.missed, required this.label});

  final List<RecorderLessonDto> missed;
  final String Function(RecorderLessonDto) label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: TutorSurface.sage(),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Không có bản ghi',
              style: TutorType.caption(color: TutorColors.ink),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < missed.length; i++)
              InkWell(
                onTap: missed[i].studentId == null
                    ? null
                    : () => TutorStudentDetailScreen.open(
                        context,
                        missed[i].studentId!,
                      ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  decoration: BoxDecoration(
                    border: Border(
                      top: i == 0 ? BorderSide.none : TutorSurface.rule,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label(missed[i]), style: TutorType.body()),
                      ),
                      if (missed[i].studentId != null) const CanvasChevron(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Hàng bản ghi gần đây: ô micro, "Tên · ngày", thời lượng nếu có.
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.lesson,
    required this.first,
    required this.onTap,
  });

  final RecorderLessonDto lesson;
  final bool first;
  final VoidCallback onTap;

  String? get _duration {
    if (lesson.durationSec <= 0) return null;
    final mins = (lesson.durationSec / 60).round();
    final start = lesson.scheduledStart;
    final end = lesson.scheduledEnd;
    if (start != null && end != null && end.isAfter(start)) {
      return '$mins/${end.difference(start).inMinutes} phút';
    }
    return '$mins phút';
  }

  @override
  Widget build(BuildContext context) {
    final when = lesson.when!;
    final duration = _duration;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(top: first ? BorderSide.none : TutorSurface.rule),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: TutorSurface.well(),
              child: const Icon(
                Icons.mic_none_rounded,
                size: 18,
                color: TutorColors.ink,
              ),
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
                      Text(
                        ' · ${when.day}/${when.month}',
                        style: TutorType.body(),
                      ),
                    ],
                  ),
                  if (duration != null)
                    Text(duration, style: TutorType.rowSub()),
                ],
              ),
            ),
            if (lesson.status == 'awaiting_approval') ...[
              const CanvasTag('Duyệt', filled: true),
              const SizedBox(width: 10),
            ],
            const CanvasChevron(),
          ],
        ),
      ),
    );
  }
}
