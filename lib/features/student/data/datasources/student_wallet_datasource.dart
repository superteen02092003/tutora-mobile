import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';

/// Ví học sinh — dùng chung endpoint /wallet với phụ huynh
/// (role ParentOrStudentOrTutor). Envelope `content`.
class StudentWalletDatasource {
  const StudentWalletDatasource(this._dio);

  final Dio _dio;

  Future<StudentWalletSummary> getSummary() async {
    final balanceRes = await _dio.get<dynamic>('/wallet/balance');
    final txRes = await _dio.get<dynamic>(
      '/wallet/transactions',
      queryParameters: {'page': 1, 'pageSize': 30},
    );

    final b =
        (balanceRes.data as Map<String, dynamic>?)?['content']
            as Map<String, dynamic>? ??
        const {};
    final txContent =
        (txRes.data as Map<String, dynamic>?)?['content']
            as Map<String, dynamic>? ??
        const {};

    final txs = (txContent['transactions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(StudentWalletTx.fromJson)
        .toList();

    return StudentWalletSummary(
      balance: (b['balance'] as num?)?.toDouble() ?? 0,
      availableBalance: (b['availableBalance'] as num?)?.toDouble() ?? 0,
      frozenBalance: (b['frozenBalance'] as num?)?.toDouble() ?? 0,
      totalBalance: (b['totalBalance'] as num?)?.toDouble() ?? 0,
      transactions: txs,
    );
  }
}

class StudentWalletSummary {
  const StudentWalletSummary({
    required this.balance,
    required this.availableBalance,
    required this.frozenBalance,
    required this.totalBalance,
    required this.transactions,
  });

  final double balance;
  final double availableBalance;

  /// Escrow đang bị giữ.
  final double frozenBalance;
  final double totalBalance;
  final List<StudentWalletTx> transactions;
}

class StudentWalletTx {
  const StudentWalletTx({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdAt,
  });

  factory StudentWalletTx.fromJson(Map<String, dynamic> j) => StudentWalletTx(
    transactionId: j['transactionId'] as int? ?? 0,
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    transactionType: j['transactionType'] as String? ?? '',
    description: j['description'] as String? ?? '',
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal(),
  );

  final int transactionId;
  final double amount;
  final String transactionType;
  final String description;
  final DateTime? createdAt;

  bool get isCredit => amount >= 0;
}

final studentWalletDatasourceProvider = Provider<StudentWalletDatasource>((
  ref,
) {
  return StudentWalletDatasource(ref.read(apiClientProvider));
});

final AutoDisposeFutureProvider<StudentWalletSummary> studentWalletProvider =
    FutureProvider.autoDispose<StudentWalletSummary>((ref) {
      return ref.read(studentWalletDatasourceProvider).getSummary();
    });
