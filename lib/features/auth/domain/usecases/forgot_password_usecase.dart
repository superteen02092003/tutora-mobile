import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String phone}) {
    // Cùng quy tắc với màn đăng ký: bỏ dấu cách, nhận 0… / 84… / +84….
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập số điện thoại.'),
      ));
    }
    if (!vnPhoneRegExp.hasMatch(normalized)) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Số điện thoại không hợp lệ.'),
      ));
    }
    return _repository.forgotPassword(phone: normalized);
  }
}
