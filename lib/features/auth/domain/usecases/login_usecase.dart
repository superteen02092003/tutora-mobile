import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/entities/auth_token.dart';
import 'package:tutora/features/auth/domain/repositories/auth_repository.dart';

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _digitsOnlyRe = RegExp(r'^\d+$');

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthToken>> call({
    required String emailOrPhone,
    required String password,
  }) {
    final identifier = emailOrPhone.trim();

    if (identifier.isEmpty || password.isEmpty) {
      return Future.value((
        data: null,
        failure: const ValidationFailure('Vui lòng nhập đầy đủ thông tin.'),
      ));
    }

    // Khớp đúng 3 nhánh phân loại của /auth/login
    final ValidationFailure? invalid;
    if (identifier.contains('@')) {
      invalid = _emailRe.hasMatch(identifier)
          ? null
          : const ValidationFailure('Email không hợp lệ.');
    } else if (identifier.startsWith('+') ||
        _digitsOnlyRe.hasMatch(identifier)) {
      final digits = identifier.replaceAll(RegExp(r'\D'), '');
      invalid = digits.length >= 9 && digits.length <= 11
          ? null
          : const ValidationFailure('Số điện thoại không hợp lệ.');
    } else {
      invalid = identifier.length >= 3
          ? null
          : const ValidationFailure('Tên đăng nhập không hợp lệ.');
    }

    if (invalid != null) {
      return Future.value((data: null, failure: invalid));
    }

    return _repository.login(emailOrPhone: identifier, password: password);
  }
}
