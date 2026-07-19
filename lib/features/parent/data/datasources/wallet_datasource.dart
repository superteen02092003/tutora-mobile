import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/parent/data/models/wallet_models.dart';

/// Wallet data for the parent account.
///
/// NOTE: currently returns MOCK data so the UI can be reviewed. The real
/// endpoints are wired but commented out — GET /wallet/balance and
/// GET /wallet/transactions (both allowed for the Parent role). Swap
/// `_mock*` for the live calls once the backend data is seeded.
class WalletDatasource {
  const WalletDatasource(this._dio);
  // Used by the live wiring (commented out below) once data is seeded.
  // ignore: unused_field
  final Dio _dio;

  Future<WalletSummary> getWalletSummary() async {
    // --- Live wiring (enable when backend data is ready) ---
    // final balanceRes = await _dio.get<dynamic>('/wallet/balance');
    // final txRes = await _dio.get<dynamic>('/wallet/transactions',
    //     queryParameters: {'page': 1, 'pageSize': 20});
    // final balance = WalletBalance.fromJson(
    //   (balanceRes.data as Map<String, dynamic>)['content']
    //       as Map<String, dynamic>,
    // );
    // final txContent = (txRes.data as Map<String, dynamic>)['content']
    //     as Map<String, dynamic>;
    // final txs = (txContent['transactions'] as List<dynamic>? ?? [])
    //     .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
    //     .toList();
    // return WalletSummary(balance: balance, transactions: txs);

    return _mockSummary();
  }

  WalletSummary _mockSummary() {
    const balance = WalletBalance(
      balance: 1250000,
      availableBalance: 1250000,
      frozenBalance: 630000,
      totalBalance: 1880000,
    );

    // Relative day offsets keep the mock deterministic without Date.now here;
    // createdAt is a plain ISO string the UI parses to local time.
    final txs = <WalletTransaction>[
      const WalletTransaction(
        transactionId: 1042,
        amount: 2000000,
        transactionType: 'Deposit',
        description: 'Nạp tiền vào ví qua PayOS',
        createdAt: '2026-07-05T09:12:00Z',
      ),
      const WalletTransaction(
        transactionId: 1051,
        amount: -105000,
        transactionType: 'DepositPayment',
        description: 'Thanh toán buổi học đầu · Toán · Trần Minh Công',
        createdAt: '2026-07-06T02:30:00Z',
        referenceId: 121,
        referenceTable: 'bookings',
      ),
      const WalletTransaction(
        transactionId: 1067,
        amount: -630000,
        transactionType: 'Payment',
        description: 'Giữ escrow gói học · Tiếng Anh · Đào Mỹ Linh',
        createdAt: '2026-07-08T04:00:00Z',
        referenceId: 122,
        referenceTable: 'bookings',
      ),
      const WalletTransaction(
        transactionId: 1080,
        amount: 105000,
        transactionType: 'Refund',
        description: 'Hoàn tiền buổi học bị hủy · Vật Lý',
        createdAt: '2026-07-09T07:45:00Z',
        referenceId: 123,
        referenceTable: 'bookings',
      ),
      const WalletTransaction(
        transactionId: 1091,
        amount: -120000,
        transactionType: 'RemainingPayment',
        description: 'Thanh toán các buổi còn lại · Toán',
        createdAt: '2026-07-10T01:15:00Z',
        referenceId: 121,
        referenceTable: 'bookings',
      ),
    ];

    return WalletSummary(balance: balance, transactions: txs);
  }
}

final walletDatasourceProvider = Provider<WalletDatasource>((ref) {
  return WalletDatasource(ref.read(apiClientProvider));
});

/// Wallet summary for the parent account (mock-backed for now).
final parentWalletProvider = FutureProvider<WalletSummary>((ref) {
  return ref.read(walletDatasourceProvider).getWalletSummary();
});
