import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/student/data/models/profile_models.dart';

export 'package:tutora/features/student/data/models/profile_models.dart'
    show ChangePasswordRequest, StudentProfileDto, UpdateProfileRequest;

class ParentProfileDatasource {
  const ParentProfileDatasource(this._dio, this._storage);

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
    final userId = map['userId'] as String?;
    if (userId == null) throw Exception('Không tìm thấy userId trong token');
    return userId;
  }

  // GET /api/users/profile
  Future<StudentProfileDto> getProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/profile');
    return StudentProfileDto.fromJson(res.data!);
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    final userId = await _getUserId();
    await _dio.put<void>('/users/$userId', data: request.toJson());
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/passwords/change',
      data: request.toJson(),
    );
    debugPrint('[changePassword] status=${res.statusCode} body=${res.data}');
    final data = res.data;
    if (data != null) {
      final success = data['success'] as bool?;
      final status = data['status'] as int?;
      if (success == false || (status != null && status >= 400)) {
        throw Exception('Mật khẩu hiện tại không đúng');
      }
    }
  }

  Future<void> deactivateAccount() async {
    await _dio.put<void>('/users/me/deactivate');
  }

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
}

final parentProfileDatasourceProvider = Provider<ParentProfileDatasource>(
  (ref) => ParentProfileDatasource(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  ),
);
