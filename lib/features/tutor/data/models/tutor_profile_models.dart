// Response from GET /api/users/{id}
class TutorUserDto {
  const TutorUserDto({
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

  factory TutorUserDto.fromJson(Map<String, dynamic> json) {
    final c = json['content'] as Map<String, dynamic>? ?? json;
    return TutorUserDto(
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

// PUT /api/users/{id}
/// GET /api/tutors/me/profile — hồ sơ nghề nghiệp gia sư tự sửa được.
class TutorSelfProfileDto {
  const TutorSelfProfileDto({
    required this.headline,
    required this.bio,
    required this.teachingMode,
    required this.isAcceptingBookings,
  });

  factory TutorSelfProfileDto.fromJson(Map<String, dynamic> json) {
    final c = json['content'] as Map<String, dynamic>? ?? json;
    return TutorSelfProfileDto(
      headline: c['headline'] as String? ?? '',
      bio: c['bio'] as String? ?? '',
      teachingMode: c['teachingMode'] as String? ?? '',
      isAcceptingBookings: c['isAcceptingBookings'] as bool? ?? true,
    );
  }

  final String headline;
  final String bio;
  final String teachingMode;

  /// Còn nhận yêu cầu đặt lịch mới hay đang tạm dừng.
  final bool isAcceptingBookings;
}

class UpdateTutorUserRequest {
  const UpdateTutorUserRequest({
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

// PUT /api/passwords/change
class TutorChangePasswordRequest {
  const TutorChangePasswordRequest({
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

// Response from GET /api/tutor-verification/{id}/progress
class TutorVerificationProgressDto {
  const TutorVerificationProgressDto({
    required this.video,
    required this.basicInfo,
    required this.introduction,
    required this.certificates,
    required this.identityCard,
    required this.pricing,
  });

  factory TutorVerificationProgressDto.fromJson(Map<String, dynamic> json) {
    final c = json['content'] as Map<String, dynamic>? ?? json;
    final sections = c['sections'] as Map<String, dynamic>? ?? {};
    return TutorVerificationProgressDto(
      video: VerificationSectionDto.fromJson(
        sections['video'] as Map<String, dynamic>? ?? {},
      ),
      basicInfo: BasicInfoSectionDto.fromJson(
        sections['basicInfo'] as Map<String, dynamic>? ?? {},
      ),
      introduction: IntroductionSectionDto.fromJson(
        sections['introduction'] as Map<String, dynamic>? ?? {},
      ),
      certificates: CertificatesSectionDto.fromJson(
        sections['certificates'] as Map<String, dynamic>? ?? {},
      ),
      identityCard: VerificationSectionDto.fromJson(
        sections['identityCard'] as Map<String, dynamic>? ?? {},
      ),
      pricing: PricingSectionDto.fromJson(
        sections['pricing'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final VerificationSectionDto video;
  final BasicInfoSectionDto basicInfo;
  final IntroductionSectionDto introduction;
  final CertificatesSectionDto certificates;
  final VerificationSectionDto identityCard;
  final PricingSectionDto pricing;

  bool get isComplete =>
      video.isUpdated &&
      basicInfo.isUpdated &&
      introduction.isUpdated &&
      certificates.isUpdated &&
      identityCard.isUpdated &&
      pricing.isUpdated;
}

class VerificationSectionDto {
  const VerificationSectionDto({required this.status, this.updatedAt});

  factory VerificationSectionDto.fromJson(Map<String, dynamic> json) =>
      VerificationSectionDto(
        status: (json['status'] as String?) ?? 'in_progress',
        updatedAt: json['updatedAt'] as String?,
      );

  final String status;
  final String? updatedAt;

  bool get isUpdated => status == 'updated';
}

class BasicInfoSectionDto extends VerificationSectionDto {
  const BasicInfoSectionDto({
    required super.status,
    super.updatedAt,
    this.avatarUrl,
    this.headline,
    this.teachingAreaCity,
    this.teachingAreaDistrict,
    this.teachingMode,
    this.subjects = const [],
  });

  factory BasicInfoSectionDto.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'];
    final subjects = <SubjectSelectionDto>[];
    if (rawSubjects is List) {
      for (final s in rawSubjects) {
        if (s is Map<String, dynamic>) {
          subjects.add(SubjectSelectionDto.fromJson(s));
        }
      }
    }
    return BasicInfoSectionDto(
      status: (json['status'] as String?) ?? 'in_progress',
      updatedAt: json['updatedAt'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      headline: json['headline'] as String?,
      teachingAreaCity: json['teachingAreaCity'] as String?,
      teachingAreaDistrict: json['teachingAreaDistrict'] as String?,
      teachingMode: json['teachingMode'] as String?,
      subjects: subjects,
    );
  }

  final String? avatarUrl;
  final String? headline;
  final String? teachingAreaCity;
  final String? teachingAreaDistrict;
  final String? teachingMode;
  final List<SubjectSelectionDto> subjects;
}

class SubjectSelectionDto {
  const SubjectSelectionDto({
    required this.subjectId,
    required this.subjectName,
  });

  factory SubjectSelectionDto.fromJson(Map<String, dynamic> json) =>
      SubjectSelectionDto(
        subjectId: (json['subjectId'] as int?) ?? 0,
        subjectName: (json['subjectName'] as String?) ?? '',
      );

  final int subjectId;
  final String subjectName;
}

class IntroductionSectionDto extends VerificationSectionDto {
  const IntroductionSectionDto({
    required super.status,
    super.updatedAt,
    this.bio,
    this.education,
    this.gpa,
    this.gpaScale,
    this.experience,
  });

  factory IntroductionSectionDto.fromJson(Map<String, dynamic> json) =>
      IntroductionSectionDto(
        status: (json['status'] as String?) ?? 'in_progress',
        updatedAt: json['updatedAt'] as String?,
        bio: json['bio'] as String?,
        education: json['education'] as String?,
        gpa: (json['gpa'] as num?)?.toDouble(),
        gpaScale: (json['gpaScale'] as num?)?.toDouble(),
        experience: json['experience'] as String?,
      );

  final String? bio;
  final String? education;
  final double? gpa;
  final double? gpaScale;
  final String? experience;
}

class CertificatesSectionDto extends VerificationSectionDto {
  const CertificatesSectionDto({
    required super.status,
    super.updatedAt,
    this.totalCount = 0,
    this.certificates = const [],
  });

  factory CertificatesSectionDto.fromJson(Map<String, dynamic> json) {
    final raw = json['certificates'];
    final certs = <CertificateDto>[];
    if (raw is List) {
      for (final c in raw) {
        if (c is Map<String, dynamic>) {
          certs.add(CertificateDto.fromJson(c));
        }
      }
    }
    return CertificatesSectionDto(
      status: (json['status'] as String?) ?? 'in_progress',
      updatedAt: json['updatedAt'] as String?,
      totalCount: (json['totalCount'] as int?) ?? 0,
      certificates: certs,
    );
  }

  final int totalCount;
  final List<CertificateDto> certificates;
}

class CertificateDto {
  const CertificateDto({
    required this.certificateId,
    required this.certificateName,
    required this.certificateType,
    required this.issuingOrganization,
    required this.verificationStatus,
    this.yearIssued,
    this.certificateFileUrl,
    this.verificationNote,
    this.createdAt,
  });

  factory CertificateDto.fromJson(Map<String, dynamic> json) => CertificateDto(
    certificateId: (json['certificateId'] as String?) ?? '',
    certificateName: (json['certificateName'] as String?) ?? '',
    certificateType: (json['certificateType'] as String?) ?? '',
    issuingOrganization: (json['issuingOrganization'] as String?) ?? '',
    verificationStatus:
        (json['verificationStatus'] as String?) ?? 'pending_review',
    yearIssued: json['yearIssued'] as int?,
    certificateFileUrl: json['certificateFileUrl'] as String?,
    verificationNote: json['verificationNote'] as String?,
    createdAt: json['createdAt'] as String?,
  );

  final String certificateId;
  final String certificateName;
  final String certificateType;
  final String issuingOrganization;
  final String verificationStatus;
  final int? yearIssued;
  final String? certificateFileUrl;
  final String? verificationNote;
  final String? createdAt;

  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';
}

class PricingSectionDto extends VerificationSectionDto {
  const PricingSectionDto({
    required super.status,
    super.updatedAt,
    this.hourlyRate = 0,
    this.trialLessonPrice,
    this.allowPriceNegotiation = false,
  });

  factory PricingSectionDto.fromJson(Map<String, dynamic> json) =>
      PricingSectionDto(
        status: (json['status'] as String?) ?? 'in_progress',
        updatedAt: json['updatedAt'] as String?,
        hourlyRate: (json['hourlyRate'] as num?)?.toInt() ?? 0,
        trialLessonPrice: (json['trialLessonPrice'] as num?)?.toInt(),
        allowPriceNegotiation:
            (json['allowPriceNegotiation'] as bool?) ?? false,
      );

  final int hourlyRate;
  final int? trialLessonPrice;
  final bool allowPriceNegotiation;
}

// PUT /api/tutor-verification/{id}/tutor-profile/introduction
class UpdateIntroductionRequest {
  const UpdateIntroductionRequest({
    required this.bio,
    required this.education,
    required this.experience,
    this.gpa,
    this.gpaScale,
  });

  Map<String, dynamic> toJson() => {
    'bio': bio,
    'education': education,
    'experience': experience,
    if (gpa != null) 'gpa': gpa,
    if (gpaScale != null) 'gpaScale': gpaScale,
  };

  final String bio;
  final String education;
  final String experience;
  final double? gpa;
  final double? gpaScale;
}

// PUT /api/tutor-verification/{id}/tutor-profile/pricing
class UpdatePricingRequest {
  const UpdatePricingRequest({
    required this.hourlyRate,
    required this.allowPriceNegotiation,
    this.trialLessonPrice,
  });

  Map<String, dynamic> toJson() => {
    'hourlyRate': hourlyRate,
    'allowPriceNegotiation': allowPriceNegotiation,
    'trialLessonPrice': trialLessonPrice,
  };

  final int hourlyRate;
  final bool allowPriceNegotiation;
  final int? trialLessonPrice;
}
