/// Model yêu cầu đặt lịch phía gia sư.
///
/// Backend: `GET /api/tutors/bookings` trả envelope `content` là object
/// `{ items, totalCount, currentPage, totalPages, pageSize }` — khác với
/// `/tutor/disputes` (trả mảng trần). Đừng gộp cách parse của hai bên.
library;

/// Trạng thái booking — khớp `BookingStatus` của backend.
enum TutorBookingStatus {
  pendingTutor,
  accepted,
  pendingPayment,
  depositPaid,
  pendingRemainingPayment,
  paid,
  paymentTimeout,
  ongoing,
  completed,
  cancelled,
  cancelledNoshow,
  unknown
  ;

  static TutorBookingStatus parse(String? raw) => switch (raw?.toLowerCase()) {
    'pending_tutor' => TutorBookingStatus.pendingTutor,
    'accepted' => TutorBookingStatus.accepted,
    'pending_payment' => TutorBookingStatus.pendingPayment,
    'deposit_paid' => TutorBookingStatus.depositPaid,
    'pending_remaining_payment' => TutorBookingStatus.pendingRemainingPayment,
    'paid' => TutorBookingStatus.paid,
    'payment_timeout' => TutorBookingStatus.paymentTimeout,
    'ongoing' => TutorBookingStatus.ongoing,
    'completed' => TutorBookingStatus.completed,
    'cancelled' => TutorBookingStatus.cancelled,
    'cancelled_noshow' => TutorBookingStatus.cancelledNoshow,
    _ => TutorBookingStatus.unknown,
  };

  String get label => switch (this) {
    TutorBookingStatus.pendingTutor => 'Chờ bạn phản hồi',
    TutorBookingStatus.accepted => 'Đã nhận',
    TutorBookingStatus.pendingPayment => 'Chờ thanh toán',
    TutorBookingStatus.depositPaid => 'Đã trả phí buổi đầu',
    TutorBookingStatus.pendingRemainingPayment => 'Chờ trả phần còn lại',
    TutorBookingStatus.paid => 'Đã thanh toán',
    TutorBookingStatus.paymentTimeout => 'Quá hạn thanh toán',
    TutorBookingStatus.ongoing => 'Đang diễn ra',
    TutorBookingStatus.completed => 'Hoàn thành',
    TutorBookingStatus.cancelled => 'Đã huỷ',
    TutorBookingStatus.cancelledNoshow => 'Huỷ do vắng mặt',
    TutorBookingStatus.unknown => 'Không xác định',
  };

  /// Đang chờ gia sư bấm nhận hoặc từ chối.
  bool get needsDecision => this == TutorBookingStatus.pendingTutor;
}

