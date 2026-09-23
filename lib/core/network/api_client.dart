import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:tutora/core/errors/app_exception.dart';
import 'package:tutora/core/network/interceptors/auth_interceptor.dart';

const String _configuredBaseUrl = String.fromEnvironment(
  'BASE_URL',
);
/// Bản debug mặc định gọi `localhost:5166` — chạy trên điện thoại thật cắm USB
/// kèm `adb reverse tcp:5166 tcp:5166`. Dùng emulator thì truyền
/// `--dart-define=BASE_URL=http://10.0.2.2:5166`.
const String _debugDefaultBaseUrl = 'http://localhost:5166';

String get appBaseUrl {
  if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
  if (kReleaseMode) {
    throw StateError(
      'Missing BASE_URL. Provide --dart-define=BASE_URL=<your-api-host>',
    );
  }
  return _debugDefaultBaseUrl;
}

String get _baseUrl => appBaseUrl;

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
    // Chỉ log ở bản debug, và bỏ qua toàn bộ /auth/* — body ở đó chứa mật khẩu,
    // OTP và token, không được in ra console/logcat.
    if (kDebugMode)
      PrettyDioLogger(
        requestBody: true,
        filter: (options, _) => !options.path.startsWith('/auth/'),
      ),
  ]);

  return dio;
});

AppException mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => const NetworkException(),
    DioExceptionType.connectionError => const NetworkException(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
      401 => const UnauthorizedException(),
      404 => const NotFoundException(),
      final int code when code >= 500 => ServerException.withMessage(
        (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
            'Lỗi máy chủ.',
      ),
      _ => ServerException.withMessage(
        (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
            'Lỗi không xác định.',
      ),
    },
    _ => const NetworkException(),
  };
}
