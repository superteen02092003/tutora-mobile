import '../entities/auth_token.dart';
import '../../../../core/errors/failure.dart';

abstract interface class AuthRepository {
  Future<Result<AuthToken>> login({
    required String emailOrPhone,
    required String password,
  });
}
