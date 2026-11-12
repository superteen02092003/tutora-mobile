import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_calendar_agenda.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Tab Lịch (prototype: "8 · Lịch · Tháng ghim + Agenda").
///
/// Tiêu đề + nút "Hôm nay"; bên dưới là lịch tháng ghim và agenda cuộn.
/// Chạm một buổi trong agenda để mở chi tiết buổi học.
class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends State<TutorScheduleScreen> {
  final _agenda = TutorCalendarAgendaController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                20,
                TutorSurface.gutter,
                12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('Bài học', style: TutorType.display()),
                  ),
                  TextButton(
                    onPressed: _agenda.goToday,
                    child: const CanvasKicker(
                      'Hôm nay',
                      color: TutorColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const _NeedsYou(),
            Expanded(child: TutorCalendarAgenda(controller: _agenda)),
          ],
        ),
      ),
    );
  }
}

/// Canvas T4 "Cần bạn": báo cáo chờ duyệt (tối đa 3) ở đầu tab Bài học.
class _NeedsYou extends ConsumerWidget {
  const _NeedsYou();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        (ref.watch(recorderPendingReviewsProvider).valueOrNull ??
                const <RecorderLessonDto>[])
            .where((l) => l.status == 'awaiting_approval')
            .take(3)
            .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        0,
        TutorSurface.gutter,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: CanvasKicker('Cần bạn'),
          ),
          for (final l in items)
            CanvasRow(
              onTap: () => GoRouter.of(context).push(
                AppRoutes.tutorReportReview,
                extra: ReportReviewArgs(
                  recordingId: l.lessonId,
                  studentName: l.studentName,
                  subtitle: [
                    if (l.subject != null && l.subject!.isNotEmpty) l.subject!,
                    if (l.grade != null) 'Lớp ${l.grade}',
                  ].join(' · '),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      l.when == null ? '—' : '${l.when!.day}/${l.when!.month}',
                      style: TutorType.display(
                        size: 22,
                        weight: FontWeight.w600,
                      ).copyWith(letterSpacing: -0.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${l.studentName} · báo cáo cần duyệt',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: TutorColors.ink,
                      ),
                    ),
                  ),
                  const CanvasTag('Duyệt', filled: true),
                  const SizedBox(width: 8),
                  const CanvasChevron(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
