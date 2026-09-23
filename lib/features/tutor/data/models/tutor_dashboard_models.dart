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
    this.calendarDate,
    this.isContinuation = false,
    this.isDisputeRelearn = false,
    this.skipConfirmedByBothSides = false,
    this.hasPendingReschedule = false,
  });

  /// [calendarDate] là khoá ngày do BE gom sẵn — xem [TutorWeekSessionDto.calendarDate].
  factory TutorWeekSessionDto.fromJson(
    Map<String, dynamic> j, {
    DateTime? calendarDate,
  }) => TutorWeekSessionDto(
    calendarDate: calendarDate,
    classSessionId: j['classSessionId'] as int? ?? 0,
    bookingId: j['bookingId'] as int?,
    studentName: j['studentName'] as String? ?? 'Học sinh',
    subjectName: j['subjectName'] as String? ?? '',
    scheduledStart: j['scheduledStart'] as String? ?? '',
    scheduledEnd: j['scheduledEnd'] as String? ?? '',
    status: j['status'] as String? ?? 'scheduled',
    checkOutTime: j['checkOutTime'] as String?,
    isContinuation: j['isContinuation'] as bool? ?? false,
    isDisputeRelearn: j['isDisputeRelearn'] as bool? ?? false,
    skipConfirmedByBothSides: j['skipConfirmedByBothSides'] as bool? ?? false,
    hasPendingReschedule: j['hasPendingReschedule'] as bool? ?? false,
  );

  final int classSessionId;
  final int? bookingId;
  final String studentName;
  final String subjectName;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final String? checkOutTime;

  /// Ngày mà BE xếp buổi này vào, theo giờ VN.
  final DateTime? calendarDate;

  /// Buổi phụ học nốt phần bị ngắt của buổi gốc.
  final bool isContinuation;

  /// Buổi học lại do hoà giải tranh chấp.
  final bool isDisputeRelearn;

  /// Buổi phụ đã được hai phía đồng ý bỏ, không vào lớp được nữa.
  final bool skipConfirmedByBothSides;

  /// Có đề xuất đổi lịch đang chờ phản hồi.
  final bool hasPendingReschedule;

  /// BE trả UTC tuyệt đối → phải .toLocal() mới ra giờ người dùng thấy.
  DateTime? get startLocal => DateTime.tryParse(scheduledStart)?.toLocal();

  /// Ngày dùng để xếp buổi lên lịch: ưu tiên khoá ngày của BE, chỉ khi thiếu
  /// mới lùi về giờ hẹn.
  DateTime? get dayKey {
    final d = calendarDate ?? startLocal;
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  String get timeStart {
    final dt = startLocal;
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get isCompleted =>
      status == 'completed' || status == 'pending_confirmation';

  /// Buổi gốc bị báo ngắt giữa chừng — chưa xong.
  bool get isInterrupted => status == 'interrupted';

  bool get isCancelled =>
      status == 'cancelled' ||
      status == 'no_show' ||
      status == 'cancelled_noshow';

  /// Buổi đã tạo nhưng CHƯA mở
  bool get isReserved => status == 'reserved';

  /// Buổi đáng hiện trên lịch làm việc.
  bool get isActionable => !isCancelled && !isReserved;

  /// Đang chờ gia sư gửi báo cáo
  bool get needsReport =>
      (status == 'in_progress' && checkOutTime != null) || isInterrupted;

  bool get isLive =>
      status == 'in_progress' &&
      checkOutTime == null &&
      !skipConfirmedByBothSides;

  /// Nhãn cho buổi sinh thêm ngoài gói.
  /// đã có chip riêng, nhồi thêm chữ vào hàng ngang là tràn dòng.
  String? get linkLabel => isExtra ? 'Buổi học phụ' : null;

  /// Buổi sinh thêm ngoài gói: buổi phụ hoặc buổi học lại.
  bool get isExtra => isContinuation || isDisputeRelearn;
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
    this.recorderLessonId,
    this.recorderStatus,
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

  /// Có khi là buổi của học sinh ngoài nền tảng — ghi âm vào đúng buổi này.
  final String? recorderLessonId;

  /// Trạng thái gốc bên recorder (scheduled | recording | … | sent).
  final String? recorderStatus;

  bool get isOffPlatform => recorderLessonId != null;

  String get timeStart {
    if (scheduledStart.isEmpty) return '';
    // BE trả UTC → phải .toLocal(), không thì 07:30 hiện thành 00:30.
    final dt = DateTime.tryParse(scheduledStart)?.toLocal();
    if (dt == null) return scheduledStart;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get timeEnd {
    if (scheduledEnd.isEmpty) return '';
    final dt = DateTime.tryParse(scheduledEnd)?.toLocal();
    if (dt == null) return scheduledEnd;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get isUpcoming =>
      status.toLowerCase() == 'scheduled' ||
      status.toLowerCase() == 'confirmed';
}

/// `nextClassSessions` của BE là các buổi SẮP TỚI (mọi ngày), không phải buổi
/// hôm nay. Lọc lại: buổi bắt đầu trong hôm nay theo giờ máy, hoặc đang diễn ra.
List<TutorTodaySessionDto> sessionsToday(List<TutorTodaySessionDto> all) {
  final now = DateTime.now();
  return all.where((s) {
    final start = DateTime.tryParse(s.scheduledStart)?.toLocal();
    final end = DateTime.tryParse(s.scheduledEnd)?.toLocal();
    if (start == null) return false;
    final sameDay =
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final live = end != null && !start.isAfter(now) && end.isAfter(now);
    return sameDay || live;
  }).toList();
}
