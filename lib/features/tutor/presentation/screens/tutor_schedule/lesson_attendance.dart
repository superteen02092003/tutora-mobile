import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

// Điểm danh + huỷ buổi recorder trên tab Bài học (board V56-Attendance).

/// Buổi recorder (đủ trường điểm danh / dời / huỷ) trong khoảng của agenda,
/// theo `lessonId`. Agenda chỉ giữ `TutorLessonDto` rút gọn, nên tra thêm ở đây.
///
/// Theo dõi [tutorAgendaLessonsProvider]: mọi lần agenda tải lại (kéo làm mới,
/// sau khi điểm danh / dời / huỷ) thì bảng này cũng tải lại.
final AutoDisposeFutureProvider<Map<String, RecorderLessonDto>>
agendaRecorderLessonsProvider =
    FutureProvider.autoDispose<Map<String, RecorderLessonDto>>((ref) async {
      ref.watch(tutorAgendaLessonsProvider.future).ignore();
      final first = tutorAgendaFirstMonth();
      const total = tutorAgendaMonthsBefore + tutorAgendaMonthsAfter + 1;
      final lastDay = DateTime(first.year, first.month + total, 0);
      final list = await ref
          .read(recorderDatasourceProvider)
          .lessons(from: first, to: lastDay.add(const Duration(days: 1)));
      return {for (final l in list) l.lessonId: l};
    });

/// Nhãn lý do vắng / không ghi âm.
String absenceReasonLabel(String? reason) => switch (reason) {
  RecorderAbsenceReason.cancelled => 'Buổi bị huỷ',
  RecorderAbsenceReason.pupilAbsent => 'Học sinh vắng',
  RecorderAbsenceReason.forgot => 'Tôi quên ghi âm',
  RecorderAbsenceReason.battery => 'Hết pin',
  RecorderAbsenceReason.appProblem => 'Lỗi ứng dụng',
  RecorderAbsenceReason.other => 'Khác',
  _ => 'Không rõ lý do',
};

/// Nhãn lý do huỷ buổi.
String cancelReasonLabel(String reason) => switch (reason) {
  RecorderCancelReason.cancelled => 'Buổi bị huỷ',
  RecorderCancelReason.pupilAbsent => 'Học sinh vắng',
  _ => 'Lý do khác',
};

/// "Vắng · Học sinh vắng", "Có mặt · tự điểm danh", "Có mặt"; null khi chưa
/// điểm danh.
String? attendanceLine(RecorderLessonDto l) {
  if (l.isAbsent) return 'Vắng · ${absenceReasonLabel(l.absenceReason)}';
  if (l.autoPresent) return 'Có mặt · tự điểm danh';
  if (l.isPresent) return 'Có mặt';
  return null;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// "Đã dời từ 12/11 16:30"
String movedFromLine(DateTime from) {
  final d = from.toLocal();
  return 'Đã dời từ ${d.day}/${d.month} ${_two(d.hour)}:${_two(d.minute)}';
}

/// Lời nhắn lỗi của server (`message`), hoặc [fallback].
String apiErrorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.trim().isNotEmpty) return m.trim();
    }
  }
  return fallback;
}

/// Đánh dấu có mặt / vắng rồi báo bằng toast. Trả về true khi thành công.
Future<bool> markAttendance(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  required String status,
  String? reason,
}) async {
  final actions = ref.read(recorderLessonActionsProvider);
  try {
    await actions.setAttendance(lessonId, status, reason: reason);
    if (context.mounted) {
      AppToast.show(
        context,
        message: status == RecorderAttendance.present
            ? 'Đã điểm danh: có mặt'
            : 'Đã ghi vắng · ${absenceReasonLabel(reason)}',
        type: AppToastType.success,
      );
    }
    return true;
  } on Object catch (e) {
    if (context.mounted) {
      AppToast.show(
        context,
        message: apiErrorMessage(
          e,
          'Chưa lưu được điểm danh. Kiểm tra mạng rồi thử lại.',
        ),
        type: AppToastType.error,
      );
    }
    return false;
  }
}

/// Bảng chọn lý do (chip). Trả về giá trị đã chọn, null khi đóng.
Future<String?> showReasonSheet(
  BuildContext context, {
  required String title,
  required List<String> reasons,
  required String Function(String) label,
  String? body,
}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  backgroundColor: TutorColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (ctx) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 14),
          Text(title, style: TutorType.display(size: 20)),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(body, style: TutorType.rowSub()),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in reasons)
                ActionChip(
                  key: Key('reason-$r'),
                  label: Text(label(r)),
                  labelStyle: TutorType.rowTitle(),
                  backgroundColor: const Color(0xFFF8F7F4),
                  side: const BorderSide(color: TutorColors.line),
                  shape: const StadiumBorder(),
                  onPressed: () => Navigator.of(ctx).pop(r),
                ),
            ],
          ),
        ],
      ),
    ),
  ),
);

