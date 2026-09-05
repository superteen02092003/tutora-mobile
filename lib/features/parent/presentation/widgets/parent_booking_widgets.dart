import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';

final _money = NumberFormat('#,###', 'vi_VN');
final _dueFmt = DateFormat('HH:mm dd/MM');

String parentMoney(double v) => '${_money.format(v.round())}đ';

/// Nhãn + màu cho mọi trạng thái booking của BE. Phủ đủ 11 giá trị để không có
/// đơn nào rơi vào "Không rõ".
({String label, Color bg, Color fg}) parentBookingStatusStyle(
  ParentBookingDto b,
) {
  final s = (b.status ?? '').toLowerCase();
  return switch (s) {
    'pending_payment' || 'accepted' => (
      label: 'Chờ trả phí buổi đầu',
      bg: const Color(0xFFFEF3C7),
      fg: const Color(0xFF92400E),
    ),
    'pending_tutor' => (
      label: 'Chờ gia sư nhận',
      bg: const Color(0xFFDBEAFE),
      fg: const Color(0xFF1E40AF),
    ),
    'deposit_paid' || 'paid' || 'ongoing' => (
      label: 'Đang học',
      bg: const Color(0xFFD1FAE5),
      fg: const Color(0xFF065F46),
    ),
    'pending_remaining_payment' => (
      label: 'Cần trả nốt',
      bg: const Color(0xFFFFEDD5),
      fg: const Color(0xFF9A3412),
    ),
    'completed' || 'closed' => (
      label: 'Hoàn thành',
      bg: AppColors.cream2,
      fg: AppColors.ink3,
    ),
    'cancelled' ||
    'cancelled_noshow' ||
    'cancelled_by_staff' ||
    'cancelled_by_dispute' ||
    'refunded' => (
      label: 'Đã huỷ',
      bg: const Color(0xFFFFE4E6),
      fg: const Color(0xFF9F1239),
    ),
    'payment_timeout' => (
      label: 'Hết hạn thanh toán',
      bg: const Color(0xFFF3F4F6),
      fg: const Color(0xFF6B7280),
    ),
    _ => (label: 'Đang xử lý', bg: AppColors.cream2, fg: AppColors.ink3),
  };
}

class ParentBookingStatusPill extends StatelessWidget {
  const ParentBookingStatusPill({required this.booking, super.key});

  final ParentBookingDto booking;

  @override
  Widget build(BuildContext context) {
    final st = parentBookingStatusStyle(booking);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        st.label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: st.fg,
        ),
      ),
    );
  }
}

/// Dải nhắc trả tiền dưới card/đầu màn chi tiết: nói rõ đợt nào, bao nhiêu, hạn
/// khi nào, kèm nút đi tiếp.
class ParentPayCta extends StatelessWidget {
  const ParentPayCta({
    required this.booking,
    required this.onPay,
    this.label = 'Thanh toán',
    super.key,
  });

  final ParentBookingDto booking;
  final VoidCallback onPay;
  final String label;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final amount = b.amountDue;
    final due = b.dueAtDt;
    final phase = b.needsDeposit ? 'phí buổi học đầu' : 'phần còn lại';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        border: Border(top: BorderSide(color: Color(0xFFF3D9BC))),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount == null
                      ? 'Cần thanh toán $phase'
                      : 'Cần trả $phase: ${parentMoney(amount)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                if (due != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Trước ${_dueFmt.format(due)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onPay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.oxblood,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
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
