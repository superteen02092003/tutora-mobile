import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_class_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/course_renew.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/notification_bell.dart';

/// Trang chủ gia sư — design V5.6 (canvas "TopTutor tutor app V5.6", bảng
/// V55-Home, đã duyệt): lá cây góc phải, chữ viết tay, lời chào + tên lớn,
/// banner "Cần bạn duyệt", thẻ học sinh cuộn ngang, "Việc hôm nay". Không logo.
class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  static String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? '' : parts.last;
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(tutorBookingsProvider)
      ..invalidate(tutorClassesProvider)
      ..invalidate(recorderStudentsProvider)
      ..invalidate(recorderPendingReviewsProvider)
      ..invalidate(recorderTodayLessonsProvider);
    await ref.read(tutorDashboardProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(tutorProfileProvider);
    final dash = ref.watch(tutorDashboardProvider);

    final first = _firstName(profile.user?.fullName ?? '');
    final data = dash.data;
    final loading = dash.isLoading && data == null;
    final students =
        ref.watch(recorderStudentsProvider).valueOrNull ??
        const <RecorderStudentDto>[];
    final reviews =
        ref.watch(recorderPendingReviewsProvider).valueOrNull ??
        const <RecorderLessonDto>[];
    // Buổi hôm nay của học sinh ngoài nền tảng, chưa ghi âm xong.
    final offPlatformToday =
        (ref.watch(recorderTodayLessonsProvider).valueOrNull ?? const [])
            .where(
              (s) => const {
                'scheduled',
                'recording',
                'uploading',
              }.contains(s.recorderStatus),
            )
            .toList();
    final today = [
      ...sessionsToday(data?.todaySessions ?? const []),
      ...offPlatformToday,
    ];
    final awaiting = reviews
        .where((r) => r.status == 'awaiting_approval')
        .length;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: TutorColors.primary,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                _Hero(
                  first: first,
                  summary: [
                    '${today.length} buổi học hôm nay',
                    if (awaiting > 0) '$awaiting báo cáo cần duyệt',
                  ].join(' · '),
                ),
                if (reviews.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TutorSurface.gutter,
                      16,
                      TutorSurface.gutter,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReviewBanner(lesson: reviews.first),
                        for (final r in reviews.skip(1)) ...[
                          const SizedBox(height: 10),
                          _ReviewRow(lesson: r),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 26),
                _EndedCoursesSection(students: students),
                _StudentsSection(students: students),
                const SizedBox(height: 8),
                Padding(
                  padding: TutorSurface.screenPadding,
                  child: loading
                      ? const TutorSkeleton(height: 120, radius: 20)
                      : _TodayTasks(sessions: today),
                ),
                const SizedBox(height: 22),
                const Padding(
                  padding: TutorSurface.screenPadding,
                  child: _ClassesSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _greeting(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'Chào buổi sáng,';
  if (h < 13) return 'Chào buổi trưa,';
  if (h < 18) return 'Chào buổi chiều,';
  return 'Chào buổi tối,';
}

/// Phần đầu: lá cây (sau nội dung), chuông + avatar, chữ viết tay, lời chào.
class _Hero extends StatelessWidget {
  const _Hero({required this.first, required this.summary});

  final String first;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lá cây góc phải, sau nội dung, không bao giờ đè chữ.
        const Positioned(
          top: 0,
          right: 0,
          width: 165,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.94,
              child: Image(
                image: AssetImage('assets/images/decor/leaf_home.webp'),
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TutorSurface.gutter,
            14,
            TutorSurface.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CanvasCircleButton(
                    tooltip: 'Thông báo',
                    onTap: () =>
                        unawaited(context.push(AppRoutes.tutorNotifications)),
                    child: const NotificationBadge(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: TutorColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CanvasCircleButton(
                    tooltip: 'Tôi',
                    color: TutorColors.ink,
                    onTap: () =>
                        unawaited(context.push(AppRoutes.tutorProfile)),
                    child: Text(
                      first.isEmpty
                          ? '?'
                          : first.characters.first.toUpperCase(),
                      style: TutorType.action(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const CanvasHand(
                'Từng bước nhỏ, tiến bộ lớn',
                size: 18,
                swash: false,
              ),
              const SizedBox(height: 8),
              Text(
                _greeting(DateTime.now()),
                style: TutorType.display(size: 17, weight: FontWeight.w400),
              ),
              const SizedBox(height: 2),
              Text(first.isEmpty ? 'Bạn' : first, style: TutorType.name()),
              const SizedBox(height: 8),
              Text(summary, style: TutorType.rowSub()),
            ],
          ),
        ),
      ],
    );
  }
}

ReportReviewArgs _reviewArgs(RecorderLessonDto lesson) => ReportReviewArgs(
  recordingId: lesson.lessonId,
  studentName: lesson.studentName,
  subtitle: [
    if (lesson.subject != null && lesson.subject!.isNotEmpty) lesson.subject!,
    if (lesson.grade != null) 'Lớp ${lesson.grade}',
  ].join(' · '),
);

String _reviewLabel(RecorderLessonDto lesson) => switch (lesson.status) {
  'awaiting_approval' => 'Cần bạn duyệt',
  'failed' => 'AI lỗi · bạn tự viết báo cáo',
  _ => 'AI đang viết báo cáo…',
};

/// Banner tối có ảnh (khối nổi mức 2): báo cáo đầu tiên cần duyệt.
class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.lesson});

  final RecorderLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final d = lesson.when;
    final ready = lesson.status == 'awaiting_approval';
    return Semantics(
      button: true,
      label: '${_reviewLabel(lesson)}: báo cáo của ${lesson.studentName}',
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          color: const Color(0xFF141E19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331F2A24),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/decor/home_banner.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment(0.4, 0),
              ),
            ),
            child: InkWell(
              onTap: () => unawaited(
                GoRouter.of(
                  context,
                ).push(AppRoutes.tutorReportReview, extra: _reviewArgs(lesson)),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x8C111A15),
                      Color(0x26111A15),
                      Color(0x00111A15),
                    ],
                    stops: [0, 0.5, 0.7],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reviewLabel(lesson),
                        style: TutorType.caption(
                          color: const Color(0xFFC8CEC8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Báo cáo của ${lesson.studentName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TutorType.display(
                          size: 20,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (d != null)
                        Text(
                          'Buổi ${d.day}/${d.month}',
                          style: TutorType.caption(
                            color: const Color(0xFFC8CEC8),
                          ).copyWith(fontSize: 12.5),
                        ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ready ? 'Duyệt ngay' : 'Xem',
                              style: TutorType.action(color: Colors.white),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Báo cáo chờ duyệt thứ hai trở đi: thẻ mức 1.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.lesson});

  final RecorderLessonDto lesson;

  @override
  Widget build(BuildContext context) {
    final d = lesson.when;
    return CanvasOutlineCard(
      onTap: () => unawaited(
        GoRouter.of(
          context,
        ).push(AppRoutes.tutorReportReview, extra: _reviewArgs(lesson)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CanvasKicker(_reviewLabel(lesson)),
                const SizedBox(height: 2),
                Text(
                  [
                    'Báo cáo của ${lesson.studentName}',
                    if (d != null) 'buổi ${d.day}/${d.month}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TutorType.rowTitle(),
                ),
              ],
            ),
          ),
          const CanvasChevron(),
        ],
      ),
    );
  }
}

/// "Hết khóa": mỗi học sinh đã hết ngày kết thúc một khối gia hạn tháng mới
/// (nút nhanh 1 · 2 · 3 tháng hoặc chọn ngày). Ẩn khi không có ai.
class _EndedCoursesSection extends StatelessWidget {
  const _EndedCoursesSection({required this.students});

  final List<RecorderStudentDto> students;

  @override
  Widget build(BuildContext context) {
    final ended = students
        .where((s) => s.courseStatus() == CourseStatus.ended)
        .toList();
    if (ended.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        0,
        TutorSurface.gutter,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: 'Hết khóa', trailing: '${ended.length} em'),
          for (var i = 0; i < ended.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            CourseRenewPanel(student: ended[i], showName: true),
          ],
        ],
      ),
    );
  }
}

