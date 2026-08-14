import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_finance_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_bookings/tutor_booking_requests_screen.dart';
import 'package:tutora/features/tutor/presentation/shell/tutor_shell.dart';
import 'package:tutora/features/tutor/presentation/widgets/booking_request_card.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/providers/notification_provider.dart';

/// Trang chủ gia sư.
///
/// Nguyên tắc bố cục: mở app ra là thấy **việc phải làm hôm nay**, không phải
/// lời chào. Thứ tự khối theo mức độ cần hành động giảm dần:
/// buổi hôm nay → tiền đang chờ → số liệu tháng.
class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen>
    with TutorScrollToTopMixin {
  final _scrollController = ScrollController();

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

  static String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? '' : parts.last;
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(tutorWalletProvider)
      ..invalidate(tutorBookingsProvider);
    await ref.read(tutorDashboardProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(tutorProfileProvider);
    final dash = ref.watch(tutorDashboardProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    final name = profile.user?.fullName ?? '';
    final data = dash.data;
    final loading = dash.isLoading && data == null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.ink,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              TutorScreenHeader(
                title: name.isEmpty ? 'Trang chủ' : 'Chào ${_firstName(name)}',
                subtitle: _todayLabel(),
                actions: [
                  TutorHeaderButton(
                    icon: Icons.notifications_none_rounded,
                    badge: unread > 0,
                    tooltip: 'Thông báo',
                    onTap: () => context.push(AppRoutes.tutorNotifications),
                  ),
                ],
              ),

              if (loading)
                const _HomeSkeleton()
              else ...[
                // Yêu cầu đặt lịch có hạn 24h → luôn đứng trên mọi thứ khác.
                const _PendingBookingsSection(),
                _TodaySection(sessions: data?.todaySessions ?? const []),
                const SizedBox(height: TutorSurface.sectionGap),
                _MoneySection(data: data),
                const SizedBox(height: TutorSurface.sectionGap),
                _MonthSection(data: data),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _todayLabel() {
    const weekdays = [
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
      'Chủ nhật',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day}/${now.month}';
  }
}

// ── Cần xử lý ───────────────────────────────────────────────────────────────

/// Yêu cầu đặt lịch đang chờ quyết định.
///
/// Ẩn hoàn toàn khi không có việc nào — Home không nên có khối rỗng chiếm chỗ.
/// Hiện tối đa 2 thẻ; nhiều hơn thì đẩy sang màn danh sách đầy đủ.
class _PendingBookingsSection extends ConsumerWidget {
  const _PendingBookingsSection();

  static const _maxInline = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingBookingsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();

    final shown = pending.take(_maxInline).toList();
    final hiddenCount = pending.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TutorSectionHeader(
          title: 'Cần xử lý · ${pending.length}',
          trailingLabel: pending.length > _maxInline ? 'Xem tất cả' : null,
          onTrailingTap: () => _openAll(context),
        ),
        Padding(
          padding: TutorSurface.screenPadding,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(height: TutorSurface.rowGap),
                BookingRequestCard(booking: shown[i]),
              ],
              if (hiddenCount > 0) ...[
                const SizedBox(height: TutorSurface.rowGap),
                TutorCard(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () => _openAll(context),
                  child: Center(
                    child: Text(
                      'Còn $hiddenCount yêu cầu khác',
                      style: TutorType.action(color: AppColors.ink2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TutorSurface.sectionGap),
      ],
    );
  }

  static void _openAll(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const TutorBookingRequestsScreen(),
    ),
  );
}

// ── Hôm nay ─────────────────────────────────────────────────────────────────

class _TodaySection extends StatelessWidget {
  const _TodaySection({required this.sessions});

  final List<TutorTodaySessionDto> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TutorSectionHeader(
          title: sessions.isEmpty
              ? 'Hôm nay'
              : 'Hôm nay · ${sessions.length} buổi',
          trailingLabel: 'Xem lịch',
          onTrailingTap: () => context.go(AppRoutes.tutorSchedule),
        ),
        Padding(
          padding: TutorSurface.screenPadding,
          child: sessions.isEmpty
              ? TutorCard(
                  padding: EdgeInsets.zero,
                  child: TutorEmptyState(
                    icon: Icons.event_available_outlined,
                    message: 'Hôm nay không có buổi dạy nào.',
                    actionLabel: 'Mở lịch dạy',
                    onAction: () => context.go(AppRoutes.tutorSchedule),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < sessions.length; i++) ...[
                      if (i > 0) const SizedBox(height: TutorSurface.rowGap),
                      _SessionCard(
                        session: sessions[i],
                        // Chỉ buổi gần nhất được nhấn mạnh, tránh cả màn đỏ.
                        isNext: i == 0 && sessions[i].isUpcoming,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.isNext});

  final TutorTodaySessionDto session;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final start = session.timeStart.isEmpty ? '--:--' : session.timeStart;
    final end = session.timeEnd;

    return TutorCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      borderColor: isNext ? AppColors.ink : null,
      onTap: () => context.go(AppRoutes.tutorSchedule),
      child: Row(
        children: [
          // Cột giờ: mốc neo mắt khi lướt danh sách nhiều buổi.
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(start, style: TutorType.numeral().copyWith(fontSize: 17)),
                if (end.isNotEmpty) Text(end, style: TutorType.caption()),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: AppColors.line,
            margin: const EdgeInsets.only(right: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.studentName,
                  style: TutorType.rowTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (session.subjectName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.subjectName,
                    style: TutorType.rowSub(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isNext)
            TutorStatusChip.attention('Sắp tới')
          else
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.ink4,
            ),
        ],
      ),
    );
  }
}

// ── Tiền ────────────────────────────────────────────────────────────────────

/// Khối tiền: một thẻ mực duy nhất trên màn — số dư rút được, kèm số đang giữ.
class _MoneySection extends ConsumerWidget {
  const _MoneySection({required this.data});

  final TutorDashboardDto? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(tutorWalletProvider);
    final available = wallet.value?.summary.availableBalance;
    final frozen =
        wallet.value?.summary.frozenBalance ?? data?.escrowBalance ?? 0;
    final holdSessions = data?.escrowSessions ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TutorSectionHeader(title: 'Ví của bạn'),
        Padding(
          padding: TutorSurface.screenPadding,
          child: TutorCard(
            color: AppColors.ink,
            borderColor: AppColors.ink,
            onTap: () => context.go(AppRoutes.tutorWallet),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư khả dụng',
                  style: TutorType.caption(
                    color: AppColors.cream.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                if (available == null)
                  const TutorSkeleton(height: 30, width: 160)
                else
                  Text(
                    fmtVnd(available.round()),
                    style: TutorType.numeralLarge(color: AppColors.cream),
                  ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: AppColors.cream.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InkStat(
                        label: 'Đang giữ tạm',
                        value: fmtVnd(frozen.round()),
                        sub: holdSessions > 0
                            ? '$holdSessions buổi chờ xác nhận'
                            : 'Chưa có buổi chờ',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.cream.withValues(alpha: 0.14),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _InkStat(
                        label: 'Thu nhập tháng',
                        value: data == null
                            ? '—'
                            : fmtVnd(data!.monthlyEarnings.round()),
                        sub: data == null
                            ? ''
                            : '${data!.completedSessions} buổi hoàn thành',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InkStat extends StatelessWidget {
  const _InkStat({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TutorType.caption(
            color: AppColors.cream.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: TutorType.numeral(color: AppColors.cream)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            style: TutorType.caption(
              color: AppColors.cream.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ── Tháng này ───────────────────────────────────────────────────────────────

/// Số liệu tham khảo — đặt cuối vì không đòi hành động nào.
class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.data});

  final TutorDashboardDto? data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TutorSectionHeader(title: 'Tổng quan'),
        Padding(
          padding: TutorSurface.screenPadding,
          child: TutorCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                TutorListRow(
                  dense: true,
                  leading: const _RowIcon(Icons.event_outlined),
                  title: 'Buổi sắp tới',
                  subtitle: 'Đã lên lịch, chưa diễn ra',
                  trailing: Text(
                    '${data?.upcomingSessions ?? 0}',
                    style: TutorType.numeral(),
                  ),
                  onTap: () => context.go(AppRoutes.tutorSchedule),
                ),
                const Divider(height: 1, color: AppColors.line, indent: 16),
                TutorListRow(
                  dense: true,
                  leading: const _RowIcon(Icons.star_outline_rounded),
                  title: 'Đánh giá trung bình',
                  subtitle: '${data?.totalReviews ?? 0} lượt đánh giá',
                  trailing: Text(
                    data == null || data!.totalReviews == 0
                        ? '—'
                        : data!.averageRating.toStringAsFixed(1),
                    style: TutorType.numeral(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      ),
      child: Icon(icon, size: 17, color: AppColors.ink2),
    );
  }
}

// ── Loading ─────────────────────────────────────────────────────────────────

/// Giữ đúng bố cục thật để nội dung không nhảy khi dữ liệu về.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: TutorSurface.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TutorSkeleton(height: 15, width: 110),
          SizedBox(height: 12),
          TutorSkeleton(height: 72, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.rowGap),
          TutorSkeleton(height: 72, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.sectionGap),
          TutorSkeleton(height: 15, width: 90),
          SizedBox(height: 12),
          TutorSkeleton(height: 150, radius: TutorSurface.radius),
        ],
      ),
    );
  }
}
