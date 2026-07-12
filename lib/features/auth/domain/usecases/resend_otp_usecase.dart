import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class ResendOtpUseCase {
  const ResendOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String phone}) {
    return _repository.resendPhoneOtp(phone: phone);
  }
}
