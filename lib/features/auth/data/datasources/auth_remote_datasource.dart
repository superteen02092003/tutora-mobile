import 'package:dio/dio.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/auth/data/models/auth_models.dart';

const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        '/SimpleAuth/register',
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post<dynamic>(
        '/SimpleAuth/login',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    // Step 1: kiểm tra email tồn tại trong hệ thống
    try {
      await _dio.get<dynamic>('/users/by-email/${Uri.encodeComponent(email)}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw mapDioException(e); // NotFoundException
      }
      throw mapDioException(e);
    }

    // Step 2: gọi Supabase REST API gửi email reset
    final supabaseDio = Dio(
      BaseOptions(
        headers: <String, String>{'apikey': _supabaseAnonKey},
      ),
    );
    try {
      await supabaseDio.post<dynamic>(
        '/auth/v1/recover',
        data: <String, dynamic>{
          'email': email,
          'gotrue_meta_security': <String, dynamic>{},
        },
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
