import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/student/data/models/profile_models.dart';
import 'package:tutora/features/student/data/models/student_access_models.dart';

class ProfileDatasource {
  const ProfileDatasource(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  Future<String> _getUserId() async {
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token không hợp lệ');
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final map = json.decode(payload) as Map<String, dynamic>;
    final userId =
        map['userId'] as String? ??
        map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
            as String?;
    if (userId == null) throw Exception('Không tìm thấy userId trong token');
    return userId;
  }

  // GET /api/users/profile
  Future<StudentProfileDto> getProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/profile');
    return StudentProfileDto.fromJson(res.data!);
  }

  // PUT /api/users/{id}
  Future<void> updateProfile(UpdateProfileRequest request) async {
    final userId = await _getUserId();
    await _dio.put<void>('/users/$userId', data: request.toJson());
  }

  // PUT /api/passwords/change
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _dio.put<void>('/passwords/change', data: request.toJson());
  }

  // PUT /api/users/{id}/avatar — multipart/form-data
  Future<String> uploadAvatar(String filePath) async {
    final userId = await _getUserId();
    final formData = FormData.fromMap({
      'AvatarFile': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.put<Map<String, dynamic>>(
      '/users/$userId/avatar',
      data: formData,
    );
    final content = res.data?['content'] as Map<String, dynamic>?;
    return (content?['avatarUrl'] as String?) ?? '';
  }

  /// POST /api/students/me/verify-cccd — 422 là lỗi người dùng sửa được
  /// (ảnh mờ, chưa đủ tuổi...) nên phải giữ nguyên message của BE.
  Future<CccdVerifyResult> verifyCccd({
    required String frontPath,
    required String backPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'FrontImage': await MultipartFile.fromFile(frontPath),
        'BackImage': await MultipartFile.fromFile(backPath),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/students/me/verify-cccd',
        data: formData,
      );
      final body = res.data ?? const {};
      final content = body['content'] as Map<String, dynamic>? ?? const {};
      return CccdVerifyResult.fromJson(
        content,
        fallbackMessage: body['message'] as String?,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;
      throw Exception(msg ?? 'Không xác minh được CCCD, vui lòng thử lại.');
    }
  }
}

final profileDatasourceProvider = Provider<ProfileDatasource>(
  (ref) => ProfileDatasource(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  ),
);
