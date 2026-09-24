import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

export 'package:tutora/core/utils/input_validators.dart' show vnPhoneRegExp;

/// Đăng ký tài khoản gia sư (app chỉ dành cho gia sư — không chọn vai trò).
/// Thành công trả về số điện thoại cần xác minh bằng OTP gửi qua Zalo.
class RegisterTutorUseCase {
  const RegisterTutorUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<String>> call({
    required String fullName,
    required String phone,
    required String password,
  }) {
    final name = collapseSpaces(fullName);
    final normalizedPhone = normalizePhone(phone);
    final nameError = validatePersonName(name);
    if (nameError != null) {
      return Future.value((
        data: null,
        failure: ValidationFailure('$nameError.'),
      ));
    }
    if (!vnPhoneRegExp.hasMatch(normalizedPhone)) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Số điện thoại không hợp lệ.'),
      ));
    }
    if (password.length < passwordMinLength) {
      return Future.value((
        data: null,
        failure: const ValidationFailure(
          'Mật khẩu phải có ít nhất $passwordMinLength ký tự.',
        ),
      ));
    }
    return _repository.registerTutor(
      fullName: name,
      phone: normalizedPhone,
      password: password,
    );
  }
}
