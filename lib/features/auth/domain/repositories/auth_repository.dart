import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/entities/auth_token.dart';

abstract interface class AuthRepository {
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  });

  Future<Result<AuthToken>> login({
    required String emailOrPhone,
    required String password,
  });

  Future<Result<void>> forgotPassword({required String email});
}
