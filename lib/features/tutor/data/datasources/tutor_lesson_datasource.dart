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
    int? bookingId,
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
        'bookingId': bookingId,
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

  // GET /api/tutor/classes — danh sách lớp (booking), không phải buổi lẻ.
  Future<TutorClassPage> getClasses({
    int page = 1,
    int pageSize = 50,
    String? status,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/classes',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': ?status,
      },
    );
    final content = res.data?['content'];
    return TutorClassPage.fromJson(
      content is Map<String, dynamic> ? content : const {},
    );
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
    // BE trả buổi lồng theo ngày → gộp phẳng.
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
