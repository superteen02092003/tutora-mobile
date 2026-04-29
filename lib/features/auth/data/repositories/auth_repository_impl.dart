import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

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

  Failure _mapException(AppException e) => switch (e) {
        UnauthorizedException() => const AuthFailure('Email/SĐT hoặc mật khẩu không đúng.'),
        NetworkException() => const NetworkFailure(),
        ServerException() => ServerFailure(e.message),
        _ => const ServerFailure(),
      };
}