/// Một buổi trong lịch học của booking.
class BookingScheduleItem {
  const BookingScheduleItem({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory BookingScheduleItem.fromJson(Map<String, dynamic> j) =>
      BookingScheduleItem(
        dayOfWeek: j['dayOfWeek'] as int? ?? 0,
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
      );

  /// 0 = Chủ nhật, theo `DayOfWeek` của .NET.
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  static const _names = [
    'Chủ nhật',
    'Thứ hai',
    'Thứ ba',
    'Thứ tư',
    'Thứ năm',
    'Thứ sáu',
    'Thứ bảy',
  ];

  String get dayLabel =>
      dayOfWeek >= 0 && dayOfWeek < _names.length ? _names[dayOfWeek] : '';

  /// "Thứ tư · 19:00–20:30" — cắt giây nếu backend trả "19:00:00".
  String get label {
    String trim(String t) {
      final parts = t.split(':');
      return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : t;
    }

    if (startTime.isEmpty) return dayLabel;
    return '$dayLabel · ${trim(startTime)}–${trim(endTime)}';
  }
}

/// Yêu cầu đặt lịch gửi tới gia sư.
class TutorBookingDto {
  const TutorBookingDto({
    required this.bookingId,
    required this.studentName,
    required this.gradeLevelName,
    required this.subjectName,
    required this.status,
    required this.totalSessions,
    required this.durationMinutes,
    required this.tutorReceivable,
    required this.pricePerHour,
    required this.schedule,
    required this.startDate,
    required this.createdAt,
    required this.responseDeadline,
  });

  factory TutorBookingDto.fromJson(Map<String, dynamic> j) {
    final student = j['student'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    final grade = j['gradeLevel'] as Map<String, dynamic>?;

    return TutorBookingDto(
      bookingId: j['bookingId'] as int? ?? 0,
      studentName: student?['fullName'] as String? ?? 'Học sinh',
      // BE dùng cả gradeLevelName lẫn gradeLevel ở StudentMiniResponse.
      gradeLevelName:
          grade?['gradeName'] as String? ??
          student?['gradeLevelName'] as String? ??
          student?['gradeLevel'] as String? ??
          '',
      subjectName: subject?['subjectName'] as String? ?? '',
      status: TutorBookingStatus.parse(j['status'] as String?),
      totalSessions:
          j['totalSessions'] as int? ?? j['sessionCount'] as int? ?? 0,
      durationMinutes: j['durationMinutesPerSession'] as int? ?? 0,
      // Số gia sư THỰC NHẬN sau phí nền tảng — không phải tổng phụ huynh trả.
      tutorReceivable: (j['tutorReceivable'] as num?)?.toDouble(),
      pricePerHour: (j['pricePerHour'] as num?)?.toDouble(),
      schedule:
          (j['schedule'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BookingScheduleItem.fromJson)
              .toList() ??
          const [],
      startDate: DateTime.tryParse(j['startDate'] as String? ?? ''),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      responseDeadline: DateTime.tryParse(
        j['responseDeadline'] as String? ?? '',
      ),
    );
  }

  final int bookingId;
  final String studentName;
  final String gradeLevelName;
  final String subjectName;
  final TutorBookingStatus status;
  final int totalSessions;
  final int durationMinutes;
  final double? tutorReceivable;
  final double? pricePerHour;
  final List<BookingScheduleItem> schedule;
  final DateTime? startDate;
  final DateTime? createdAt;

  /// Hạn 24h để nhận/từ chối. Backend trả UTC.
  final DateTime? responseDeadline;

  /// Còn phải quyết định và chưa quá hạn.
  bool get isActionable {
    if (!status.needsDecision) return false;
    final deadline = responseDeadline;
    return deadline == null || DateTime.now().toUtc().isBefore(deadline);
  }

  /// Đã quá hạn phản hồi — backend sẽ tự huỷ, gia sư không bấm được nữa.
  bool get isExpired {
    if (!status.needsDecision) return false;
    final deadline = responseDeadline;
    return deadline != null && !DateTime.now().toUtc().isBefore(deadline);
  }

  /// Thời gian còn lại để phản hồi; null khi không có hạn.
  Duration? get timeLeft {
    final deadline = responseDeadline;
    if (deadline == null) return null;
    final left = deadline.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  /// "còn 5 giờ" / "còn 40 phút" — dùng ngay cạnh nút nhận.
  String? get timeLeftLabel {
    final left = timeLeft;
    if (left == null) return null;
    if (left == Duration.zero) return 'Đã quá hạn';
    if (left.inHours >= 1) return 'Còn ${left.inHours} giờ';
    if (left.inMinutes >= 1) return 'Còn ${left.inMinutes} phút';
    return 'Sắp hết hạn';
  }

  String get summaryLine {
    final parts = <String>[
      if (subjectName.isNotEmpty) subjectName,
      if (gradeLevelName.isNotEmpty) gradeLevelName,
    ];
    return parts.join(' · ');
  }

  String get sessionsLine {
    final parts = <String>[
      if (totalSessions > 0) '$totalSessions buổi',
      if (durationMinutes > 0) '$durationMinutes phút/buổi',
    ];
    return parts.join(' · ');
  }
}

/// Trang danh sách yêu cầu đặt lịch.
class TutorBookingPage {
  const TutorBookingPage({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory TutorBookingPage.fromJson(Map<String, dynamic> j) => TutorBookingPage(
    items:
        (j['items'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(TutorBookingDto.fromJson)
            .toList() ??
        const [],
    totalCount: j['totalCount'] as int? ?? 0,
    currentPage: j['currentPage'] as int? ?? 1,
    totalPages: j['totalPages'] as int? ?? 1,
  );

  final List<TutorBookingDto> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
}
