import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/lesson_models.dart';

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
      '/student/lessons',
      queryParameters: params,
    );
    return StudentLessonPagedResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<StudentLessonDetailDto> getStudentLessonDetail(int lessonId) async {
    final response = await _dio.get<dynamic>('/studentlesson/$lessonId');
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>? ?? data;
    return StudentLessonDetailDto.fromJson(content);
  }

  Future<StudentLessonPagedResult> getStudentCalendarLessons({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get<dynamic>(
      '/studentlesson/calendar',
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
    final data = response.data as Map<String, dynamic>;
    final rawContent = data['content'];
    // Calendar endpoint returns a list of CalendarDay objects
    if (rawContent is List) {
      final lessons = <StudentLessonDto>[];
      for (final day in rawContent) {
        final dayMap = day as Map<String, dynamic>;
        final dayLessons = dayMap['lessons'] as List<dynamic>? ?? [];
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
}

final lessonDatasourceProvider = Provider<LessonDatasource>((ref) {
  return LessonDatasource(ref.read(apiClientProvider));
});
