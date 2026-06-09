import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/screens/parent_home/parent_home_widgets.dart';
import 'package:tutora/features/parent/presentation/screens/parent_home/parent_next_lesson_card.dart';
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_child_avatar_strip.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_lesson_row.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_section_header.dart';
import 'package:tutora/mock/parent_home_mock.dart' as mock;
import 'package:tutora/shared/widgets/app_toast.dart';

class ParentHomePage extends ConsumerWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(secureStorageProvider).getAccessToken(),
      builder: (context, snap) {
        final claims = snap.hasData ? parseJwt(snap.data!) : null;
        final name = claims?.name ?? '';
        return _HomeContent(parentName: name);
      },
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({required this.parentName});
  final String parentName;

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

  void _confirmLesson(ParentLessonDto lesson) {
    unawaited(
      ref
          .read(parentDashboardProvider.notifier)
          .confirmLesson(lesson.lessonId)
          .then((_) {
            if (mounted) {
              AppToast.show(
                context,
                message: 'Đã xác nhận buổi học',
                type: AppToastType.success,
              );
            }
          }),
    );
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

    final allUpcoming =
        [...dash.todayLessons, ...dash.weekLessons]
            .where((l) => l.status != 'completed' && l.status != 'cancelled')
            .toList()
          ..sort((a, b) => a.startDt.compareTo(b.startDt));

    final filteredLessons = selectedId == null
        ? allUpcoming
        : allUpcoming.where((l) => l.studentId == selectedId).toList();

    // nextLesson scoped to selected student — with per-student mock fallback.
    final nextLesson =
        filteredLessons.firstOrNull ??
        mock.mockNextLessonFor(selectedId, selectedStudent?.fullName);

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
                    selectedSubject: nextLesson?.subjectName,
                    selectedTutor: nextLesson?.tutorName,
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
                        onReportAbsence: () => AppToast.show(
                          context,
                          message: 'Tính năng báo vắng sẽ sớm ra mắt',
                          type: AppToastType.info,
                        ),
                        onViewInfo: () =>
                            context.push(_calendarRoute(selectedId)),
                      ),
                    ],
                    if (dash.pendingLessons.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ParentConfirmBanner(
                        count: dash.pendingLessons.length,
                        onTap: () => _confirmLesson(dash.pendingLessons.first),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ParentQuickStats(
                      weekCount: dash.weekLessons.length,
                      childrenCount: students.students.length,
                      pendingCount: dash.pendingLessons.length,
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
                          ? 'Buổi học của ${selectedStudent.fullName.trim().split(' ').lastOrNull ?? selectedStudent.fullName}'
                          : 'Buổi học sắp tới',
                      action: 'Xem tất cả',
                      onAction: () => context.push(_calendarRoute(selectedId)),
                    ),
                    if (filteredLessons.isEmpty)
                      ParentNoLessonCta(
                        onFindTutor: () => context.go(AppRoutes.parentSearch),
                      )
                    else
                      ...filteredLessons
                          .take(3)
                          .map(
                            (l) => ParentLessonRow(lesson: l),
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
