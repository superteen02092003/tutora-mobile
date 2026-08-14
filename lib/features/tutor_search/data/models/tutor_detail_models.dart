import 'dart:convert';

List<String>? _parseStringOrList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String) {
    if (value.isEmpty) return null;
    // Try JSON array first
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    // Plain string — treat as single-item list
    return [value];
  }
  return null;
}

class AvailabilitySlotDto {
  const AvailabilitySlotDto({
    required this.dayofweek,
    required this.starttime,
    required this.endtime,
    this.dayName,
  });

  factory AvailabilitySlotDto.fromJson(Map<String, dynamic> j) =>
      AvailabilitySlotDto(
        dayofweek: (j['dayofweek'] ?? j['dayOfWeek']) as int? ?? 0,
        starttime: (j['starttime'] ?? j['startTime']) as String? ?? '',
        endtime: (j['endtime'] ?? j['endTime']) as String? ?? '',
        dayName: j['dayName'] as String?,
      );

  final int dayofweek;
  final String starttime;
  final String endtime;
  final String? dayName;

  String get localDayName {
    const names = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'CN',
    ];
    if (dayofweek >= 1 && dayofweek <= 7) return names[dayofweek];
    return dayName ?? '';
  }
}

class SubjectGradePriceDto {
  const SubjectGradePriceDto({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.gradeLevelId,
    required this.gradeLevelName,
    required this.pricePerHour,
    this.durationMinutesPerSession,
    this.sessionsPerWeek,
    this.currency = 'VND',
  });

  factory SubjectGradePriceDto.fromJson(Map<String, dynamic> j) =>
      SubjectGradePriceDto(
        id: j['id'] as int? ?? 0,
        subjectId: j['subjectId'] as int? ?? 0,
        subjectName: j['subjectName'] as String? ?? '',
        gradeLevelId: j['gradeLevelId'] as int? ?? 0,
        gradeLevelName: j['gradeLevelName'] as String? ?? '',
        pricePerHour: (j['pricePerHour'] as num?)?.toDouble() ?? 0,
        durationMinutesPerSession: j['durationMinutesPerSession'] as int?,
        sessionsPerWeek: j['sessionsPerWeek'] as int?,
        currency: j['currency'] as String? ?? 'VND',
      );

  final int id;
  final int subjectId;
  final String subjectName;
  final int gradeLevelId;
  final String gradeLevelName;
  final double pricePerHour;
  final int? durationMinutesPerSession;
  final int? sessionsPerWeek;
  final String currency;
}

