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
  Future<Result<AuthToken>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await datasource.login(
        LoginRequest(emailOrPhone: emailOrPhone, password: password),
      );
      if (response.requiresPhoneVerification) {
        return (
          data: null,
          failure: PhoneVerificationRequiredFailure(
            response.phone ?? emailOrPhone,
          ),
        );
      }
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
  Future<Result<AuthToken>> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await datasource.verifyPhone(
        VerifyPhoneRequest(phone: phone, otp: otp),
      );
      final entity = response.toEntity();
      await storage.saveTokens(
        access: entity.token,
        refresh: entity.refreshToken,
      );
      return (data: entity, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapOtpException(e));
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  @override
  Future<Result<void>> resendPhoneOtp({required String phone}) async {
    try {
      await datasource.resendPhoneOtp(ResendOtpRequest(phone: phone));
      return (data: null, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapException(e));
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String phone}) async {
    try {
      await datasource.forgotPassword(ForgotPasswordRequest(phone: phone));
      return (data: null, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapException(e));
    } catch (_) {
      return (data: null, failure: const ServerFailure());
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await datasource.resetPassword(
        ResetPasswordRequest(phone: phone, otp: otp, newPassword: newPassword),
      );
      return (data: null, failure: null);
    } on AppException catch (e) {
      return (data: null, failure: _mapOtpException(e));
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

  Failure _mapException(AppException e) => switch (e) {
    UnauthorizedException() => const AuthFailure(
      'Email/SĐT hoặc mật khẩu không đúng.',
    ),
    NetworkException() => const NetworkFailure(),
    ServerException() => ServerFailure(e.message),
    _ => const ServerFailure(),
  };

  Failure _mapOtpException(AppException e) => switch (e) {
    UnauthorizedException() => const ValidationFailure(
      'Mã OTP không đúng hoặc đã hết hạn.',
    ),
    NetworkException() => const NetworkFailure(),
    ServerException() => ServerFailure(e.message),
    _ => const ServerFailure(),
  };
}
