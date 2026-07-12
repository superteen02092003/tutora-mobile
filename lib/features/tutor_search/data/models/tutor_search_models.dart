import 'package:tutora/core/constants/app_filter_options.dart';

class TutorSearchResult {
  const TutorSearchResult({
    required this.tutorId,
    this.fullName,
    this.avatarUrl,
    this.headline,
    this.education,
    this.degreeLevel,
    this.averageRating,
    this.totalReviews,
    this.yearsOfExperience,
    this.completedHours,
    this.subjects,
    this.hourlyRate,
    this.trialLessonPrice,
    this.allowPriceNegotiation,
    this.teachingAreaCity,
    this.teachingAreaDistrict,
    this.teachingMode,
    this.subscriptionType,
    this.subscriptionTypeLabel,
    this.verificationStatus,
    this.successRate,
    this.highlights,
    this.specialty,
  });

  factory TutorSearchResult.fromJson(Map<String, dynamic> json) {
    final rawRate = json['minPricePerHour'] ?? json['hourlyRate'];
    return TutorSearchResult(
      tutorId: json['tutorId'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      headline: json['headline'] as String?,
      education: json['education'] as String?,
      degreeLevel: json['degreeLevel'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      completedHours: (json['completedHours'] as num?)?.toDouble(),
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((e) => TutorSubjectInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      hourlyRate: (rawRate as num?)?.toDouble(),
      trialLessonPrice: (json['trialLessonPrice'] as num?)?.toDouble(),
      allowPriceNegotiation: json['allowPriceNegotiation'] as bool?,
      teachingAreaCity: json['teachingAreaCity'] as String?,
      teachingAreaDistrict: json['teachingAreaDistrict'] as String?,
      teachingMode: json['teachingMode'] as String?,
      subscriptionType: json['subscriptionType'] as String?,
      subscriptionTypeLabel: json['subscriptionTypeLabel'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
      successRate: json['successRate'] as String?,
      highlights: (json['highlights'] as List<dynamic>?)?.cast<String>(),
      specialty: json['specialty'] as String?,
    );
  }

  final String tutorId;
  final String? fullName;
  final String? avatarUrl;
  final String? headline;
  final String? education;
  final String? degreeLevel;
  final double? averageRating;
  final int? totalReviews;
  final int? yearsOfExperience;
  final double? completedHours;
  final List<TutorSubjectInfo>? subjects;
  final double? hourlyRate;
  final double? trialLessonPrice;
  final bool? allowPriceNegotiation;
  final String? teachingAreaCity;
  final String? teachingAreaDistrict;
  final String? teachingMode;
  final String? subscriptionType;
  final String? subscriptionTypeLabel;
  final String? verificationStatus;
  final String? successRate;
  final List<String>? highlights;
  final String? specialty;

  String get displayName => fullName ?? 'Gia sư';

  String get subjectSummary {
    if (subjects == null || subjects!.isEmpty) return '';
    return subjects!
        .map((s) => s.subjectName ?? '')
        .where((s) => s.isNotEmpty)
        .join(' · ');
  }

  String get locationSummary {
    if (teachingAreaCity == null) return '';
    return filterLabel(cityOptions, teachingAreaCity);
  }

  int get displayPrice => ((hourlyRate ?? 0) * 1.05).round();
}

class TutorSubjectInfo {
  const TutorSubjectInfo({
    this.subjectId,
    this.subjectName,
    this.gradeLevels,
    this.tags,
  });

  factory TutorSubjectInfo.fromJson(Map<String, dynamic> json) {
    return TutorSubjectInfo(
      subjectId: json['subjectId'] as int?,
      subjectName: json['subjectName'] as String?,
      gradeLevels: (json['gradeLevels'] as List<dynamic>?)?.cast<String>(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  final int? subjectId;
  final String? subjectName;
  final List<String>? gradeLevels;
  final List<String>? tags;
}

class TutorSearchPage {
  const TutorSearchPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory TutorSearchPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;
    return TutorSearchPage(
      items: (content['items'] as List<dynamic>)
          .map((e) => TutorSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: content['currentPage'] as int? ?? 1,
      totalPages: content['totalPages'] as int? ?? 1,
      totalCount: content['totalCount'] as int? ?? 0,
      hasNext: content['hasNext'] as bool? ?? false,
      hasPrevious: content['hasPrevious'] as bool? ?? false,
    );
  }

  final List<TutorSearchResult> items;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;
}
