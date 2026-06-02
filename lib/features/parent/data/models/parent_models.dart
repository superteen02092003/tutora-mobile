class ParentStudentDto {
  const ParentStudentDto({
    required this.studentId,
    required this.fullName,
    this.gradeLevel,
    this.school,
    this.avatarUrl,
    this.birthdate,
  });

  factory ParentStudentDto.fromJson(Map<String, dynamic> j) => ParentStudentDto(
    studentId: j['studentId'] as String? ?? '',
    fullName: j['fullName'] as String? ?? '',
    gradeLevel: j['gradeLevel'] as String?,
    school: j['school'] as String?,
    avatarUrl: j['avatarUrl'] as String?,
    birthdate: j['birthdate'] as String?,
  );

  final String studentId;
  final String fullName;
  final String? gradeLevel;
  final String? school;
  final String? avatarUrl;
  final String? birthdate;
}

class ParentLessonDto {
  const ParentLessonDto({
    required this.lessonId,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.studentId,
    this.studentName,
    this.tutorId,
    this.tutorName,
    this.tutorAvatarUrl,
    this.subjectName,
    this.status,
    this.meetingLink,
    this.confirmDeadline,
    this.parentAckedAt,
    this.bookingId,
    this.teachingMode,
  });

  factory ParentLessonDto.fromJson(Map<String, dynamic> j) => ParentLessonDto(
    lessonId: j['lessonId'] as int? ?? 0,
    scheduledStart: j['scheduledStart'] as String? ?? '',
    scheduledEnd: j['scheduledEnd'] as String? ?? '',
    studentId: j['studentId'] as String?,
    studentName: j['studentName'] as String?,
    tutorId: j['tutorId'] as String?,
    tutorName: j['tutorName'] as String?,
    tutorAvatarUrl: j['tutorAvatarUrl'] as String?,
    subjectName: j['subjectName'] as String?,
    status: j['status'] as String?,
    meetingLink: j['meetingLink'] as String?,
    confirmDeadline: j['confirmDeadline'] as String?,
    parentAckedAt: j['parentAckedAt'] as String?,
    bookingId: j['bookingId'] as int?,
    teachingMode: j['teachingMode'] as String?,
  );

  final int lessonId;
  final String scheduledStart;
  final String scheduledEnd;
  final String? studentId;
  final String? studentName;
  final String? tutorId;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final String? subjectName;
  final String? status;
  final String? meetingLink;
  final String? confirmDeadline;
  final String? parentAckedAt;
  final int? bookingId;
  final String? teachingMode;

  bool get isPendingConfirm => status == 'completed' && parentAckedAt == null;

  DateTime get startDt => DateTime.tryParse(scheduledStart) ?? DateTime.now();
  DateTime get endDt => DateTime.tryParse(scheduledEnd) ?? DateTime.now();
}

class ParentBookingDto {
  const ParentBookingDto({
    required this.bookingId,
    this.studentId,
    this.studentName,
    this.tutorId,
    this.tutorName,
    this.tutorAvatarUrl,
    this.subjectName,
    this.status,
    this.paymentStatus,
    this.sessionCount,
    this.remainingSessions,
    this.startDate,
    this.teachingMode,
    this.finalPrice,
    this.schedule,
  });

  factory ParentBookingDto.fromJson(Map<String, dynamic> j) => ParentBookingDto(
    bookingId: j['bookingId'] as int? ?? 0,
    studentId: j['studentId'] as String?,
    studentName: j['studentName'] as String?,
    tutorId: j['tutorId'] as String?,
    tutorName: j['tutorName'] as String?,
    tutorAvatarUrl: j['tutorAvatarUrl'] as String?,
    subjectName: j['subjectName'] as String?,
    status: j['status'] as String?,
    paymentStatus: j['paymentStatus'] as String?,
    sessionCount: j['sessionCount'] as int?,
    remainingSessions: j['remainingSessions'] as int?,
    startDate: j['startDate'] as String?,
    teachingMode: j['teachingMode'] as String?,
    finalPrice: (j['finalPrice'] as num?)?.toDouble(),
    schedule: (j['schedule'] as List<dynamic>?)
        ?.map((e) => ParentScheduleSlot.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final int bookingId;
  final String? studentId;
  final String? studentName;
  final String? tutorId;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final String? subjectName;
  final String? status;
  final String? paymentStatus;
  final int? sessionCount;
  final int? remainingSessions;
  final String? startDate;
  final String? teachingMode;
  final double? finalPrice;
  final List<ParentScheduleSlot>? schedule;

  bool get isActive => status == 'active';
}

class ParentScheduleSlot {
  const ParentScheduleSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ParentScheduleSlot.fromJson(Map<String, dynamic> j) =>
      ParentScheduleSlot(
        dayOfWeek: j['dayOfWeek'] as int? ?? 0,
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
      );

  final int dayOfWeek;
  final String startTime;
  final String endTime;

  static const _days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  String get dayLabel => _days[dayOfWeek % 7];
}
