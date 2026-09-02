import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/models/tutor_dashboard_models.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_finance_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_bookings/tutor_booking_requests_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/booking_request_card.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/providers/notification_provider.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

/// Trang chủ gia sư.
class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  final _scrollController = ScrollController();

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
      ..invalidate(tutorBalanceProvider)
      ..invalidate(tutorBookingsProvider)
      ..invalidate(tutorWeekSessionsProvider)
      ..invalidate(awaitingReportProvider);
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
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: TutorColors.ink,
          child: ListView(
            controller: _scrollController,
            // Chừa chỗ cho thanh tab trong suốt, nếu không nội dung cuối bị che.
            padding: const EdgeInsets.only(bottom: kTutorNavTotalHeight + 16),
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
                // Tiền tháng này: câu trả lời cho thứ gia sư mở app ra để xem.
                _EarnedCard(data: data),
                const SizedBox(height: TutorSurface.rowGap),
                // Yêu cầu đặt lịch có hạn 24h → trên mọi việc khác.
                const _PendingBookingsSection(),
                _NextLessonCard(sessions: data?.todaySessions ?? const []),
                const SizedBox(height: TutorSurface.sectionGap),
                // Lịch tuần bám dưới buổi kế tiếp — cùng một mạch đọc.
                const _WeekScheduleSection(),
                const SizedBox(height: TutorSurface.sectionGap),
                _AwaitingReportCard(data: data),
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
                      style: TutorType.action(color: TutorColors.ink2),
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

class _EarnedCard extends ConsumerWidget {
  const _EarnedCard({required this.data});

  final TutorDashboardDto? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(tutorBalanceProvider).value;
    final frozen = wallet?.frozenBalance ?? data?.escrowBalance ?? 0;
    final available = wallet?.availableBalance;

    return Padding(
      padding: TutorSurface.screenPadding,
      child: TutorCard(
        color: TutorColors.heroInkBg,
        borderColor: TutorColors.heroInkBg,
        shadow: TutorColors.raisedCardShadow,
        backgroundImage: const DecorationImage(
          image: AssetImage('assets/images/common/backgroud_tutor.png'),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          opacity: 0.35,
        ),
        onTap: () => context.go(AppRoutes.tutorWallet),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TutorColors.surface,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 18,
                          color: TutorColors.heroInk,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doanh thu',
                            style: TutorType.rowTitle(),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Tháng này',
                            style: TutorType.caption(
                              color: TutorColors.ink2,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 9, 8),
                  decoration: BoxDecoration(
                    color: TutorColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem ví',
                        style: TutorType.action(color: TutorColors.heroInk),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: TutorColors.heroInk,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tạm giữ cho bạn',
              style: TutorType.caption(
                color: TutorColors.ink2,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              fmtVnd(frozen.round()),
              style: TutorType.numeralLarge(color: TutorColors.heroInk),
            ),
            const SizedBox(height: 4),
            Text(
              'Về ví sau khi buổi học được xác nhận',
              style: TutorType.caption(color: TutorColors.ink2),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TutorColors.surface,
                borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TutorColors.successBg,
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      size: 16,
                      color: TutorColors.success,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rút được ngay',
                          style: TutorType.caption(
                            color: TutorColors.ink2,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          available == null ? '—' : fmtVnd(available.round()),
                          style: TutorType.numeral(),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Số dư ví',
                    style: TutorType.caption(color: TutorColors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Buổi dạy gần nhất — tên học sinh là thứ to nhất, vì đó là cái cần nhớ.
class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.sessions});

  final List<TutorTodaySessionDto> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Padding(
        padding: TutorSurface.screenPadding,
        child: TutorCard(
          color: TutorColors.heroTealBg,
          borderColor: TutorColors.heroTealBg,
          shadow: TutorColors.raisedCardShadow,
          backgroundImage: const DecorationImage(
            image: AssetImage(
              'assets/images/common/backgroud_tutor_next.png',
            ),
            fit: BoxFit.cover,
            opacity: 0.35,
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/mascot/sample.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chưa có buổi nào sắp tới',
                      style: TutorType.rowTitle(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mở lịch dạy để xem lịch rảnh',
                      style: TutorType.rowSub(
                        color: TutorColors.ink2,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: TutorColors.ink4,
              ),
            ],
          ),
        ),
      );
    }

    final next = sessions.first;
    final day = _dayLabel(next.scheduledStart);
    final time = next.timeStart.isEmpty ? '--:--' : next.timeStart;

    return Padding(
      padding: TutorSurface.screenPadding,
      child: TutorCard(
        color: TutorColors.heroTealBg,
        borderColor: TutorColors.heroTealBg,
        shadow: TutorColors.raisedCardShadow,
        backgroundImage: const DecorationImage(
          image: AssetImage(
            'assets/images/common/backgroud_tutor_next.png',
          ),
          fit: BoxFit.cover,
          opacity: 0.35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chip môn nổi ở đầu thẻ — mẫu VN dùng nó làm "nhãn dán" nhận diện.
            Row(
              children: [
                if (next.subjectName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TutorColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 13,
                          color: TutorColors.surface,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          next.subjectName,
                          style: TutorType.action(color: TutorColors.surface),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  'Buổi kế tiếp',
                  style: TutorType.caption(
                    color: TutorColors.heroTeal,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TutorColors.surface,
                borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
              ),
              child: Row(
                children: [
                  TutorAvatar(name: next.studentName, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next.studentName,
                          style: TutorType.numeralLarge().copyWith(
                            fontSize: 22,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: TutorColors.heroTeal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$day · $time',
                              style: TutorType.rowSub(
                                color: TutorColors.ink2,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go(AppRoutes.tutorSchedule),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem lịch dạy',
                        style: TutorType.action(color: TutorColors.heroTeal),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: TutorColors.heroTeal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Hôm nay" / "Ngày mai" dễ đọc hơn ngày tháng khi buổi ở rất gần.
  static String _dayLabel(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final days = DateTime(
      dt.year,
      dt.month,
      dt.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Ngày mai';
    return '${dt.day}/${dt.month}';
  }
}

/// Buổi đã dạy xong mà chưa gửi báo cáo.
class _AwaitingReportCard extends ConsumerWidget {
  const _AwaitingReportCard({required this.data});

  final TutorDashboardDto? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dashboard là nguồn chính; quét lịch chỉ đỡ khi BE chưa có field này.
    final fromDash = data?.awaitingReport ?? 0;
    final scanned = ref.watch(awaitingReportProvider).value ?? const [];
    final count = fromDash > 0 ? fromDash : scanned.length;
    if (count == 0) return const SizedBox.shrink();

    final dashFirst = (data?.awaitingReportSessions ?? const []).firstOrNull;
    final firstName =
        dashFirst?.studentName ?? scanned.firstOrNull?.studentName;
    final firstSince =
        dashFirst?.sinceLabel ??
        (scanned.isEmpty ? null : _sinceLabel(scanned.first));

    return Padding(
      padding: TutorSurface.screenPadding,
      child: TutorCard(
        color: TutorStatusTone.pendingBg,
        borderColor: TutorStatusTone.pendingBorder,
        shadow: TutorColors.cardShadow,
        onTap: () => context.go(AppRoutes.tutorSchedule),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 15,
                        color: TutorStatusTone.pending,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Chờ gửi báo cáo',
                        style: TutorType.rowTitle(
                          color: TutorStatusTone.pending,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count == 1
                        ? '1 buổi cần báo cáo'
                        : '$count buổi cần báo cáo',
                    style: TutorType.numeral(
                      color: TutorStatusTone.pending,
                    ).copyWith(fontSize: 19),
                  ),
                  if (firstName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$firstName · ${firstSince ?? ''}',
                      style: TutorType.caption(color: TutorStatusTone.pending),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: TutorStatusTone.pending,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải 7 ngày của tuần hiện tại + buổi dạy của ngày đang chọn.
class _WeekScheduleSection extends ConsumerStatefulWidget {
  const _WeekScheduleSection();

  @override
  ConsumerState<_WeekScheduleSection> createState() =>
      _WeekScheduleSectionState();
}

class _WeekScheduleSectionState extends ConsumerState<_WeekScheduleSection> {
  late DateTime _selected = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tuần bắt đầu từ thứ hai — đúng cách người Việt đọc lịch.
  List<DateTime> get _week {
    final today = _dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<TutorWeekSessionDto> _sessionsOn(
    List<TutorWeekSessionDto> all,
    DateTime day,
  ) {
    // Xếp theo ngày BE đã gom (buổi học sớm/muộn nằm đúng ngày đã học)
    return all.where((s) => s.isActionable && s.dayKey == day).toList()
      ..sort((a, b) => a.timeStart.compareTo(b.timeStart));
  }

  @override
  Widget build(BuildContext context) {
    final week = _week;
    final today = _dateOnly(DateTime.now());
    final async = ref.watch(tutorWeekSessionsProvider);
    // .value ?? []: lịch tuần hỏng thì dải ngày vẫn hiện, không sập Home.
    final all = async.value ?? const <TutorWeekSessionDto>[];
    final daySessions = _sessionsOn(all, _selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TutorSectionHeader(
          title: 'Lịch tuần này',
          trailingLabel: 'Xem tất cả',
          onTrailingTap: () => context.go(AppRoutes.tutorSchedule),
        ),
        Padding(
          padding: TutorSurface.screenPadding,
          child: Column(
            children: [
              Row(
                children: [
                  for (final day in week)
                    Expanded(
                      child: _DayCell(
                        day: day,
                        selected: day == _selected,
                        isToday: day == today,
                        hasSessions: _sessionsOn(all, day).isNotEmpty,
                        onTap: () => setState(() => _selected = day),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TutorSurface.rowGap),
              if (async.hasError)
                TutorCard(
                  color: TutorStatusTone.attentionBg,
                  borderColor: TutorStatusTone.attentionBorder,
                  onTap: () => ref.invalidate(tutorWeekSessionsProvider),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 16,
                        color: TutorStatusTone.attention,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Không tải được lịch tuần. Chạm để thử lại.',
                          style: TutorType.rowSub(
                            color: TutorStatusTone.attention,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (daySessions.isEmpty)
                TutorCard(
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/mascot/sample.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selected == today
                              ? 'Hôm nay bạn rảnh.'
                              : 'Không có buổi nào ngày này.',
                          style: TutorType.rowSub(),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _Timeline(sessions: daySessions),
            ],
          ),
        ),
      ],
    );
  }
}

/// Một ô ngày trong dải tuần: thứ ở trên, số ngày ở dưới, chấm báo có buổi.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasSessions,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasSessions;
  final VoidCallback onTap;

  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final fg = selected ? TutorColors.surface : TutorColors.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? TutorColors.primary : TutorColors.surface,
          borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
          border: Border.all(
            color: selected
                ? TutorColors.primary
                : (isToday ? TutorColors.primary : TutorColors.line),
          ),
        ),
        child: Column(
          children: [
            Text(
              _labels[day.weekday - 1],
              style: TutorType.caption(
                color: selected ? TutorColors.surface : TutorColors.ink4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: TutorType.numeral(color: fg).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            // Chấm luôn chiếm chỗ để các ô không cao thấp lệch nhau.
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasSessions
                    ? (selected ? TutorColors.surface : TutorColors.accent)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline một ngày: trục giờ bên trái, buổi học đặt đúng mốc giờ của nó.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.sessions});

  final List<TutorWeekSessionDto> sessions;

  /// Chiều cao một mốc giờ.
  static const double _slotHeight = 62;

  /// Chiều cao thật của một thẻ buổi — dùng để chống chồng lấn.
  static const double _cardHeight = 58;
  static const double _railWidth = 46;

  @override
  Widget build(BuildContext context) {
    final withTime = sessions.where((s) => s.startLocal != null).toList();
    if (withTime.isEmpty) return const SizedBox.shrink();

    withTime.sort((a, b) => a.startLocal!.compareTo(b.startLocal!));

    final hours = withTime.map((s) => s.startLocal!.hour).toList();
    final startHour = hours.reduce((a, b) => a < b ? a : b);
    // +1 để buổi cuối còn một mốc trống bên dưới, không dính mép.
    final endHour = hours.reduce((a, b) => a > b ? a : b) + 1;
    final slots = endHour - startHour + 1;

    // Hai buổi cách nhau ít phút sẽ chồng thẻ lên nhau — đẩy xuống cho đủ chỗ.
    final tops = <double>[];
    for (final s in withTime) {
      final exact =
          ((s.startLocal!.hour - startHour) + s.startLocal!.minute / 60) *
          _slotHeight;
      final min = tops.isEmpty ? exact : tops.last + _cardHeight + 6;
      tops.add(exact > min ? exact : min);
    }

    final railHeight = slots * _slotHeight;
    final needed = tops.last + _cardHeight + 8;

    return SizedBox(
      height: railHeight > needed ? railHeight : needed,
      child: Stack(
        children: [
          // Lớp dưới: trục giờ + đường kẻ đứt.
          Column(
            children: [
              for (var h = startHour; h <= endHour; h++)
                SizedBox(
                  height: _slotHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _railWidth,
                        child: Transform.translate(
                          // Nhấc chữ lên để chân số thẳng hàng với đường kẻ.
                          offset: const Offset(0, -6),
                          child: Text(
                            '${h.toString().padLeft(2, '0')}:00',
                            style: TutorType.caption(),
                          ),
                        ),
                      ),
                      const Expanded(child: _DashedLine()),
                    ],
                  ),
                ),
            ],
          ),
          // Lớp trên: thẻ buổi học, đặt theo phút thật trong ngày.
          for (var i = 0; i < withTime.length; i++)
            Positioned(
              top: tops[i],
              left: _railWidth + 6,
              right: 0,
              child: _TimelineCard(session: withTime[i]),
            ),
        ],
      ),
    );
  }
}

/// Đường kẻ đứt ngang mốc giờ — vẽ bằng CustomPaint để nét đều mọi bề rộng.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 1,
    child: CustomPaint(painter: _DashPainter()),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TutorColors.line
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

/// Thẻ một buổi trên timeline — gọn, cao vừa một mốc giờ.
class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.session});

  final TutorWeekSessionDto session;

  @override
  Widget build(BuildContext context) {
    // Chỉ viền + vạch đổi màu; chữ luôn đen đậm để buổi đã qua vẫn đọc được.
    final (Color tone, String? chip) = switch (session) {
      _ when session.isCancelled => (TutorColors.danger, 'Đã huỷ'),
      _ when session.isContinuation && session.skipConfirmedByBothSides => (
        TutorColors.ink3,
        'Đã bỏ',
      ),
      _ when session.isInterrupted => (TutorColors.warning, 'Học dở dang'),
      _ when session.needsReport => (TutorColors.warning, 'Chờ báo cáo'),
      _ when session.isCompleted => (TutorColors.success, 'Hoàn thành'),
      _ when session.isLive => (TutorColors.accent, 'Đang dạy'),
      _ => (TutorColors.primary, null),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.tutorSchedule),
        borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 9, 10, 9),
          decoration: BoxDecoration(
            color: TutorColors.surface,
            borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
            border: Border.all(color: tone.withValues(alpha: 0.45)),
            boxShadow: TutorColors.cardShadow,
          ),
          child: Row(
            children: [
              // Vạch màu mép trái: neo mắt vào đúng mốc bắt đầu.
              Container(
                width: 3,
                height: 30,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.studentName,
                      style: TutorType.rowTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.subjectName.isEmpty
                          ? session.timeStart
                          : '${session.timeStart} · ${session.subjectName}',
                      style: TutorType.caption(color: TutorColors.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (chip != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    chip,
                    style: TutorType.caption(
                      color: tone,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                )
              else
                Icon(Icons.open_in_new_rounded, size: 15, color: tone),
            ],
          ),
        ),
      ),
    );
  }
}

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
                const Divider(height: 1, color: TutorColors.line, indent: 16),
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
                const Divider(height: 1, color: TutorColors.line, indent: 16),
                _DisputeRow(count: data?.activeDisputes ?? 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hàng tranh chấp trong Tổng quan.
class _DisputeRow extends StatelessWidget {
  const _DisputeRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    final tone = active ? TutorColors.danger : TutorColors.ink2;

    return TutorListRow(
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? TutorColors.dangerBg : TutorColors.surfaceSunken,
          borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
        ),
        child: Icon(Icons.gavel_rounded, size: 17, color: tone),
      ),
      title: 'Tranh chấp',
      subtitle: active
          ? 'Tiền buổi liên quan đang bị giữ'
          : 'Không có tranh chấp nào',
      trailing: Text(
        '$count',
        style: TutorType.numeral(
          color: active ? TutorColors.danger : TutorColors.ink,
        ),
      ),
      onTap: () => context.push(AppRoutes.tutorDisputes),
    );
  }
}

/// "3 giờ trước" — đo buổi kết thúc bao lâu rồi.
String _sinceLabel(TutorLessonDto l) {
  final ref = DateTime.tryParse(l.checkOutTime ?? '')?.toLocal() ?? l.startDt;
  if (ref == null) return '';
  final diff = DateTime.now().difference(ref);
  if (diff.inMinutes < 60) return 'vừa xong';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
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
        color: TutorColors.surfaceSunken,
        borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      ),
      child: Icon(icon, size: 17, color: TutorColors.ink2),
    );
  }
}

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
