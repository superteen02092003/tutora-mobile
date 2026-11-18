import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyAccessToken = 'access_token';
const _keyRefreshToken = 'refresh_token';
const _keyLiveSessionDeviceId = 'live_session_device_id';
const _keyWelcomeSeen = 'tutor_welcome_seen';

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: access),
      _storage.write(key: _keyRefreshToken, value: refresh),
    ]);
  }

  /// Persistent device id cho phiên học trực tuyến (UUID .NET "N", 32 hex).
  /// Không xóa khi logout — nhận diện thiết bị, không phải dữ liệu nhạy cảm.
  Future<String?> getLiveSessionDeviceId() =>
      _storage.read(key: _keyLiveSessionDeviceId);

  Future<void> saveLiveSessionDeviceId(String value) =>
      _storage.write(key: _keyLiveSessionDeviceId, value: value);

  /// Màn chào mừng T1 đã xem trên máy này chưa. Không xoá khi đăng xuất.
  Future<bool> getWelcomeSeen() async =>
      (await _storage.read(key: _keyWelcomeSeen)) == '1';

  Future<void> setWelcomeSeen() =>
      _storage.write(key: _keyWelcomeSeen, value: '1');

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }
}
