import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/notification_bell.dart';

class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen>
    with TutorScrollToTopMixin {
  final _scrollController = ScrollController();

  static String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.last;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 0, _scrollController);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(tutorProfileProvider);
    final dashState = ref.watch(tutorDashboardProvider);
    final name = profileState.user?.fullName ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: dashState.isLoading && dashState.data == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(tutorDashboardProvider.notifier).load(),
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    _TopBar(name: name),
                    _Greeting(
                      firstName: name.isNotEmpty ? _firstName(name) : 'bạn',
                      sessionCount: dashState.data?.todaySessions.length ?? 0,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatGrid(data: dashState.data),
                    if (dashState.data != null &&
                        dashState.data!.todaySessions.isNotEmpty) ...[
                      _SectionHeader(
                        title:
                            'Hôm nay · ${dashState.data!.todaySessions.length} buổi',
                        action: 'Xem cả tuần',
                        onAction: () => context.go(AppRoutes.tutorSchedule),
                      ),
                      ...dashState.data!.todaySessions.map(
                        (s) => _SessionCard(session: s),
                      ),
                    ] else if (dashState.data != null) ...[
                      _SectionHeader(
                        title: 'Hôm nay · 0 buổi',
                        action: 'Xem lịch',
                        onAction: () => context.go(AppRoutes.tutorSchedule),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(
                          'Không có buổi học nào hôm nay.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _QuestionBankStrip(
                      onContribute: () => context.go(AppRoutes.tutorContribute),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(AppRoutes.tutorNotifications),
            child: NotificationBadge(
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
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName, required this.sessionCount});

  final String firstName;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BẢNG ĐIỀU KHIỂN GIA SƯ',
            style: AppTextStyles.eyebrow(color: AppColors.oxblood),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Chào, $firstName.\n',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    letterSpacing: -0.6,
                    height: 1.05,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: sessionCount > 0
                      ? '$sessionCount buổi học hôm nay.'
                      : 'Không có buổi học hôm nay.',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 26,
                    color: AppColors.ink2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({this.data});

  final TutorDashboardDto? data;

  String _fmtEarnings(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}tr';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return fmtVnd(v.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final stats = data == null
        ? _loadingStats
        : [
            (
              label: 'Doanh thu tháng',
              value: _fmtEarnings(data!.monthlyEarnings),
              sub: '${data!.completedSessions} buổi hoàn thành',
              tone: 'ink',
            ),
            (
              label: 'Buổi sắp tới',
              value: '${data!.upcomingSessions}',
              sub: 'Chưa diễn ra',
              tone: 'cream',
            ),
            (
              label: 'Đánh giá',
              value: data!.averageRating.toStringAsFixed(2),
              sub: '${data!.totalReviews} đánh giá',
              tone: 'cream',
            ),
            (
              label: 'Đang giữ tạm',
              value: _fmtEarnings(data!.escrowBalance),
              sub: '${data!.escrowSessions} buổi · escrow',
              tone: 'gold',
            ),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: stats
            .map(
              (s) => _StatCard(
                label: s.label,
                value: s.value,
                sub: s.sub,
                tone: s.tone,
              ),
            )
            .toList(),
      ),
    );
  }
}

const _loadingStats = <({String label, String value, String sub, String tone})>[
  (label: 'Doanh thu tháng', value: '—', sub: '—', tone: 'ink'),
  (label: 'Buổi sắp tới', value: '—', sub: '—', tone: 'cream'),
  (label: 'Đánh giá', value: '—', sub: '—', tone: 'cream'),
  (label: 'Đang giữ tạm', value: '—', sub: '—', tone: 'gold'),
];

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.tone,
  });

  final String label;
  final String value;
  final String sub;
  final String tone;

  bool get _isDark => tone == 'ink';
  bool get _isGold => tone == 'gold';

  Color get _bg => _isDark
      ? AppColors.ink
      : _isGold
      ? const Color(0xFFF0E3CA)
      : AppColors.paper;

  Color get _border => _isDark
      ? Colors.transparent
      : _isGold
      ? const Color(0xFFE0D2A8)
      : AppColors.line;

  Color get _labelColor => _isDark ? AppColors.gold : AppColors.ink3;
  Color get _valueColor => _isDark ? AppColors.cream : AppColors.ink;
  Color get _subColor =>
      _isDark ? AppColors.cream.withValues(alpha: 0.55) : AppColors.ink3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.eyebrow(color: _labelColor)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: _valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: _subColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppTextStyles.eyebrow()),
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: GoogleFonts.ibmPlexSerif(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: AppColors.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final TutorTodaySessionDto session;

  @override
  Widget build(BuildContext context) {
    final isNext = session.isUpcoming;
    final timeLabel = session.timeStart.isNotEmpty ? session.timeStart : '—';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: const BorderSide(color: AppColors.line),
            right: const BorderSide(color: AppColors.line),
            bottom: const BorderSide(color: AppColors.line),
            left: BorderSide(
              color: isNext ? AppColors.oxblood : AppColors.line,
              width: isNext ? 3 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                timeLabel,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.studentName,
                    style: GoogleFonts.ibmPlexSerif(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.subjectName,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isNext ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: isNext ? null : Border.all(color: AppColors.line),
                ),
                child: Text(
                  isNext ? 'Vào lớp' : 'Xem',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isNext ? AppColors.cream : AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBankStrip extends StatelessWidget {
  const _QuestionBankStrip({required this.onContribute});

  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NGÂN HÀNG CÂU HỎI', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onContribute,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E3CA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: AppColors.oxblood,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đóng góp bài tập có lời giải',
                          style: GoogleFonts.ibmPlexSerif(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chia sẻ kiến thức · nhận thưởng',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.ink3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
