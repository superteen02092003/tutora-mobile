import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';

export 'package:tutora/features/parent/data/models/parent_models.dart';

class ParentDatasource {
  const ParentDatasource(this._dio);
  final Dio _dio;

  Future<List<ParentStudentDto>> getStudents() async {
    final res = await _dio.get<dynamic>('/parent/students');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ParentStudentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParentStudentDto> getStudent(String studentId) async {
    final res = await _dio.get<dynamic>('/parent/students/$studentId');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>? ?? data;
    return ParentStudentDto.fromJson(content);
  }

  Future<List<ParentLessonDto>> getPendingLessons() async {
    final res = await _dio.get<dynamic>('/parent/lessons/pending');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ParentLessonDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParentLessonDto>> getCalendarLessons({
    required String startDate,
    required String endDate,
  }) async {
    final res = await _dio.get<dynamic>(
      '/parent/lessons/calendar',
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ParentLessonDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmLesson(int lessonId) async {
    await _dio.put<dynamic>('/parent/lessons/$lessonId/confirm');
  }

  Future<List<GradeLevelDto>> getGradeLevels() async {
    final res = await _dio.get<dynamic>('/grade-levels');
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => GradeLevelDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddStudentResult> addStudent({
    required String fullname,
    required String birthdate,
    required String school,
    required int gradeLevelId,
    String? learninggoals,
  }) async {
    final res = await _dio.post<dynamic>(
      '/parent/students',
      data: {
        'fullname': fullname,
        'birthdate': birthdate,
        'school': school,
        'gradeLevelId': gradeLevelId,
        if (learninggoals != null && learninggoals.isNotEmpty)
          'learninggoals': learninggoals,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final content = data['content'] as Map<String, dynamic>;
    return AddStudentResult.fromJson(content);
  }

  Future<List<ParentBookingDto>> getBookings({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? studentId,
  }) async {
    final res = await _dio.get<dynamic>(
      '/parent/bookings',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
        if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final items =
        (data['content'] as Map<String, dynamic>?)?['items']
            as List<dynamic>? ??
        data['content'] as List<dynamic>? ??
        [];
    return items
        .map((e) => ParentBookingDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final parentDatasourceProvider = Provider<ParentDatasource>((ref) {
  return ParentDatasource(ref.watch(apiClientProvider));
});
