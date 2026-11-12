import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_journal_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/consent_text_dialog.dart';
import 'package:tutora/features/tutor/presentation/widgets/recorded_lesson_tile.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_skills_section.dart';

/// Hồ sơ một học sinh ngoài nền tảng (canvas V5.6 Pupil): tên + lớp, kỹ năng,
/// lỗ hổng, từng buổi học, phụ huynh + lịch, đồng ý ghi âm và nút ghi âm.
class TutorStudentDetailScreen extends ConsumerWidget {
  const TutorStudentDetailScreen({required this.studentId, super.key});

  final String studentId;

  static Future<void> open(BuildContext context, String studentId) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => TutorStudentDetailScreen(studentId: studentId),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students =
        ref.watch(recorderStudentsProvider).valueOrNull ?? const [];
    RecorderStudentDto? s;
    for (final x in students) {
      if (x.studentId == studentId) s = x;
    }
    final lessons = ref.watch(recorderStudentLessonsProvider(studentId));

    if (s == null) {
      return Scaffold(
        backgroundColor: TutorColors.bg,
        body: DecoratedBox(
          decoration: TutorSurface.paper,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    16,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: CanvasBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final student = s;

    Future<void> edit() async {
      await TutorStudentFormScreen.open(context, student: student);
      // Đã xoá học sinh ở form → màn hồ sơ không còn gì để xem.
      final list = await ref.read(recorderStudentsProvider.future);
      if (!list.any((x) => x.studentId == studentId) && context.mounted) {
        await Navigator.of(context).maybePop();
      }
    }

    const gutter = EdgeInsets.symmetric(horizontal: TutorSurface.gutter);

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: TutorColors.ink2,
                  onRefresh: () async {
                    ref
                      ..invalidate(recorderStudentsProvider)
                      ..invalidate(recorderStudentLessonsProvider(studentId));
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _Top(
                        onBack: () => Navigator.of(context).maybePop(),
                        onEdit: edit,
                      ),
                      _Identity(student: student),
                      ...lessons.when<List<Widget>>(
                        loading: () => [
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                        error: (_, _) => [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TutorSurface.gutter,
                              20,
                              TutorSurface.gutter,
                              0,
                            ),
                            child: Text(
                              'Không tải được danh sách buổi. Kéo xuống để thử lại.',
                              style: TutorType.rowSub(),
                            ),
                          ),
                        ],
                        data: (list) {
                          final now = DateTime.now();
                          // Sắp tới: 3 buổi đã lên lịch gần nhất, tăng dần theo giờ.
                          final upcoming =
                              list
                                  .where(
                                    (l) =>
                                        l.status == 'scheduled' &&
                                        (l.scheduledEnd ?? l.when ?? now)
                                            .isAfter(now),
                                  )
                                  .toList()
                                ..sort((a, b) => a.when!.compareTo(b.when!));
                          // Đã ghi: mới nhất trước.
                          final recorded =
                              list
                                  .where((l) => l.status != 'scheduled')
                                  .toList()
                                ..sort(
                                  (a, b) =>
                                      (b.when ?? now).compareTo(a.when ?? now),
                                );
                          // Topi v1: buổi đã có báo cáo gần nhất — kế hoạch của
                          // nó dành cho buổi tới, kỹ năng của nó là ảnh chụp gần
                          // nhất. Các widget Topi tự ẩn khi cờ tắt.
                          final latestReported = latestReportedLesson(recorded);
                          return [
                            if (latestReported != null)
                              Padding(
                                padding: gutter,
                                child: TopiSkillsSection(
                                  lessonId: latestReported.lessonId,
                                  title: 'Kỹ năng ở buổi gần nhất',
                                  padding: const EdgeInsets.only(top: 16),
                                ),
                              ),
                            // Gợi ý trước buổi luôn hiện khi đã có buổi có báo
                            // cáo — kể cả khi chưa lên lịch buổi tới.
                            if (latestReported != null)
                              _GapsBlock(
                                args: BeforeLessonArgs(
                                  lessonId: latestReported.lessonId,
                                  studentName: student.fullName,
                                  nextLessonAt: upcoming.firstOrNull?.when,
                                ),
                              ),
                            if (upcoming.isNotEmpty) ...[
                              const _SectionTitle('Sắp tới'),
                              Padding(
                                padding: gutter,
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < upcoming.length && i < 3;
                                      i++
                                    )
                                      _LessonTile(
                                        lesson: upcoming[i],
                                        studentName: student.fullName,
                                        subtitle: student.subtitle,
                                        first: i == 0,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            _SectionTitle(
                              'Từng buổi học',
                              action: 'Nhật ký →',
                              onAction: () => unawaited(
                                TutorJournalScreen.open(
                                  context,
                                  studentId,
                                  student.fullName,
                                ),
                              ),
                            ),
                            Padding(
                              padding: gutter,
                              child: recorded.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Chưa có buổi nào. Bấm "Ghi âm buổi học" khi bắt đầu dạy.',
                                        style: TutorType.rowSub(),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (final l in recorded)
                                          RecordedLessonTile(
                                            lesson: l,
                                            studentName: student.fullName,
                                          ),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: TutorSurface.rule,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ];
                        },
                      ),
                      const _SectionTitle('Phụ huynh và lịch học'),
                      Padding(
                        padding: gutter,
                        child: Column(
                          children: [
                            _Row(
                              first: true,
                              icon: Icons.person_outline_rounded,
                              title: student.parentName?.isNotEmpty ?? false
                                  ? student.parentName!
                                  : 'Chưa có tên phụ huynh',
                              sub: student.parentPhone?.isNotEmpty ?? false
                                  ? 'Phụ huynh · ${student.parentPhone}'
                                  : 'Chưa có SĐT — chưa gửi được báo cáo qua Zalo',
                              warn: student.parentPhone?.isEmpty ?? true,
                            ),
                            _Row(
                              icon: Icons.event_repeat_rounded,
                              title: student.schedule.isEmpty
                                  ? 'Chưa có lịch học'
                                  : RecorderScheduleSlot.summary(
                                      student.schedule,
                                    ),
                              sub: student.schedule.isEmpty
                                  ? 'Bấm Sửa để thêm lịch — buổi học sẽ hiện trong tab Bài học'
                                  : _range(student),
                              warn: student.schedule.isEmpty,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _BottomBar(
                student: student,
                onRecord: student.isDeclined
                    ? null
                    : () => startStudentRecording(context, ref, student),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hàng đầu: nút quay lại tròn, "Hồ sơ học sinh", nút Sửa.
class _Top extends StatelessWidget {
  const _Top({required this.onBack, required this.onEdit});

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      16,
      TutorSurface.gutter - 8,
      0,
    ),
    child: Row(
      children: [
        CanvasBackButton(onTap: onBack),
        const Spacer(),
        Text('Hồ sơ học sinh', style: TutorType.rowSub()),
        const SizedBox(width: 4),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            foregroundColor: TutorColors.ink,
            minimumSize: const Size(44, 44),
            shape: const StadiumBorder(),
          ),
          child: Text('Sửa', style: TutorType.action()),
        ),
      ],
    ),
  );
}

/// Avatar chữ cái đầu + tên lớn + "Toán · Lớp 8".
class _Identity extends StatelessWidget {
  const _Identity({required this.student});

  final RecorderStudentDto student;

  String get _initials {
    final words = student.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final picked = words.length == 1
        ? [words.first]
        : words.sublist(words.length - 2);
    return picked.map((w) => w.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      14,
      TutorSurface.gutter,
      0,
    ),
    child: Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: TutorColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: TutorType.display(
                size: 20,
                weight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: TutorType.display(size: 26, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                student.subtitle.isEmpty ? 'Ngoài nền tảng' : student.subtitle,
                style: TutorType.rowSub(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.action, this.onAction});

  final String text;

  /// Liên kết chữ xám bên phải ("Nhật ký →").
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      22,
      action == null ? TutorSurface.gutter : TutorSurface.gutter - 10,
      6,
    ),
    child: action == null
        ? Text(text, style: TutorType.sectionTitle())
        : Row(
            children: [
              Expanded(child: Text(text, style: TutorType.sectionTitle())),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      widthFactor: 1,
                      child: Text(action!, style: TutorType.rowSub()),
                    ),
                  ),
                ),
              ),
            ],
          ),
  );
}

String _gapLabel(String? role, int number) => switch (role) {
  'focus' => 'Lỗ hổng $number · luyện ngay',
  'next' => 'Lỗ hổng $number · tiếp theo',
  _ => 'Lỗ hổng $number',
};

int _dots(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 1,
  TopiLevel.improving => 2,
  TopiLevel.standard => 3,
  TopiLevel.mastered => 4,
};

/// "Lỗ hổng": thẻ sage dẫn sang Chuẩn bị buổi học, rồi các lỗ hổng tiếp theo.
/// Ẩn cả khối khi cờ `plan` tắt hoặc buổi gần nhất chưa có kế hoạch.
class _GapsBlock extends ConsumerWidget {
  const _GapsBlock({required this.args});

  final BeforeLessonArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).plan) return const SizedBox.shrink();
    final plan = ref.watch(lessonTopiProvider(args.lessonId)).valueOrNull?.plan;
    if (plan == null || plan.isEmpty) return const SizedBox.shrink();

    // Thứ tự như màn Chuẩn bị: lỗ hổng đang luyện, rồi "tiếp theo".
    int rank(TopiGap g) => switch (g.role) {
      'focus' => 0,
      'next' => 1,
      _ => 2,
    };
    final shown = plan.gaps.where((g) => g.role != 'watch').toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          plan.gaps.isEmpty ? 'Chuẩn bị buổi tới' : 'Lỗ hổng',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            4,
            TutorSurface.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopiBeforeLessonEntry(args: args),
              for (var i = 1; i < shown.length && i < 3; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border(
                      top: i == 1 ? BorderSide.none : TutorSurface.rule,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (shown[i].level != null) ...[
                        CanvasSkillDots(level: _dots(shown[i].level!)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shown[i].title ?? shown[i].node ?? '—',
                              style: TutorType.body(),
                            ),
                            Text(
                              _gapLabel(shown[i].role, i + 1),
                              style: TutorType.rowSub(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chân màn: dòng khoá "đồng ý ghi âm" và nút "Ghi âm buổi học".
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.student, required this.onRecord});

  final RecorderStudentDto student;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final consent = switch (student.consentStatus) {
      'parent_confirmed' => 'Phụ huynh đã xác nhận đồng ý ghi âm',
      'tutor_confirmed' => 'Bạn đã xác nhận phụ huynh đồng ý ghi âm',
      'declined' => 'Phụ huynh từ chối ghi âm',
      _ => 'Chưa có đồng ý ghi âm',
    };
    final note = student.hasConsent
        ? consent
        : '$consent · cần phụ huynh đồng ý trước khi ghi âm';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        8,
        TutorSurface.gutter,
        14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                student.hasConsent
                    ? Icons.lock_outline_rounded
                    : Icons.mic_off_outlined,
                size: 16,
                color: student.hasConsent
                    ? TutorColors.ink3
                    : TutorColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note,
                  style: TutorType.caption(
                    color: student.hasConsent
                        ? TutorColors.ink3
                        : TutorColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CanvasCta(
            label: 'Ghi âm buổi học',
            icon: const Icon(Icons.mic_none_rounded, size: 18),
            onPressed: onRecord,
          ),
        ],
      ),
    );
  }
}

/// "21/09/2026 – 21/12/2026 · 26 buổi"
String _range(RecorderStudentDto s) {
  String d(DateTime x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';
  final from = s.scheduleFrom;
  final until = s.scheduleUntil;
  if (from == null) return 'Lịch học hằng tuần';
  if (until == null) return 'Từ ${d(from)} · không giới hạn';
  return '${d(from)} – ${d(until)} · ${countScheduledLessons(s.schedule, from, until)} buổi';
}

/// Bấm ghi cho học sinh ngoài nền tảng. Chưa có đồng ý thì hỏi gia sư xác nhận
/// trước (lưu lại vào hồ sơ), từ chối thì chặn.
///
/// [onBeforeStart] chạy ngay trước khi mở màn "Đang ghi" — sheet chọn buổi
/// dùng nó để tự đóng, sau khi mọi hộp thoại (cần `ref` còn sống) đã xong.
Future<void> startStudentRecording(
  BuildContext context,
  WidgetRef ref,
  RecorderStudentDto student, {
  VoidCallback? onBeforeStart,
}) async {
  final router = GoRouter.of(context);
  if (ref.read(lessonRecordingProvider).isRecording) {
    final target = ref.read(lessonRecordingProvider.notifier).target;
    onBeforeStart?.call();
    if (target != null) {
      unawaited(router.push(AppRoutes.tutorRecording, extra: target));
    }
    return;
  }

  var s = student;
  if (!s.hasConsent || s.needsReconsent) {
    final ok = await showConsentTextDialog(context, askConfirm: true);
    if (ok != true || !context.mounted) return;
    try {
      s = await ref
          .read(recorderDatasourceProvider)
          .updateStudent(
            s.studentId,
            RecorderStudentInput(
              fullName: s.fullName,
              grade: s.grade,
              subject: s.subject,
              parentName: s.parentName,
              parentPhone: s.parentPhone,
              parentConsent: true,
              note: s.note,
            ),
          );
      reloadRecorderStudentData(ref);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa lưu được đồng ý. Kiểm tra mạng rồi thử lại.'),
          ),
        );
      }
      return;
    }
  }

