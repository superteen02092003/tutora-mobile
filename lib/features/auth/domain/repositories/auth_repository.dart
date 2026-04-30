import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/entities/auth_token.dart';

abstract interface class AuthRepository {
  Future<Result<AuthToken>> login({
    required String emailOrPhone,
    required String password,
  });
}
