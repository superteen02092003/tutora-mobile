import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';

class TutorLessonDatasource {
  const TutorLessonDatasource(this._dio);

  final Dio _dio;

  // GET /api/tutor/lessons
  Future<List<TutorLessonDto>> getLessons({
    String? status,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/lessons',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': status,
        'from': from,
        'to': to,
      }..removeWhere((_, v) => v == null),
    );
    final content = res.data?['content'];
    final raw = content is List
        ? content
        : (content as Map<String, dynamic>?)?['items'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TutorLessonDto.fromJson)
        .toList();
  }

  // GET /api/tutor/lessons/calendar
  Future<List<TutorLessonDto>> getCalendar({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/lessons/calendar',
      queryParameters: {'from': from, 'to': to},
    );
    final content = res.data?['content'];
    final raw = content is List ? content : <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TutorLessonDto.fromJson)
        .toList();
  }

  // GET /api/tutor/availabilities
  Future<List<TutorAvailabilityDto>> getAvailability() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/availabilities',
    );
    final content = res.data?['content'];
    final raw = content is List ? content : <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TutorAvailabilityDto.fromJson)
        .toList();
  }

  // POST /api/tutor/availabilities
  Future<void> createAvailability(CreateAvailabilityRequest request) async {
    await _dio.post<void>(
      '/tutor/availabilities',
      data: request.toJson(),
    );
  }

  // DELETE /api/tutor/availabilities/{id}
  Future<void> deleteAvailability(int availabilityId) async {
    await _dio.delete<void>(
      '/tutor/availabilities/$availabilityId',
    );
  }
}

final tutorLessonDatasourceProvider = Provider<TutorLessonDatasource>(
  (ref) => TutorLessonDatasource(ref.read(apiClientProvider)),
);
