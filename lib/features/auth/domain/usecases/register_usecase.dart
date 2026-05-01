import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) {
    if (fullName.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập đầy đủ thông tin.'),
      ));
    }
    if (!email.contains('@')) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Email không hợp lệ.'),
      ));
    }
    if (password.length < 8) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Mật khẩu phải có ít nhất 8 ký tự.'),
      ));
    }
    return _repository.register(
      email: email.trim(),
      password: password,
      fullName: fullName.trim(),
      role: role,
      phone: phone?.trim(),
    );
  }
}
