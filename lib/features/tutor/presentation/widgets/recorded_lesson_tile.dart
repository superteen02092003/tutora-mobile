import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';

/// Một buổi đã ghi âm — dùng chung cho chi tiết lớp booking và hồ sơ học sinh
/// ngoài nền tảng. Chạm để mở màn Tóm tắt / Bản ghi / nghe lại.
class RecordedLessonTile extends StatelessWidget {
  const RecordedLessonTile({required this.lesson, this.studentName, super.key});

  final RecorderLessonDto lesson;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final d = lesson.startedAt ?? lesson.when;
    final date = d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} · '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final (label, bg, fg) = switch (lesson.status) {
      'sent' => lesson.deliveryStatus == 'sent'
          ? ('Đã gửi', TutorColors.successBg, TutorColors.success)
          : ('Đã duyệt · chờ gửi Zalo', TutorColors.accentBg, TutorColors.warning),
      'awaiting_approval' => ('Chờ duyệt', TutorColors.primaryBg, TutorColors.primary),
      'processing' => ('AI đang viết', TutorColors.accentBg, TutorColors.warning),
      'failed' => ('Lỗi', TutorColors.primaryBg, TutorColors.primary),
      _ => ('Đang ghi', TutorColors.accentBg, TutorColors.warning),
    };
    final minutes = (lesson.durationSec / 60).round();
    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => TutorRecordingDetailScreen.open(
          context,
          RecordingDetailArgs(
            recordingId: lesson.lessonId,
            studentName: studentName ?? lesson.studentName,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TutorColors.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.graphic_eq_rounded, size: 20, color: TutorColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: TutorColors.ink)),
                    const SizedBox(height: 3),
                    Text(
                      minutes > 0 ? '$minutes phút ghi âm' : 'Dưới 1 phút ghi âm',
                      style: const TextStyle(fontSize: 13, color: TutorColors.ink3),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: TutorColors.ink4),
            ],
          ),
        ),
      ),
    );
  }
}
