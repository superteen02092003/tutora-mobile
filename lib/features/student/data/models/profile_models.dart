// Response từ GET /api/users/{id} — map theo UserResponse.cs (lowercase)
class StudentProfileDto {
  const StudentProfileDto({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.birthdate,
    required this.address,
    required this.gender,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory StudentProfileDto.fromJson(Map<String, dynamic> json) {
    final c = json['content'] as Map<String, dynamic>? ?? json;
    return StudentProfileDto(
      userId: (c['userid'] as String?) ?? '',
      fullName: (c['fullname'] as String?) ?? '',
      email: (c['email'] as String?) ?? '',
      phone: (c['phone'] as String?) ?? '',
      birthdate: (c['birthdate'] as String?) ?? '',
      address: (c['address'] as String?) ?? '',
      gender: (c['gender'] as String?) ?? '',
      avatarUrl: (c['avatarurl'] as String?) ?? '',
      createdAt: (c['createdat'] as String?) ?? '',
    );
  }

  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String birthdate;
  final String address;
  final String gender;
  final String avatarUrl;
  final String createdAt;
}

// Request PUT /api/users/{id} — map theo UpdateUserRequest.cs
class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.fullName,
    required this.birthdate,
    required this.address,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
    'Fullname': fullName,
    'Birthdate': birthdate,
    'Address': address,
    'Gender': gender,
  };

  final String fullName;
  final String birthdate;
  final String address;
  final String gender;
}

// Request PUT /api/passwords/change — map theo ChangePasswordRequest.cs
class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'OldPassword': oldPassword,
    'NewPassword': newPassword,
  };

  final String oldPassword;
  final String newPassword;
}
