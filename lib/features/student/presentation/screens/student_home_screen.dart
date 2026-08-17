import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_assets.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/student/data/datasources/ai_solve_datasource.dart';
import 'package:tutora/features/student/presentation/providers/ai_solve_provider.dart';
import 'package:tutora/features/student/presentation/providers/class_provider.dart';
import 'package:tutora/features/student/presentation/screens/student_class_detail_screen.dart';
import 'package:tutora/features/student/presentation/screens/student_session_detail_screen.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/shared/live_session/session_lobby_screen.dart';
import 'package:tutora/shared/models/class_models.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/class_widgets.dart';
import 'package:tutora/shared/widgets/notification_bell.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(secureStorageProvider).getAccessToken(),
      builder: (context, snap) {
        final claims = snap.hasData ? parseJwt(snap.data!) : null;
        final firstName = _firstName(claims?.name ?? '');
        return _HomeContent(firstName: firstName);
      },
    );
  }

  String _firstName(String fullName) {
    if (fullName.isEmpty) return 'bạn';
    final parts = fullName.trim().split(' ');
    return parts.first;
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({required this.firstName});

  final String firstName;

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent>
    with ScrollToTopMixin {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() => ref.read(classListProvider.notifier).refresh()),
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

  Future<void> _refresh() async {
    ref
      ..invalidate(nextSessionProvider)
      ..invalidate(solveHistoryProvider);
    await ref.read(classListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classListProvider);
    final ongoing = classes.ongoing;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.oxblood,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _TopBar(name: widget.firstName),
              _Greeting(firstName: widget.firstName),
              const SizedBox(height: AppSpacing.sm),
              const _UpcomingCard(),
              const SizedBox(height: 4),
              const _QuickActions(),
              _SectionHeader(
                title: 'Lớp đang học',
                onSeeAll: () => context.go(AppRoutes.studentLessons),
              ),
              _OngoingClasses(
                classes: ongoing,
                isLoading: classes.isLoading && classes.items.isEmpty,
              ),
              _SectionHeader(
                title: 'Hỏi AI gần đây',
                onSeeAll: () => context.push(AppRoutes.studentSolveHistory),
              ),
              const _RecentAskList(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// Top bar

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.notifications_outlined,
            onTap: () => context.push(AppRoutes.notifications),
            withBadge: true,
          ),
          const SizedBox(width: 10),
          _CircleIconButton(
            icon: Icons.chat_bubble_outline,
            onTap: () => context.push(AppRoutes.studentMessages),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.withBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool withBadge;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(icon, size: 19, color: AppColors.ink),
    );

    return GestureDetector(
      onTap: onTap,
      child: withBadge ? NotificationBadge(child: button) : button,
    );
  }
}

// Greeting

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào, $firstName 👋',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hôm nay học gì?',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 30,
              letterSpacing: -0.02 * 30,
              height: 1.1,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// Buổi học sắp tới — card chính của trang chủ

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nextSessionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: async.when(
        loading: () => Container(
          height: 168,
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        error: (e, _) => _UpcomingEmpty(
          title: 'Chưa tải được lịch học',
          message: e.toString().replaceFirst('Exception: ', ''),
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(nextSessionProvider),
        ),
        data: (session) {
          if (session == null) {
            return _UpcomingEmpty(
              title: 'Chưa có buổi học nào',
              message: 'Tìm gia sư phù hợp và đặt buổi học đầu tiên của bạn.',
              actionLabel: 'Tìm gia sư',
              onAction: () => context.go(AppRoutes.studentSearch),
            );
          }
          return _UpcomingContent(session: session);
        },
      ),
    );
  }
}

class _UpcomingContent extends StatelessWidget {
  const _UpcomingContent({required this.session});

  final UpcomingSessionDto session;

  @override
  Widget build(BuildContext context) {
    final live = session.state == ClassSessionState.inProgress;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              StudentSessionDetailPage(lessonId: session.classSessionId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3EE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD6E0D4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: live ? AppColors.green : AppColors.moss,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    live ? 'ĐANG DIỄN RA' : 'BUỔI HỌC SẮP TỚI',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.08,
                      color: AppColors.cream,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  session.countdownLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.moss,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          height: 1.15,
                          color: AppColors.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.tutorName ?? 'Gia sư',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            size: 15,
                            color: AppColors.moss,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${session.dayLabel} · ${session.timeRange}',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  AppAssets.heroUpcoming,
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _JoinButton(session: session),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.session});

  final UpcomingSessionDto session;

