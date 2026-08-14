import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/datasources/booking_datasource.dart';
import 'package:tutora/features/student/presentation/providers/booking_list_provider.dart';
import 'package:tutora/features/student/presentation/providers/student_access_provider.dart';

typedef _TabItem = ({String key, String label});

// Khớp tab bên web; BE nhận nhiều status ngăn cách bằng dấu phẩy.
const _tabs = <_TabItem>[
  (key: '', label: 'Tất cả'),
  (key: 'pending_payment,accepted', label: 'Chờ trả phí buổi đầu'),
  (key: 'pending_tutor', label: 'Chờ gia sư'),
  (key: 'deposit_paid', label: 'Đã trả phí buổi đầu'),
  (key: 'ongoing,paid', label: 'Đang học'),
  (key: 'pending_remaining_payment', label: 'Trả nốt'),
  (key: 'completed', label: 'Hoàn thành'),
  (key: 'cancelled,cancelled_noshow,payment_timeout', label: 'Đã huỷ'),
];

typedef _StatusStyle = ({Color bg, Color fg, String label});

_StatusStyle _statusStyle(BookingStatusType t) => switch (t) {
  BookingStatusType.pendingDeposit => (
    bg: const Color(0xFFFEF3C7),
    fg: const Color(0xFF92400E),
    label: 'Chờ trả phí buổi đầu',
  ),
  BookingStatusType.pendingTutor => (
    bg: const Color(0xFFDBEAFE),
    fg: const Color(0xFF1E40AF),
    label: 'Chờ gia sư nhận',
  ),
  BookingStatusType.depositPaid => (
    bg: const Color(0xFFE0E7FF),
    fg: const Color(0xFF3730A3),
    label: 'Đã trả phí buổi đầu',
  ),
  BookingStatusType.active => (
    bg: const Color(0xFFD1FAE5),
    fg: const Color(0xFF065F46),
    label: 'Đang học',
  ),
  BookingStatusType.pendingRemaining => (
    bg: const Color(0xFFFFEDD5),
    fg: const Color(0xFF9A3412),
    label: 'Cần trả nốt',
  ),
  BookingStatusType.completed => (
    bg: AppColors.cream2,
    fg: AppColors.ink3,
    label: 'Hoàn thành',
  ),
  BookingStatusType.cancelled => (
    bg: const Color(0xFFFFE4E6),
    fg: const Color(0xFF9F1239),
    label: 'Đã huỷ',
  ),
  BookingStatusType.paymentTimeout => (
    bg: const Color(0xFFF3F4F6),
    fg: const Color(0xFF6B7280),
    label: 'Hết hạn thanh toán',
  ),
};

class StudentBookingScreen extends ConsumerStatefulWidget {
  const StudentBookingScreen({super.key});

  @override
  ConsumerState<StudentBookingScreen> createState() =>
      _StudentBookingScreenState();
}

class _StudentBookingScreenState extends ConsumerState<StudentBookingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      unawaited(
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    _tabController.animateTo(i, duration: Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isParentManagedProvider)) {
      return const _ParentManagedNotice();
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar(),
            ColoredBox(
              color: AppColors.paper,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.ink,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.ink4,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                dividerColor: AppColors.line,
                tabs: _tabs.map((t) => Tab(text: t.label, height: 42)).toList(),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _tabs.length,
                itemBuilder: (_, i) =>
                    _BookingPageView(statusKey: _tabs[i].key),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn thay thế cho tài khoản học sinh do phụ huynh quản lý
class _ParentManagedNotice extends StatelessWidget {
  const _ParentManagedNotice();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/common/empty_mesages.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bố mẹ đặt lịch giúp con',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tài khoản của con do bố mẹ quản lý. Sau khi tìm được gia sư '
                        'mình thích rồi chia sẻ cho bố mẹ đặt lịch nhé.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.ink4,
                        ),
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
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lịch đặt của tôi',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2(),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}

class _BookingPageView extends ConsumerStatefulWidget {
  const _BookingPageView({required this.statusKey});
  final String statusKey;

  @override
  ConsumerState<_BookingPageView> createState() => _BookingPageViewState();
}

class _BookingPageViewState extends ConsumerState<_BookingPageView>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(
      Future.microtask(
        () => ref
            .read(bookingListProvider(widget.statusKey).notifier)
            .load(reset: true),
      ),
    );
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      unawaited(
        ref.read(bookingListProvider(widget.statusKey).notifier).nextPage(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(bookingListProvider(widget.statusKey));
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.oxblood,
          strokeWidth: 2,
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(bookingListProvider(widget.statusKey).notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return _EmptyView(statusKey: widget.statusKey);
    }

    return ListView.separated(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + AppSpacing.xxl),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.oxblood,
                strokeWidth: 2,
              ),
            ),
          );
        }
        return _BookingCard(
          booking: state.items[i],
          onTap: () => context.push(
            '/student/bookings/${state.items[i].bookingId}',
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});
  final StudentBookingDto booking;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _priceFmt = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    final st = _statusStyle(booking.statusType);
    final isDone =
        booking.statusType == BookingStatusType.completed ||
        booking.statusType == BookingStatusType.cancelled ||
        booking.statusType == BookingStatusType.paymentTimeout;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDone ? 0.72 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.subjectName ?? 'Lịch đặt #',
                      style: GoogleFonts.ibmPlexSerif(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.tutorName ?? 'Gia sư',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: st.bg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            st.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: st.fg,
                            ),
                          ),
                        ),
                        if (booking.sessionCount != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${booking.sessionCount} buổi',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.ink4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_priceFmt.format(booking.finalPrice.toInt())}đ',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateFmt.format(booking.createdAtDt),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _emptyLabel(String statusKey) => switch (statusKey) {
  'pending_tutor' => 'Bạn không có đặt lịch đang chờ gia sư',
  'accepted' => 'Bạn không có đặt lịch đang chờ thanh toán',
  'active' => 'Bạn không có lớp học nào đang diễn ra',
  'completed' => 'Bạn chưa có lớp học nào hoàn thành',
  'cancelled' => 'Bạn không có đặt lịch nào đã hủy',
  _ => 'Bạn chưa có lịch đặt nào',
};

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.statusKey});
  final String statusKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/common/empty_mesages.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            _emptyLabel(statusKey),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Không tải được danh sách',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cream,
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
