import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Bản ghi âm (design V5.6, board V56-Score): màn con mở từ Lộ trình, nút tròn
/// quay lại, không có thanh tab riêng. Số buổi đã ghi trong 7 ngày qua, buổi
/// lẽ ra có mà không có bản ghi, và các bản ghi gần đây.
///
/// Khác board có chủ đích: nút "Ghi âm buổi học" ở đầu màn (mở lại màn "Đang
/// ghi" nếu đang có buổi ghi dở). Board đếm "ghi âm tốt" và có chip "Chuyện gì
/// đã xảy ra?" — chưa có dữ liệu chất lượng bản ghi và chưa có API lưu lý do,
/// nên màn đếm buổi đã ghi và hàng "không có bản ghi" chỉ mở hồ sơ học sinh.
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

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () async => ref.invalidate(recorderAllLessonsProvider),
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
                            Text(
                              '7 ngày qua · ${_d(weekAgo)} đến ${_d(now)}',
                              style: TutorType.rowSub(),
                            ),
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
                // Thẻ số buổi đã ghi.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    14,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: CanvasOutlineCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buổi đã ghi âm', style: TutorType.caption()),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '$recorded'),
                              TextSpan(
                                text: ' / ${lastWeek.length}',
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
                        _SegmentBar(done: recorded, total: lastWeek.length),
                        const SizedBox(height: 10),
                        Text(
                          lastWeek.isEmpty
                              ? 'Chưa có buổi nào trong 7 ngày qua.'
                              : 'Ghi âm đều là nền tảng, không cộng điểm. Thế nào là "ghi tốt" vẫn đang được thống nhất.',
                          style: TutorType.rowSub(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (missed.isNotEmpty)
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

/// Thẻ sage "Không có bản ghi": mỗi buổi thiếu một hàng, chạm mở hồ sơ học sinh.
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
