import 'package:dio/dio.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/auth/data/models/auth_models.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/login',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Tạo tài khoản + gửi OTP xác minh SĐT (qua Zalo). Chưa trả JWT.
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/register',
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<VerifyPhoneResponse> verifyPhone(VerifyPhoneRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        '/auth/verify-phone',
        data: request.toJson(),
      );
      return VerifyPhoneResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> resendPhoneOtp(ResendOtpRequest request) async {
    try {
      await _dio.post<dynamic>(
        '/auth/resend-phone-otp',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      await _dio.post<dynamic>(
        '/auth/forgot-password',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post<dynamic>(
        '/auth/reset-password',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
