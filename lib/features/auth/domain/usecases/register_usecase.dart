import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call({
    required String phone,
    required String password,
    required String fullName,
    required String role,
    String? email,
  }) {
    if (fullName.trim().isEmpty || phone.trim().isEmpty || password.isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập đầy đủ thông tin.'),
      ));
    }
    if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(phone.trim())) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Số điện thoại không hợp lệ.'),
      ));
    }
    if (password.length < 8) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Mật khẩu phải có ít nhất 8 ký tự.'),
      ));
    }
    return _repository.register(
      phone: phone.trim(),
      password: password,
      fullName: fullName.trim(),
      role: role,
      email: (email?.trim().isEmpty ?? true) ? null : email!.trim(),
    );
  }
}
