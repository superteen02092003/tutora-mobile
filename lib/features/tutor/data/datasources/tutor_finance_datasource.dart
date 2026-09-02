import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';

/// Lỗi nghiệp vụ ví/rút tiền — mang message tiếng Việt từ backend để UI hiển thị.
class TutorFinanceException implements Exception {
  const TutorFinanceException(this.message, {this.errorCode});
  final String message;

  /// Mã lỗi BE trả kèm, ví dụ OTP_COOLDOWN_ACTIVE.
  final String? errorCode;
  @override
  String toString() => message;
}

/// Endpoint tài chính gia sư; payload nằm trong envelope `{ content: ... }`.
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
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutor/finance/transactions',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'type': ?type,
        'from': ?from?.toUtc().toIso8601String(),
        'to': ?to?.toUtc().toIso8601String(),
      },
    );
    return TutorTransactionPage.fromJson(_content(res));
  }

  Future<TutorTransaction> getTransactionDetail(int transactionId) async {
    final res = await _dio.get<dynamic>(
      '/tutor/finance/transactions/$transactionId',
    );
    return TutorTransaction.fromJson(_content(res));
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
      throw TutorFinanceException(
        _messageOf(e, 'Không lưu được tài khoản.'),
        errorCode: _codeOf(e),
      );
    }
  }

  /// Gửi OTP về SĐT gia sư; BE bắt buộc xác thực trước khi lưu/xoá TK.
  Future<void> sendBankOtp() async {
    try {
      await _dio.post<dynamic>('/bank-account/otp/send');
    } on DioException catch (e) {
      throw TutorFinanceException(
        _messageOf(e, 'Không gửi được mã OTP.'),
        errorCode: _codeOf(e),
      );
    }
  }

  /// Xác thực OTP; phê duyệt sống 15 phút, đủ cho một lần lưu.
  Future<void> verifyBankOtp(String code) async {
    try {
      await _dio.post<dynamic>(
        '/bank-account/otp/verify',
        data: {'code': code},
      );
    } on DioException catch (e) {
      throw TutorFinanceException(
        _messageOf(e, 'Mã OTP không đúng.'),
        errorCode: _codeOf(e),
      );
    }
  }

  /// Số giây phải chờ trước khi gửi lại, BE trả kèm OTP_COOLDOWN_ACTIVE.
  static int? retryAfterOf(DioException e) {
    final d = e.response?.data;
    return d is Map && d['retryAfterSeconds'] is num
        ? (d['retryAfterSeconds'] as num).toInt()
        : null;
  }

  static String? _codeOf(DioException e) {
    final d = e.response?.data;
    return d is Map ? d['errorCode'] as String? : null;
  }

  Future<void> deleteBankInfo() async {
    try {
      await _dio.delete<dynamic>('/bank-account');
    } on DioException catch (e) {
      throw TutorFinanceException(
        _messageOf(e, 'Không xóa được tài khoản.'),
        errorCode: _codeOf(e),
      );
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

  /// Huỷ yêu cầu rút tiền còn đang chờ xử lý
  Future<void> cancelWithdrawal(int id) async {
    try {
      await _dio.delete<dynamic>('/tutor/withdrawals/$id');
    } on DioException catch (e) {
      throw TutorFinanceException(
        _messageOf(e, 'Không huỷ được yêu cầu rút tiền.'),
        errorCode: _codeOf(e),
      );
    }
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
