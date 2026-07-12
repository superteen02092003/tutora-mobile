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

  bool get hasCheckoutUrl => checkoutUrl.isNotEmpty;
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
