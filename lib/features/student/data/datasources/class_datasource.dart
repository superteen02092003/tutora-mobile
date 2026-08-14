import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/class_models.dart';

/// Lớp học của học sinh
class ClassDatasource {
  const ClassDatasource(this._dio);
  final Dio _dio;

  /// GET /student/bookings
  Future<StudentClassPagedResult> getClasses({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/student/bookings',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return StudentClassPagedResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /student/class-sessions/upcoming — 1 buổi gần nhất, null nếu không có.
  Future<UpcomingSessionDto?> getNextSession() async {
    try {
      final res = await _dio.get<dynamic>('/student/class-sessions/upcoming');
      final data = res.data;
      final content = data is Map<String, dynamic> ? data['content'] : null;
      if (content is! Map<String, dynamic>) return null;
      return UpcomingSessionDto.fromJson(content);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /bookings/{id}
  Future<StudentClassDto> getClassDetail(int bookingId) async {
    try {
      final res = await _dio.get<dynamic>('/bookings/$bookingId');
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>? ?? data;
      return StudentClassDto.fromJson(content);
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
    return Exception(msg ?? 'Không tải được lớp học, vui lòng thử lại.');
  }
}

final classDatasourceProvider = Provider<ClassDatasource>((ref) {
  return ClassDatasource(ref.read(apiClientProvider));
});
