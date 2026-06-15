import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';

class TutorProfileDatasource {
  const TutorProfileDatasource(this._dio, this._storage);

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

  // GET /api/users/
  Future<TutorUserDto> getUser() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/profile');
    return TutorUserDto.fromJson(res.data!);
  }

  // PUT /api/users/{id}
  Future<void> updateUser(UpdateTutorUserRequest request) async {
    final userId = await _getUserId();
    await _dio.put<void>('/users/$userId', data: request.toJson());
  }

  // PUT /api/users/{id}/avatar
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

  // PUT /api/passwords/change
  Future<void> changePassword(TutorChangePasswordRequest request) async {
    await _dio.put<void>('/passwords/change', data: request.toJson());
  }

  // GET /api/tutors/{id}/verification/progress
  Future<TutorVerificationProgressDto> getVerificationProgress() async {
    final userId = await _getUserId();
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutors/$userId/verification/progress',
    );
    return TutorVerificationProgressDto.fromJson(res.data!);
  }

  // PUT /api/tutors/{id}/profile/introduction
  Future<void> updateIntroduction(UpdateIntroductionRequest request) async {
    final userId = await _getUserId();
    await _dio.put<void>(
      '/tutors/$userId/profile/introduction',
      data: request.toJson(),
    );
  }

  // PUT /api/tutors/{id}/profile/pricing
  Future<void> updatePricing(UpdatePricingRequest request) async {
    final userId = await _getUserId();
    await _dio.put<void>(
      '/tutors/$userId/profile/pricing',
      data: request.toJson(),
    );
  }

  // POST /api/tutors/{id}/submit-for-review
  Future<void> submitForReview() async {
    final userId = await _getUserId();
    await _dio.post<void>(
      '/tutors/$userId/submit-for-review',
    );
  }

  // GET /api/tutors/{id}/profile/certificates
  Future<List<CertificateDto>> getCertificates() async {
    final userId = await _getUserId();
    final res = await _dio.get<Map<String, dynamic>>(
      '/tutors/$userId/profile/certificates',
    );
    final content = res.data?['content'];
    if (content is List) {
      return content
          .whereType<Map<String, dynamic>>()
          .map(CertificateDto.fromJson)
          .toList();
    }
    return [];
  }

  // DELETE /api/tutors/{id}/profile/certificates/{certId}
  Future<void> deleteCertificate(String certId) async {
    final userId = await _getUserId();
    await _dio.delete<void>(
      '/tutors/$userId/profile/certificates/$certId',
    );
  }

  // POST /api/tutors/{id}/profile/certificates  (multipart)
  Future<void> uploadCertificate({
    required String filePath,
    required String certificateName,
    required String certificateType,
    required String issuingOrganization,
    int? yearIssued,
  }) async {
    final userId = await _getUserId();
    final formData = FormData.fromMap({
      'CertificateFile': await MultipartFile.fromFile(filePath),
      'CertificateName': certificateName,
      'CertificateType': certificateType,
      'IssuingOrganization': issuingOrganization,
      if (yearIssued != null) 'YearIssued': yearIssued.toString(),
    });
    await _dio.post<void>(
      '/tutors/$userId/profile/certificates',
      data: formData,
    );
  }
}

final tutorProfileDatasourceProvider = Provider<TutorProfileDatasource>(
  (ref) => TutorProfileDatasource(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  ),
);
