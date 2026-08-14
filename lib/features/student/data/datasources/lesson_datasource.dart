import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/lesson_models.dart';
export 'package:tutora/features/student/data/models/lesson_models.dart'
    show LessonRecordingDto, RescheduleProposalDto;

class LessonDatasource {
  const LessonDatasource(this._dio);
  final Dio _dio;

  Future<StudentLessonPagedResult> getStudentLessons({
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
      '/student/class-sessions',
      queryParameters: params,
    );
    return StudentLessonPagedResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<StudentLessonDetailDto> getStudentLessonDetail(int lessonId) async {
    final response = await _dio.get<dynamic>(
      '/student/class-sessions/$lessonId',
    );
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>? ?? data;
    return StudentLessonDetailDto.fromJson(content);
  }

  Future<StudentLessonPagedResult> getStudentCalendarLessons({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get<dynamic>(
      '/student/class-sessions/calendar',
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
    final data = response.data as Map<String, dynamic>;
    final rawContent = data['content'];
    // Calendar endpoint returns a list of CalendarDay objects
    if (rawContent is List) {
      final lessons = <StudentLessonDto>[];
      for (final day in rawContent) {
        final dayMap = day as Map<String, dynamic>;
        final dayLessons = dayMap['classSessions'] as List<dynamic>? ?? [];
        lessons.addAll(
          dayLessons.map(
            (e) => StudentLessonDto.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      return StudentLessonPagedResult(
        items: lessons,
        totalCount: lessons.length,
      );
    }
    return StudentLessonPagedResult.fromJson(data);
  }

  /// GET /class-sessions/{id}/recording — trạng thái + link xem lại video.
  /// Trả null khi buổi chưa có bản ghi hoặc endpoint từ chối (404/403).
  Future<LessonRecordingDto?> getRecording(int lessonId) async {
    try {
      final res = await _dio.get<dynamic>(
        '/class-sessions/$lessonId/recording',
      );
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>? ?? data;
      return LessonRecordingDto.fromJson(content);
    } on DioException {
      return null;
    }
  }
}

final lessonDatasourceProvider = Provider<LessonDatasource>((ref) {
  return LessonDatasource(ref.read(apiClientProvider));
});
