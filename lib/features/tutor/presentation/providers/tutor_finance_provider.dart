import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';

/// Tất cả dữ liệu cần cho màn Ví: số dư, TK ngân hàng, và trang giao dịch đầu.
class TutorWalletData {
  const TutorWalletData({
    required this.summary,
    required this.bank,
    required this.transactions,
  });

  final TutorFinanceSummary summary;
  final TutorBankInfo bank;
  final TutorTransactionPage transactions;
}

/// Màn Ví — gộp 3 lời gọi song song.
final AutoDisposeFutureProvider<TutorWalletData> tutorWalletProvider =
    FutureProvider.autoDispose<TutorWalletData>((ref) async {
      final ds = ref.read(tutorFinanceDatasourceProvider);
      final results = await Future.wait([
        ds.getSummary(),
        ds.getBankInfo(),
        ds.getTransactions(pageSize: 8),
      ]);
      return TutorWalletData(
        summary: results[0] as TutorFinanceSummary,
        bank: results[1] as TutorBankInfo,
        transactions: results[2] as TutorTransactionPage,
      );
    });

/// Chỉ TK ngân hàng — dùng ở màn quản lý TK.
final AutoDisposeFutureProvider<TutorBankInfo> tutorBankInfoProvider =
    FutureProvider.autoDispose<TutorBankInfo>((ref) {
      return ref.read(tutorFinanceDatasourceProvider).getBankInfo();
    });

/// Danh sách ngân hàng để chọn (cache lâu — ít đổi).
final FutureProvider<List<BankOption>> bankListProvider =
    FutureProvider<List<BankOption>>((ref) {
      return ref.read(tutorFinanceDatasourceProvider).getBankList();
    });

/// Lịch sử rút tiền (trang đầu).
final AutoDisposeFutureProvider<TutorWithdrawalPage> tutorWithdrawalsProvider =
    FutureProvider.autoDispose<TutorWithdrawalPage>((ref) {
      return ref.read(tutorFinanceDatasourceProvider).getWithdrawals();
    });
