class PaymentInfoDto {
  const PaymentInfoDto({
    required this.bookingId,
    required this.amount,
    required this.checkoutUrl,
    required this.status,
    required this.paymentPhase,
    required this.depositAmount,
    required this.remainingAmount,
    required this.isDepositPaid,
    required this.isRemainingPaid,
    this.qrCode,
    this.paymentCode,
    this.expiredAt,
    this.bin,
    this.accountNumber,
    this.accountName,
    this.description,
  });

  factory PaymentInfoDto.fromJson(Map<String, dynamic> j) => PaymentInfoDto(
    bookingId: j['bookingId'] as int? ?? 0,
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    checkoutUrl: j['checkoutUrl'] as String? ?? '',
    status: j['status'] as String? ?? '',
    paymentPhase: j['paymentPhase'] as String? ?? 'deposit',
    depositAmount: (j['depositAmount'] as num?)?.toDouble() ?? 0,
    remainingAmount: (j['remainingAmount'] as num?)?.toDouble() ?? 0,
    isDepositPaid: j['isDepositPaid'] as bool? ?? false,
    isRemainingPaid: j['isRemainingPaid'] as bool? ?? false,
    qrCode: j['qrCode'] as String?,
    paymentCode: j['paymentCode'] as String?,
    expiredAt: j['expiredAt'] as String?,
    bin: j['bin'] as String?,
    accountNumber: j['accountNumber'] as String?,
    accountName: j['accountName'] as String?,
    description: j['description'] as String?,
  );

  final int bookingId;
  final double amount;
  final String checkoutUrl;
  final String status;

  /// "deposit" | "remaining"
  final String paymentPhase;
  final double depositAmount;
  final double remainingAmount;
  final bool isDepositPaid;
  final bool isRemainingPaid;
  final String? qrCode;
  final String? paymentCode;
  final String? expiredAt;
  final String? bin;
  final String? accountNumber;
  final String? accountName;
  final String? description;

  bool get hasCheckoutUrl => checkoutUrl.isNotEmpty;

  /// Ảnh VietQR dựng từ thông tin ngân hàng — hiện ngay trong app, giống web.
  String? get vietQrImageUrl {
    if (bin == null || accountNumber == null) return qrCode;
    final q = <String, String>{
      if (amount > 0) 'amount': amount.round().toString(),
      if (description?.isNotEmpty ?? false) 'addInfo': description!,
      if (accountName?.isNotEmpty ?? false) 'accountName': accountName!,
    };
    final query = Uri(queryParameters: q).query;
    return 'https://img.vietqr.io/image/$bin-$accountNumber-compact2.png?$query';
  }
}

/// Tóm tắt số tiền cho đợt đang phải trả + số dư ví, dùng để dựng màn chọn
/// phương thức mà chưa tạo link PayOS.
class PaymentSummaryDto {
  const PaymentSummaryDto({
    required this.bookingId,
    required this.amount,
    required this.paymentPhase,
    required this.totalAmount,
    required this.depositAmount,
    required this.remainingAmount,
    required this.walletBalance,
    required this.canPayWithWallet,
    required this.isDepositPaid,
    required this.isRemainingPaid,
  });

  factory PaymentSummaryDto.fromJson(Map<String, dynamic> j) =>
      PaymentSummaryDto(
        bookingId: j['bookingId'] as int? ?? 0,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paymentPhase: j['paymentPhase'] as String? ?? 'deposit',
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        depositAmount: (j['depositAmount'] as num?)?.toDouble() ?? 0,
        remainingAmount: (j['remainingAmount'] as num?)?.toDouble() ?? 0,
        walletBalance: (j['walletBalance'] as num?)?.toDouble() ?? 0,
        canPayWithWallet: j['canPayWithWallet'] as bool? ?? false,
        isDepositPaid: j['isDepositPaid'] as bool? ?? false,
        isRemainingPaid: j['isRemainingPaid'] as bool? ?? false,
      );

  final int bookingId;
  final double amount;

  /// "deposit" | "remaining"
  final String paymentPhase;
  final double totalAmount;
  final double depositAmount;
  final double remainingAmount;
  final double walletBalance;
  final bool canPayWithWallet;
  final bool isDepositPaid;
  final bool isRemainingPaid;
}

class PaymentStatusDto {
  const PaymentStatusDto({
    required this.bookingId,
    required this.status,
    required this.isPaid,
    required this.isDepositPaid,
    required this.isRemainingPaid,
    required this.isExpired,
    this.amountPaid = 0,
    this.amountRemaining = 0,
  });

  factory PaymentStatusDto.fromJson(Map<String, dynamic> j) => PaymentStatusDto(
    bookingId: j['bookingId'] as int? ?? 0,
    status: j['status'] as String? ?? '',
    isPaid: j['isPaid'] as bool? ?? false,
    isDepositPaid: j['isDepositPaid'] as bool? ?? false,
    isRemainingPaid: j['isRemainingPaid'] as bool? ?? false,
    isExpired: j['isExpired'] as bool? ?? false,
    amountPaid: (j['amountPaid'] as num?)?.toInt() ?? 0,
    amountRemaining: (j['amountRemaining'] as num?)?.toInt() ?? 0,
  );

  final int bookingId;
  final String status;
  final bool isPaid;
  final bool isDepositPaid;
  final bool isRemainingPaid;
  final bool isExpired;
  final int amountPaid;
  final int amountRemaining;

  /// Deposit phase settled — booking can proceed to lessons.
  bool get depositSettled => isDepositPaid || isPaid;
}