/// "Học sinh của bạn": thẻ cuộn ngang + thẻ thêm học sinh.
class _StudentsSection extends StatelessWidget {
  const _StudentsSection({required this.students});

  final List<RecorderStudentDto> students;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: TutorSurface.screenPadding,
          child: _SectionTitle(
            title: 'Học sinh của bạn',
            action: students.isEmpty ? null : 'Xem tất cả →',
            onAction: () => context.go(AppRoutes.tutorStudents),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              TutorSurface.gutter,
              4,
              TutorSurface.gutter,
              22,
            ),
            children: [
              for (final s in students) ...[
                _StudentCard(student: s),
                const SizedBox(width: 10),
              ],
              _AddStudentCard(wide: students.isEmpty),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final RecorderStudentDto student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: TutorSurface.card(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                unawaited(TutorStudentDetailScreen.open(context, s.studentId)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.courseStatus() == CourseStatus.ended)
                    const CanvasTag('Hết khóa', filled: true)
                  else if (s.courseStatus() == CourseStatus.endingSoon)
                    CanvasTag(
                      s.courseDaysLeft() == 0
                          ? 'Hết hôm nay'
                          : 'Còn ${s.courseDaysLeft()} ngày',
                    )
                  else if (!s.hasConsent)
                    const CanvasTag('Chờ đồng ý')
                  else
                    CanvasTag(
                      s.lessonCount == 0 ? 'Mới' : '${s.lessonCount} buổi',
                    ),
                  const Spacer(),
                  Text(
                    s.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.body(),
                  ),
                  Text(
                    s.subtitle.isEmpty ? 'Học 1-1' : s.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.rowSub(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddStudentCard extends StatelessWidget {
  const _AddStudentCard({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 220 : 60,
      child: DecoratedBox(
        decoration: TutorSurface.card(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => unawaited(TutorStudentFormScreen.open(context)),
            child: Center(
              child: wide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: TutorColors.ink),
                        const SizedBox(width: 6),
                        Text('Thêm học sinh', style: TutorType.action()),
                      ],
                    )
                  : const Icon(
                      Icons.add_rounded,
                      color: TutorColors.ink,
                      semanticLabel: 'Thêm học sinh',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Việc hôm nay": mỗi buổi chưa dạy là một việc ghi âm (vòng tròn trống),
/// buổi đã dạy có dấu tích. Gợi ý Topi "trước buổi học" nằm dưới buổi tới.
class _TodayTasks extends StatelessWidget {
  const _TodayTasks({required this.sessions});

  final List<TutorTodaySessionDto> sessions;

  static DateTime? _t(String iso) => DateTime.tryParse(iso)?.toLocal();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final list = [...sessions]
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    bool done(TutorTodaySessionDto s) {
      final end = _t(s.scheduledEnd);
      return end != null && !end.isAfter(now);
    }

    final next = list.where((s) => !done(s)).firstOrNull;
    final open = list.where((s) => !done(s)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Việc hôm nay',
          trailing: list.isEmpty ? null : '$open việc',
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Hôm nay bạn rảnh.', style: TutorType.rowSub()),
                ),
                CanvasGhostLink(
                  label: 'Xem lịch dạy',
                  onTap: () => context.go(AppRoutes.tutorSchedule),
                ),
              ],
            ),
          ),
        for (var i = 0; i < list.length; i++) ...[
          _TaskRow(session: list[i], done: done(list[i]), first: i == 0),
          if (identical(list[i], next) && next!.recorderStudentId != null)
            TopiStudentBeforeLessonEntry(
              studentId: next.recorderStudentId!,
              studentName: next.studentName,
              nextLessonAt: _t(next.scheduledStart),
              padding: const EdgeInsets.only(bottom: 10),
            ),
        ],
      ],
    );
  }
}

String _timeRange(TutorTodaySessionDto s) => [
  if (s.subjectName.isNotEmpty) s.subjectName,
  if (s.timeStart.isNotEmpty && s.timeEnd.isEmpty)
    s.timeStart
  else if (s.timeStart.isNotEmpty)
    '${s.timeStart} – ${s.timeEnd}',
].join(' · ');

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.session,
    required this.done,
    required this.first,
  });

