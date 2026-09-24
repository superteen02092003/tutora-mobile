import 'package:tutora/features/auth/domain/entities/auth_token.dart';

class LoginRequest {
  const LoginRequest({required this.emailOrPhone, required this.password});

  final String emailOrPhone;
  final String password;

  Map<String, dynamic> toJson() => {
    'emailOrPhone': emailOrPhone,
    'password': password,
  };
}

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.refreshToken,
    this.requiresPhoneVerification = false,
    this.phone,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? {};
    final requiresVerify =
        (content['requiresPhoneVerification'] as bool?) ?? false;
    if (requiresVerify) {
      return LoginResponse(
        token: '',
        refreshToken: '',
        requiresPhoneVerification: true,
        phone: content['phone'] as String?,
      );
    }
    return LoginResponse(
      token:
          (content['accessToken'] as String?) ??
          (content['token'] as String?) ??
          '',
      refreshToken: (content['refreshToken'] as String?) ?? '',
    );
  }

  final String token;
  final String refreshToken;
  final bool requiresPhoneVerification;
  final String? phone;

  AuthToken toEntity() => AuthToken(token: token, refreshToken: refreshToken);
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.role,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
  });

  final String fullName;
  final String phone;
  final String password;

  /// Vai trò theo backend: `Student` | `Tutor` | `Parent`.
  final String role;

  /// Đã tick đồng ý Điều khoản sử dụng — backend lưu vào
  /// user_policy_acceptances kèm phiên bản văn bản đang xuất bản.
  final bool acceptedTerms;

  /// Đã tick đồng ý Chính sách quyền riêng tư.
  final bool acceptedPrivacy;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'password': password,
    'role': role,
    'acceptedTerms': acceptedTerms,
    'acceptedPrivacy': acceptedPrivacy,
    'source': 'mobile',
  };
}

class RegisterResponse {
  const RegisterResponse({this.phone});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? {};
    return RegisterResponse(phone: content['phone'] as String?);
  }

  /// Số điện thoại backend đã gửi OTP (đã trim).
  final String? phone;
}

class VerifyPhoneRequest {
  const VerifyPhoneRequest({required this.phone, required this.otp});

  final String phone;
  final String otp;

  Map<String, dynamic> toJson() => {'phone': phone, 'otp': otp};
}

class VerifyPhoneResponse {
  const VerifyPhoneResponse({required this.token, required this.refreshToken});

  factory VerifyPhoneResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? {};
    return VerifyPhoneResponse(
      token:
          (content['accessToken'] as String?) ??
          (content['token'] as String?) ??
          '',
      refreshToken: (content['refreshToken'] as String?) ?? '',
    );
  }

  final String token;
  final String refreshToken;

  AuthToken toEntity() => AuthToken(token: token, refreshToken: refreshToken);
}

class ResendOtpRequest {
  const ResendOtpRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.phone});

  final String phone;

  Map<String, dynamic> toJson() => {'phone': phone};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.phone,
    required this.otp,
    required this.newPassword,
  });

  final String phone;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'otp': otp,
    'newPassword': newPassword,
  };
}
