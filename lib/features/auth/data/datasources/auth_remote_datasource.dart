import 'package:dio/dio.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/auth/data/models/auth_models.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._dio);

  final Dio _dio;

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
}
