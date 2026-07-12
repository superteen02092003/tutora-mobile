import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/payment_models.dart';

class PaymentDatasource {
  const PaymentDatasource(this._dio);
  final Dio _dio;

  Future<PaymentInfoDto> getPaymentInfo(int bookingId) async {
    try {
      final res = await _dio.get<dynamic>('/bookings/$bookingId/payment');
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>? ?? data;
      return PaymentInfoDto.fromJson(content);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<PaymentStatusDto> getPaymentStatus(int bookingId) async {
    try {
      final res = await _dio.get<dynamic>(
        '/bookings/$bookingId/payment/status',
      );
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>? ?? data;
      return PaymentStatusDto.fromJson(content);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    final data = e.response?.data;
    String? msg;
    if (data is Map<String, dynamic>) {
      msg = data['message'] as String?;
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }
    return Exception(msg ?? 'Không thể tạo thanh toán, vui lòng thử lại.');
  }
}

final paymentDatasourceProvider = Provider<PaymentDatasource>((ref) {
  return PaymentDatasource(ref.read(apiClientProvider));
});
