import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';

class PushTokenDatasource {
  const PushTokenDatasource(this._dio);

  final Dio _dio;

  // POST /api/push-tokens
  Future<void> savePushToken({
    required String userId,
    required String fcmToken,
  }) async {
    await _dio.post<void>(
      '/push-tokens',
      data: {'userId': userId, 'fcmToken': fcmToken},
    );
  }

  // DELETE /api/push-tokens/{id}
  Future<void> deletePushToken(String userId) async {
    await _dio.delete<void>('/push-tokens/$userId');
  }
}

final pushTokenDatasourceProvider = Provider<PushTokenDatasource>((ref) {
  return PushTokenDatasource(ref.read(apiClientProvider));
});
