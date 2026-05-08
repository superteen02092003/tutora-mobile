import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';

class TutorLessonDatasource {
  const TutorLessonDatasource(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  Future<String> _getTutorId() async {
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token không hợp lệ');
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final map = json.decode(payload) as Map<String, dynamic>;
    final id =
        map['userId'] as String? ??
        map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
            as String?;
    if (id == null) throw Exception('Không tìm thấy user');
    return id;
  }

  // GET /api/tutorlesson/lessons
  Future<List<TutorLessonDto>> getLessons({
    String? status,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutorlesson/lessons',
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

  // GET /api/tutorlesson/calendar
  Future<List<TutorLessonDto>> getCalendar({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutorlesson/calendar',
      queryParameters: {'from': from, 'to': to},
    );
    final content = res.data?['content'];
    final raw = content is List ? content : <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TutorLessonDto.fromJson)
        .toList();
  }

  // GET /api/tutor/availability/{tutorId}
  Future<List<TutorAvailabilityDto>> getAvailability() async {
    final tutorId = await _getTutorId();
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutor/availability/$tutorId',
    );
    final content = res.data?['content'];
    final raw = content is List ? content : <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TutorAvailabilityDto.fromJson)
        .toList();
  }

  // POST /api/tutor/availability/{tutorId}
  Future<void> createAvailability(CreateAvailabilityRequest request) async {
    final tutorId = await _getTutorId();
    await _dio.post<void>(
      '/tutor/availability/$tutorId',
      data: request.toJson(),
    );
  }

  // DELETE /api/tutor/availability/{tutorId}/{availabilityId}
  Future<void> deleteAvailability(int availabilityId) async {
    final tutorId = await _getTutorId();
    await _dio.delete<void>(
      '/tutor/availability/$tutorId/$availabilityId',
    );
  }
}

final tutorLessonDatasourceProvider = Provider<TutorLessonDatasource>(
  (ref) => TutorLessonDatasource(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  ),
);
