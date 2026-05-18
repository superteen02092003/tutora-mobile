import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/shared/models/notification_models.dart';

class NotificationDatasource {
  const NotificationDatasource(this._dio);

  final Dio _dio;

  // GET /api/notifications/mine
  Future<List<NotificationDto>> getMyNotifications() async {
    final res = await _dio.get<dynamic>('/notifications/mine');
    final data = res.data;
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      raw = data['content'] as List<dynamic>? ?? [];
    } else {
      raw = [];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationDto.fromJson)
        .toList();
  }

  // PUT /api/notifications/{id}/read
  Future<void> markAsRead(int id) async {
    await _dio.put<void>('/notifications/$id/read');
  }

  // PUT /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _dio.put<void>('/notifications/read-all');
  }
}

final notificationDatasourceProvider = Provider<NotificationDatasource>((ref) {
  return NotificationDatasource(ref.read(apiClientProvider));
});