/// Một buổi cố định trong gói của gia sư.
class TutorPackageFixedSlotDto {
  const TutorPackageFixedSlotDto({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory TutorPackageFixedSlotDto.fromJson(Map<String, dynamic> j) =>
      TutorPackageFixedSlotDto(
        dayOfWeek: (j['dayOfWeek'] as num?)?.toInt() ?? 0,
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
      );

  final int dayOfWeek;
  final String startTime;
  final String endTime;
}

/// A tutor booking package. packageType 1 = flexible; packageType 2 = fixed combo.
class TutorPackageDto {
  const TutorPackageDto({
    required this.packageId,
    required this.packageType,
    this.name,
    this.isActive = true,
    this.fixedSlots = const [],
  });

  factory TutorPackageDto.fromJson(Map<String, dynamic> j) => TutorPackageDto(
    packageId: (j['packageId'] as num?)?.toInt() ?? 0,
    packageType: (j['packageType'] as num?)?.toInt() ?? 0,
    name: j['name'] as String?,
    isActive: j['isActive'] as bool? ?? true,
    fixedSlots:
        (j['fixedSlots'] as List<dynamic>?)
            ?.map(
              (e) =>
                  TutorPackageFixedSlotDto.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [],
  );

  final int packageId;
  final int packageType;
  final String? name;
  final bool isActive;
  final List<TutorPackageFixedSlotDto> fixedSlots;

  bool get isFixed => packageType == 2;
}

class TutorDetailSubjectDto {
  const TutorDetailSubjectDto({
    this.subjectId,
    this.subjectName,
    this.gradeLevels,
    this.tags,
  });

  factory TutorDetailSubjectDto.fromJson(Map<String, dynamic> j) =>
      TutorDetailSubjectDto(
        subjectId: j['subjectId'] as int?,
        subjectName: j['subjectName'] as String?,
        gradeLevels: _parseStringOrList(j['gradeLevels']),
        tags: _parseStringOrList(j['tags']),
      );

  final int? subjectId;
  final String? subjectName;
  final List<String>? gradeLevels;
  final List<String>? tags;
}

class TutorDetailCertificateDto {
  const TutorDetailCertificateDto({
    required this.certificateId,
    required this.certificateName,
    required this.issuingOrganization,
    this.yearIssued,
    this.verificationStatus,
  });

  factory TutorDetailCertificateDto.fromJson(Map<String, dynamic> j) =>
      TutorDetailCertificateDto(
        certificateId: j['certificateId'] as String? ?? '',
        certificateName: j['certificateName'] as String? ?? '',
        issuingOrganization: j['issuingOrganization'] as String? ?? '',
        yearIssued: j['yearIssued'] as int?,
        verificationStatus: j['verificationStatus'] as String?,
      );

  final String certificateId;
  final String certificateName;
  final String issuingOrganization;
  final int? yearIssued;
  final String? verificationStatus;

  bool get isVerified => verificationStatus == 'verified';
}

class TutorDetailFeedbackDto {
  const TutorDetailFeedbackDto({
    required this.feedbackId,
    this.fromUserName,
    this.rating,
    this.comment,
    this.createdAt,
    this.initialGoal,
    this.actualResult,
    this.courseDuration,
  });

  factory TutorDetailFeedbackDto.fromJson(Map<String, dynamic> j) =>
      TutorDetailFeedbackDto(
        feedbackId: j['feedbackId'] as int? ?? 0,
        fromUserName: j['fromUserName'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
        comment: j['comment'] as String?,
        createdAt: j['createdAt'] as String?,
        initialGoal: j['initialGoal'] as String?,
        actualResult: j['actualResult'] as String?,
        courseDuration: j['courseDuration'] as String?,
      );

  final int feedbackId;
  final String? fromUserName;
  final double? rating;
  final String? comment;
  final String? createdAt;
  final String? initialGoal;
  final String? actualResult;
  final String? courseDuration;
}

class TutorFullProfileDto {
  const TutorFullProfileDto({
    this.avatarUrl,
    this.fullName,
    this.headline,
    this.teachingAreaCity,
    this.teachingAreaDistrict,
    this.teachingMode,
    this.bio,
    this.education,
    this.gpa,
    this.gpaScale,
    this.experience,
    this.videoIntroUrl,
    this.hourlyRate,
    this.averageRating = 0,
    this.totalFeedbacks = 0,
    this.certificates,
    this.feedbacks,
    this.subjects,
    this.availabilities,
    this.subjectGradePrices,
    this.packages,
  });

  factory TutorFullProfileDto.fromJson(Map<String, dynamic> j) {
    final content = j['content'] as Map<String, dynamic>? ?? j;

    final subjectGradePrices = (content['subjectGradePrices'] as List<dynamic>?)
        ?.map((e) => SubjectGradePriceDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawSubjects = content['subjects'] as List<dynamic>?;
    final subjects = rawSubjects != null
        ? rawSubjects
              .map(
                (e) =>
                    TutorDetailSubjectDto.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : _subjectsFromPrices(subjectGradePrices);

    return TutorFullProfileDto(
      avatarUrl: content['avatarUrl'] as String?,
      fullName: content['fullName'] as String?,
      headline: content['headline'] as String?,
      teachingAreaCity: content['teachingAreaCity'] as String?,
      teachingAreaDistrict: content['teachingAreaDistrict'] as String?,
      teachingMode: content['teachingMode'] as String?,
      bio: content['bio'] as String?,
      education: content['education'] as String?,
      gpa: (content['gpa'] as num?)?.toDouble(),
      gpaScale: (content['gpaScale'] as num?)?.toDouble(),
      experience: content['experience'] as String?,
      videoIntroUrl: content['videoIntroUrl'] as String?,
      hourlyRate: (content['hourlyRate'] as num?)?.toDouble(),
      averageRating: (content['averageRating'] as num?)?.toDouble() ?? 0,
      totalFeedbacks: content['totalFeedbacks'] as int? ?? 0,
      certificates: (content['certificates'] as List<dynamic>?)
          ?.map(
            (e) =>
                TutorDetailCertificateDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      feedbacks: (content['feedbacks'] as List<dynamic>?)
          ?.map(
            (e) => TutorDetailFeedbackDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      subjects: subjects,
      availabilities: (content['availabilities'] as List<dynamic>?)
          ?.map((e) => AvailabilitySlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectGradePrices: subjectGradePrices,
      packages: (content['packages'] as List<dynamic>?)
          ?.map((e) => TutorPackageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<TutorDetailSubjectDto>? _subjectsFromPrices(
    List<SubjectGradePriceDto>? prices,
  ) {
    if (prices == null || prices.isEmpty) return null;
    final bySubject = <int, TutorDetailSubjectDto>{};
    final grades = <int, List<String>>{};
    for (final p in prices) {
      final names = grades.putIfAbsent(p.subjectId, () => <String>[]);
      if (p.gradeLevelName.isNotEmpty && !names.contains(p.gradeLevelName)) {
        names.add(p.gradeLevelName);
      }
      bySubject[p.subjectId] = TutorDetailSubjectDto(
        subjectId: p.subjectId,
        subjectName: p.subjectName,
        gradeLevels: grades[p.subjectId],
      );
    }
    return bySubject.values.toList();
  }

  final String? avatarUrl;
  final String? fullName;
  final String? headline;
  final String? teachingAreaCity;
  final String? teachingAreaDistrict;
  final String? teachingMode;
  final String? bio;
  final String? education;
  final double? gpa;
  final double? gpaScale;
  final String? experience;
  final String? videoIntroUrl;
  final double? hourlyRate;
  final double averageRating;
  final int totalFeedbacks;
  final List<TutorDetailCertificateDto>? certificates;
  final List<TutorDetailFeedbackDto>? feedbacks;
  final List<TutorDetailSubjectDto>? subjects;
  final List<AvailabilitySlotDto>? availabilities;
  final List<SubjectGradePriceDto>? subjectGradePrices;
  final List<TutorPackageDto>? packages;

  /// Null if the tutor has no flexible package.
  int? get flexiblePackageId {
    final pkgs = packages;
    if (pkgs == null) return null;
    for (final p in pkgs) {
      if (p.isActive && p.packageType == 1) return p.packageId;
    }
    return null;
  }

  /// Các gói cố định còn hiệu lực và có ít nhất 1 buổi — dùng cho bước "Cách đặt".
  List<TutorPackageDto> get fixedPackages => (packages ?? [])
      .where((p) => p.isActive && p.isFixed && p.fixedSlots.isNotEmpty)
      .toList();

  String get displayName => fullName ?? 'Gia sư';

  double get lowestPrice {
    final prices = subjectGradePrices;
    if (prices != null && prices.isNotEmpty) {
      return prices.map((p) => p.pricePerHour).reduce((a, b) => a < b ? a : b);
    }
    return hourlyRate ?? 0;
  }

  String get gpaText {
    if (gpa == null) return '';
    final scale = gpaScale != null ? '/${gpaScale!.toStringAsFixed(1)}' : '';
    return '${gpa!.toStringAsFixed(1)}$scale';
  }
}
