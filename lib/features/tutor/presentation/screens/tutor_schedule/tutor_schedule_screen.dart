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

/// Tab Bài học — design V5.6 (board V55-Lessons).
///
/// Tiêu đề "Lịch dạy" + nút tròn "Hôm nay"; báo cáo chờ duyệt; bên dưới là
/// hàng tháng, dải 7 ngày và dòng thời gian cuộn. Chạm một buổi để mở chi tiết.
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
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  22,
                  TutorSurface.gutter,
                  16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch dạy',
                            style: TutorType.display(
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chuẩn bị hôm nay, tiến bộ ngày mai.',
                            style: TutorType.rowSub(),
                          ),
                        ],
                      ),
                    ),
                    CanvasCircleButton(
                      onTap: _agenda.goToday,
                      tooltip: 'Hôm nay',
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 19,
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
      ),
    );
  }
}

/// "Cần bạn": báo cáo chờ duyệt (tối đa 3), thẻ mức 1 như board V55-Lessons.
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
        16,
      ),
      child: DecoratedBox(
        decoration: TutorSurface.card(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _ReviewRow(lesson: items[i], first: i == 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.lesson, required this.first});

  final RecorderLessonDto lesson;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    return InkWell(
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
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Icons.description_outlined,
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
                    'Duyệt báo cáo ${l.studentName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.body(),
                  ),
                  Text(
                    l.when == null
                        ? 'Cần bạn'
                        : 'Buổi ${l.when!.day}/${l.when!.month} · cần bạn',
                    style: TutorType.rowSub(),
                  ),
                ],
              ),
            ),
            const CanvasChevron(),
          ],
        ),
      ),
    );
  }
}
