import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Kênh native — xem android/app/src/main/kotlin/.../MainActivity.kt.
const MethodChannel _channel = MethodChannel('vn.tutora/zalo_auth');

/// Lỗi khi đăng nhập qua Zalo SDK. [cancelled] = người dùng tự huỷ.
class ZaloSdkException implements Exception {
  const ZaloSdkException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

/// Đăng nhập bằng app Zalo qua Zalo SDK native (MainActivity.kt).
///
/// SDK tự mở app Zalo (hoặc trình duyệt nếu máy chưa cài Zalo), người dùng bấm
/// "Đồng ý", SDK đổi mã PKCE lấy Zalo access token. Backend dùng access token đó
/// gọi Graph API lấy Zalo ID rồi cấp token Tutora (POST /auth/zalo/app).
class ZaloSdkAuth {
  const ZaloSdkAuth();

  /// [viaWeb] = true: đăng nhập qua trang web Zalo (Chrome Custom Tab) thay vì
  /// mở app Zalo — dùng khi app Zalo báo "Bản Zalo hiện tại không tương thích".
  Future<String> obtainAccessToken({bool viaWeb = false}) async {
    // Xoá phiên cũ để lần nào cũng xin quyền mới, tránh dùng lại oauth code đã hết hạn.
    try {
      await _channel.invokeMethod<void>('logout');
    } catch (_) {}

    final verifier = _codeVerifier();
    final challenge = _base64Url(
      sha256.convert(ascii.encode(verifier)).bytes,
    );

    final Map<dynamic, dynamic>? result;
    try {
      result = await _channel.invokeMethod<Map<dynamic, dynamic>>('login', {
        'codeVerifier': verifier,
        'codeChallenge': challenge,
        'via': viaWeb ? 'web' : 'app',
      });
    } on MissingPluginException {
      throw const ZaloSdkException(
        'Đăng nhập Zalo hiện chỉ hỗ trợ Android.',
      );
    } catch (e) {
      throw ZaloSdkException('Không mở được đăng nhập Zalo: $e');
    }

    if (result == null) {
      throw const ZaloSdkException('Đã huỷ đăng nhập Zalo.', cancelled: true);
    }

    if (result['isSuccess'] != true) {
      final error = result['error'];
      final code = error is Map ? error['errorCode'] : null;
      final message = error is Map
          ? (error['errorMessage'] ?? error['errorReason'])?.toString()
          : null;
      debugPrint('Zalo SDK login lỗi: $result');
      // -1111 / -1114: người dùng tự huỷ (theo mã lỗi Zalo SDK).
      final cancelled = code == -1111 || code == -1114;
      throw ZaloSdkException(
        cancelled
            ? 'Đã huỷ đăng nhập Zalo.'
            : 'Đăng nhập Zalo thất bại${code != null ? ' ($code)' : ''}'
                  '${message != null && message.isNotEmpty ? ': $message' : ''}.',
        cancelled: cancelled,
      );
    }

    final data = result['data'];
    final token = data is Map
        ? (data['access_token'] ?? data['accessToken'])?.toString()
        : null;
    if (token == null || token.isEmpty) {
      debugPrint('Zalo SDK login không có access token: $result');
      throw const ZaloSdkException('Zalo không trả về access token.');
    }
    return token;
  }

  /// Key hash của chữ ký app hiện tại — phải khai báo trong Zalo Developers
  /// (Đăng nhập → Android) thì SDK mới chịu mở app Zalo.
  Future<String?> androidHashKey() async {
    try {
      return await _channel.invokeMethod<String>('getHashKey');
    } catch (_) {
      return null;
    }
  }

  static String _codeVerifier() {
    final random = Random.secure();
    return _base64Url(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
