import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/SimpleAuth/login',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
