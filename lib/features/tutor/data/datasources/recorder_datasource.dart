import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';

/// Danh bạ học sinh ngoài nền tảng + nhật ký buổi dạy (`/api/recorder/...`).
class RecorderDatasource {
  RecorderDatasource(this._dio);

  final Dio _dio;

  static dynamic _content(Response<Map<String, dynamic>> res) =>
      res.data?['content'];

  static List<Map<String, dynamic>> _list(dynamic c) =>
      (c is List ? c : const <dynamic>[]).whereType<Map<String, dynamic>>().toList();

  static Map<String, dynamic> _map(dynamic c) =>
      c is Map<String, dynamic> ? c : const <String, dynamic>{};

  // ── Học sinh ────────────────────────────────────────────────────────────

  Future<List<RecorderStudentDto>> students() async {
    final res = await _dio.get<Map<String, dynamic>>('/recorder/students');
    return _list(_content(res)).map(RecorderStudentDto.fromJson).toList();
  }

  Future<RecorderStudentDto> student(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/recorder/students/$id');
    return RecorderStudentDto.fromJson(_map(_content(res)));
  }

  Future<RecorderStudentDto> createStudent(RecorderStudentInput input) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recorder/students',
      data: input.toJson(),
    );
    return RecorderStudentDto.fromJson(_map(_content(res)));
  }

  Future<RecorderStudentDto> updateStudent(
    String id,
    RecorderStudentInput input,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/recorder/students/$id',
      data: input.toJson(),
    );
    return RecorderStudentDto.fromJson(_map(_content(res)));
  }

  Future<void> archiveStudent(String id) =>
      _dio.delete<void>('/recorder/students/$id');

  /// Tạo link mời phụ huynh liên kết Zalo (link cũ còn hạn bị thu hồi).
  Future<RecorderParentInviteDto> createParentInvite(String studentId) async {
    final res = await _dio.post<Map<String, dynamic>>('/recorder/students/$studentId/parent-invite');
    return RecorderParentInviteDto.fromJson(_map(_content(res)));
  }

  /// Gỡ liên kết Zalo của phụ huynh.
  Future<void> unlinkParent(String studentId) =>
      _dio.delete<void>('/recorder/students/$studentId/parent-link');

  // ── Buổi dạy ────────────────────────────────────────────────────────────

  Future<List<RecorderLessonDto>> lessons({
    DateTime? from,
    DateTime? to,
    String? studentId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/recorder/lessons',
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (studentId != null) 'studentId': studentId,
      },
    );
    return _list(_content(res)).map(RecorderLessonDto.fromJson).toList();
  }

  Future<RecorderLessonDto> createLesson({
    required String studentId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? subject,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recorder/lessons',
      data: {
        'studentId': studentId,
        'scheduledStart': scheduledStart?.toUtc().toIso8601String(),
        'scheduledEnd': scheduledEnd?.toUtc().toIso8601String(),
        'subject': subject,
      },
    );
    return RecorderLessonDto.fromJson(_map(_content(res)));
  }

  Future<void> deleteLesson(String id) =>
      _dio.delete<void>('/recorder/lessons/$id');
}

final recorderDatasourceProvider = Provider<RecorderDatasource>(
  (ref) => RecorderDatasource(ref.read(apiClientProvider)),
);