  final TutorTodaySessionDto session;
  final bool done;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: done
          ? () => context.go(AppRoutes.tutorSchedule)
          : () => unawaited(
              context.push(
                AppRoutes.tutorRecording,
                extra: RecordingTarget.fromSession(session),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(top: first ? BorderSide.none : TutorSurface.rule),
        ),
        child: Row(
          children: [
            _Ring(done: done),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done
                        ? 'Đã dạy · ${session.studentName}'
                        : 'Ghi âm buổi học của ${session.studentName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.body(
                      color: done ? const Color(0xFF7E847E) : TutorColors.ink,
                    ),
                  ),
                  Text(
                    _timeRange(session),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _Ring extends StatelessWidget {
  const _Ring({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: done ? TutorColors.ink : null,
      border: done
          ? null
          : Border.all(color: const Color(0xFFA3A8A2), width: 1.6),
    ),
    child: done
        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
        : null,
  );
}

/// Vòng tròn chữ cái đầu.
class _Initial extends StatelessWidget {
  const _Initial({required this.text});

  final String text;

  static String of(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.split(' ').last.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: TutorColors.surfaceSunken,
        shape: BoxShape.circle,
      ),
      child: Text(text, style: TutorType.action()),
    );
  }
}

/// Tiêu đề nhóm (Bricolage) + liên kết phải hoặc chữ phụ phải.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: TutorType.sectionTitle())),
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Text(action!, style: TutorType.rowSub()),
              ),
            )
          else if (trailing != null)
            Text(trailing!, style: TutorType.rowSub()),
        ],
      ),
    );
  }
}

