import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';

class ClassSessionDatasource {
  const ClassSessionDatasource(this._dio);
  final Dio _dio;

  Future<void> confirmClassSession(int classSessionId) async {
    try {
      await _dio.put<dynamic>(
        '/student/class-sessions/$classSessionId/confirm',
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /student/class-sessions/{id}/reschedule-proposal — học sinh tự quản lý
  /// đề xuất dời buổi sang giờ khác. Học sinh do phụ huynh quản lý sẽ bị BE từ
  /// chối (403) vì quyền thuộc về phụ huynh.
  Future<void> proposeReschedule({
    required int classSessionId,
    required DateTime proposedStart,
    String? reason,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/student/class-sessions/$classSessionId/reschedule-proposal',
        data: {
          'proposedScheduledStart': proposedStart.toUtc().toIso8601String(),
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /student/class-sessions/{id}/reschedule-proposal/respond —
  /// đồng ý / từ chối đề xuất đổi lịch do gia sư gửi.
  Future<void> respondToReschedule({
    required int classSessionId,
    required bool accepted,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/student/class-sessions/$classSessionId/reschedule-proposal/respond',
        data: {'accepted': accepted},
      );
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

final classSessionDatasourceProvider = Provider<ClassSessionDatasource>((ref) {
  return ClassSessionDatasource(ref.read(apiClientProvider));
});
