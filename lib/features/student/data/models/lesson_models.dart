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
    this.confirmDeadline,
    this.bookingId,
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
      confirmDeadline: j['confirmDeadline'] as String?,
      bookingId: j['bookingId'] as int?,
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

  /// Hạn xác nhận buổi đã hoàn tất (đếm ngược); null nếu chưa cần.
  final String? confirmDeadline;

  /// Id booking chứa buổi — điều hướng sang chi tiết gói.
  final int? bookingId;

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

  /// Phòng mở theo TRẠNG THÁI buổi học, không theo khung giờ (khớp BE).
  bool get canJoinNow =>
      statusType == LessonStatusType.scheduled ||
      statusType == LessonStatusType.inProgress;

  /// Đã tới sát giờ học (±15 phút) — chỉ để đổi nhãn nút, không chặn vào.
  bool get isWithinJoinWindow =>
      DateTime.now().isAfter(startDt.subtract(const Duration(minutes: 15)));

  LessonStatusType get statusType => switch (status.toLowerCase()) {
    'reserved' => LessonStatusType.reserved,
    'scheduled' => LessonStatusType.scheduled,
    'in_progress' => LessonStatusType.inProgress,
    'pending_confirmation' => LessonStatusType.pending,
    'completed' => LessonStatusType.done,
    'cancelled' || 'no_show' => LessonStatusType.cancelled,
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
    super.confirmDeadline,
    super.bookingId,
    this.tutorAvatarUrl,
    this.lessonContent,
    this.homework,
    this.tutorNotes,
    this.report,
    this.isTutorPresent,
    this.isStudentPresent,
    this.requiresRemainingPayment = false,
    this.bookingStatus,
    this.isSettled,
    this.checkinTime,
    this.checkoutTime,
    this.pendingReschedule,
    this.rescheduleProposals = const [],
  });

  factory StudentLessonDetailDto.fromJson(Map<String, dynamic> j) {
    final reportRaw = j['report'] as Map<String, dynamic>?;
    final pendingRaw = j['pendingRescheduleProposal'] as Map<String, dynamic>?;
    final proposalsRaw = j['rescheduleProposals'] as List<dynamic>? ?? const [];
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
      confirmDeadline: j['confirmDeadline'] as String?,
      bookingId: j['bookingId'] as int?,
      bookingStatus: j['bookingStatus'] as String?,
      isSettled: j['isSettled'] as bool?,
      checkinTime: (j['checkinTime'] ?? j['checkInTime']) as String?,
      checkoutTime: (j['checkoutTime'] ?? j['checkOutTime']) as String?,
      lessonContent:
          (reportRaw?['topicsCovered'] ?? j['lessonContent']) as String?,
      homework: reportRaw?['homeworkAssigned'] as String?,
      tutorNotes: reportRaw?['tutorNotes'] as String?,
      isTutorPresent: j['isTutorPresent'] as bool?,
      isStudentPresent: j['isStudentPresent'] as bool?,
      requiresRemainingPayment: j['requiresRemainingPayment'] as bool? ?? false,
      report: reportRaw != null ? LessonReportDto.fromJson(reportRaw) : null,
      pendingReschedule: pendingRaw != null
          ? RescheduleProposalDto.fromJson(pendingRaw)
          : null,
      rescheduleProposals: proposalsRaw
          .map((e) => RescheduleProposalDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? tutorAvatarUrl;
  final String? lessonContent;
  final String? homework;
  final String? tutorNotes;
  final bool? isTutorPresent;
  final bool? isStudentPresent;

  /// Buổi tiếp theo bị khóa do phụ huynh chưa thanh toán các buổi còn lại.
  final bool requiresRemainingPayment;
  final LessonReportDto? report;

  /// Trạng thái của lớp (booking) chứa buổi này.
  final String? bookingStatus;

  /// Buổi đã được quyết toán (tiền đã chuyển cho gia sư).
  final bool? isSettled;

  final String? checkinTime;
  final String? checkoutTime;

  /// Đề xuất đổi lịch đang chờ phản hồi (gia sư gửi, hoặc chính học sinh gửi).
  final RescheduleProposalDto? pendingReschedule;

  /// Toàn bộ lịch sử đề xuất đổi lịch, mới nhất trước.
  final List<RescheduleProposalDto> rescheduleProposals;

  DateTime? get checkinDt =>
      checkinTime == null ? null : DateTime.tryParse(checkinTime!)?.toLocal();
  DateTime? get checkoutDt =>
      checkoutTime == null ? null : DateTime.tryParse(checkoutTime!)?.toLocal();

  /// Thời lượng học thực tế (phút) nếu đã có cả check-in lẫn check-out.
  int? get actualMinutes {
    final inAt = checkinDt;
    final outAt = checkoutDt;
    if (inAt == null || outAt == null) return null;
    final mins = outAt.difference(inAt).inMinutes;
    return mins > 0 ? mins : null;
  }

  DateTime? get confirmDeadlineDt => confirmDeadline == null
      ? null
      : DateTime.tryParse(confirmDeadline!)?.toLocal();

  /// BE chặn đề xuất đổi lịch khi còn dưới 2 giờ trước giờ học đã đặt
  /// (ClassSessionRescheduleProposalService.MinHoursBeforeOriginalStart).
  /// Giữ khớp với `kRescheduleCutoff` ở shared/widgets/reschedule_sheet.dart.
  static const rescheduleCutoff = Duration(hours: 2);

  /// Có được đề xuất đổi lịch buổi này không — khớp đúng ràng buộc của BE để
  /// UI không mời gọi một hành động chắc chắn bị từ chối:
  ///  • buổi phải đang ở trạng thái `scheduled` (đã học/đang học/hủy đều không)
  ///  • còn tối thiểu 2 giờ trước giờ bắt đầu
  ///  • chưa có đề xuất nào đang chờ phản hồi
  bool get canProposeReschedule =>
      statusType == LessonStatusType.scheduled &&
      DateTime.now().isBefore(startDt.subtract(rescheduleCutoff)) &&
      !(pendingReschedule?.isPending ?? false);

  /// Lý do không đổi lịch được, để hiện cho học sinh thay vì im lặng ẩn nút.
  String? get rescheduleBlockReason {
    if (canProposeReschedule) return null;
    if (pendingReschedule?.isPending ?? false) {
      return 'Buổi học đang có một đề xuất đổi lịch chờ phản hồi.';
    }
    if (statusType != LessonStatusType.scheduled) {
      return 'Buổi học đã diễn ra hoặc đã kết thúc nên không đổi lịch được.';
    }
    return 'Chỉ đổi lịch được khi còn tối thiểu 2 giờ trước giờ học.';
  }
}

/// Đề xuất đổi lịch một buổi học (POST reschedule-proposal).
class RescheduleProposalDto {
  const RescheduleProposalDto({
    required this.rescheduleProposalId,
    required this.classSessionId,
    required this.status,
    required this.originalStart,
    required this.proposedStart,
    required this.proposedEnd,
    this.proposedByRole,
    this.proposedByName,
    this.reason,
    this.expiresAt,
  });

  factory RescheduleProposalDto.fromJson(Map<String, dynamic> j) =>
      RescheduleProposalDto(
        rescheduleProposalId: (j['rescheduleProposalId'] as num?)?.toInt() ?? 0,
        classSessionId: (j['classSessionId'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? '',
        originalStart: j['originalScheduledStart'] as String? ?? '',
        proposedStart: j['proposedScheduledStart'] as String? ?? '',
        proposedEnd: j['proposedScheduledEnd'] as String? ?? '',
        proposedByRole: j['proposedByRole'] as String?,
        proposedByName: j['proposedByName'] as String?,
        reason: j['reason'] as String?,
        expiresAt: j['expiresAt'] as String?,
      );

  final int rescheduleProposalId;
  final int classSessionId;
  final String status;
  final String originalStart;
  final String proposedStart;
  final String proposedEnd;
  final String? proposedByRole;
  final String? proposedByName;
  final String? reason;
  final String? expiresAt;

  DateTime? get proposedStartDt => DateTime.tryParse(proposedStart)?.toLocal();
  DateTime? get proposedEndDt => DateTime.tryParse(proposedEnd)?.toLocal();
  DateTime? get originalStartDt => DateTime.tryParse(originalStart)?.toLocal();
  DateTime? get expiresAtDt =>
      expiresAt == null ? null : DateTime.tryParse(expiresAt!)?.toLocal();

  bool get isPending => status.toLowerCase() == 'pending';

  /// Đề xuất do gia sư gửi → học sinh là bên phải phản hồi.
  bool get fromTutor => (proposedByRole ?? '').toLowerCase() == 'tutor';
}

/// Trạng thái bản ghi video buổi học (GET /class-sessions/{id}/recording).
class LessonRecordingDto {
  const LessonRecordingDto({
    required this.status,
    required this.available,
    this.streamUrl,
  });

  factory LessonRecordingDto.fromJson(Map<String, dynamic> j) =>
      LessonRecordingDto(
        status: j['status'] as String? ?? 'none',
        available: j['available'] as bool? ?? false,
        streamUrl: j['streamUrl'] as String?,
      );

  /// available | processing | recording | failed | none
  final String status;
  final bool available;
  final String? streamUrl;
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

enum LessonStatusType {
  /// Buổi 2..N chờ phụ huynh trả nốt phần còn lại mới được kích hoạt.
  reserved,
  scheduled,
  inProgress,
  pending,
  done,
  cancelled,
}
