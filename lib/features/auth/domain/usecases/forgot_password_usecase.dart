import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String phone}) {
    if (phone.trim().isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập số điện thoại.'),
      ));
    }
    if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(phone.trim())) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Số điện thoại không hợp lệ.'),
      ));
    }
    return _repository.forgotPassword(phone: phone.trim());
  }
}
