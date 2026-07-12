import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/entities/auth_token.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class VerifyPhoneUseCase {
  const VerifyPhoneUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthToken>> call({
    required String phone,
    required String otp,
  }) {
    if (otp.trim().length != 6) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Mã OTP phải có 6 chữ số.'),
      ));
    }
    return _repository.verifyPhone(phone: phone, otp: otp.trim());
  }
}
