import 'dart:convert';

const _roleClaimKey =
    'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';
const _nameClaimKey =
    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';
const _userIdClaimKey = 'userId';

enum UserRole { student, tutor, parent, unknown }

class JwtClaims {
  const JwtClaims({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.exp,
  });

  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final int exp;

  bool get isExpired => DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
}

JwtClaims? parseJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(decoded) as Map<String, dynamic>;

    final rawRole = map[_roleClaimKey] as String?;
    final role = switch (rawRole) {
      'Student' => UserRole.student,
      'Tutor' => UserRole.tutor,
      'Parent' => UserRole.parent,
      _ => UserRole.unknown,
    };

    return JwtClaims(
      userId: map[_userIdClaimKey] as String? ?? '',
      name: map[_nameClaimKey] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: role,
      exp: map['exp'] as int? ?? 0,
    );
  } catch (_) {
    return null;
  }
}
