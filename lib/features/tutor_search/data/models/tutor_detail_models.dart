import 'dart:convert';

List<String>? _parseStringOrList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.cast<String>();
  if (value is String) {
    final decoded = jsonDecode(value);
    if (decoded is List) return decoded.cast<String>();
  }
  return null;
}

class AvailabilitySlotDto {
  const AvailabilitySlotDto({
    required this.dayofweek,
    required this.starttime,
    required this.endtime,
  });

  factory AvailabilitySlotDto.fromJson(Map<String, dynamic> j) =>
      AvailabilitySlotDto(
        dayofweek: j['dayofweek'] as int? ?? 0,
        starttime: j['starttime'] as String? ?? '',
        endtime: j['endtime'] as String? ?? '',
      );

  final int dayofweek;
  final String starttime;
  final String endtime;
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
  });

  factory TutorFullProfileDto.fromJson(Map<String, dynamic> j) {
    final content = j['content'] as Map<String, dynamic>? ?? j;
    return TutorFullProfileDto(
      avatarUrl: content['avatarUrl'] as String?,
      fullName: content['fullName'] as String?,
      headline: content['headline'] as String?,
      teachingAreaCity: content['teachingAreaCity'] as String?,
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
      subjects: (content['subjects'] as List<dynamic>?)
          ?.map(
            (e) => TutorDetailSubjectDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      availabilities: (content['availabilities'] as List<dynamic>?)
          ?.map((e) => AvailabilitySlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? avatarUrl;
  final String? fullName;
  final String? headline;
  final String? teachingAreaCity;
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

  String get displayName => fullName ?? 'Gia sư';
  int get priceInK => ((hourlyRate ?? 0) / 1000).round();
  String get gpaText {
    if (gpa == null) return '';
    final scale = gpaScale != null ? '/${gpaScale!.toStringAsFixed(1)}' : '';
    return '${gpa!.toStringAsFixed(1)}$scale';
  }
}
