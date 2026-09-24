import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String phone,
    required String otp,
    required String newPassword,
  }) {
    if (otp.trim().length != 6) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Mã OTP phải có 6 chữ số.'),
      ));
    }
    if (newPassword.length < passwordMinLength) {
      return Future.value((
        data: null,
        failure: const ValidationFailure(
          'Mật khẩu phải có ít nhất $passwordMinLength ký tự.',
        ),
      ));
    }
    return _repository.resetPassword(
      phone: phone,
      otp: otp.trim(),
      newPassword: newPassword,
    );
  }
}