/// Thanh kéo nhỏ ở đầu bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0x2E1F2A24),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// Hỏi lý do + xác nhận rồi huỷ buổi recorder. Trả về true khi đã huỷ.
Future<bool> cancelRecorderLesson(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  required String studentName,
}) async {
  final reason = await showReasonSheet(
    context,
    title: 'Vì sao huỷ buổi?',
    body: 'Buổi của $studentName sẽ bị xoá khỏi lịch.',
    reasons: RecorderCancelReason.all,
    label: cancelReasonLabel,
  );
  if (reason == null || !context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: TutorColors.surface,
      title: Text('Huỷ buổi này?', style: TutorType.display(size: 20)),
      content: Text(
        'Buổi học của $studentName sẽ bị huỷ (${cancelReasonLabel(reason)}). '
        'Các buổi khác trong lịch vẫn giữ nguyên.',
        style: TutorType.rowSub(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Thôi', style: TutorType.action(color: TutorColors.ink3)),
        ),
        TextButton(
          key: const Key('confirm-cancel-lesson'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Huỷ buổi',
            style: TutorType.action(color: TutorColors.danger),
          ),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await ref
        .read(recorderLessonActionsProvider)
        .cancelLesson(lessonId, reason: reason);
    if (context.mounted) {
      AppToast.show(
        context,
        message: 'Đã huỷ buổi học',
        type: AppToastType.success,
      );
    }
    return true;
  } on Object catch (e) {
    if (context.mounted) {
      AppToast.show(
        context,
        message: apiErrorMessage(e, 'Chưa huỷ được buổi. Thử lại sau.'),
        type: AppToastType.error,
      );
    }
    return false;
  }
}

/// Thẻ sage nổi "Chưa điểm danh" cho buổi đã qua mà không có bản ghi.
///
/// "Có mặt" / "Vắng" (chọn lý do) gọi API điểm danh. "Dời buổi": buổi đã qua
/// không dời được trên server, nên ghi vắng với lý do "Buổi bị huỷ" rồi gợi ý
/// mở hồ sơ học sinh để thêm buổi bù ([onMakeUp]).
class AttendanceCard extends ConsumerStatefulWidget {
  const AttendanceCard({
    required this.lessonId,
    required this.studentName,
    required this.subtitle,
    this.onTap,
    this.onMakeUp,
    super.key,
  });

  final String lessonId;
  final String studentName;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onMakeUp;

  @override
  ConsumerState<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends ConsumerState<AttendanceCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _present() => _run(
    () => markAttendance(
      context,
      ref,
      lessonId: widget.lessonId,
      status: RecorderAttendance.present,
    ),
  );

  Future<void> _absent() => _run(() async {
    final reason = await showReasonSheet(
      context,
      title: 'Vì sao vắng?',
      body: 'Buổi của ${widget.studentName} không có bản ghi âm.',
      reasons: RecorderAbsenceReason.all,
      label: absenceReasonLabel,
    );
    if (reason == null || !mounted) return;
    await markAttendance(
      context,
      ref,
      lessonId: widget.lessonId,
      status: RecorderAttendance.absent,
      reason: reason,
    );
  });

  Future<void> _moved() => _run(() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TutorColors.surface,
        title: Text('Buổi này đã dời?', style: TutorType.display(size: 20)),
        content: Text(
          'Buổi đã qua nên không đổi giờ được nữa. TopTutor ghi buổi này là '
          '"Vắng · Buổi bị huỷ"; bạn thêm buổi học bù trong hồ sơ học sinh.',
          style: TutorType.rowSub(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Thôi',
              style: TutorType.action(color: TutorColors.ink3),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Ghi đã dời', style: TutorType.action()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await markAttendance(
      context,
      ref,
      lessonId: widget.lessonId,
      status: RecorderAttendance.absent,
      reason: RecorderAbsenceReason.cancelled,
    );
    if (done && mounted && widget.onMakeUp != null) {
      AppToast.show(
        context,
        message: 'Đã ghi buổi bị dời. Thêm buổi học bù?',
        type: AppToastType.success,
        actionLabel: 'Thêm',
        onAction: widget.onMakeUp,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Chưa điểm danh: ${widget.studentName}',
      child: CanvasOutlineCard(
        sage: true,
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      widget.studentName,
                      if (widget.subtitle.isNotEmpty) widget.subtitle,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.body(),
                  ),
                ),
                const SizedBox(width: 8),
                const CanvasTag('Chưa điểm danh', filled: true),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Không có bản ghi âm cho buổi này',
              style: TutorType.rowSub(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Pill(
                  label: 'Có mặt',
                  filled: true,
                  onTap: _busy ? null : _present,
                ),
                const SizedBox(width: 6),
                _Pill(label: 'Vắng', onTap: _busy ? null : _absent),
                const SizedBox(width: 6),
                _Pill(label: 'Dời buổi', onTap: _busy ? null : _moved),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          backgroundColor: filled ? TutorColors.ink : const Color(0xFFF8F7F4),
          foregroundColor: filled ? Colors.white : TutorColors.ink,
          disabledBackgroundColor: filled
              ? const Color(0x991F2A24)
              : const Color(0xFFF8F7F4),
          disabledForegroundColor: filled ? Colors.white70 : TutorColors.ink3,
          shape: const StadiumBorder(),
          textStyle: TutorType.action().copyWith(fontSize: 13),
        ),
        child: Text(label, maxLines: 1),
      ),
    ),
  );
}

/// Chip nhỏ "Từ ghi âm" có micro (điểm danh tự động).
class FromRecordingTag extends StatelessWidget {
  const FromRecordingTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: TutorColors.sage,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic_none_rounded, size: 13, color: TutorColors.ink),
        const SizedBox(width: 4),
        Text(
          'Từ ghi âm',
          style: TutorType.caption(
            color: TutorColors.ink,
          ).copyWith(fontSize: 11.5, height: 1),
        ),
      ],
    ),
  );
}
