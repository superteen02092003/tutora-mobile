import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/parent/data/datasources/parent_datasource.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_booking_widgets.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_page_header.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_payment_sheet.dart';
import 'package:tutora/shared/widgets/app_toast.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

final _date = DateFormat('dd/MM/yyyy');
final _dateTime = DateFormat('HH:mm · dd/MM/yyyy');
final _sessionDate = DateFormat('dd/MM');

/// Chi tiết một đơn đặt lịch: trạng thái, tiền, lịch, các buổi, và nút trả tiếp
/// nếu còn đợt chưa thanh toán.
class ParentBookingDetailScreen extends ConsumerStatefulWidget {
  const ParentBookingDetailScreen({required this.bookingId, super.key});

  final int bookingId;

  @override
  ConsumerState<ParentBookingDetailScreen> createState() =>
      _ParentBookingDetailScreenState();
}

class _ParentBookingDetailScreenState
    extends ConsumerState<ParentBookingDetailScreen> {
  bool _paying = false;

  Future<void> _pay(ParentBookingDto booking) async {
    setState(() => _paying = true);
    try {
      final ds = ref.read(parentDatasourceProvider);
      final info = await ds.getPaymentInfo(widget.bookingId);
      if (!mounted) return;

      final paid = await showParentPaymentSheet(
        context,
        info: info,
        onCheck: () async {
          final st = await ds.getPaymentStatus(widget.bookingId);
          return st.settledFor(deposit: info.isDeposit);
        },
      );
      if (!mounted) return;

      if (paid ?? false) {
        // Nạp lại cả chi tiết và mọi tab của danh sách — trạng thái đơn vừa đổi.
        ref
          ..invalidate(parentBookingDetailProvider(widget.bookingId))
          ..invalidate(parentAllBookingsProvider);
        AppToast.show(
          context,
          message: 'Đã ghi nhận thanh toán. Cảm ơn bạn!',
          type: AppToastType.success,
        );
      }
    } on ParentActionException catch (e) {
      if (!mounted) return;
      AppToast.show(context, message: e.message, type: AppToastType.error);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(parentBookingDetailProvider(widget.bookingId));
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ParentPageHeader(title: 'Chi tiết đơn đặt lịch'),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Không tải được chi tiết đơn.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (b) => ListView(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 24),
                  children: [
                    _StatusBanner(booking: b),
                    if (b.needsPayment) ...[
                      const SizedBox(height: 12),
                      _PayBox(
                        booking: b,
                        busy: _paying,
                        onPay: () => unawaited(_pay(b)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _TutorCard(booking: b),
                    const SizedBox(height: 12),
                    _InfoCard(booking: b),
                    const SizedBox(height: 12),
                    _MoneyCard(booking: b),
                    if (b.sessions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SessionsCard(booking: b),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải trạng thái đầu màn — nói bằng lời phụ huynh hiểu, không phải mã trạng thái.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.booking});

  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final st = parentBookingStatusStyle(b);
    final (icon, text) = switch (true) {
      _ when b.needsDeposit => (
        Icons.payments_outlined,
        'Cần thanh toán phí buổi học đầu để giữ lịch.',
      ),
      _ when b.isPendingTutor => (
        Icons.hourglass_top_rounded,
        'Đã trả phí buổi đầu, đang chờ gia sư nhận lớp.',
      ),
      _ when b.needsRemaining => (
        Icons.account_balance_wallet_outlined,
        'Cần thanh toán phần còn lại để con học tiếp các buổi sau.',
      ),
      _ when b.isLearning => (
        Icons.play_circle_outline_rounded,
        'Lớp đang diễn ra bình thường.',
      ),
      _ when b.isCompleted => (
        Icons.check_circle_outline_rounded,
        'Lớp đã hoàn thành.',
      ),
      _ when b.isClosed => (Icons.cancel_outlined, 'Đơn này đã kết thúc.'),
      _ => (Icons.info_outline_rounded, 'Đơn đang được xử lý.'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: st.fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: st.fg,
                  ),
                ),
              ),
            ],
          ),
          if (b.isClosed && (b.cancellationReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              'Lý do: ${b.cancellationReason}'
              '${b.cancelledBy == 'system' ? ' (hệ thống tự huỷ)' : ''}',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.4,
                color: st.fg,
              ),
            ),
          ],
          if ((b.refundStatus ?? '') == 'refunded' &&
              b.refundAmount != null) ...[
            const SizedBox(height: 6),
            Text(
              'Đã hoàn ${parentMoney(b.refundAmount!)} về ví.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: st.fg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Khối thanh toán nổi bật — phụ huynh vào màn này chủ yếu để trả tiếp.
class _PayBox extends StatelessWidget {
  const _PayBox({
    required this.booking,
    required this.busy,
    required this.onPay,
  });

  final ParentBookingDto booking;
  final bool busy;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final amount = b.amountDue;
    final due = b.dueAtDt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFF3D9BC), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b.needsDeposit ? 'Phí buổi học đầu' : 'Phần còn lại của lớp',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
          ),
          const SizedBox(height: 4),
          Text(
            amount == null ? '—' : parentMoney(amount),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (due != null) ...[
            const SizedBox(height: 6),
            Text(
              'Hạn thanh toán: ${_dateTime.format(due)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9A3412),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            b.needsDeposit
                ? 'Chưa trả trong thời hạn thì lịch đặt sẽ bị huỷ.'
                : 'Chưa trả thì các buổi sau chưa được mở.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: busy ? null : onPay,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: busy ? AppColors.ink3 : AppColors.oxblood,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                busy ? 'Đang xử lý…' : 'Thanh toán ngay',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.booking});

  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return _Card(
      child: Row(
        children: [
          UserAvatar(
            name: b.tutorName ?? 'GS',
            imageUrl: b.tutorAvatarUrl,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.tutorName ?? 'Gia sư',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (b.studentName?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Dạy cho ${b.studentName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.booking});

  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return _Card(
      label: 'Thông tin đơn',
      child: Column(
        children: [
          _Row(label: 'Môn học', value: b.subjectName ?? '—'),
          _Row(label: 'Số buổi', value: '${b.totalSessionCount} buổi'),
          if (b.startDateDt != null)
            _Row(label: 'Bắt đầu', value: _date.format(b.startDateDt!)),
          if (b.createdAtDt != null)
            _Row(label: 'Ngày đặt', value: _dateTime.format(b.createdAtDt!)),
          if (b.paymentCode?.isNotEmpty ?? false)
            _Row(label: 'Mã thanh toán', value: b.paymentCode!, wrap: true),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.booking});

  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return _Card(
      label: 'Thanh toán',
      child: Column(
        children: [
          if (b.totalAmount != null)
            _Row(label: 'Học phí', value: parentMoney(b.totalAmount!)),
          if ((b.discountApplied ?? 0) > 0)
            _Row(
              label: 'Giảm giá',
              value: '−${parentMoney(b.discountApplied!)}',
            ),
          if (b.finalPrice != null)
            _Row(
              label: 'Tổng cộng',
              value: parentMoney(b.finalPrice!),
              strong: true,
            ),
          const Divider(height: 20, color: AppColors.line),
          if (b.depositAmount != null)
            _Row(
              label: 'Đợt 1 · buổi đầu',
              value: parentMoney(b.depositAmount!),
              note: b.depositPaidAt != null ? 'Đã trả' : 'Chưa trả',
              notePaid: b.depositPaidAt != null,
            ),
          if (b.remainingAmount != null && b.remainingAmount! > 0)
            _Row(
              label: 'Đợt 2 · các buổi sau',
              value: parentMoney(b.remainingAmount!),
              note: b.remainingPaidAt != null ? 'Đã trả' : 'Chưa trả',
              notePaid: b.remainingPaidAt != null,
            ),
        ],
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.booking});

  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return _Card(
      label: 'Các buổi học (${b.doneSessions}/${b.totalSessionCount} đã học)',
      child: Column(
        children: [
          for (final s in b.sessions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${s.sessionIndex}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink4,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_sessionDate.format(s.startDt)} · '
                      '${DateFormat('HH:mm').format(s.startDt)}'
                      '–${DateFormat('HH:mm').format(s.endDt)}',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    s.isFinished
                        ? 'Đã học'
                        : s.isLocked
                        ? 'Chưa mở'
                        : 'Sắp tới',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: s.isFinished ? AppColors.green : AppColors.ink4,
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.strong = false,
    this.note,
    this.notePaid = false,
    this.wrap = false,
  });

  final String label;
  final String value;
  final bool strong;
  final String? note;
  final bool notePaid;

  /// Giá trị dài (mã thanh toán) được xuống dòng thay vì tràn ra ngoài.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn cố định bề ngang: giá trị dài (mã thanh toán) không được bóp
          // nhãn xuống thành nhiều dòng.
          SizedBox(
            width: 116,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: AppColors.ink3,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: notePaid ? AppColors.green : AppColors.oxblood,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: wrap ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: wrap ? 13.5 : (strong ? 16.5 : 15),
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                height: wrap ? 1.35 : null,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
