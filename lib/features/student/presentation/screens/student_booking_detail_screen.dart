import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/datasources/booking_datasource.dart';
import 'package:tutora/features/student/presentation/providers/booking_detail_provider.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class StudentBookingDetailScreen extends ConsumerWidget {
  const StudentBookingDetailScreen({required this.bookingId, super.key});
  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingDetailProvider(bookingId));
    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.oxblood,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              const _NavBar(title: 'Chi tiết booking'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được booking',
                          style: AppTextStyles.label(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.toString(),
                          style: AppTextStyles.bodySmall(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        _PrimaryBtn(
                          label: 'Thử lại',
                          onTap: () =>
                              ref.invalidate(bookingDetailProvider(bookingId)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (b) => _DetailScaffold(booking: b),
    );
  }
}

// ── Scaffold ──────────────────────────────────────────────────────────────────

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.booking});
  final BookingDetailDto booking;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(title: booking.subjectName ?? 'Chi tiết booking'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomPad + 96),
                children: [
                  _StatusBanner(booking: booking),
                  _TutorCard(booking: booking),
                  _InfoCard(booking: booking),
                  _ScheduleCard(booking: booking),
                  _PaymentCard(booking: booking),
                  _TimelineCard(booking: booking),
                ],
              ),
            ),
            if (booking.canCancel)
              _BottomActions(booking: booking, bottomPad: bottomPad),
          ],
        ),
      ),
    );
  }
}

// Nav bar