  onBeforeStart?.call();
  unawaited(
    router.push(
      AppRoutes.tutorRecording,
      extra: RecordingTarget.fromStudent(s),
    ),
  );
}

/// Buổi sắp tới: hàng kẻ mảnh — ngày nhỏ bên trái, giờ + thời lượng, thẻ
/// trạng thái bên phải.
class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.studentName,
    required this.subtitle,
    required this.first,
  });

  final RecorderLessonDto lesson;
  final String studentName;
  final String subtitle;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final d = lesson.when;
    final day = d == null ? '—' : '${d.day}/${d.month}';
    final time = d == null
        ? ''
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final label = switch (lesson.status) {
      'sent' =>
        lesson.deliveryStatus == 'sent' ? 'Đã gửi' : 'Đã duyệt · chờ gửi Zalo',
      'awaiting_approval' => 'Chờ duyệt',
      'processing' => 'AI đang viết',
      'failed' => 'Lỗi',
      'recording' || 'uploading' => 'Đang ghi',
      _ => 'Đã lên lịch',
    };
    final recorded = !{
      'scheduled',
      'recording',
      'uploading',
    }.contains(lesson.status);
    final body = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: first ? BorderSide.none : TutorSurface.rule),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(day, style: TutorType.caption(color: TutorColors.ink3)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time.isEmpty ? '—' : time, style: TutorType.body()),
                if (lesson.durationSec > 0)
                  Text(
                    '${(lesson.durationSec / 60).round()} phút',
                    style: TutorType.rowSub(),
                  ),
              ],
            ),
          ),
          CanvasTag(label),
          if (recorded) ...[const SizedBox(width: 6), const CanvasChevron()],
        ],
      ),
    );
    if (!recorded) return body;
    return InkWell(
      onTap: () => TutorRecordingDetailScreen.open(
        context,
        RecordingDetailArgs(
          recordingId: lesson.lessonId,
          studentName: studentName,
        ),
      ),
      child: body,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.sub,
    this.warn = false,
    this.first = false,
  });

  final IconData icon;
  final String title;
  final String sub;
  final bool warn;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
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
          child: Icon(
            icon,
            size: 19,
            color: warn ? TutorColors.warning : TutorColors.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TutorType.body()),
              const SizedBox(height: 1),
              Text(
                sub,
                style: TutorType.rowSub(
                  color: warn ? TutorColors.warning : TutorColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
