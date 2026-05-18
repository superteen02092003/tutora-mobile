import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/shared/datasources/push_token_datasource.dart';

class PushTokenService {
  const PushTokenService(this._datasource, this._storage);

  final PushTokenDatasource _datasource;
  final SecureStorageService _storage;

  Future<void> registerToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final fcmToken = await messaging.getToken();
      if (fcmToken == null) return;

      final userId = await _getUserId();
      if (userId == null) return;

      await _datasource.savePushToken(userId: userId, fcmToken: fcmToken);
    } catch (_) {
      // Non-critical — app vẫn hoạt động bình thường nếu không lưu được token
    }
  }

  Future<void> unregisterToken() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return;

      await _datasource.deletePushToken(userId);
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<String?> _getUserId() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;
    return parseJwt(token)?.userId;
  }
}

final pushTokenServiceProvider = Provider<PushTokenService>((ref) {
  return PushTokenService(
    ref.read(pushTokenDatasourceProvider),
    ref.read(secureStorageProvider),
  );
});
