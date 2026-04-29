import '../../../../core/errors/failure.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthToken>> call({
    required String emailOrPhone,
    required String password,
  }) {
    if (emailOrPhone.trim().isEmpty || password.isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập đầy đủ thông tin.'),
      ));
    }
    return _repository.login(emailOrPhone: emailOrPhone.trim(), password: password);
  }
}
