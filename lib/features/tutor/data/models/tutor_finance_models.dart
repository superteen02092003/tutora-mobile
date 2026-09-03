import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';

/// GET /api/tutor/finance/summary
class TutorFinanceSummary {
  const TutorFinanceSummary({
    required this.availableBalance,
    required this.frozenBalance,
    required this.totalBalance,
    required this.totalEarned,
    required this.pendingSettlement,
    required this.hasActiveDispute,
    required this.disputedAmount,
    this.lastWithdrawalAt,
  });

  factory TutorFinanceSummary.fromJson(Map<String, dynamic> j) =>
      TutorFinanceSummary(
        availableBalance: (j['availableBalance'] as num?)?.toDouble() ?? 0,
        frozenBalance: (j['frozenBalance'] as num?)?.toDouble() ?? 0,
        totalBalance: (j['totalBalance'] as num?)?.toDouble() ?? 0,
        totalEarned: (j['totalEarned'] as num?)?.toDouble() ?? 0,
        pendingSettlement: (j['pendingSettlement'] as num?)?.toDouble() ?? 0,
        hasActiveDispute: j['hasActiveDispute'] as bool? ?? false,
        disputedAmount: (j['disputedAmount'] as num?)?.toDouble() ?? 0,
        lastWithdrawalAt: _dt(j['lastWithdrawalAt']),
      );

  /// Số dư khả dụng — có thể rút.
  final double availableBalance;

  /// Escrow đang bị giữ (buổi học chưa hoàn tất).
  final double frozenBalance;
  final double totalBalance;

  /// Tổng thu nhập thật (chỉ tính EscrowRelease).
  final double totalEarned;

  /// Tiền của các buổi đã hoàn tất nhưng chưa giải ngân.
  final double pendingSettlement;

  /// Đang có tranh chấp chưa đóng — phần tiền liên quan bị giữ lại.
  final bool hasActiveDispute;

  /// Số tiền đang bị giữ vì tranh chấp, nằm trong [frozenBalance].
  final double disputedAmount;
  final DateTime? lastWithdrawalAt;
}

/// GET /api/bank-account
class TutorBankInfo {
  const TutorBankInfo({
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.bankChangedAt,
  });

  factory TutorBankInfo.fromJson(Map<String, dynamic> j) => TutorBankInfo(
    bankName: j['bankName'] as String?,
    accountNumber: j['accountNumber'] as String?,
    accountHolderName: j['accountHolderName'] as String?,
    bankChangedAt: _dt(j['bankChangedAt']),
  );

  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final DateTime? bankChangedAt;

  /// Backend chỉ giải ngân về TK đã lưu; rút tiền yêu cầu đủ 3 trường này.
  bool get isComplete =>
      (bankName?.isNotEmpty ?? false) &&
      (accountNumber?.isNotEmpty ?? false) &&
      (accountHolderName?.isNotEmpty ?? false);

  /// 4 số cuối, dùng hiển thị gọn.
  String get maskedAccount {
    final n = accountNumber ?? '';
    if (n.length <= 4) return n;
    return '•••• ${n.substring(n.length - 4)}';
  }
}

/// Một dòng trong danh sách ngân hàng (GET /api/banks).
class BankOption {
  const BankOption({
    required this.code,
    required this.shortName,
    required this.fullName,
    this.logoUrl,
    this.bin,
  });

  factory BankOption.fromJson(Map<String, dynamic> j) => BankOption(
    code: j['code'] as String? ?? '',
    shortName: j['shortName'] as String? ?? '',
    fullName: j['fullName'] as String? ?? '',
    logoUrl: j['logoUrl'] as String?,
    bin: j['bin'] as String?,
  );

  final String code;
  final String shortName;
  final String fullName;
  final String? logoUrl;
  final String? bin;
}

/// GET /api/tutor/finance/transactions (một dòng)
class TutorTransaction {
  const TutorTransaction({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdAt,
    this.referenceId,
    this.referenceTable,
    this.providerTransactionId,
    this.paidAt,
    this.proofImageUrl,
  });

