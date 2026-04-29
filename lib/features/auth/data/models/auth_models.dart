import '../../domain/entities/auth_token.dart';

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
