import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../errors/app_exception.dart';
import 'interceptors/auth_interceptor.dart';

const String _baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:5166', // localhost via Android emulator
);

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '$_baseUrl/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    PrettyDioLogger(requestHeader: false, requestBody: true, responseBody: true),
  ]);

  return dio;
});

AppException mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout =>
      const NetworkException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
        401 => const UnauthorizedException(),
        404 => const NotFoundException(),
        final int code when code >= 500 => ServerException.withMessage(
            e.response?.data?['message'] as String? ?? 'Lỗi máy chủ.',
          ),
        _ => ServerException.withMessage(
            e.response?.data?['message'] as String? ?? 'Lỗi không xác định.',
          ),
      },
    _ => const NetworkException(),
  };
}
