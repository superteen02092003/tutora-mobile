import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';

/// Đọc kết quả Topi v1 qua backend (`/api/recording/app/...`). App không gọi
/// tutora-ai trực tiếp: backend lưu kết quả và chỉ trả phần đang bật cờ.
class TopiDatasource {
  TopiDatasource(this._dio);

  final Dio _dio;

  /// Backend bọc kết quả trong `content` như các endpoint khác; nếu không bọc
  /// thì đọc thẳng body.
  static Map<String, dynamic> _body(Map<String, dynamic>? data) {
    final c = data?['content'];
    if (c is Map) return c.cast<String, dynamic>();
    return data ?? const {};
  }

  // GET /recording/app/topi/flags → {report, plan, tips, skills}
  Future<TopiFlags> getFlags() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/recording/app/topi/flags',
    );
    return TopiFlags.fromJson(_body(res.data));
  }

  // GET /recording/app/{lessonId}/topi — null khi buổi chưa có kết quả (404).
  Future<LessonTopi?> getLessonTopi(String lessonId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/recording/app/$lessonId/topi',
      );
      return LessonTopi.fromJson(_body(res.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

final topiDatasourceProvider = Provider<TopiDatasource>(
  (ref) => TopiDatasource(ref.read(apiClientProvider)),
);
