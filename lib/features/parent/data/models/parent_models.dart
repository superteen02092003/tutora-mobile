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

  /// Chờ phụ huynh xác nhận.
  bool get isPendingConfirm =>
      status == 'pending_confirmation' && parentAckedAt == null;

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
    this.depositPaidAt,
    this.remainingPaidAt,
    this.escrowStatus,
    this.paymentCode,
    this.paymentDueAt,
    this.responseDeadline,
    this.createdAt,
    this.totalAmount,
    this.discountApplied,
    this.cancellationReason,
    this.cancelledBy,
    this.refundAmount,
    this.refundStatus,
    this.sessions = const [],
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
      depositPaidAt: j['depositPaidAt'] as String?,
      remainingPaidAt: j['remainingPaidAt'] as String?,
      escrowStatus: j['escrowStatus'] as String?,
      paymentCode: j['paymentCode'] as String?,
      paymentDueAt: j['paymentDueAt'] as String?,
      responseDeadline: j['responseDeadline'] as String?,
      createdAt: j['createdAt'] as String?,
      totalAmount: (j['totalAmount'] as num?)?.toDouble(),
      discountApplied: (j['discountApplied'] as num?)?.toDouble(),
      cancellationReason: j['cancellationReason'] as String?,
      cancelledBy: j['cancelledBy'] as String?,
      refundAmount: (j['refundAmount'] as num?)?.toDouble(),
      refundStatus: j['refundStatus'] as String?,
      schedule: (j['schedule'] as List<dynamic>?)
          ?.map((e) => ParentScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      sessions:
          (j['classSessions'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (e) => ParentBookingSession.fromJson(e as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => a.sessionIndex.compareTo(b.sessionIndex)),
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
  final String? depositPaidAt;
  final String? remainingPaidAt;
  final String? escrowStatus;
  final String? paymentCode;

  /// Hạn của đợt đang chờ trả
  final String? paymentDueAt;

  /// Hạn gia sư phải nhận/từ chối lớp.
  final String? responseDeadline;
  final String? createdAt;
  final double? totalAmount;
  final double? discountApplied;
  final String? cancellationReason;
  final String? cancelledBy;
  final double? refundAmount;
  final String? refundStatus;

  /// Các buổi của lớp, đã sắp theo sessionIndex.
  final List<ParentBookingSession> sessions;

  String get _s => (status ?? '').toLowerCase();

  /// Chờ trả phí buổi đầu
  bool get needsDeposit => _s == 'pending_payment' || _s == 'accepted';

  /// Chờ gia sư nhận lớp.
  bool get isPendingTutor => _s == 'pending_tutor';

  /// Cần trả nốt phần còn lại
  bool get needsRemaining =>
      remainingPaidAt == null && _s == 'pending_remaining_payment';

  bool get isLearning =>
      _s == 'deposit_paid' || _s == 'paid' || _s == 'ongoing';
  bool get isCompleted => _s == 'completed' || _s == 'closed';
  bool get isClosed =>
      _s == 'cancelled' || _s == 'cancelled_noshow' || _s == 'payment_timeout';

  /// Có việc phụ huynh phải trả tiền ngay.
  bool get needsPayment => needsDeposit || needsRemaining;

  /// Số tiền của đợt đang chờ trả.
  double? get amountDue => needsDeposit ? depositAmount : remainingAmount;

  DateTime? get createdAtDt =>
      createdAt == null ? null : DateTime.tryParse(createdAt!)?.toLocal();
  DateTime? get dueAtDt =>
      paymentDueAt == null ? null : DateTime.tryParse(paymentDueAt!)?.toLocal();
  DateTime? get startDateDt =>
      startDate == null ? null : DateTime.tryParse(startDate!)?.toLocal();

  int get doneSessions => sessions.where((s) => s.isFinished).length;
  int get totalSessionCount => sessionCount ?? sessions.length;
}

/// Thông tin chuyển khoản của đợt đang chờ trả (GET /bookings/{id}/payment).
class ParentPaymentInfo {
  const ParentPaymentInfo({
    required this.amount,
    this.paymentPhase,
    this.qrCode,
    this.accountNumber,
    this.accountName,
    this.bin,
    this.description,
    this.expiredAt,
    this.canPayWithWallet = false,
    this.walletBalance = 0,
  });

  factory ParentPaymentInfo.fromJson(Map<String, dynamic> j) =>
      ParentPaymentInfo(
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        paymentPhase: j['paymentPhase'] as String?,
        qrCode: j['qrCode'] as String?,
        accountNumber: j['accountNumber'] as String?,
        accountName: j['accountName'] as String?,
        bin: j['bin'] as String?,
        description: j['description'] as String?,
        expiredAt: j['expiredAt'] as String?,
        canPayWithWallet: j['canPayWithWallet'] as bool? ?? false,
        walletBalance: (j['walletBalance'] as num?)?.toDouble() ?? 0,
      );

  final double amount;

  /// `deposit` | `remaining`.
  final String? paymentPhase;
  final String? qrCode;
  final String? accountNumber;
  final String? accountName;
  final String? bin;
  final String? description;
  final String? expiredAt;
  final bool canPayWithWallet;
  final double walletBalance;

  bool get isDeposit => paymentPhase == 'deposit';

  /// Ảnh QR dựng từ số tài khoản; `qrCode` của PayOS là chuỗi EMV nên không
  /// hiển thị trực tiếp được.
  String? get vietQrImageUrl {
    if (bin == null || accountNumber == null) return null;
    final q = <String>[
      'amount=${amount.round()}',
      if (description?.isNotEmpty ?? false)
        'addInfo=${Uri.encodeComponent(description!)}',
      if (accountName?.isNotEmpty ?? false)
        'accountName=${Uri.encodeComponent(accountName!)}',
    ].join('&');
    return 'https://img.vietqr.io/image/$bin-$accountNumber-compact2.png?$q';
  }

  DateTime? get expiredAtDt =>
      expiredAt == null ? null : DateTime.tryParse(expiredAt!)?.toLocal();
}

/// Kết quả đối soát (GET /bookings/{id}/payment/status).
class ParentPaymentStatus {
  const ParentPaymentStatus({
    this.isPaid = false,
    this.isDepositPaid = false,
    this.isRemainingPaid = false,
    this.isExpired = false,
  });

  factory ParentPaymentStatus.fromJson(Map<String, dynamic> j) =>
      ParentPaymentStatus(
        isPaid: j['isPaid'] as bool? ?? false,
        isDepositPaid: j['isDepositPaid'] as bool? ?? false,
        isRemainingPaid: j['isRemainingPaid'] as bool? ?? false,
        isExpired: j['isExpired'] as bool? ?? false,
      );

  final bool isPaid;
  final bool isDepositPaid;
  final bool isRemainingPaid;
  final bool isExpired;

  bool settledFor({required bool deposit}) =>
      isPaid || (deposit ? isDepositPaid : isRemainingPaid);
}

/// Một trang đơn đặt lịch — giữ lại metadata phân trang của BE để cuộn vô hạn.
class ParentBookingPage {
  const ParentBookingPage({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory ParentBookingPage.fromJson(Map<String, dynamic> j) {
    final content = j['content'];
    // BE trả object có metadata; chấp nhận cả dạng list phẳng cho chắc.
    if (content is List) {
      final items = content
          .map((e) => ParentBookingDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return ParentBookingPage(
        items: items,
        totalCount: items.length,
        currentPage: 1,
        totalPages: 1,
      );
    }
    final map = content as Map<String, dynamic>? ?? const {};
    final raw = map['items'] as List<dynamic>? ?? const [];
    return ParentBookingPage(
      items: raw
          .map((e) => ParentBookingDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (map['totalCount'] as num?)?.toInt() ?? raw.length,
      currentPage: (map['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  final List<ParentBookingDto> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  bool get hasMore => currentPage < totalPages;
}

/// Một buổi trong lớp — BE trả trong `classSessions` của BookingResponse.
class ParentBookingSession {
  const ParentBookingSession({
    required this.classSessionId,
    required this.sessionIndex,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.price,
  });

  factory ParentBookingSession.fromJson(Map<String, dynamic> j) =>
      ParentBookingSession(
        classSessionId: (j['classSessionId'] as num?)?.toInt() ?? 0,
        sessionIndex: (j['sessionIndex'] as num?)?.toInt() ?? 0,
        scheduledStart: j['scheduledStart'] as String? ?? '',
        scheduledEnd: j['scheduledEnd'] as String? ?? '',
        status: j['status'] as String? ?? '',
        price: (j['classSessionPrice'] as num?)?.toDouble(),
      );

  final int classSessionId;
  final int sessionIndex;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final double? price;

  DateTime get startDt =>
      DateTime.tryParse(scheduledStart)?.toLocal() ?? DateTime(2000);
  DateTime get endDt => DateTime.tryParse(scheduledEnd)?.toLocal() ?? startDt;

  bool get isFinished =>
      status == 'completed' || status == 'pending_confirmation';

  /// Buổi giữ chỗ, chưa mở vì chưa trả đủ tiền.
  bool get isLocked => status == 'reserved';
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
