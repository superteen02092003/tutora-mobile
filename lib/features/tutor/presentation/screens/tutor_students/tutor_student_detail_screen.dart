import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/recorded_lesson_tile.dart';

/// Hồ sơ một học sinh ngoài nền tảng: phụ huynh, đồng ý ghi âm, các buổi đã ghi.
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
        appBar: AppBar(backgroundColor: TutorColors.bg),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final student = s;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      appBar: AppBar(
        backgroundColor: TutorColors.bg,
        surfaceTintColor: Colors.transparent,
        title: const Text('Học sinh'),
        actions: [
          TextButton(
            onPressed: () =>
                TutorStudentFormScreen.open(context, student: student),
            child: const Text(
              'Sửa',
              style: TextStyle(color: TutorColors.primary),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: TutorColors.primary,
        onRefresh: () async {
          ref
            ..invalidate(recorderStudentsProvider)
            ..invalidate(recorderStudentLessonsProvider(studentId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                _Circle(name: student.fullName, size: 54, fontSize: 19),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: TutorColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        student.subtitle.isEmpty
                            ? 'Ngoài nền tảng'
                            : '${student.subtitle} · Ngoài nền tảng',
                        style: const TextStyle(
                          fontSize: 13,
                          color: TutorColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Card(
              children: [
                _Row(
                  icon: Icons.person_outline_rounded,
                  title: student.parentName?.isNotEmpty ?? false
                      ? student.parentName!
                      : 'Chưa có tên phụ huynh',
                  sub: student.parentPhone?.isNotEmpty ?? false
                      ? 'Phụ huynh · ${student.parentPhone}'
                      : 'Chưa có SĐT — chưa gửi được báo cáo qua Zalo',
                  warn: student.parentPhone?.isEmpty ?? true,
                ),
                const Divider(height: 1, color: TutorColors.line),
                _Row(
                  icon: student.hasConsent
                      ? Icons.verified_outlined
                      : Icons.mic_off_outlined,
                  title: switch (student.consentStatus) {
                    'parent_confirmed' => 'Phụ huynh đã xác nhận đồng ý',
                    'tutor_confirmed' => 'Bạn đã xác nhận phụ huynh đồng ý',
                    'declined' => 'Phụ huynh từ chối ghi âm',
                    _ => 'Chưa có đồng ý ghi âm',
                  },
                  sub: student.hasConsent
                      ? 'Được ghi âm buổi học và gửi báo cáo'
                      : 'Cần phụ huynh đồng ý trước khi ghi âm',
                  warn: !student.hasConsent,
                ),
                const Divider(height: 1, color: TutorColors.line),
                _Row(
                  icon: Icons.event_repeat_rounded,
                  title: student.schedule.isEmpty
                      ? 'Chưa có lịch học'
                      : RecorderScheduleSlot.summary(student.schedule),
                  sub: student.schedule.isEmpty
                      ? 'Bấm Sửa để thêm lịch — buổi học sẽ hiện trong tab Lịch'
                      : _range(student),
                  warn: student.schedule.isEmpty,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: student.isDeclined
                    ? null
                    : () => startStudentRecording(context, ref, student),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: TutorColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.mic_none_rounded, size: 18),
                label: const Text(
                  'Ghi âm buổi học',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 26),
            ...lessons.when<List<Widget>>(
              loading: () => [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                const Text(
                  'Không tải được danh sách buổi. Kéo xuống để thử lại.',
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
                              (l.scheduledEnd ?? l.when ?? now).isAfter(now),
                        )
                        .toList()
                      ..sort((a, b) => a.when!.compareTo(b.when!));
                // Đã ghi: mới nhất trước.
                final recorded =
                    list.where((l) => l.status != 'scheduled').toList()..sort(
                      (a, b) => (b.when ?? now).compareTo(a.when ?? now),
                    );
                return [
                  if (upcoming.isNotEmpty) ...[
                    const _Section('SẮP TỚI'),
                    for (final l in upcoming.take(3)) ...[
                      _LessonTile(
                        lesson: l,
                        studentName: student.fullName,
                        subtitle: student.subtitle,
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 16),
                  ],
                  const _Section('CÁC BUỔI ĐÃ GHI ÂM'),
                  if (recorded.isEmpty)
                    const Text(
                      'Chưa có buổi nào. Bấm "Ghi âm buổi học" khi bắt đầu dạy.',
                      style: TextStyle(fontSize: 13, color: TutorColors.ink3),
                    )
                  else
                    for (final l in recorded) ...[
                      RecordedLessonTile(
                        lesson: l,
                        studentName: student.fullName,
                      ),
                      const SizedBox(height: 10),
                    ],
                ];
              },
            ),
          ],
        ),
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
  if (!s.hasConsent) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phụ huynh đã đồng ý ghi âm?'),
        content: Text(
          'Bản ghi có giọng của ${s.fullName}. Chỉ ghi khi phụ huynh đã đồng ý cho '
          'ghi âm buổi học và nhận báo cáo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã đồng ý'),
          ),
        ],
      ),
    );
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
      ref.invalidate(recorderStudentsProvider);
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

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.studentName,
    required this.subtitle,
  });

  final RecorderLessonDto lesson;
  final String studentName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final d = lesson.when;
    final date = d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} · '
              '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final (label, bg, fg) = switch (lesson.status) {
      'sent' =>
        lesson.deliveryStatus == 'sent'
            ? ('Đã gửi', TutorColors.successBg, TutorColors.success)
            : (
                'Đã duyệt · chờ gửi Zalo',
                TutorColors.accentBg,
                TutorColors.warning,
              ),
      'awaiting_approval' => (
        'Chờ duyệt',
        TutorColors.primaryBg,
        TutorColors.primary,
      ),
      'processing' => (
        'AI đang viết',
        TutorColors.accentBg,
        TutorColors.warning,
      ),
      'failed' => ('Lỗi', TutorColors.primaryBg, TutorColors.primary),
      'recording' ||
      'uploading' => ('Đang ghi', TutorColors.accentBg, TutorColors.warning),
      _ => ('Đã lên lịch', TutorColors.surfaceSunken, TutorColors.ink3),
    };
    final recorded = !{
      'scheduled',
      'recording',
      'uploading',
    }.contains(lesson.status);
    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: recorded
            ? () => TutorRecordingDetailScreen.open(
                context,
                RecordingDetailArgs(
                  recordingId: lesson.lessonId,
                  studentName: studentName,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TutorColors.ink,
                      ),
                    ),
                    if (lesson.durationSec > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${(lesson.durationSec / 60).round()} phút',
                        style: const TextStyle(
                          fontSize: 13,
                          color: TutorColors.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: TutorColors.surface,
      border: Border.all(color: TutorColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: children),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.sub,
    this.warn = false,
  });

  final IconData icon;
  final String title;
  final String sub;
  final bool warn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: warn ? TutorColors.warning : TutorColors.ink3,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TutorColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: warn ? TutorColors.warning : TutorColors.ink4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Circle extends StatelessWidget {
  const _Circle({required this.name, this.size = 42, this.fontSize = 15});

  final String name;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TutorColors.surfaceSunken,
        shape: BoxShape.circle,
        border: Border.all(color: TutorColors.line),
      ),
      child: Text(
        t.isEmpty ? '?' : t.split(' ').last.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: TutorColors.ink,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: TutorColors.ink4,
      ),
    ),
  );
}
