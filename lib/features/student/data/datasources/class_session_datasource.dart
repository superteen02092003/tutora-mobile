import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/agora_room_models.dart';

class ClassSessionDatasource {
  const ClassSessionDatasource(this._dio);
  final Dio _dio;

  Future<void> confirmClassSession(int classSessionId) async {
    try {
      await _dio.put<dynamic>(
        '/student/class-sessions/$classSessionId/confirm',
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AgoraRoomDto> getAgoraRoom(int classSessionId) async {
    try {
      final res = await _dio.get<dynamic>('/agora/room/$classSessionId');
      final data = res.data as Map<String, dynamic>;
      final content = data['content'] as Map<String, dynamic>? ?? data;
      return AgoraRoomDto.fromJson(content);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    final data = e.response?.data;
    String? msg;
    if (data is Map<String, dynamic>) {
      msg = data['message'] as String?;
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }
    return Exception(msg ?? 'Có lỗi xảy ra, vui lòng thử lại.');
  }
}

final classSessionDatasourceProvider = Provider<ClassSessionDatasource>((ref) {
  return ClassSessionDatasource(ref.read(apiClientProvider));
});
