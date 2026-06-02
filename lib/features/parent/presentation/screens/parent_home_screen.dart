import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
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

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';
    final first = name.trim().split(' ').lastOrNull ?? 'bạn';
    return '$greet, $first.';
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(parentDashboardProvider);
    final students = ref.watch(parentStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          backgroundColor: AppColors.paper,
          onRefresh: () async {
            await ref.read(parentDashboardProvider.notifier).load();
            await ref.read(parentStudentsProvider.notifier).load();
          },
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              _TopBar(
                onNotif: () => context.push(AppRoutes.parentNotifications),
              ),
              _Greeting(text: _greeting(widget.parentName)),
              const SizedBox(height: AppSpacing.sm),
              _QuickActions(
                onFindTutor: () => context.go(AppRoutes.parentSearch),
                onCalendar: () => context.push(AppRoutes.parentCalendar),
              ),
              if (dash.isLoading) ...[
                const SizedBox(height: AppSpacing.lg),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                _ChildrenStrip(
                  students: students.students,
                  isLoading: students.isLoading,
                ),
                if (dash.todayLessons.isNotEmpty) ...[
                  const _SectionHeader(title: 'Buổi học hôm nay'),
                  ...dash.todayLessons.map(
                    (l) => _LessonCard(lesson: l, showConfirm: false),
                  ),
                ],
                if (dash.pendingLessons.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Cần xác nhận',
                    badge: dash.pendingLessons.length,
                  ),
                  ...dash.pendingLessons.map(
                    (l) => _LessonCard(
                      lesson: l,
                      showConfirm: true,
                      onConfirm: () async {
                        await ref
                            .read(parentDashboardProvider.notifier)
                            .confirmLesson(l.lessonId);
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            message: 'Đã xác nhận buổi học',
                            type: AppToastType.success,
                          );
                        }
                      },
                    ),
                  ),
                ],
                if (dash.weekLessons.isNotEmpty) ...[
                  const _SectionHeader(title: 'Lịch học tuần này'),
                  _WeekStrip(lessons: dash.weekLessons),
                ],
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onNotif});
  final VoidCallback onNotif;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          GestureDetector(
            onTap: onNotif,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHỤ HUYNH',
            style: AppTextStyles.eyebrow(color: AppColors.oxblood),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.02 * 28,
              height: 1.1,
              color: AppColors.ink,
            ),
          ),
          Text(
            'Theo dõi việc học của con.',
            style: GoogleFonts.ibmPlexSerif(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              fontSize: 22,
              color: AppColors.ink2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onFindTutor, required this.onCalendar});
  final VoidCallback onFindTutor;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.search_rounded,
              label: 'Tìm gia sư',
              color: AppColors.oxblood,
              bg: const Color(0xFFF5E9E9),
              onTap: onFindTutor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.calendar_month_outlined,
              label: 'Xem lịch học',
              color: const Color(0xFF3D6EEA),
              bg: const Color(0xFFE8F0FE),
              onTap: onCalendar,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildrenStrip extends StatelessWidget {
  const _ChildrenStrip({required this.students, required this.isLoading});
  final List<ParentStudentDto> students;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Con của tôi'),
        SizedBox(
          height: 90,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...students.map((s) => _ChildChip(student: s)),
                    _AddChildChip(
                      onTap: () => context.push(AppRoutes.parentProfile),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({required this.student});
  final ParentStudentDto student;

  @override
  Widget build(BuildContext context) {
    final initials = student.fullName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.parentStudentDetail.replaceFirst(':id', student.studentId),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: student.avatarUrl != null && student.avatarUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        student.avatarUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _Initials(initials),
                      ),
                    )
                  : _Initials(initials),
            ),
            const SizedBox(height: 5),
            Text(
              student.fullName.trim().split(' ').lastOrNull ?? student.fullName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (student.gradeLevel != null)
              Text(
                student.gradeLevel!,
                style: AppTextStyles.bodySmall(),
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink2,
      ),
    );
  }
}

class _AddChildChip extends StatelessWidget {
  const _AddChildChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 22,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Thêm con',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.badge});
  final String title;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
              color: AppColors.ink4,
            ),
          ),
          if (badge != null && badge! > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.oxblood,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$badge',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.showConfirm,
    this.onConfirm,
  });
  final ParentLessonDto lesson;
  final bool showConfirm;
  final VoidCallback? onConfirm;

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = lesson.startDt;
    final end = lesson.endDt;
    final modeIcon = lesson.teachingMode == 'online'
        ? Icons.videocam_outlined
        : Icons.location_on_outlined;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cream2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(modeIcon, size: 18, color: AppColors.ink3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.studentName ?? 'Học sinh',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        lesson.subjectName ?? 'Chưa có môn',
                        style: AppTextStyles.bodySmall(),
                      ),
                    ],
                  ),
                ),
                _StatusDot(status: lesson.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: AppColors.ink4,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_fmtDate(start)}  ${_fmtTime(start)} – ${_fmtTime(end)}',
                  style: AppTextStyles.bodySmall(),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.ink4,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lesson.tutorName ?? '—',
                    style: AppTextStyles.bodySmall(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (showConfirm) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.cream,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    'Xác nhận hoàn thành',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppColors.green,
      'checkedin' || 'scheduled' => const Color(0xFF3D6EEA),
      'cancelled' || 'noshow' => AppColors.oxblood,
      _ => AppColors.ink4,
    };
    final label = switch (status) {
      'completed' => 'Hoàn thành',
      'checkedin' => 'Đang học',
      'scheduled' => 'Sắp diễn ra',
      'cancelled' => 'Đã huỷ',
      'noshow' => 'Vắng mặt',
      _ => 'Không rõ',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.lessons});
  final List<ParentLessonDto> lessons;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            // Day headers
            Row(
              children: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final isToday =
                    day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year;
                final hasLesson = lessons.any((l) {
                  final ld = l.startDt;
                  return ld.day == day.day &&
                      ld.month == day.month &&
                      ld.year == day.year;
                });
                const dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        dayNames[i],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isToday ? AppColors.oxblood : AppColors.ink4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? AppColors.ink : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isToday ? AppColors.cream : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasLesson
                              ? AppColors.oxblood
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            if (lessons.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 10),
              ...lessons
                  .take(3)
                  .map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.oxblood,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l.studentName ?? 'Học sinh'} · ${l.subjectName ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  _fmtLesson(l),
                                  style: AppTextStyles.bodySmall(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (lessons.length > 3)
                Text(
                  '+${lessons.length - 3} buổi khác',
                  style: AppTextStyles.bodySmall(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtLesson(ParentLessonDto l) {
    final dt = l.startDt;
    final end = l.endDt;
    String h(int v) => v.toString().padLeft(2, '0');
    String m(int v) => v.toString().padLeft(2, '0');
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayLabel = days[(dt.weekday - 1) % 7];
    return '$dayLabel ${h(dt.hour)}:${m(dt.minute)} – ${h(end.hour)}:${m(end.minute)}';
  }
}
