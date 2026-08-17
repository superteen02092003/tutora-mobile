// GET /api/tutor/class-sessions/dashboard → TutorDashboardStatsResponse
class TutorDashboardDto {
  const TutorDashboardDto({
    required this.upcomingSessions,
    required this.completedSessions,
    required this.monthlyEarnings,
    required this.averageRating,
    required this.totalReviews,
    required this.escrowBalance,
    required this.escrowSessions,
    required this.earnedPendingThisMonth,
    required this.upcomingEarnings,
    required this.upcomingSessionsThisMonth,
    required this.activeDisputes,
    required this.awaitingReport,
    required this.awaitingReportSessions,
    required this.todaySessions,
  });

  factory TutorDashboardDto.fromJson(Map<String, dynamic> json) {
    final c = json['content'] as Map<String, dynamic>? ?? json;
    // Backend TutorDashboardStatsResponse — tên field khác tên mobile cũ.
    final next = c['nextClassSessions'] as List<dynamic>? ?? [];
    return TutorDashboardDto(
      upcomingSessions: c['upcomingClassSessions'] as int? ?? 0,
      completedSessions: c['completedThisMonth'] as int? ?? 0,
      monthlyEarnings: (c['earningsThisMonth'] as num?)?.toDouble() ?? 0,
      averageRating: (c['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: c['totalReviews'] as int? ?? 0,
      // "Escrow" = số dư đang bị giữ; số buổi ~ số buổi chờ xác nhận.
      escrowBalance: (c['frozenBalance'] as num?)?.toDouble() ?? 0,
      escrowSessions: c['pendingConfirmation'] as int? ?? 0,
      earnedPendingThisMonth:
          (c['earnedPendingThisMonth'] as num?)?.toDouble() ?? 0,
      upcomingEarnings: (c['upcomingEarnings'] as num?)?.toDouble() ?? 0,
      upcomingSessionsThisMonth:
          c['upcomingClassSessionsThisMonth'] as int? ?? 0,
      activeDisputes: c['activeDisputes'] as int? ?? 0,
      awaitingReport: c['awaitingReport'] as int? ?? 0,
      awaitingReportSessions:
          (c['awaitingReportClassSessions'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(TutorAwaitingReportDto.fromJson)
              .toList(),
      todaySessions: next
          .whereType<Map<String, dynamic>>()
          .map(TutorTodaySessionDto.fromJson)
          .toList(),
    );
  }

  final int upcomingSessions;
  final int completedSessions;
  final double monthlyEarnings;
  final double averageRating;
  final int totalReviews;
  final double escrowBalance;
  final int escrowSessions;

  /// Tiền buổi đã dạy trong tháng nhưng chưa quyết toán
  final double earnedPendingThisMonth;

  /// Tiền các buổi đã lên lịch chưa dạy **trong tháng này** — chưa vào escrow,
  /// chỉ là dự kiến.
  final double upcomingEarnings;

  /// Số buổi ứng với [upcomingEarnings] — cùng kỳ, khác [upcomingSessions]
  final int upcomingSessionsThisMonth;

  /// Tranh chấp chưa đóng — tiền của buổi liên quan bị giữ tới khi giải quyết.
  final int activeDisputes;
  final int awaitingReport;
  final List<TutorAwaitingReportDto> awaitingReportSessions;
  final List<TutorTodaySessionDto> todaySessions;
}

/// Một buổi trên lịch — GET /api/tutor/class-sessions/calendar
class TutorWeekSessionDto {
  const TutorWeekSessionDto({
    required this.classSessionId,
    required this.bookingId,
    required this.studentName,
    required this.subjectName,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.checkOutTime,
  });

  factory TutorWeekSessionDto.fromJson(Map<String, dynamic> j) =>
      TutorWeekSessionDto(
        classSessionId: j['classSessionId'] as int? ?? 0,
        bookingId: j['bookingId'] as int?,
        studentName: j['studentName'] as String? ?? 'Học sinh',
        subjectName: j['subjectName'] as String? ?? '',
        scheduledStart: j['scheduledStart'] as String? ?? '',
        scheduledEnd: j['scheduledEnd'] as String? ?? '',
        status: j['status'] as String? ?? 'scheduled',
        checkOutTime: j['checkOutTime'] as String?,
      );

  final int classSessionId;
  final int? bookingId;
  final String studentName;
  final String subjectName;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final String? checkOutTime;

  /// BE trả UTC tuyệt đối → phải .toLocal() mới ra giờ người dùng thấy.
  DateTime? get startLocal => DateTime.tryParse(scheduledStart)?.toLocal();

  String get timeStart {
    final dt = startLocal;
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get isCompleted =>
      status == 'completed' || status == 'pending_confirmation';

  bool get isCancelled =>
      status == 'cancelled' ||
      status == 'no_show' ||
      status == 'cancelled_noshow';

  /// Đã rời phòng mà vẫn in_progress = đang chờ gia sư gửi báo cáo.
  bool get needsReport => status == 'in_progress' && checkOutTime != null;

  bool get isLive => status == 'in_progress' && checkOutTime == null;
}

/// Buổi đã dạy xong nhưng chưa gửi báo cáo — tiền đứng lại tới khi tutor gửi.
class TutorAwaitingReportDto {
  const TutorAwaitingReportDto({
    required this.classSessionId,
    required this.studentName,
    required this.subjectName,
    required this.scheduledStart,
    required this.checkOutTime,
    required this.price,
  });

  factory TutorAwaitingReportDto.fromJson(Map<String, dynamic> j) =>
      TutorAwaitingReportDto(
        classSessionId: j['classSessionId'] as int? ?? 0,
        studentName: j['studentName'] as String? ?? 'Học sinh',
        subjectName: j['subjectName'] as String? ?? '',
        scheduledStart: j['scheduledStart'] as String? ?? '',
        checkOutTime: j['checkOutTime'] as String? ?? '',
        price: (j['classSessionPrice'] as num?)?.toDouble() ?? 0,
      );

  final int classSessionId;
  final String studentName;
  final String subjectName;
  final String scheduledStart;
  final String checkOutTime;
  final double price;

  /// Nhãn "buổi này kết thúc bao lâu rồi" — đo mức trễ của báo cáo.
  String get sinceLabel {
    final ref = DateTime.tryParse(
      checkOutTime.isNotEmpty ? checkOutTime : scheduledStart,
    )?.toLocal();
    if (ref == null) return '';
    final diff = DateTime.now().difference(ref);
    if (diff.inMinutes < 60) return 'vừa xong';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}

class TutorTodaySessionDto {
  const TutorTodaySessionDto({
    required this.lessonId,
    required this.studentName,
    required this.subjectName,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
  });

  factory TutorTodaySessionDto.fromJson(Map<String, dynamic> j) =>
      TutorTodaySessionDto(
        lessonId: (j['classSessionId'] ?? j['lessonId']) as int? ?? 0,
        studentName: j['studentName'] as String? ?? 'Học sinh',
        subjectName: j['subjectName'] as String? ?? '',
        scheduledStart: j['scheduledStart'] as String? ?? '',
        scheduledEnd: j['scheduledEnd'] as String? ?? '',
        // UpcomingClassSessionResponse không có `status`; mặc định scheduled.
        status: j['status'] as String? ?? 'scheduled',
      );

  final int lessonId;
  final String studentName;
  final String subjectName;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;

  String get timeStart {
    if (scheduledStart.isEmpty) return '';
    final dt = DateTime.tryParse(scheduledStart);
    if (dt == null) return scheduledStart;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get timeEnd {
    if (scheduledEnd.isEmpty) return '';
    final dt = DateTime.tryParse(scheduledEnd);
    if (dt == null) return scheduledEnd;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get isUpcoming =>
      status.toLowerCase() == 'scheduled' ||
      status.toLowerCase() == 'confirmed';
}