  factory TutorTransaction.fromJson(Map<String, dynamic> j) => TutorTransaction(
    transactionId: j['transactionId'] as int? ?? 0,
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    transactionType: j['transactionType'] as String? ?? '',
    description: j['description'] as String? ?? '',
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal(),
    referenceId: j['referenceId'] as int?,
    referenceTable: j['referenceTable'] as String?,
    providerTransactionId: j['providerTransactionId'] as String?,
    paidAt: DateTime.tryParse(j['paidAt'] as String? ?? '')?.toLocal(),
    proofImageUrl: j['proofImageUrl'] as String?,
  );

  final int transactionId;
  final double amount;

  /// EscrowRelease | Withdrawal | Refund | ... (xem TransactionType backend).
  final String transactionType;
  final String description;
  final DateTime? createdAt;
  final int? referenceId;
  final String? referenceTable;
  final String? providerTransactionId;
  final DateTime? paidAt;
  final String? proofImageUrl;

  /// Tiền vào ví (thu nhập/hoàn) so với tiền ra (rút).
  bool get isCredit => amount >= 0;

  /// Nhãn tiếng Việt gọn cho loại giao dịch.
  String get typeLabel => transactionTypeLabel(transactionType);
}

class TutorTransactionPage {
  const TutorTransactionPage({
    required this.transactions,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory TutorTransactionPage.fromJson(Map<String, dynamic> j) =>
      TutorTransactionPage(
        transactions: (j['transactions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TutorTransaction.fromJson)
            .toList(),
        totalCount: j['totalCount'] as int? ?? 0,
        page: j['page'] as int? ?? 1,
        pageSize: j['pageSize'] as int? ?? 20,
      );

  final List<TutorTransaction> transactions;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;
}

/// GET/POST /api/tutor/withdrawals (chi tiết)
class TutorWithdrawal {
  const TutorWithdrawal({
    required this.withdrawalId,
    required this.amount,
    required this.status,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.requestedAt,
    this.processedAt,
    this.claimedAt,
    this.completionNote,
    this.rejectionReason,
    this.transactionId,
    this.bankTransactionCode,
    this.paidAt,
    this.proofImageUrl,
  });

  factory TutorWithdrawal.fromJson(Map<String, dynamic> j) => TutorWithdrawal(
    withdrawalId: j['withdrawalId'] as int? ?? 0,
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    status: j['status'] as String? ?? '',
    bankName: j['bankName'] as String?,
    accountNumber: j['accountNumber'] as String?,
    accountHolderName: j['accountHolderName'] as String?,
    requestedAt: _dt(j['requestedAt']),
    processedAt: _dt(j['processedAt']),
    claimedAt: _dt(j['claimedAt']),
    completionNote: j['completionNote'] as String?,
    rejectionReason: j['rejectionReason'] as String?,
    transactionId: j['transactionId'] as String?,
    bankTransactionCode: j['bankTransactionCode'] as String?,
    paidAt: _dt(j['paidAt']),
    proofImageUrl: j['proofImageUrl'] as String?,
  );

  final int withdrawalId;
  final double amount;

  /// pending | pending_review | approved | delayed | completed | rejected | cancelled
  final String status;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final DateTime? requestedAt;
  final DateTime? processedAt;

  /// Giờ nhân viên nhận xử lý yêu cầu.
  final DateTime? claimedAt;
  final String? completionNote;
  final String? rejectionReason;
  final String? transactionId;

  /// Mã giao dịch phía ngân hàng, hiện trên biên lai.
  final String? bankTransactionCode;

  /// "Vietcombank · 1028712322", hoặc null khi BE không trả thông tin.
  String? get bankLine {
    final parts = [
      bankName,
      accountNumber,
    ].where((e) => e != null && e.trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  final DateTime? paidAt;
  final String? proofImageUrl;
}

class TutorWithdrawalPage {
  const TutorWithdrawalPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory TutorWithdrawalPage.fromJson(Map<String, dynamic> j) =>
      TutorWithdrawalPage(
        items: (j['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TutorWithdrawal.fromJson)
            .toList(),
        total: j['total'] as int? ?? 0,
        page: j['page'] as int? ?? 1,
        pageSize: j['pageSize'] as int? ?? 20,
      );

  final List<TutorWithdrawal> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;
}

DateTime? _dt(dynamic v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;
