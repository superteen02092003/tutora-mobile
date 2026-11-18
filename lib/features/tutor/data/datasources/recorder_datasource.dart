import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';

/// Danh bạ học sinh ngoài nền tảng + nhật ký buổi dạy (`/api/recorder/...`).
class RecorderDatasource {
  RecorderDatasource(this._dio);

  final Dio _dio;

  static dynamic _content(Response<Map<String, dynamic>> res) =>
      res.data?['content'];

  static List<Map<String, dynamic>> _list(dynamic c) =>
      (c is List ? c : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

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

  /// Xoá VĨNH VIỄN học sinh và toàn bộ dữ liệu (ghi âm, báo cáo, đồng ý).
  /// Không khôi phục được.
  Future<void> deleteStudentPermanently(String id) =>
      _dio.delete<void>('/recorder/students/$id');

  /// Tạo link mời phụ huynh liên kết Zalo (link cũ còn hạn bị thu hồi).
  Future<RecorderParentInviteDto> createParentInvite(String studentId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recorder/students/$studentId/parent-invite',
    );
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
        'studentId': ?studentId,
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

  /// Huỷ buổi (chỉ buổi `scheduled`). Giữ cho code cũ; xem [cancelLesson].
  Future<void> deleteLesson(String id, {String? reason}) =>
      cancelLesson(id, reason: reason);

  /// DELETE /recorder/lessons/{id}?reason=cancelled|pupil_absent|other —
  /// huỷ buổi `scheduled`, lưu lý do ([RecorderCancelReason]).
  Future<void> cancelLesson(String lessonId, {String? reason}) =>
      _dio.delete<void>(
        '/recorder/lessons/$lessonId',
        queryParameters: {'reason': ?reason},
      );

  /// PUT /recorder/lessons/{id}/attendance — điểm danh buổi đã qua / đã bắt
  /// đầu. [status]: [RecorderAttendance]; [reason]: [RecorderAbsenceReason]
  /// (chỉ khi vắng); [note] ≤ 300 ký tự. Trả về buổi đã cập nhật.
  Future<RecorderLessonDto> setAttendance(
    String lessonId,
    String status, {
    String? reason,
    String? note,
  }) async {
    final n = note?.trim();
    final res = await _dio.put<Map<String, dynamic>>(
      '/recorder/lessons/$lessonId/attendance',
      data: {
        'status': status,
        'reason': reason,
        'note': n == null || n.isEmpty
            ? null
            : (n.length > 300 ? n.substring(0, 300) : n),
      },
    );
    return RecorderLessonDto.fromJson(_map(_content(res)));
  }

  /// PUT /recorder/lessons/{id}/schedule — dời buổi `scheduled` chưa diễn ra.
  /// Trả về buổi mới (scope `this`) hoặc buổi đã sinh lại cho ngày đó
  /// (scope `following`). 409 khi trùng giờ buổi khác.
  Future<RecorderLessonDto> moveLesson(
    String lessonId,
    DateTime start,
    DateTime end,
    RecorderMoveScope scope,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/recorder/lessons/$lessonId/schedule',
      data: {
        'scheduledStart': start.toUtc().toIso8601String(),
        'scheduledEnd': end.toUtc().toIso8601String(),
        'scope': scope.apiValue,
      },
    );
    return RecorderLessonDto.fromJson(_map(_content(res)));
  }

  // ── Ghi âm theo tuần, cài đặt, nhật ký ─────────────────────────────────

  /// GET /recorder/weekly-recording?weeks=n (1..8, mới nhất trước).
  Future<WeeklyRecordingDto> getWeeklyRecording({int weeks = 2}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/recorder/weekly-recording',
      queryParameters: {'weeks': weeks.clamp(1, 8)},
    );
    return WeeklyRecordingDto.fromJson(_map(_content(res)));
  }

  /// GET /recorder/settings (server trả mặc định khi chưa lưu).
  Future<RecorderSettingsDto> getSettings() async {
    final res = await _dio.get<Map<String, dynamic>>('/recorder/settings');
    return RecorderSettingsDto.fromJson(_map(_content(res)));
  }

  /// PUT /recorder/settings. Server không trả nội dung thì giữ [settings].
  Future<RecorderSettingsDto> saveSettings(RecorderSettingsDto settings) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/recorder/settings',
      data: settings.toJson(),
    );
    final c = _map(_content(res));
    return c.isEmpty ? settings : RecorderSettingsDto.fromJson(c);
  }

  /// GET /recorder/students/{studentId}/journal?month=YYYY-MM.
  Future<StudentJournalDto> getJournal(String studentId, String month) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/recorder/students/$studentId/journal',
      queryParameters: {'month': month},
    );
    final c = _map(_content(res));
    return c.isEmpty
        ? StudentJournalDto(studentId: studentId, month: month)
        : StudentJournalDto.fromJson(c);
  }
}

final recorderDatasourceProvider = Provider<RecorderDatasource>(
  (ref) => RecorderDatasource(ref.read(apiClientProvider)),
);
