import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

/// Số điện thoại Việt Nam: 0xxxxxxxxx, 84xxxxxxxxx hoặc +84xxxxxxxxx.
final RegExp vnPhoneRegExp = RegExp(r'^(\+?84|0)\d{9,10}$');

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
    final name = fullName.trim();
    final normalizedPhone = phone.replaceAll(RegExp(r'\s'), '');
    if (name.length < 2) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Họ tên phải có ít nhất 2 ký tự.'),
      ));
    }
    if (!vnPhoneRegExp.hasMatch(normalizedPhone)) {
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
    return _repository.registerTutor(
      fullName: name,
      phone: normalizedPhone,
      password: password,
    );
  }
}
