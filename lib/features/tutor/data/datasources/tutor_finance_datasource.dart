import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';

/// Lỗi nghiệp vụ ví/rút tiền — mang message tiếng Việt từ backend để UI hiển thị.
class TutorFinanceException implements Exception {
  const TutorFinanceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Gọi các endpoint tài chính gia sư dưới `/tutor/*` và `/banks`.
///
/// Mọi payload nằm trong envelope `{ content: ... }` (APIResponse của backend).
class TutorFinanceDatasource {
  const TutorFinanceDatasource(this._dio);

  final Dio _dio;

  static Map<String, dynamic> _content(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final c = data['content'];
      if (c is Map<String, dynamic>) return c;
    }
    return const {};
  }

  Future<TutorFinanceSummary> getSummary() async {
    final res = await _dio.get<dynamic>('/tutor/finance/summary');
    return TutorFinanceSummary.fromJson(_content(res));
  }

  Future<TutorTransactionPage> getTransactions({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutor/finance/transactions',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'type': ?type,
      },
    );
    return TutorTransactionPage.fromJson(_content(res));
  }

  Future<TutorBankInfo> getBankInfo() async {
    final res = await _dio.get<dynamic>('/bank-account');
    return TutorBankInfo.fromJson(_content(res));
  }

  Future<TutorBankInfo> updateBankInfo({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      final res = await _dio.put<dynamic>(
        '/bank-account',
        data: {
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
        },
      );
      return TutorBankInfo.fromJson(_content(res));
    } on DioException catch (e) {
      throw TutorFinanceException(_messageOf(e, 'Không lưu được tài khoản.'));
    }
  }

  Future<void> deleteBankInfo() async {
    try {
      await _dio.delete<dynamic>('/bank-account');
    } on DioException catch (e) {
      throw TutorFinanceException(_messageOf(e, 'Không xóa được tài khoản.'));
    }
  }

  Future<List<BankOption>> getBankList() async {
    final res = await _dio.get<dynamic>('/banks');
    final data = res.data;
    final list = data is Map<String, dynamic> ? data['content'] : null;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(BankOption.fromJson)
          .toList();
    }
    return const [];
  }

  Future<TutorWithdrawal> createWithdrawal(double amount) async {
    try {
      final res = await _dio.post<dynamic>(
        '/tutor/withdrawals',
        // Backend bỏ qua bank fields với tutor — luôn trả về TK đã lưu.
        data: {'amount': amount},
      );
      return TutorWithdrawal.fromJson(_content(res));
    } on DioException catch (e) {
      throw TutorFinanceException(
        _messageOf(e, 'Không tạo được yêu cầu rút tiền.'),
      );
    }
  }

  Future<TutorWithdrawalPage> getWithdrawals({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutor/withdrawals',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return TutorWithdrawalPage.fromJson(_content(res));
  }

  Future<TutorWithdrawal> getWithdrawalDetail(int id) async {
    final res = await _dio.get<dynamic>('/tutor/withdrawals/$id');
    return TutorWithdrawal.fromJson(_content(res));
  }

  static String _messageOf(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}

final tutorFinanceDatasourceProvider = Provider<TutorFinanceDatasource>(
  (ref) => TutorFinanceDatasource(ref.read(apiClientProvider)),
);
