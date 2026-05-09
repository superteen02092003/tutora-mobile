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
import 'package:tutora/features/student/presentation/providers/dashboard_provider.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/shared/widgets/app_logo.dart';

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
  static const List<({String book, String sub, String time, String topic})>
  _recents = [
    (
      sub: 'Toán 10',
      topic: 'Hệ thức Vi-ét',
      book: 'Cánh Diều · §3.4',
      time: '5p trước',
    ),
    (
      sub: 'Vật Lý 10',
      topic: 'Định luật II Newton',
      book: 'Chân trời · §9.2',
      time: 'Hôm qua',
    ),
    (
      sub: 'Hóa 10',
      topic: 'Cấu hình electron',
      book: 'Kết nối · §4.1',
      time: '2 ngày',
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(ref.read(dashboardProvider.notifier).load));
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
    final dash = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            _TopBar(name: widget.firstName),
            _Greeting(firstName: widget.firstName),
            const SizedBox(height: AppSpacing.sm),
            const _HeroCapture(),
            const SizedBox(height: AppSpacing.xs),
            _QuickActions(
              onFindTutor: () => context.go(AppRoutes.studentSearch),
              onLessons: () => context.go(AppRoutes.studentLessons),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatRow(state: dash),
            _SectionHeader(
              title: 'Gần đây',
              onSeeAll: () {},
            ),
            ..._recents.map(
              (r) => _RecentItem(
                subject: r.sub,
                topic: r.topic,
                book: r.book,
                time: r.time,
                onTap: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const AppLogo(),
          const Spacer(),
          // Bell icon
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.oxblood,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Chat icon
          GestureDetector(
            onTap: () => context.push(AppRoutes.studentMessages),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
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

// Greeting
class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HỌC SINH',
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
                    letterSpacing: -0.02 * 30,
                    height: 1.05,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(
                  text: 'Hôm nay học gì?',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 28,
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

// Hero AI capture card
class _HeroCapture extends StatelessWidget {
  const _HeroCapture();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            // Radial gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const RadialGradient(
                    center: Alignment(0.9, -1),
                    radius: 1.2,
                    colors: [Color(0x2ED4B483), Colors.transparent],
                    stops: [0.0, 0.55],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI HỖ TRỢ',
                  style: AppTextStyles.eyebrow(color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chụp bài toán.\n',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.1,
                          color: AppColors.cream,
                        ),
                      ),
                      TextSpan(
                        text: 'Nhận lời giải nhanh chóng.',
                        style: GoogleFonts.ibmPlexSerif(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          fontSize: 21,
                          color: AppColors.gold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đọc bài toán → phân loại → gợi ý theo SGK Việt Nam.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _CameraButton(
                  onTap: () => context.go(AppRoutes.studentCapture),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 16,
              color: AppColors.ink,
            ),
            const SizedBox(width: 8),
            Text(
              'Mở camera',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick actions
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onFindTutor, required this.onLessons});

  final VoidCallback onFindTutor;
  final VoidCallback onLessons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
              onTap: onLessons,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
              ),
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

// Stat row
class _StatRow extends StatelessWidget {
  const _StatRow({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Booking',
            value: s?.totalBookings,
            icon: Icons.bookmark_border_rounded,
            isLoading: state.isLoading,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Buổi học',
            value: s?.totalLessons,
            icon: Icons.school_outlined,
            isLoading: state.isLoading,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Chờ xác nhận',
            value: s?.pendingCount,
            icon: Icons.hourglass_empty_rounded,
            isLoading: state.isLoading,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Hoàn thành',
            value: s?.completedCount,
            icon: Icons.check_circle_outline_rounded,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final int? value;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            // Icon(icon, size: 18, color: AppColors.ink3),
            const SizedBox(height: 6),
            if (isLoading)
              Container(
                width: 24,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              Text(
                '${value ?? 0}',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.eyebrow(),
              textAlign: TextAlign.center,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Xem tất cả',
              style: GoogleFonts.ibmPlexSerif(
                fontStyle: FontStyle.italic,
                fontSize: 16,
                color: AppColors.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Recent item
class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.subject,
    required this.topic,
    required this.book,
    required this.time,
    required this.onTap,
  });

  final String subject;
  final String topic;
  final String book;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              // Subject thumbnail placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFE9DA), Color(0xFFE5DDC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  subject.substring(0, 1),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: AppColors.ink2.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$book · $time',
                      style: AppTextStyles.bodySmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
