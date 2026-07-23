import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';

class TutorLessonDatasource {
  const TutorLessonDatasource(this._dio);

  final Dio _dio;

  // GET /api/tutor/class-sessions
  Future<List<TutorLessonDto>> getLessons({
    String? status,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/class-sessions',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': status,
        // Backend nhận `fromDate` (không có `to`).
        'fromDate': from,
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

  // GET /api/tutor/class-sessions/calendar
  Future<List<TutorLessonDto>> getCalendar({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/class-sessions/calendar',
      // Backend nhận `startDate`/`endDate`.
      queryParameters: {'startDate': from, 'endDate': to},
    );
    // Backend trả CalendarDayResponse[] (mỗi ngày lồng danh sách buổi) →
    // gộp phẳng thành danh sách buổi học.
    final content = res.data?['content'];
    final days = content is List ? content : <dynamic>[];
    return days
        .whereType<Map<String, dynamic>>()
        .expand(
          (day) => (day['classSessions'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>(),
        )
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
