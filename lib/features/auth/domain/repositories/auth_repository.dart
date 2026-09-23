import 'package:tutora/core/errors/failure.dart';
import 'package:tutora/features/auth/domain/entities/auth_token.dart';

abstract interface class AuthRepository {
  Future<Result<String>> register({
    required String phone,
    required String password,
    required String fullName,
    required String role,
    String? email,
  });

  Future<Result<AuthToken>> login({
    required String emailOrPhone,
    required String password,
  });

  /// Đăng nhập bằng Zalo: gửi access token Zalo (từ SDK) để đổi lấy token Tutora.
  Future<Result<AuthToken>> loginWithZalo({required String zaloAccessToken});

  Future<Result<AuthToken>> verifyPhone({
    required String phone,
    required String otp,
  });

  Future<Result<void>> resendPhoneOtp({required String phone});

  Future<Result<void>> forgotPassword({required String phone});

  Future<Result<void>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  });

  Future<Result<void>> logout();
}
