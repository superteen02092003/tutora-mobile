import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Một buổi đã ghi âm — dùng chung cho chi tiết lớp booking và hồ sơ học sinh
/// ngoài nền tảng. Chạm để mở màn Tóm tắt / Bản ghi / nghe lại.
class RecordedLessonTile extends StatelessWidget {
  const RecordedLessonTile({required this.lesson, this.studentName, super.key});

  final RecorderLessonDto lesson;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final d = lesson.startedAt ?? lesson.when;
    final day = d == null ? '—' : '${d.day}/${d.month}';
    final time = d == null
        ? ''
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final (label, approve) = switch (lesson.status) {
      'sent' =>
        lesson.deliveryStatus == 'sent'
            ? ('Đã gửi', false)
            : ('Đã duyệt · chờ gửi Zalo', false),
      'awaiting_approval' => ('Duyệt', true),
      'processing' => ('AI đang viết', false),
      'failed' => ('Lỗi', false),
      _ => ('Đang ghi', false),
    };
    final minutes = (lesson.durationSec / 60).round();
    final sub = [
      if (time.isNotEmpty) time,
      if (minutes > 0) '$minutes phút ghi âm' else 'dưới 1 phút ghi âm',
    ].join(' · ');
    // Canvas: hàng kẻ mực — ngày lớn Bricolage, thẻ chữ hoa bên phải.
    return CanvasRow(
      onTap: () => TutorRecordingDetailScreen.open(
        context,
        RecordingDetailArgs(
          recordingId: lesson.lessonId,
          studentName: studentName ?? lesson.studentName,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              day,
              style: TutorType.display(
                size: 22,
                weight: FontWeight.w600,
                color: TutorColors.ink,
              ).copyWith(letterSpacing: -0.5),
            ),
          ),
          Expanded(
            child: Text(
              sub,
              style: const TextStyle(fontSize: 15, color: TutorColors.ink3),
            ),
          ),
          if (approve)
            const CanvasTag('Duyệt', filled: true)
          else
            CanvasKicker(
              label,
              color: lesson.status == 'failed'
                  ? TutorColors.danger
                  : TutorColors.ink3,
            ),
          const SizedBox(width: 8),
          const CanvasChevron(),
        ],
      ),
    );
  }
}
