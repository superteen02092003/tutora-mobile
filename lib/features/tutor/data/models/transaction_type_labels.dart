import 'package:intl/intl.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');

/// '1.250.000đ' — dùng thống nhất trong feature tài chính gia sư.
String fmtMoney(double v) => '${_vnd.format(v.round())}đ';

/// '+1.250.000đ' / '-500.000đ' — có dấu cho dòng giao dịch.
String fmtSignedMoney(double v) {
  final s = fmtMoney(v.abs());
  return v < 0 ? '-$s' : '+$s';
}

/// Nhãn tiếng Việt cho các loại giao dịch ví (khớp TransactionType backend).
String transactionTypeLabel(String type) => switch (type) {
  'EscrowRelease' => 'Giải ngân buổi học',
  'EscrowCredit' => 'Ghi có escrow',
  'EscrowReversal' => 'Hoàn escrow',
  'Withdrawal' => 'Rút tiền',
  'Refund' => 'Hoàn tiền',
  'Deposit' => 'Nạp tiền',
  'Payment' => 'Thanh toán',
  'DepositPayment' => 'Thanh toán đặt cọc',
  'RemainingPayment' => 'Thanh toán còn lại',
  'BankVerification' => 'Xác minh ngân hàng',
  _ => 'Giao dịch',
};

/// Nhãn tiếng Việt cho trạng thái yêu cầu rút tiền (khớp WithdrawalStatus).
String withdrawalStatusLabel(String status) => switch (status) {
  'pending' => 'Chờ xử lý',
  'pending_review' => 'Chờ duyệt',
  'approved' => 'Đã duyệt',
  'delayed' => 'Tạm hoãn',
  'completed' => 'Hoàn tất',
  'rejected' => 'Bị từ chối',
  'cancelled' => 'Đã hủy',
  _ => status,
};

/// Nhóm trạng thái để tô màu badge: 0 = đang xử lý, 1 = thành công, 2 = thất bại.
int withdrawalStatusTone(String status) => switch (status) {
  'completed' => 1,
  'rejected' || 'cancelled' => 2,
  _ => 0,
};
