class WalletBalance {
  const WalletBalance({
    required this.balance,
    required this.availableBalance,
    required this.frozenBalance,
    required this.totalBalance,
    this.lastUpdated,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> j) => WalletBalance(
    balance: (j['balance'] as num?)?.toDouble() ?? 0,
    availableBalance: (j['availableBalance'] as num?)?.toDouble() ?? 0,
    frozenBalance: (j['frozenBalance'] as num?)?.toDouble() ?? 0,
    totalBalance: (j['totalBalance'] as num?)?.toDouble() ?? 0,
    lastUpdated: j['lastUpdated'] as String?,
  );

  /// Spendable balance.
  final double balance;
  final double availableBalance;

  /// Held in escrow for active bookings.
  final double frozenBalance;
  final double totalBalance;
  final String? lastUpdated;
}

class WalletTransaction {
  const WalletTransaction({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdAt,
    this.referenceId,
    this.referenceTable,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> j) =>
      WalletTransaction(
        transactionId: j['transactionId'] as int? ?? 0,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        transactionType: j['transactionType'] as String? ?? '',
        description: j['description'] as String? ?? '',
        createdAt: j['createdAt'] as String? ?? '',
        referenceId: j['referenceId'] as int?,
        referenceTable: j['referenceTable'] as String?,
      );

  final int transactionId;
  final double amount;

  /// One of: Deposit, Payment, EscrowCredit, EscrowRelease, Withdrawal,
  /// Refund, DepositPayment, RemainingPayment, BankVerification.
  final String transactionType;
  final String description;
  final String createdAt;
  final int? referenceId;
  final String? referenceTable;

  DateTime get createdAtDt =>
      DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();

  /// Money coming into the wallet (top-up / refund) vs going out (payment).
  bool get isCredit => const {
    'Deposit',
    'Refund',
    'EscrowRelease',
  }.contains(transactionType);
}

class WalletSummary {
  const WalletSummary({required this.balance, required this.transactions});

  final WalletBalance balance;
  final List<WalletTransaction> transactions;
}