class _NavBar extends StatelessWidget {
  const _NavBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSerif(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// Status banner

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.booking});
  final BookingDetailDto booking;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, text) = switch (booking.statusType) {
      BookingStatusType.pendingTutor => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.hourglass_top_rounded,
        'Đang chờ gia sư xác nhận',
      ),
      BookingStatusType.accepted => (
        const Color(0xFFDBEAFE),
        const Color(0xFF1E40AF),
        Icons.payments_outlined,
        'Gia sư đã xác nhận · Chờ đặt cọc',
      ),
      BookingStatusType.active => (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        Icons.play_circle_outline_rounded,
        'Đang trong quá trình học',
      ),
      BookingStatusType.completed => (
        AppColors.cream2,
        AppColors.moss,
        Icons.check_circle_outline_rounded,
        'Khoá học đã hoàn thành',
      ),
      BookingStatusType.cancelled => (
        const Color(0xFFFFE4E6),
        const Color(0xFF9F1239),
        Icons.cancel_outlined,
        'Booking đã bị hủy',
      ),
      BookingStatusType.paymentTimeout => (
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        Icons.timer_off_outlined,
        'Hết hạn thanh toán',
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          if (booking.paymentDueAt != null &&
              booking.statusType == BookingStatusType.accepted)
            Text(
              'Hạn: ${_fmtDate(booking.paymentDueAt!)}',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10.5,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}

// Tutor card

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.booking});
  final BookingDetailDto booking;

  static final _priceFmt = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: booking.tutorName ?? 'GS',
            size: 52,
            imageUrl: booking.tutorAvatarUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.tutorName ?? 'Gia sư',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                if (booking.tutorHourlyRate != null)
                  Text(
                    '${_priceFmt.format(booking.tutorHourlyRate!.toInt())} đ/giờ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.oxblood,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Icon(
                  booking.teachingMode == 'online'
                      ? Icons.videocam_outlined
                      : Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.ink3,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.teachingMode == 'online' ? 'Online' : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
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

// Info card

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.booking});
  final BookingDetailDto booking;

  static final _dtFmt = DateFormat('HH:mm · dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        icon: Icons.menu_book_rounded,
        label: 'Môn học',
        value: booking.subjectName ?? '—',
      ),
      (
        icon: Icons.layers_outlined,
        label: 'Số buổi',
        value: '${booking.sessionCount} buổi',
      ),
      (
        icon: Icons.calendar_today_outlined,
        label: 'Ngày bắt đầu',
        value: booking.startDate != null
            ? DateFormat('dd/MM/yyyy').format(
                DateTime.tryParse(booking.startDate!)?.toLocal() ??
                    DateTime.now(),
              )
            : '—',
      ),
      (
        icon: Icons.access_time_rounded,
        label: 'Ngày tạo',
        value: _dtFmt.format(booking.createdAtDt),
      ),
      if (booking.paymentCode != null)
        (
          icon: Icons.tag_rounded,
          label: 'Mã thanh toán',
          value: booking.paymentCode!,
        ),
    ];

    return _SectionCard(
      label: 'THÔNG TIN BOOKING',
      child: Column(
        children: rows.asMap().entries.map((e) {
          return Column(
            children: [
              if (e.key > 0)
                const Divider(height: 1, indent: 46, color: AppColors.line),
              _InfoRow(
                icon: e.value.icon,
                label: e.value.label,
                value: e.value.value,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Schedule card

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.booking});
  final BookingDetailDto booking;

  static const _days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  Widget build(BuildContext context) {
    if (booking.schedule.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      label: 'LỊCH HỌC',
      child: Column(
        children: booking.schedule.asMap().entries.map((e) {
          final s = e.value;
          final day = _days[s.dayOfWeek % 7];
          return Column(
            children: [
              if (e.key > 0)
                const Divider(height: 1, indent: 16, color: AppColors.line),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${s.startTime} — ${s.endTime}',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Payment card

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.booking});
  final BookingDetailDto booking;

  static final _fmt = NumberFormat('#,###', 'vi_VN');

  String _vnd(double v) => '${_fmt.format(v.toInt())} đ';

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      label: 'THANH TOÁN',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            _PayRow(label: 'Giá gốc khoá học', value: _vnd(booking.price)),
            if (booking.discountApplied > 0)
              _PayRow(
                label: 'Giảm giá',
                value: '−${_vnd(booking.discountApplied)}',
                valueColor: AppColors.green,
              ),
            _PayRow(label: 'Phí dịch vụ', value: _vnd(booking.platformFee)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.line),
            ),
            Row(
              children: [
                Text(
                  'Tổng thanh toán',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  _vnd(booking.finalPrice),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            if (booking.depositAmount != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 10),
              _PayRow(
                label: '→ Đặt cọc (50%)',
                value: _vnd(booking.depositAmount!),
                sub:
                    booking.depositAmount != null &&
                        booking.statusType == BookingStatusType.active
                    ? 'Đã thanh toán'
                    : null,
              ),
              if (booking.remainingAmount != null)
                _PayRow(
                  label: '→ Còn lại (50%)',
                  value: _vnd(booking.remainingAmount!),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.sub,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink3,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// Timeline card

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.booking});
  final BookingDetailDto booking;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(booking);
    return _SectionCard(
      label: 'TIẾN TRÌNH',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: steps.asMap().entries.map((e) {
            final step = e.value;
            final isLast = e.key == steps.length - 1;
            return _TimelineRow(step: step, isLast: isLast);
          }).toList(),
        ),
      ),
    );
  }

  List<_StepData> _buildSteps(BookingDetailDto b) {
    final idx = _statusIndex(b.statusType);
    return [
      _StepData(
        label: 'Tạo booking',
        state: _stepState(0, idx),
        sub: DateFormat('dd/MM HH:mm').format(b.createdAtDt),
      ),
      _StepData(label: 'Chờ gia sư', state: _stepState(1, idx)),
      _StepData(label: 'Gia sư xác nhận', state: _stepState(2, idx)),
      _StepData(label: 'Đặt cọc (50%)', state: _stepState(3, idx)),
      _StepData(label: 'Bắt đầu học', state: _stepState(4, idx)),
      _StepData(label: 'Hoàn thành', state: _stepState(5, idx)),
    ];
  }

  int _statusIndex(BookingStatusType t) => switch (t) {
    BookingStatusType.pendingTutor => 1,
    BookingStatusType.accepted => 2,
    BookingStatusType.active => 4,
    BookingStatusType.completed => 5,
    BookingStatusType.cancelled => -1,
    BookingStatusType.paymentTimeout => -1,
  };

  _StepState _stepState(int step, int currentIdx) {
    if (currentIdx == -1) return _StepState.idle;
    if (step < currentIdx) return _StepState.done;
    if (step == currentIdx) return _StepState.active;
    return _StepState.idle;
  }
}

enum _StepState { done, active, idle }

class _StepData {
  const _StepData({required this.label, required this.state, this.sub});
  final String label;
  final _StepState state;
  final String? sub;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});
  final _StepData step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (dotColor, dotBorder, dotIcon) = switch (step.state) {
      _StepState.done => (
        AppColors.moss,
        AppColors.moss,
        Icons.check_rounded,
      ),
      _StepState.active => (
        AppColors.paper,
        AppColors.oxblood,
        null,
      ),
      _StepState.idle => (
        AppColors.paper,
        AppColors.line,
        null,
      ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(color: dotBorder, width: 2),
                  ),
                  child: dotIcon != null
                      ? Icon(dotIcon, size: 11, color: AppColors.cream)
                      : step.state == _StepState.active
                      ? Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.oxblood,
                            ),
                          ),
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.state == _StepState.done
                          ? AppColors.moss
                          : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: step.state == _StepState.active
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: step.state == _StepState.idle
                        ? AppColors.ink4
                        : AppColors.ink,
                  ),
                ),
                if (step.sub != null)
                  Text(
                    step.sub!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.ink4,
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

// Bottom actions

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.booking,
    required this.bottomPad,
  });
  final BookingDetailDto booking;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: booking.statusType == BookingStatusType.accepted
          ? Row(
              children: [
                Expanded(
                  child: _OutlineBtn(
                    label: 'Hủy booking',
                    color: AppColors.oxblood,
                    onTap: () => _showCancelSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _PrimaryBtn(
                    label: 'Thanh toán đặt cọc',
                    onTap: () {},
                  ),
                ),
              ],
            )
          : _OutlineBtn(
              label: 'Hủy booking',
              color: AppColors.oxblood,
              onTap: () => _showCancelSheet(context),
            ),
    );
  }

  void _showCancelSheet(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hủy booking?',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc muốn hủy booking với ${booking.tutorName ?? 'gia sư'}?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.ink3,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E3CA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0D2A8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.oxblood,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hủy trước khi gia sư xác nhận — hoàn tiền 100% nếu đã cọc.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: _PrimaryBtn(
                  label: 'Xác nhận hủy',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _OutlineBtn(
                  label: 'Giữ nguyên',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shared primitives

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(label, style: AppTextStyles.eyebrow()),
          ),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.ink3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink4),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.cream,
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.onTap,
    this.color = AppColors.ink,
  });
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
