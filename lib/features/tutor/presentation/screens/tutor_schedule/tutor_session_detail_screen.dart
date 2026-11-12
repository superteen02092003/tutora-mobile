import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_lesson_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/lesson_attendance.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/lesson_move_sheet.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

final AutoDisposeFutureProviderFamily<TutorSessionDetailDto, int>
_sessionDetailProvider = FutureProvider.autoDispose
    .family<TutorSessionDetailDto, int>(
      (ref, id) => ref.read(tutorLessonDatasourceProvider).getSessionDetail(id),
    );

/// Chi tiết buổi học (prototype: "11 · Chi tiết buổi học").
///
/// Mở từ một dòng agenda trên tab Lịch. Phần lịch có sẵn (giờ, học sinh, môn,
/// trạng thái) hiện ngay; học phí và khối lớp tải thêm từ chi tiết buổi.
///
/// "Đổi lịch" / "Huỷ buổi": buổi ngoài nền tảng (recorder) dời / huỷ ngay;
/// buổi booking gửi đề xuất đổi lịch (phụ huynh đồng ý) và không huỷ lẻ được.
class TutorSessionDetailScreen extends ConsumerWidget {
  const TutorSessionDetailScreen({required this.lesson, super.key});

  final TutorLessonDto lesson;

  static Future<void> open(BuildContext context, TutorLessonDto lesson) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorSessionDetailScreen(lesson: lesson),
        ),
      );

  static const _weekday = [
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
    'Chủ nhật',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _money(double v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '$bđ';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buổi ngoài nền tảng không có chi tiết buổi booking (lessonId = 0).
    final detail = lesson.isOffPlatform
        ? null
        : ref.watch(_sessionDetailProvider(lesson.lessonId)).valueOrNull;
    final recorderById = lesson.isOffPlatform
        ? ref.watch(agendaRecorderLessonsProvider).valueOrNull
        : null;
    final recorder = recorderById?[lesson.recorderLessonId];
    final movedFrom = recorder?.movedFromStart;
    final start = lesson.startDt?.toLocal();
    final end = lesson.endDt?.toLocal();
    final now = DateTime.now();
    final isToday =
        start != null &&
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final canRecord = isToday && !lesson.isFinished && !lesson.isAwaitingReport;

    final status = _Status.of(lesson, now);
    final subtitle = [
      if (lesson.subjectName.isNotEmpty) lesson.subjectName,
      if (detail?.gradeName != null && detail!.gradeName!.isNotEmpty)
        detail.gradeName!,
    ].join(' · ');

    // Buổi trước cùng lớp — lấy từ lịch đã tải.
    final schedule =
        ref.watch(tutorAgendaLessonsProvider).valueOrNull ??
        const <TutorLessonDto>[];
    TutorLessonDto? previous;
    if (lesson.bookingId != null && start != null) {
      for (final l in schedule) {
        final s = l.startDt;
        if (l.bookingId != lesson.bookingId ||
            s == null ||
            !s.isBefore(start)) {
          continue;
        }
        if (previous == null || s.isAfter(previous.startDt!)) previous = l;
      }
    }

    final prev = previous;
    final initial = lesson.studentName.trim().isEmpty
        ? '?'
        : lesson.studentName.trim()[0].toUpperCase();

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    16,
                    TutorSurface.gutter,
                    24,
                  ),
                  children: [
                    // ── Quay lại + trạng thái ─────────────────────────
                    Row(
                      children: [
                        CanvasBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        CanvasTag(status.label, filled: status.filled),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Học sinh ─────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: TutorColors.sage,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            initial,
                            style: TutorType.display(size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.studentName,
                                style: TutorType.screenTitle(),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(subtitle, style: TutorType.rowSub()),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Giờ · địa điểm · học phí ──────────────────────
                    _Card(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.schedule_rounded,
                            title: start == null
                                ? 'Chưa có giờ'
                                : '${_weekday[start.weekday - 1]}, '
                                      '${_two(start.day)}/${_two(start.month)} · '
                                      '${lesson.timeStart}'
                                      '${end == null ? '' : ' – ${lesson.timeEnd}'}',
                            sub: [
                              ?lesson.linkLabel,
                              if (movedFrom != null) movedFromLine(movedFrom),
                            ].join(' · ').nullIfEmpty,
                          ),
                          const Divider(height: 1, color: TutorColors.line),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            title: _place(lesson.teachingMode),
                          ),
                          // Học phí / giải ngân chỉ có ở buổi booking.
                          if (!lesson.isOffPlatform) ...[
                            const Divider(height: 1, color: TutorColors.line),
                            _InfoRow(
                              icon: Icons.payments_outlined,
                              title: detail?.price == null
                                  ? '—'
                                  : _money(detail!.price!),
                              trailing: 'Giải ngân sau khi gửi báo cáo',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: TutorSurface.sectionGap),

                    // ── Báo cáo gửi tới ──────────────────────────────
                    const _SectionLabel('Báo cáo gửi tới'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: TutorSurface.well(),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: TutorColors.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phụ huynh của ${lesson.studentName}',
                                  style: TutorType.rowTitle(),
                                ),
                                const SizedBox(height: 2),
                                Text('Phụ huynh', style: TutorType.rowSub()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TutorSurface.sectionGap),

                    // ── Ghi âm & báo cáo ─────────────────────────────
                    const _SectionLabel('Ghi âm & báo cáo'),
                    const SizedBox(height: 10),
                    _RecordingState(lesson: lesson, isToday: isToday),
                    if (prev != null) ...[
                      const SizedBox(height: 10),
                      _Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Buổi trước · '
                                    '${_two(prev.startDt!.day)}/'
                                    '${_two(prev.startDt!.month)}',
                                    style: TutorType.rowTitle(),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prev.isFinished
                                        ? 'Đã hoàn thành'
                                        : prev.isAwaitingReport
                                        ? 'Chưa có báo cáo'
                                        : 'Chưa diễn ra',
                                    style: TutorType.rowSub(),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            TutorSessionDetailScreen(
                                              lesson: prev,
                                            ),
                                      ),
                                    ),
                                style: FilledButton.styleFrom(
                                  // Theme app đặt minimumSize rộng vô hạn cho nút.
                                  minimumSize: const Size(0, 36),
                                  backgroundColor: TutorColors.sage,
                                  foregroundColor: TutorColors.ink,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text('Xem', style: TutorType.action()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Thanh hành động ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: TutorColors.paperBottom,
                  border: Border(top: TutorSurface.rule),
                ),
                padding: EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  12,
                  TutorSurface.gutter,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canRecord) ...[
                      CanvasCta(
                        label: 'Bắt đầu ghi âm',
                        icon: const Icon(Icons.mic_none_rounded, size: 18),
                        onPressed: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          unawaited(
                            router.push(
                              AppRoutes.tutorRecording,
                              extra: RecordingTarget(
                                lessonId: lesson.lessonId,
                                recorderLessonId: lesson.recorderLessonId,
                                studentName: lesson.studentName,
                                subjectName: lesson.subjectName,
                                timeStart: lesson.timeStart,
                                timeEnd: lesson.timeEnd,
                                scheduledEnd: end,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        _ActionBtn(
                          icon: Icons.calendar_today_outlined,
                          label: 'Đổi lịch',
                          onTap: () =>
                              unawaited(_reschedule(context, ref, recorder)),
                        ),
                        _ActionBtn(
                          icon: Icons.person_outline_rounded,
                          label: 'Hồ sơ HS',
                          onTap: lesson.recorderStudentId != null
                              ? () => unawaited(
                                  TutorStudentDetailScreen.open(
                                    context,
                                    lesson.recorderStudentId!,
                                  ),
                                )
                              : () => _soon(context),
                        ),
                        _ActionBtn(
                          icon: Icons.close_rounded,
                          label: 'Huỷ buổi',
                          onTap: () => unawaited(_cancel(context, ref)),
                        ),
                      ],
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

  static String _place(String? mode) {
    final m = (mode ?? '').toLowerCase();
    if (m.contains('online')) return 'Học trực tuyến';
    return 'Tại nhà học sinh';
  }

  Future<void> _reschedule(
    BuildContext context,
    WidgetRef ref,
    RecorderLessonDto? recorder,
  ) async {
    final navigator = Navigator.of(context);
    final done = lesson.isOffPlatform
        ? await moveRecorderLesson(context, ref, lesson, recorder: recorder)
        : await proposeBookedReschedule(context, ref, lesson);
    // Buổi recorder đã dời: giờ trên màn này đã cũ → quay lại lịch.
    if (done && lesson.isOffPlatform && navigator.mounted) navigator.pop();
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    if (!lesson.isOffPlatform) return explainBookedCancel(context);
    final start = lesson.startDt;
    if (lesson.recorderStatus != 'scheduled' ||
        start == null ||
        !start.isAfter(DateTime.now())) {
      AppToast.show(
        context,
        message: 'Chỉ huỷ được buổi chưa diễn ra.',
        type: AppToastType.warning,
      );
      return;
    }
    final navigator = Navigator.of(context);
    final done = await cancelRecorderLesson(
      context,
      ref,
      lessonId: lesson.recorderLessonId!,
      studentName: lesson.studentName,
    );
    if (done && navigator.mounted) navigator.pop();
  }

  static void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng này chưa có trên app — làm trên toptutor.ai.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

class _Status {
  const _Status(this.label, {this.filled = false});

  final String label;

  /// Nền mực chữ trắng — chỉ cho trạng thái cần chú ý (đang dạy, cần báo cáo).
  final bool filled;

  // Trả về các hằng `_Status` dựng sẵn, không phải khởi tạo mới.
  // ignore: prefer_constructors_over_static_methods
  static _Status of(TutorLessonDto l, DateTime now) {
    if (l.isLive) return const _Status('Đang diễn ra', filled: true);
    if (l.isAwaitingReport) return const _Status('Cần báo cáo', filled: true);
    if (l.isFinished) return const _Status('Đã hoàn thành');
    final end = l.endDt;
    if (end != null && end.isBefore(now)) return const _Status('Đã qua');
    return const _Status('Sắp diễn ra');
  }
}

class _RecordingState extends StatelessWidget {
  const _RecordingState({required this.lesson, required this.isToday});

  final TutorLessonDto lesson;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String body) = lesson.isFinished
        ? (
            Icons.check_rounded,
            'Buổi đã hoàn thành',
            'Báo cáo của buổi này đã được xử lý.',
          )
        : lesson.isAwaitingReport
        ? (
            Icons.mic_off_outlined,
            'Chưa có báo cáo',
            'Buổi đã dạy xong nhưng chưa có báo cáo gửi phụ huynh.',
          )
        : (
            Icons.mic_none_rounded,
            'Chưa ghi âm buổi này',
            isToday
                ? 'Bấm ghi khi bắt đầu dạy.'
                : 'Nút ghi âm sẽ hiện vào ngày học.',
          );
    final done = lesson.isFinished;

    // Chưa xong → thẻ sage "cần bạn"; đã xong → thẻ thường.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: done ? TutorSurface.card() : TutorSurface.sage(lifted: false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: done ? TutorColors.surfaceSunken : const Color(0xFFF8F7F4),
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: TutorColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TutorType.body()),
                const SizedBox(height: 2),
                Text(body, style: TutorType.rowSub()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: TutorSurface.card(),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.sub,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TutorColors.ink3),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TutorType.rowTitle()),
                if (sub != null) Text(sub!, style: TutorType.rowSub()),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing!, style: TutorType.caption()),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TutorType.sectionTitle().copyWith(fontSize: 17));
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: TutorColors.ink3),
              const SizedBox(height: 5),
              Text(label, style: TutorType.caption(color: TutorColors.ink3)),
            ],
          ),
        ),
      ),
    );
  }
}