  /// Phòng luôn mở nên chỉ đổi chữ theo việc đã tới sát giờ hay chưa.
  String get _label {
    if (!session.canJoinNow) return 'Phòng học đã đóng';
    return session.isWithinJoinWindow ? 'Vào phòng học' : 'Vào phòng sớm';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = session.canJoinNow;

    return GestureDetector(
      onTap: enabled
          ? () => unawaited(
              Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SessionLobbyScreen(
                    classSessionId: session.classSessionId,
                    tutorName: session.tutorName,
                  ),
                ),
              ),
            )
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? AppColors.moss : AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? AppColors.moss : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              enabled ? Icons.videocam_rounded : Icons.lock_clock_rounded,
              size: 17,
              color: enabled ? AppColors.cream : AppColors.ink3,
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.cream : AppColors.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEmpty extends StatelessWidget {
  const _UpcomingEmpty({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E0D4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                    height: 1.2,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.ink3,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.moss,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            AppAssets.heroNoLesson,
            width: 78,
            height: 78,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// Hành động nhanh

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: 'Giải bài tập',
              image: AppAssets.actionSolve,
              bg: const Color(0xFFF3EEF8),
              border: const Color(0xFFE3D9EE),
              onTap: () => context.go(AppRoutes.studentCapture),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              title: 'Tìm gia sư',
              image: AppAssets.actionFindTutor,
              bg: const Color(0xFFFBF0E8),
              border: const Color(0xFFEFDDCE),
              onTap: () => context.go(AppRoutes.studentSearch),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.image,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  final String title;
  final String image;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề luôn nằm gọn 1 dòng: chiếm hết bề ngang card và tự thu
            // nhỏ cỡ chữ trên máy hẹp thay vì bị ngắt dòng.
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.25,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Image.asset(image, width: 52, height: 52, fit: BoxFit.contain),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Lớp đang học

class _OngoingClasses extends StatelessWidget {
  const _OngoingClasses({required this.classes, required this.isLoading});

  final List<StudentClassDto> classes;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          height: 156,
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    if (classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Image.asset(
                AppAssets.emptyClasses,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bạn chưa có lớp học nào đang diễn ra.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.ink3,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: classes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _ClassProgressTile(
          klass: classes[i],
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  StudentClassDetailPage(bookingId: classes[i].bookingId),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassProgressTile extends StatelessWidget {
  const _ClassProgressTile({required this.klass, required this.onTap});

  final StudentClassDto klass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final next = klass.nextSession;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 228,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SubjectIcon(
                  iconUrl: klass.subjectIconUrl,
                  subjectName: klass.subjectName,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    klass.title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${klass.progressPercent}%',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oxblood,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              klass.tutorName ?? 'Gia sư',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ProgressBar(progress: klass.progress),
            const SizedBox(height: 10),
            Text(
              '${klass.doneSessions}/${klass.countedSessions} buổi'
              '${next != null ? ' · Buổi tới ${next.dateLabel}' : ''}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Section header

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.ink,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Xem tất cả',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.oxblood,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Hỏi AI gần đây — 3 phiên mới nhất từ /ai-chat/sessions

class _RecentAskList extends ConsumerWidget {
  const _RecentAskList();

  static const _maxItems = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(solveHistoryProvider);

    return async.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_RecentSkeleton(), _RecentSkeleton()],
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: _RecentEmpty(
          message: 'Chưa tải được lịch sử hỏi AI.',
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(solveHistoryProvider),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: _RecentEmpty(
              message: 'Bạn chưa hỏi AI bài nào. Chụp một bài toán để bắt đầu.',
              actionLabel: 'Mở camera',
              onAction: () => context.go(AppRoutes.studentCapture),
            ),
          );
        }
        final shown = sessions.take(_maxItems).toList();
        return Column(
          // stretch: mỗi dòng chiếm trọn bề ngang để chữ căn trái và đường kẻ
          // kéo hết chiều rộng — mặc định của Column là center.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < shown.length; i++)
              _RecentAskItem(
                session: shown[i],
                showDivider: i < shown.length - 1,
                onTap: () => context.push(
                  AppRoutes.studentSolveSession.replaceFirst(
                    ':sessionId',
                    shown[i].sessionId,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Một dòng lịch sử hỏi AI — danh sách phẳng, không viền/nền riêng; các dòng
/// tách nhau bằng một đường kẻ mảnh.
class _RecentAskItem extends StatelessWidget {
  const _RecentAskItem({
    required this.session,
    required this.onTap,
    required this.showDivider,
  });

  final AiChatSession session;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final title = (session.title?.trim().isNotEmpty ?? false)
        ? session.title!.trim()
        : 'Bài đã hỏi';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.ink,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              _relativeTime(session.updatedAt ?? session.createdAt),
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 9),
          Container(
            height: 11,
            width: 110,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.emptyAsk,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.ink3,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "5 phút trước" / "Hôm qua" / "12/08" — nhãn thời gian ngắn cho card.
String _relativeTime(DateTime? raw) {
  if (raw == null) return '';
  final t = raw.toLocal();
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays == 1) return 'Hôm qua';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return DateFormat('dd/MM').format(t);
}
