import 'package:intl/intl.dart';

class StudentLessonDto {
  const StudentLessonDto({
    required this.lessonId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.tutorName,
    this.subjectName,
    this.lessonPrice,
    this.meetingLink,
  });

  factory StudentLessonDto.fromJson(Map<String, dynamic> j) {
    return StudentLessonDto(
      lessonId: (j['classSessionId'] ?? j['lessonId']) as int,
      scheduledStart: j['scheduledStart'] as String,
      scheduledEnd: j['scheduledEnd'] as String,
      status: j['status'] as String? ?? '',
      tutorName: j['tutorName'] as String?,
      subjectName: j['subjectName'] as String?,
      lessonPrice: (j['classSessionPrice'] as num?)?.toDouble(),
      meetingLink: j['meetingLink'] as String?,
    );
  }

  final int lessonId;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final String? tutorName;
  final String? subjectName;
  final double? lessonPrice;
  final String? meetingLink;

  DateTime get startDt => DateTime.parse(scheduledStart).toLocal();
  DateTime get endDt => DateTime.parse(scheduledEnd).toLocal();

  String get timeStart => DateFormat('HH:mm').format(startDt);
  String get timeEnd => DateFormat('HH:mm').format(endDt);
  String get timeRange => '$timeStart – $timeEnd';
  String get dateLabel => DateFormat('dd/MM').format(startDt);
  int get priceK => ((lessonPrice ?? 0) / 1000).round();

  bool get isToday {
    final now = DateTime.now();
    return startDt.year == now.year &&
        startDt.month == now.month &&
        startDt.day == now.day;
  }

  LessonStatusType get statusType => switch (status.toLowerCase()) {
    'scheduled' => LessonStatusType.scheduled,
    'pending_confirmation' => LessonStatusType.pending,
    'completed' => LessonStatusType.done,
    'cancelled' => LessonStatusType.cancelled,
    _ => LessonStatusType.scheduled,
  };
}

class StudentLessonDetailDto extends StudentLessonDto {
  const StudentLessonDetailDto({
    required super.lessonId,
    required super.scheduledStart,
    required super.scheduledEnd,
    required super.status,
    super.tutorName,
    super.subjectName,
    super.lessonPrice,
    super.meetingLink,
    this.tutorAvatarUrl,
    this.lessonContent,
    this.homework,
    this.tutorNotes,
    this.report,
    this.isTutorPresent,
    this.isStudentPresent,
  });

  factory StudentLessonDetailDto.fromJson(Map<String, dynamic> j) {
    final reportRaw = j['report'] as Map<String, dynamic>?;
    return StudentLessonDetailDto(
      lessonId: (j['classSessionId'] ?? j['lessonId']) as int,
      scheduledStart: j['scheduledStart'] as String,
      scheduledEnd: j['scheduledEnd'] as String,
      status: j['status'] as String? ?? '',
      tutorName: j['tutorName'] as String?,
      tutorAvatarUrl: j['tutorAvatar'] as String?,
      subjectName: j['subjectName'] as String?,
      lessonPrice: (j['classSessionPrice'] as num?)?.toDouble(),
      meetingLink: j['meetingLink'] as String?,
      lessonContent:
          (reportRaw?['topicsCovered'] ?? j['lessonContent']) as String?,
      homework: reportRaw?['homeworkAssigned'] as String?,
      tutorNotes: reportRaw?['tutorNotes'] as String?,
      isTutorPresent: j['isTutorPresent'] as bool?,
      isStudentPresent: j['isStudentPresent'] as bool?,
      report: reportRaw != null ? LessonReportDto.fromJson(reportRaw) : null,
    );
  }

  final String? tutorAvatarUrl;
  final String? lessonContent;
  final String? homework;
  final String? tutorNotes;
  final bool? isTutorPresent;
  final bool? isStudentPresent;
  final LessonReportDto? report;
}

class LessonReportDto {
  const LessonReportDto({
    required this.contentCovered,
    this.reportId = 0,
    this.homeworkAssigned,
    this.studentPerformanceRating,
    this.createdAt,
  });

  factory LessonReportDto.fromJson(Map<String, dynamic> j) => LessonReportDto(
    reportId: j['reportId'] as int? ?? 0,
    contentCovered:
        (j['topicsCovered'] ?? j['contentCovered']) as String? ?? '',
    homeworkAssigned: j['homeworkAssigned'] as String?,
    studentPerformanceRating: (j['studentPerformanceRating'] as num?)?.toInt(),
    createdAt: j['createdAt'] as String?,
  );

  final int reportId;
  final String contentCovered;
  final String? homeworkAssigned;
  final int? studentPerformanceRating;
  final String? createdAt;
}

class StudentLessonPagedResult {
  const StudentLessonPagedResult({
    required this.items,
    required this.totalCount,
  });

  factory StudentLessonPagedResult.fromJson(Map<String, dynamic> j) {
    final content = j['content'] as Map<String, dynamic>? ?? j;
    final rawItems = content['items'] as List<dynamic>? ?? [];
    return StudentLessonPagedResult(
      items: rawItems
          .map((e) => StudentLessonDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: content['totalCount'] as int? ?? rawItems.length,
    );
  }

  final List<StudentLessonDto> items;
  final int totalCount;
}

enum LessonStatusType { scheduled, pending, done, cancelled }
