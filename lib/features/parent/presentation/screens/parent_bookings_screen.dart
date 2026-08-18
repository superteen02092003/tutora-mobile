import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/screens/parent_booking_detail_screen.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_booking_widgets.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_page_header.dart';

typedef _Tab = ({String key, String label});

const List<_Tab> _bookingTabs = [
  (key: '', label: 'Tất cả'),
  (key: 'pending_payment,accepted', label: 'Chờ trả đợt 1'),
  (key: 'pending_tutor', label: 'Chờ gia sư'),
  (key: 'deposit_paid,paid,ongoing', label: 'Đang học'),
  (key: 'pending_remaining_payment', label: 'Chờ trả đợt 2'),
  (key: 'completed', label: 'Hoàn thành'),
  (key: 'cancelled,cancelled_noshow,payment_timeout', label: 'Đã huỷ'),
];

class ParentBookingsPage extends ConsumerStatefulWidget {
  const ParentBookingsPage({super.key});

  @override
  ConsumerState<ParentBookingsPage> createState() => _ParentBookingsPageState();
}

class _ParentBookingsPageState extends ConsumerState<ParentBookingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _bookingTabs.length, vsync: this);
    _pages = PageController();
    // Trượt và bấm tab phải khớp nhau: mỗi bên tự đẩy bên còn lại.
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) {
        unawaited(
          _pages.animateToPage(
            _tabCtrl.index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ParentPageHeader(title: 'Lịch sử đặt lịch'),
            ColoredBox(
              color: AppColors.cream,
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.oxblood,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.ink4,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
                dividerColor: AppColors.line,
                tabs: [
                  for (final t in _bookingTabs) Tab(text: t.label, height: 44),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _bookingTabs.length,
                onPageChanged: (i) =>
                    _tabCtrl.animateTo(i, duration: Duration.zero),
                itemBuilder: (_, i) =>
                    _BookingList(statusKey: _bookingTabs[i].key),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Danh sách đơn của một tab. Giữ state khi trượt qua tab khác.
class _BookingList extends ConsumerStatefulWidget {
  const _BookingList({required this.statusKey});

  final String statusKey;

  @override
  ConsumerState<_BookingList> createState() => _BookingListState();
}

class _BookingListState extends ConsumerState<_BookingList>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  String? get _status => widget.statusKey.isEmpty ? null : widget.statusKey;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(
      Future.microtask(
        () => ref.read(parentAllBookingsProvider(_status).notifier).load(),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      unawaited(
        ref.read(parentAllBookingsProvider(_status).notifier).loadMore(),
      );
    }
  }

  void _open(ParentBookingDto booking) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              ParentBookingDetailScreen(bookingId: booking.bookingId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(parentAllBookingsProvider(_status));
    final notifier = ref.read(parentAllBookingsProvider(_status).notifier);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (state.isLoading && state.bookings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.oxblood,
          strokeWidth: 2,
        ),
      );
    }

    if (state.error != null && state.bookings.isEmpty) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        title: 'Không tải được danh sách',
        message: state.error!,
        actionLabel: 'Thử lại',
        onAction: () => unawaited(notifier.load()),
      );
    }

    if (state.bookings.isEmpty) {
      return RefreshIndicator(
        color: AppColors.oxblood,
        backgroundColor: AppColors.paper,
        onRefresh: notifier.load,
        child: ListView(
          children: [
            _Message(
              icon: Icons.receipt_long_outlined,
              title: _emptyTitle(widget.statusKey),
              message: 'Kéo xuống để tải lại.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.oxblood,
      backgroundColor: AppColors.paper,
      onRefresh: notifier.load,
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + AppSpacing.xxl),
        itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.bookings.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.oxblood,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final b = state.bookings[i];
          return _BookingCard(
            booking: b,
            onTap: () => _open(b),
            onPay: () => _open(b),
          );
        },
      ),
    );
  }

  static String _emptyTitle(String key) => switch (key) {
    'pending_payment,accepted' => 'Không có đơn nào chờ trả phí buổi đầu',
    'pending_tutor' => 'Không có đơn nào chờ gia sư nhận',
    'deposit_paid,paid,ongoing' => 'Chưa có lớp nào đang học',
    'pending_remaining_payment' => 'Không có đơn nào cần trả nốt',
    'completed' => 'Chưa có lớp nào hoàn thành',
    'cancelled,cancelled_noshow,payment_timeout' => 'Không có đơn nào đã huỷ',
    _ => 'Bạn chưa đặt lịch học nào',
  };
}

final _priceFmt = NumberFormat('#,###', 'vi_VN');
final _dateFmt = DateFormat('dd/MM/yyyy');

/// Card một đơn đặt lịch. Đơn còn phải trả tiền thì có thêm dải nhắc + nút trả.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onPay,
  });

  final ParentBookingDto booking;
  final VoidCallback onTap;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.subjectName ?? 'Lớp #${b.bookingId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if (b.studentName?.isNotEmpty ?? false)
                                    b.studentName!,
                                  if (b.tutorName?.isNotEmpty ?? false)
                                    'GS ${b.tutorName}',
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ParentBookingStatusPill(booking: b),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${b.totalSessionCount} buổi'
                            '${b.createdAtDt != null ? ' · đặt ${_dateFmt.format(b.createdAtDt!)}' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AppColors.ink4,
                            ),
                          ),
                        ),
                        if (b.finalPrice != null)
                          Text(
                            '${_priceFmt.format(b.finalPrice!.round())}đ',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (b.needsPayment) ParentPayCta(booking: b, onPay: onPay),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.ink4),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.ink3,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
