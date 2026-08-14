import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
export 'package:tutora/features/student/data/models/booking_models.dart'
    show
        BookingDetailDto,
        BookingStatusType,
        ScheduleSlotDto,
        StudentBookingDto,
        StudentBookingPagedResult;

class BookingDatasource {
  const BookingDatasource(this._dio);
  final Dio _dio;

  /// Buổi gia sư đã nhận trong khoảng [start, end] — trả về giờ LOCAL.
  Future<List<({DateTime start, DateTime end})>> getTutorBookedSlots(
    String tutorId, {
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/bookings/tutor/$tutorId/booked-slots',
        queryParameters: {
          'startDate': start.toUtc().toIso8601String(),
          'endDate': end.toUtc().toIso8601String(),
        },
      );
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>? ?? const [];
      return content
          .map((e) {
            final m = e as Map<String, dynamic>;
            final s = DateTime.tryParse(m['scheduledStart'] as String? ?? '');
            final t = DateTime.tryParse(m['scheduledEnd'] as String? ?? '');
            if (s == null || t == null || !t.isAfter(s)) return null;
            return (start: s.toLocal(), end: t.toLocal());
          })
          .whereType<({DateTime start, DateTime end})>()
          .toList();
    } on DioException {
      // Không chặn được thì để BE trả 409 lúc submit, đừng khoá hết lịch.
      return const [];
    }
  }

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

  /// DELETE /api/bookings/{id} — huỷ đơn chưa hoàn tất.
  Future<void> cancelBooking(int bookingId, {String? reason}) async {
    try {
      await _dio.delete<dynamic>(
        '/bookings/$bookingId',
        queryParameters: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<String?> getMyStudentProfileId() async {
    try {
      final response = await _dio.get<dynamic>(
        '/students/link-status',
      );
      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>?;
      final profile = content?['studentProfile'] as Map<String, dynamic>?;
      return profile?['studentId'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<BookingDetailDto> getBookingDetail(int bookingId) async {
    final response = await _dio.get<dynamic>('/bookings/$bookingId');
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>? ?? data;
    return BookingDetailDto.fromJson(content);
  }

  Future<StudentBookingPagedResult> getStudentBookings({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await _dio.get<dynamic>(
      '/student/bookings',
      queryParameters: params,
    );
    return StudentBookingPagedResult.fromJson(
      response.data as Map<String, dynamic>,
    );
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