BoxDecoration _cardDeco() => TutorSurface.card();

// ── Lớp trên TopTutor (đặt qua nền tảng) ─────────────────────────────────────

class _ClassesSection extends ConsumerWidget {
  const _ClassesSection();

  static const _maxInline = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorClassesProvider);
    final all = async.valueOrNull?.items ?? const <TutorClassDto>[];
    final sorted = _teachable(all);
    if (!async.isLoading && !async.hasError && sorted.isEmpty) {
      return const SizedBox.shrink();
    }
    final shown = sorted.take(_maxInline).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Lớp trên TopTutor',
          action: sorted.length > _maxInline ? 'Xem tất cả' : null,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _AllClassesPage()),
          ),
        ),
        if (async.isLoading && all.isEmpty)
          const TutorSkeleton(height: 140, radius: 20)
        else if (async.hasError && all.isEmpty)
          _EmptyCard(
            text: 'Không tải được danh sách lớp. Chạm để thử lại.',
            onTap: () => ref.invalidate(tutorClassesProvider),
          )
        else if (sorted.isNotEmpty)
          _ClassList(items: shown),
      ],
    );
  }
}

/// Chỉ lớp còn buổi để dạy (chưa kết thúc và đã có buổi kế tiếp được mở),
/// xếp theo buổi tới sớm nhất.
List<TutorClassDto> _teachable(List<TutorClassDto> all) =>
    all.where((c) => !c.isFinished && c.nextStartLocal != null).toList()
      ..sort((a, b) => a.nextStartLocal!.compareTo(b.nextStartLocal!));

class _ClassList extends StatelessWidget {
  const _ClassList({required this.items});

  final List<TutorClassDto> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDeco(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: TutorColors.line, indent: 70),
              _ClassRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.item});

  final TutorClassDto item;

  static const _dows = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _sub() {
    if (item.isFinished) {
      return [
        if (item.subjectName.isNotEmpty) item.subjectName,
        'Đã kết thúc',
      ].join(' · ');
    }
    final next = item.nextStartLocal;
    final String when;
    if (next != null) {
      final hm =
          '${next.hour.toString().padLeft(2, '0')}:'
          '${next.minute.toString().padLeft(2, '0')}';
      when =
          'Buổi tới ${_dows[next.weekday - 1]} ${next.day}/${next.month} $hm';
    } else if (item.isWaitingRemainingPayment) {
      when = 'Chờ phụ huynh thanh toán';
    } else {
      when = item.schedule;
    }
    return [
      if (item.subjectName.isNotEmpty) item.subjectName,
      if (when.isNotEmpty) when,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final total = item.totalWithReserved;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorClassDetailScreen(item: item),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            _Initial(text: _Initial.of(item.studentName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: item.isFinished
                          ? TutorColors.ink4
                          : TutorColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sub(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: TutorColors.ink3,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.progress.clamp(0, 1).toDouble(),
                        minHeight: 4,
                        backgroundColor: TutorColors.surfaceSunken,
                        color: item.isFinished
                            ? TutorColors.ink4
                            : TutorColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  total > 0 ? '${item.completedSessions}/$total' : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TutorColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'buổi',
                  style: TextStyle(fontSize: 12, color: TutorColors.ink4),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: TutorColors.ink4,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TutorColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TutorColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: TutorType.rowSub()),
        ),
      ),
    );
  }
}

/// Toàn bộ lớp — mở từ "Xem tất cả".
class _AllClassesPage extends ConsumerWidget {
  const _AllClassesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(tutorClassesProvider).valueOrNull?.items ??
        const <TutorClassDto>[];
    final active = _teachable(items);
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () => ref.refresh(tutorClassesProvider.future),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                CanvasHeader(
                  title: 'Lớp trên TopTutor',
                  lead: '${active.length} lớp đang dạy',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: TutorSurface.screenPadding,
                  child: active.isNotEmpty
                      ? _ClassList(items: active)
                      : const _EmptyCard(text: 'Chưa có lớp nào đang dạy.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
