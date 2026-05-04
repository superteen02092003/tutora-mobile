import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/errors/app_exception.dart';
import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tutora/features/auth/data/models/auth_models.dart';
import 'package:tutora/features/auth/domain/entities/auth_token.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    datasource: AuthRemoteDatasource(ref.read(apiClientProvider)),
    storage: ref.read(secureStorageProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.datasource,
    required this.storage,
  });

  final AuthRemoteDatasource datasource;
  final SecureStorageService storage;

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    try {
      await datasource.register(
        RegisterRequest(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
          phone: phone,
        ),
      );
      return (data: null, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapException(e));
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  @override
  Future<Result<AuthToken>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await datasource.login(
        LoginRequest(emailOrPhone: emailOrPhone, password: password),
      );
      final entity = response.toEntity();

      await storage.saveTokens(
        access: entity.token,
        refresh: entity.refreshToken,
      );

      return (data: entity, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapException(e));
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await storage.clearTokens();
      return (data: null, failure: null);
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await datasource.forgotPassword(email);
      return (data: null, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapForgotException(e));
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  Failure _mapException(AppException e) => switch (e) {
    UnauthorizedException() => const AuthFailure(
      'Email/SĐT hoặc mật khẩu không đúng.',
    ),
    NetworkException() => const NetworkFailure(),
    ServerException() => ServerFailure(e.message),
    _ => const ServerFailure(),
  };

  Failure _mapForgotException(AppException e) => switch (e) {
    NotFoundException() => const ValidationFailure(
      'Email này chưa được đăng ký trong hệ thống.',
    ),
    NetworkException() => const NetworkFailure(),
    _ => const ServerFailure('Có lỗi xảy ra. Vui lòng thử lại.'),
  };
}
