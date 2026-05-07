import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';

class BookingDatasource {
  const BookingDatasource(this._dio);
  final Dio _dio;

  Future<CreateBookingResponse> createBooking(CreateBookingRequest req) async {
    try {
      final response = await _dio.post<dynamic>(
        '/bookings',
        data: req.toJson(),
      );
      return CreateBookingResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<String?> getMyStudentProfileId() async {
    try {
      final response = await _dio.get<dynamic>(
        '/parent/students/my-link-status',
      );
      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>?;
      final profile = content?['studentProfile'] as Map<String, dynamic>?;
      return profile?['studentId'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<List<StudentSummaryDto>> getMyStudents() async {
    try {
      final response = await _dio.get<dynamic>('/Parent/students');
      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>? ?? [];
      return content
          .map((e) => StudentSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList();
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
    return Exception(msg ?? 'Có lỗi xảy ra, vui lòng thử lại.');
  }
}

final bookingDatasourceProvider = Provider<BookingDatasource>((ref) {
  return BookingDatasource(ref.read(apiClientProvider));
});
