import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_booking_models.dart';

/// Lỗi nghiệp vụ khi nhận/từ chối đặt lịch — mang message tiếng Việt từ BE
/// (ví dụ "Đã quá hạn phản hồi 24 giờ…") để hiển thị nguyên văn.
class TutorBookingException implements Exception {
  const TutorBookingException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 409 = booking hết hạn hoặc đã đổi trạng thái ở phía khác.
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

/// Yêu cầu đặt lịch phía gia sư — `/api/tutors/bookings`.
///
/// Lưu ý: route là `tutors` (số nhiều), khác nhóm `/tutor/*` của ví và buổi
/// học. Dễ gọi nhầm 404.
class TutorBookingDatasource {
  const TutorBookingDatasource(this._dio);

  final Dio _dio;

  static Map<String, dynamic> _content(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final c = data['content'];
      if (c is Map<String, dynamic>) return c;
    }
    return const {};
  }

  static Never _rethrowAsBusiness(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) {
        throw TutorBookingException(msg, statusCode: e.response?.statusCode);
      }
    }
    throw TutorBookingException(fallback, statusCode: e.response?.statusCode);
  }

  Future<TutorBookingPage> getBookingRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final res = await _dio.get<dynamic>(
      '/tutors/bookings',
      queryParameters: {'page': page, 'pageSize': pageSize, 'status': ?status},
    );
    return TutorBookingPage.fromJson(_content(res));
  }

  /// Nhận yêu cầu. Trả về `channelId` của kênh chat với phụ huynh — backend
  /// tạo/lấy kênh và gửi tin nhắn hệ thống ngay khi nhận.
  Future<int?> acceptBooking(int bookingId) async {
    try {
      final res = await _dio.post<dynamic>(
        '/tutors/bookings/$bookingId/accept',
      );
      return _content(res)['channelId'] as int?;
    } on DioException catch (e) {
      _rethrowAsBusiness(e, 'Không nhận được yêu cầu này.');
    }
  }

  /// Từ chối yêu cầu. Backend bắt buộc [reason] tối thiểu 10 ký tự.
  Future<void> declineBooking(int bookingId, String reason) async {
    try {
      await _dio.post<dynamic>(
        '/tutors/bookings/$bookingId/decline',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      _rethrowAsBusiness(e, 'Không từ chối được yêu cầu này.');
    }
  }
}

final Provider<TutorBookingDatasource> tutorBookingDatasourceProvider =
    Provider<TutorBookingDatasource>(
      (ref) => TutorBookingDatasource(ref.read(apiClientProvider)),
    );
