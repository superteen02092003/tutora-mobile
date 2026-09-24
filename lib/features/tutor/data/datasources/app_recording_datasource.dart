import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';

/// Gọi nhóm endpoint ghi âm buổi dạy tại nhà (`/api/recording/app/...`).
///
/// Lưu ý về upload: file đi THẲNG từ điện thoại lên kho qua URL presigned, không
/// đi vòng qua backend. Mỗi buổi ~22 MB — cho nó chạy qua server chỉ tốn gấp đôi
/// băng thông và biến backend thành nút thắt khi nhiều gia sư cùng dạy tối thứ
/// Bảy.
class AppRecordingDatasource {
  AppRecordingDatasource(this._dio);

  final Dio _dio;

  /// Dio riêng cho việc PUT lên kho: KHÔNG dùng client chính vì nó gắn
  /// baseUrl `/api` và interceptor đính token Tutora — gửi token của mình sang
  /// S3 vừa thừa vừa lộ.
  static final Dio _uploadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // POST /recording/app/{lessonId}/start
  Future<AppRecordingStartDto> start(
    int lessonId, {
    String? consentSnapshot,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recording/app/$lessonId/start',
      data: {'consentSnapshot': consentSnapshot},
    );
    return AppRecordingStartDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  // POST /recording/app/lesson/{lessonId}/start — buổi đã tạo sẵn (ngoài nền tảng)
  Future<AppRecordingStartDto> startLesson(String lessonId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recording/app/lesson/$lessonId/start',
      data: const <String, dynamic>{},
    );
    return AppRecordingStartDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  // POST /recording/app/student/{studentId}/start — ghi ngay, server tự tạo buổi
  Future<AppRecordingStartDto> startStudent(String studentId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recording/app/student/$studentId/start',
      data: const <String, dynamic>{},
    );
    return AppRecordingStartDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  // POST /recording/app/{recordingId}/approve — gia sư duyệt báo cáo đã sửa
  Future<AppRecordingStatusDto> approve(
    String recordingId, {
    required String lessonContent,
    String? homework,
    String? tutorNotes,
    String? zaloContent,
    String? zaloHomework,
    String? zaloNotes,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recording/app/$recordingId/approve',
      data: {
        'lessonContent': lessonContent,
        'homework': homework,
        'tutorNotes': tutorNotes,
        'zaloContent': ?zaloContent,
        'zaloHomework': ?zaloHomework,
        'zaloNotes': ?zaloNotes,
      },
    );
    return AppRecordingStatusDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  // POST /recording/app/{recordingId}/upload-url?partNumber=n
  Future<AppRecordingUploadUrlDto> uploadUrl(
    String recordingId,
    int partNumber,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recording/app/$recordingId/upload-url',
      queryParameters: {'partNumber': partNumber},
    );
    return AppRecordingUploadUrlDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// PUT một đoạn lên kho.
  ///
  /// Content-Type phải đúng `audio/mp4` vì backend đã ký URL với giá trị đó —
  /// gửi khác đi thì S3 từ chối chữ ký, và lỗi trả về không nói gì về nguyên
  /// nhân thật.
  Future<void> uploadPart(String url, File file) async {
    final length = await file.length();
    await _uploadDio.put<void>(
      url,
      data: file.openRead(),
      options: Options(
        headers: {
          Headers.contentLengthHeader: length,
          Headers.contentTypeHeader: 'audio/mp4',
        },
      ),
    );
  }

  // POST /recording/app/{recordingId}/complete
  Future<AppRecordingStatusDto> complete(
    String recordingId,
    int durationSec,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/recording/app/$recordingId/complete',
      data: {'durationSec': durationSec},
    );
    return AppRecordingStatusDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  // GET /recording/app/{recordingId}
  Future<AppRecordingStatusDto> status(String recordingId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/recording/app/$recordingId',
    );
    return AppRecordingStatusDto.fromJson(
      res.data?['content'] as Map<String, dynamic>? ?? const {},
    );
  }

  // GET /recording/app/{recordingId}/audio-url — link nghe lại (2 giờ)
  Future<String> audioUrl(String recordingId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/recording/app/$recordingId/audio-url',
    );
    final c = res.data?['content'] as Map<String, dynamic>? ?? const {};
    return c['url'] as String? ?? '';
  }

  // DELETE /recording/app/{recordingId}
  Future<void> discard(String recordingId) async {
    await _dio.delete<void>('/recording/app/$recordingId');
  }
}

final appRecordingDatasourceProvider = Provider<AppRecordingDatasource>(
  (ref) => AppRecordingDatasource(ref.read(apiClientProvider)),
);
