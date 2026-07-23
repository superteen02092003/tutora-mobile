import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/parent/data/models/wallet_models.dart';

/// Ví của phụ huynh — GET /wallet/balance + /wallet/transactions
/// (role ParentOrStudentOrTutor). Envelope `content`.
class WalletDatasource {
  const WalletDatasource(this._dio);
  final Dio _dio;

  Future<WalletSummary> getWalletSummary() async {
    final balanceRes = await _dio.get<dynamic>('/wallet/balance');
    final txRes = await _dio.get<dynamic>(
      '/wallet/transactions',
      queryParameters: {'page': 1, 'pageSize': 20},
    );

    final balanceContent =
        (balanceRes.data as Map<String, dynamic>?)?['content']
            as Map<String, dynamic>? ??
        const {};
    final balance = WalletBalance.fromJson(balanceContent);

    final txContent =
        (txRes.data as Map<String, dynamic>?)?['content']
            as Map<String, dynamic>? ??
        const {};
    final txs = (txContent['transactions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WalletTransaction.fromJson)
        .toList();

    return WalletSummary(balance: balance, transactions: txs);
  }
}

final walletDatasourceProvider = Provider<WalletDatasource>((ref) {
  return WalletDatasource(ref.read(apiClientProvider));
});

/// Ví phụ huynh (số dư + lịch sử giao dịch), lấy từ API thật.
final parentWalletProvider = FutureProvider<WalletSummary>((ref) {
  return ref.read(walletDatasourceProvider).getWalletSummary();
});
