import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/router/app_routes.dart';
// re-export parent_models: ParentLessonDto, ParentActionException.
import 'package:tutora/features/parent/data/datasources/parent_datasource.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/screens/parent_home/parent_home_widgets.dart';
import 'package:tutora/features/parent/presentation/screens/parent_home/parent_next_lesson_card.dart';
import 'package:tutora/features/parent/presentation/screens/parent_session_detail_screen.dart';
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_child_avatar_strip.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_section_header.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/class_widgets.dart';
import 'package:tutora/shared/widgets/reschedule_sheet.dart';

class ParentHomePage extends ConsumerWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const _HomeContent();
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent>
    with ParentScrollToTopMixin {
  final _scrollController = ScrollController();
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        await ref.read(parentDashboardProvider.notifier).load();
        await ref.read(parentStudentsProvider.notifier).load();
      }),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 0, _scrollController);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _calendarRoute(String? studentId) => studentId == null
      ? AppRoutes.parentCalendar
      : '${AppRoutes.parentCalendar}?studentId=$studentId';

  String _bookingsRoute(String? studentId) => studentId == null
      ? AppRoutes.parentBookings
      : '${AppRoutes.parentBookings}?studentId=$studentId';

  /// Banner "Cần xác nhận" chỉ ĐIỀU HƯỚNG, không tự xác nhận
  void _openPendingConfirmation(List<ParentLessonDto> pending) {
    if (pending.isEmpty) return;
    if (pending.length == 1) {
      unawaited(
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                ParentSessionDetailScreen(lessonId: pending.first.lessonId),
          ),
        ),
      );
      return;
    }
    unawaited(context.push(_calendarRoute(_selectedStudentId)));
  }

  Future<void> _reschedule(ParentLessonDto lesson, String? selectedId) async {
    final choice = await showRescheduleSheet(
      context,
      currentStart: lesson.startDt,
      currentEnd: lesson.endDt,
    );
    if (choice == null || !mounted) return;

    try {
      await ref
          .read(parentDatasourceProvider)
          .proposeReschedule(
            lessonId: lesson.lessonId,
            proposedStart: choice.start,
            reason: choice.reason,
          );
      if (!mounted) return;
      ref.invalidate(parentNextLessonProvider(selectedId ?? ''));
      if (selectedId != null) {
        ref.invalidate(parentChildLessonsProvider(selectedId));
      }
      AppToast.show(
        context,
        message: 'Đã gửi đề xuất đổi lịch, chờ gia sư phản hồi',
        type: AppToastType.success,
      );
    } on ParentActionException catch (e) {
      if (!mounted) return;
      AppToast.show(context, message: e.message, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(parentDashboardProvider);
    final students = ref.watch(parentStudentsProvider);

    final selectedId =
        _selectedStudentId ?? students.students.firstOrNull?.studentId;
    final selectedStudent = students.students
        .where((s) => s.studentId == selectedId)
        .firstOrNull;

    // Lịch chung (calendar) không có studentId — con đang chọn phải lấy từ API riêng.
    final childLessons = selectedId == null
        ? const AsyncValue<List<ParentLessonDto>>.data([])
        : ref.watch(parentChildLessonsProvider(selectedId));

    final source = selectedId == null
        ? dash.weekLessons
        : childLessons.valueOrNull ?? const <ParentLessonDto>[];

    final filteredLessons = source.where((l) => l.isUpcoming).toList()
      ..sort((a, b) => a.startDt.compareTo(b.startDt));

    // Buổi kế tiếp lấy từ API riêng — BE loại sẵn buổi giữ chỗ/bị khoá thanh toán.
    final nextLesson = ref
        .watch(parentNextLessonProvider(selectedId ?? ''))
        .valueOrNull;
    final stats = ref
        .watch(parentHomeStatsProvider(selectedId ?? ''))
        .valueOrNull;

    // Endpoint pending trả buổi của MỌI con — phải lọc theo con đang chọn, nếu
    // không banner đếm cả con khác rồi lệch với ô "Chờ xác nhận".
    final pendingLessons = selectedId == null
        ? dash.pendingLessons
        : dash.pendingLessons.where((l) => l.studentId == selectedId).toList();

    final childClasses = selectedId == null
        ? const AsyncValue<List<StudentClassDto>>.data([])
        : ref.watch(parentChildClassesProvider(selectedId));

    // Lớp đang học lên trước; lớp huỷ/hết hạn đã bị BE loại từ đầu.
    final classes = [
      ...(childClasses.valueOrNull ?? const <StudentClassDto>[]).where(
        (k) => k.isOngoing,
      ),
      ...(childClasses.valueOrNull ?? const <StudentClassDto>[]).where(
        (k) => !k.isOngoing,
      ),
    ];

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          ParentHomeGradientPanel(
            child: SizedBox(
              height: topInset + 230,
              width: double.infinity,
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.ink,
              backgroundColor: AppColors.paper,
              onRefresh: () async {
                if (selectedId != null) {
                  ref
                    ..invalidate(parentChildLessonsProvider(selectedId))
                    ..invalidate(parentChildClassesProvider(selectedId));
                }
                ref
                  ..invalidate(parentNextLessonProvider(selectedId ?? ''))
                  ..invalidate(parentHomeStatsProvider(selectedId ?? ''));
                await ref.read(parentDashboardProvider.notifier).load();
                await ref.read(parentStudentsProvider.notifier).load();
              },
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  ParentChildAvatarStrip(
                    students: students.students,
                    isLoading: students.isLoading,
                    selectedId: selectedId,
                    onSelect: (id) => setState(() => _selectedStudentId = id),
                    onAddChild: () async {
                      context.go(AppRoutes.parentProfile);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 300),
                      );
                      if (context.mounted) {
                        unawaited(context.push(AppRoutes.parentAddChild));
                      }
                    },
                    onNotif: () => context.push(AppRoutes.parentNotifications),
                    // Header nói con đang học môn gì
                    selectedSubject:
                        nextLesson?.subjectName ??
                        filteredLessons.firstOrNull?.subjectName,
                    selectedTutor:
                        nextLesson?.tutorName ??
                        filteredLessons.firstOrNull?.tutorName,
                    onDark: true,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (dash.isLoading) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.ink),
                    ),
                  ] else ...[
                    if (nextLesson != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ParentNextLessonCard(
                        lesson: nextLesson,
                        onReschedule: () =>
                            unawaited(_reschedule(nextLesson, selectedId)),
                        onViewInfo: () =>
                            context.push(_calendarRoute(selectedId)),
                      ),
                    ],
                    if (pendingLessons.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ParentConfirmBanner(
                        count: pendingLessons.length,
                        onTap: () => _openPendingConfirmation(pendingLessons),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ParentQuickStats(
                      weekCount: stats?.sessionsThisWeek ?? 0,
                      childrenCount: stats?.childrenLearning ?? 0,
                      pendingCount:
                          stats?.pendingConfirmation ?? pendingLessons.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ParentQuickAccessGrid(
                      onCalendar: () =>
                          context.push(_calendarRoute(selectedId)),
                      onMessages: () => context.go(AppRoutes.parentMessages),
                      onBookings: () =>
                          context.push(_bookingsRoute(selectedId)),
                      onFindTutor: () => context.go(AppRoutes.parentSearch),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ParentSectionHeader(
                      title: selectedStudent != null
                          ? 'Lớp học của ${selectedStudent.fullName.trim().split(' ').lastOrNull ?? selectedStudent.fullName}'
                          : 'Lớp học',
                      action: 'Xem tất cả',
                      onAction: () => context.push(_bookingsRoute(selectedId)),
                    ),
                    if (childClasses.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.ink,
                          ),
                        ),
                      )
                    else if (classes.isEmpty)
                      ParentNoLessonCta(
                        onFindTutor: () => context.go(AppRoutes.parentSearch),
                      )
                    else
                      // Lớp đang học lên trước, mỗi lớp một card (không phải từng buổi).
                      ...classes
                          .take(3)
                          .map(
                            (k) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  textScaler: MediaQuery.textScalerOf(
                                    context,
                                  ).clamp(minScaleFactor: 1.18),
                                ),
                                child: ClassCard(
                                  klass: k,
                                  onTap: () =>
                                      context.push(_bookingsRoute(selectedId)),
                                ),
                              ),
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
