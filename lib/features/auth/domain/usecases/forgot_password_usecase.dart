import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    if (email.trim().isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập email.'),
      ));
    }
    if (!email.contains('@')) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Email không hợp lệ.'),
      ));
    }
    return _repository.forgotPassword(email: email.trim());
  }
}
