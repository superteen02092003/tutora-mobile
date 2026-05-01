import 'package:tutora/features/auth/domain/entities/auth_token.dart';

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.phone,
  });

  final String email;
  final String password;
  final String fullName;
  final String role;
  final String? phone;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'fullName': fullName,
    'role': role,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
  };
}

class RegisterResponse {
  const RegisterResponse({required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        message: (json['message'] as String?) ?? 'Đăng ký thành công',
      );

  final String message;
}

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
  const LoginResponse({required this.token, required this.refreshToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;
    return LoginResponse(
      token: content['token'] as String,
      refreshToken: content['refreshToken'] as String,
    );
  }

  final String token;
  final String refreshToken;

  AuthToken toEntity() => AuthToken(token: token, refreshToken: refreshToken);
}
