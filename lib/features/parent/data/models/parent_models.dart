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
    // BE trả `avatarURL` (StudentProfileResponse), khác camelCase của các DTO còn lại.
    avatarUrl: (j['avatarUrl'] ?? j['avatarURL']) as String?,
    birthdate: (j['birthdate'] ?? j['birthDate']) as String?,
  );

  final String studentId;
  final String fullName;
  final String? gradeLevel;
  final String? school;
  final String? avatarUrl;
  final String? birthdate;
}

class GradeLevelDto {
  const GradeLevelDto({
    required this.gradeLevelId,
    required this.gradeName,
    required this.levelOrder,
  });

  factory GradeLevelDto.fromJson(Map<String, dynamic> j) => GradeLevelDto(
    gradeLevelId: j['gradeLevelId'] as int,
    gradeName: j['gradeName'] as String? ?? '',
    levelOrder: j['levelOrder'] as int? ?? 0,
  );

  final int gradeLevelId;
  final String gradeName;
  final int levelOrder;
}

class AddStudentResult {
  const AddStudentResult({
    required this.studentId,
    required this.fullName,
    required this.username,
    required this.temporaryPassword,
  });

  factory AddStudentResult.fromJson(Map<String, dynamic> j) => AddStudentResult(
    studentId: j['studentId'] as String? ?? '',
    fullName: j['fullName'] as String? ?? '',
    username: j['username'] as String? ?? '',
    temporaryPassword: j['temporaryPassword'] as String? ?? '',
  );

  final String studentId;
  final String fullName;
  final String username;
  final String temporaryPassword;
}

class ParentHomeStatsDto {
  const ParentHomeStatsDto({
    this.sessionsThisWeek = 0,
    this.childrenLearning = 0,
    this.childrenTotal = 0,
    this.pendingConfirmation = 0,
  });

  factory ParentHomeStatsDto.fromJson(Map<String, dynamic> j) =>
      ParentHomeStatsDto(
        sessionsThisWeek: j['sessionsThisWeek'] as int? ?? 0,
        childrenLearning: j['childrenLearning'] as int? ?? 0,
        childrenTotal: j['childrenTotal'] as int? ?? 0,
        pendingConfirmation: j['pendingConfirmation'] as int? ?? 0,
      );

  final int sessionsThisWeek;

  /// Con CÓ booking đang hoạt động — khác [childrenTotal].
  final int childrenLearning;
  final int childrenTotal;
  final int pendingConfirmation;
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
    this.lessonContent,
    this.homework,
    this.tutorNotes,
    this.requiresRemainingPayment = false,
  });

  /// Parse cả dạng list (phẳng, `lessonId`) lẫn dạng detail
  /// (ClassSessionDetailResponse: `classSessionId` + nested student/tutor/subject).
  factory ParentLessonDto.fromJson(Map<String, dynamic> j) {
    final student = j['student'] as Map<String, dynamic>?;
    final tutor = j['tutor'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    return ParentLessonDto(
      lessonId: (j['lessonId'] ?? j['classSessionId']) as int? ?? 0,
      scheduledStart: j['scheduledStart'] as String? ?? '',
      scheduledEnd: j['scheduledEnd'] as String? ?? '',
      studentId: (j['studentId'] ?? student?['studentId']) as String?,
      studentName: (j['studentName'] ?? student?['fullName']) as String?,
      tutorId: (j['tutorId'] ?? tutor?['tutorId']) as String?,
      tutorName: (j['tutorName'] ?? tutor?['fullName']) as String?,
      tutorAvatarUrl: (j['tutorAvatarUrl'] ?? tutor?['avatarUrl']) as String?,
      subjectName: (j['subjectName'] ?? subject?['subjectName']) as String?,
      status: j['status'] as String?,
      meetingLink: j['meetingLink'] as String?,
      confirmDeadline: j['confirmDeadline'] as String?,
      parentAckedAt: (j['parentAckedAt'] ?? j['parentAckAt']) as String?,
      bookingId: j['bookingId'] as int?,
      teachingMode: j['teachingMode'] as String?,
      lessonContent: j['classSessionContent'] as String?,
      homework: j['homework'] as String?,
      tutorNotes: j['tutorNotes'] as String?,
      requiresRemainingPayment: j['requiresRemainingPayment'] as bool? ?? false,
    );
  }

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

  // Chỉ có ở dạng detail (buổi đã có báo cáo).
  final String? lessonContent;
  final String? homework;
  final String? tutorNotes;
  final bool requiresRemainingPayment;

  bool get isPendingConfirm => status == 'completed' && parentAckedAt == null;

  /// Buổi giữ chỗ, chờ gia sư nhận lịch — phụ huynh đã trả cọc nên vẫn phải thấy.
  bool get isReserved => status == 'reserved';

  /// Buổi còn hiệu lực trên Home: bỏ buổi đã xong và mọi dạng huỷ.
  bool get isUpcoming => const {
    'scheduled',
    'reserved',
    'in_progress',
    'pending_confirmation',
  }.contains(status);

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
    this.depositAmount,
    this.remainingAmount,
    this.remainingPaidAt,
    this.escrowStatus,
    this.paymentCode,
    this.paymentDueAt,
  });

  factory ParentBookingDto.fromJson(Map<String, dynamic> j) {
    // Detail trả nested student/tutor/subject; list có thể phẳng.
    final student = j['student'] as Map<String, dynamic>?;
    final tutor = j['tutor'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    return ParentBookingDto(
      bookingId: j['bookingId'] as int? ?? 0,
      studentId: (j['studentId'] ?? student?['studentId']) as String?,
      studentName: (j['studentName'] ?? student?['fullName']) as String?,
      tutorId: (j['tutorId'] ?? tutor?['tutorId']) as String?,
      tutorName: (j['tutorName'] ?? tutor?['fullName']) as String?,
      tutorAvatarUrl: (j['tutorAvatarUrl'] ?? tutor?['avatarUrl']) as String?,
      subjectName: (j['subjectName'] ?? subject?['subjectName']) as String?,
      status: j['status'] as String?,
      paymentStatus: j['paymentStatus'] as String?,
      sessionCount: (j['sessionCount'] ?? j['totalSessions']) as int?,
      remainingSessions: j['remainingSessions'] as int?,
      startDate: j['startDate'] as String?,
      teachingMode: j['teachingMode'] as String?,
      finalPrice: (j['finalPrice'] as num?)?.toDouble(),
      depositAmount: (j['depositAmount'] as num?)?.toDouble(),
      remainingAmount: (j['remainingAmount'] as num?)?.toDouble(),
      remainingPaidAt: j['remainingPaidAt'] as String?,
      escrowStatus: j['escrowStatus'] as String?,
      paymentCode: j['paymentCode'] as String?,
      paymentDueAt: j['paymentDueAt'] as String?,
      schedule: (j['schedule'] as List<dynamic>?)
          ?.map((e) => ParentScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

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

  // Thanh toán (BookingResponse).
  final double? depositAmount;
  final double? remainingAmount;
  final String? remainingPaidAt;
  final String? escrowStatus;
  final String? paymentCode;
  final String? paymentDueAt;

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
