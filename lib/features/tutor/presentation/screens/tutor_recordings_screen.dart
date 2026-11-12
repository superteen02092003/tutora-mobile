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

/// T6 · Ghi âm (design canvas 11/2026): số buổi đã ghi trong 7 ngày qua, buổi
/// lẽ ra có mà không có bản ghi, và các bản ghi gần đây.
///
/// Khác canvas một điểm có chủ đích: nút "Ghi âm buổi học" ở đầu màn. Canvas bỏ
/// nút mic nổi; ghi âm vẫn là việc chính nên tab này giữ một lối vào nhanh (và
/// mở lại màn "Đang ghi" nếu đang có buổi ghi dở). Các nút "Vì sao không ghi?"
/// của canvas chưa có API lưu lý do — hàng chỉ mở hồ sơ học sinh.
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

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: TutorColors.ink2,
          onRefresh: () async => ref.invalidate(recorderAllLessonsProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              CanvasHeader(
                left: '7 ngày qua · ${_d(weekAgo)}–${_d(now)}',
                title: 'Bản ghi của bạn',
                titleSize: 40,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  20,
                  TutorSurface.gutter,
                  0,
                ),
                child: CanvasCta(
                  label: isRecording
                      ? 'Quay lại buổi đang ghi'
                      : 'Ghi âm buổi học',
                  icon: const Icon(
                    Icons.circle,
                    size: 14,
                    color: TutorColors.ink,
                  ),
                  onPressed: () => _record(context, ref),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  26,
                  TutorSurface.gutter,
                  0,
                ),
                child: CanvasRow(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$recorded'),
                            TextSpan(
                              text: ' / ${lastWeek.length}',
                              style: TutorType.display(
                                size: 44,
                                weight: FontWeight.w300,
                                color: TutorColors.ink3,
                              ).copyWith(letterSpacing: -1),
                            ),
                          ],
                        ),
                        style: TutorType.display(
                          size: 110,
                          weight: FontWeight.w300,
                          color: TutorColors.ink,
                          height: 0.9,
                        ).copyWith(letterSpacing: -6),
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: lastWeek.isEmpty
                              ? 0
                              : recorded / lastWeek.length,
                          minHeight: 4,
                          backgroundColor: TutorColors.surfaceSunken,
                          color: TutorColors.success,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lastWeek.isEmpty
                            ? 'Chưa có buổi nào trong 7 ngày qua.'
                            : 'Buổi đã ghi âm. Ghi âm đều là nền của bạn: phần này không cộng điểm. Thế nào là "ghi tốt" vẫn đang được thống nhất.',
                        style: TutorType.rowSub().copyWith(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (missed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    26,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: CanvasKicker('Không có bản ghi'),
                      ),
                      for (final l in missed)
                        CanvasRow(
                          onTap: l.studentId == null
                              ? null
                              : () => TutorStudentDetailScreen.open(
                                  context,
                                  l.studentId!,
                                ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_dt(l.when!)} · ${l.studentName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: TutorColors.ink,
                                  ),
                                ),
                              ),
                              const CanvasChevron(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  26,
                  TutorSurface.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CanvasKicker('Bản ghi gần đây'),
                    ),
                    if (async.isLoading && lessons.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: TutorColors.ink2,
                          ),
                        ),
                      )
                    else if (recent.isEmpty)
                      Text('Chưa có bản ghi nào.', style: TutorType.rowSub())
                    else
                      for (var i = 0; i < recent.length && i < 20; i++)
                        CanvasRow(
                          lastRule: i == recent.length - 1 || i == 19,
                          onTap: () => TutorRecordingDetailScreen.open(
                            context,
                            RecordingDetailArgs(
                              recordingId: recent[i].lessonId,
                              studentName: recent[i].studentName,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 76,
                                child: Text(
                                  '${recent[i].when!.day}/${recent[i].when!.month}',
                                  style: TutorType.display(
                                    size: 22,
                                    weight: FontWeight.w600,
                                    color: TutorColors.ink,
                                  ).copyWith(letterSpacing: -0.5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  recent[i].studentName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: TutorColors.ink,
                                  ),
                                ),
                              ),
                              if (recent[i].status == 'awaiting_approval') ...[
                                const CanvasTag('Duyệt', filled: true),
                                const SizedBox(width: 10),
                              ],
                              const CanvasChevron(),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  14,
                  TutorSurface.gutter,
                  0,
                ),
                child: CanvasGhostLink(
                  label: 'Mẹo ghi âm ›',
                  onTap: () => context.push(AppRoutes.tutorRecordingTips),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  14,
                  TutorSurface.gutter,
                  0,
                ),
                child: CanvasExpander(
                  title: 'Một thói quen có ích',
                  lastRule: true,
                  children: [
                    Text(
                      'Gắn việc bấm ghi âm với một việc bạn luôn làm: "Khi học sinh mở vở, mình bấm ghi âm."',
                    ),
                  ],
                ),
              ),
            ],
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
