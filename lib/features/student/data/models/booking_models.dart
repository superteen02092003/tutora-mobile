class ScheduleSlotDto {
  const ScheduleSlotDto({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleSlotDto.fromJson(Map<String, dynamic> j) => ScheduleSlotDto(
    dayOfWeek: j['dayOfWeek'] as int,
    startTime: j['startTime'] as String,
    endTime: j['endTime'] as String,
  );

  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}

/// One concrete dated session for a flexible booking, sent as absolute
class FlexibleSlotDto {
  const FlexibleSlotDto({
    required this.scheduledStart,
    required this.scheduledEnd,
  });

  final String scheduledStart;
  final String scheduledEnd;

  Map<String, dynamic> toJson() => {
    'scheduledStart': scheduledStart,
    'scheduledEnd': scheduledEnd,
  };
}

class CreateBookingRequest {
  const CreateBookingRequest({
    required this.studentId,
    required this.tutorId,
    required this.subjectId,
    required this.tutorSubjectGradePriceId,
    required this.packageId,
    required this.startDate,
    this.teachingMode = 'online',
    this.totalSessions,
    this.flexibleSlots,
    this.locationCity,
    this.locationDistrict,
    this.locationWard,
    this.locationDetail,
    this.promotionCode,
  });

  final String studentId;
  final String tutorId;
  final int subjectId;
  final int tutorSubjectGradePriceId;

  final int packageId;
  final String startDate;
  final String teachingMode;
  final int? totalSessions;

  /// Concrete dated sessions (flexible mode only).
  final List<FlexibleSlotDto>? flexibleSlots;
  final String? locationCity;
  final String? locationDistrict;
  final String? locationWard;
  final String? locationDetail;
  final String? promotionCode;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'tutorId': tutorId,
      'tutorSubjectGradePriceId': tutorSubjectGradePriceId,
      'packageId': packageId,
      'startDate': startDate,
    };
    if (studentId.isNotEmpty) m['studentId'] = studentId;
    if (subjectId != 0) m['subjectId'] = subjectId;
    if (totalSessions != null) m['totalSessions'] = totalSessions;
    if (flexibleSlots != null && flexibleSlots!.isNotEmpty) {
      m['flexibleSlots'] = flexibleSlots!.map((s) => s.toJson()).toList();
    }
    if (locationCity?.isNotEmpty ?? false) m['locationCity'] = locationCity;
    if (locationDistrict?.isNotEmpty ?? false) {
      m['locationDistrict'] = locationDistrict;
    }
    if (locationWard?.isNotEmpty ?? false) m['locationWard'] = locationWard;
    if (locationDetail?.isNotEmpty ?? false) {
      m['locationDetail'] = locationDetail;
    }
    if (promotionCode?.isNotEmpty ?? false) m['promotionCode'] = promotionCode;
    return m;
  }
}

class CreateBookingResponse {
  const CreateBookingResponse({this.bookingId});

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? json;
    return CreateBookingResponse(
      bookingId: content['bookingId'] as int?,
    );
  }

  final int? bookingId;
}

// Booking detail

class BookingDetailDto {
  const BookingDetailDto({
    required this.bookingId,
    required this.status,
    required this.paymentStatus,
    required this.price,
    required this.finalPrice,
    required this.platformFee,
    required this.discountApplied,
    required this.sessionCount,
    required this.teachingMode,
    required this.createdAt,
    this.tutorName,
    this.tutorAvatarUrl,
    this.tutorHourlyRate,
    this.subjectName,
    this.packageType,
    this.startDate,
    this.paymentDueAt,
    this.depositPaidAt,
    this.remainingPaidAt,
    this.cancelledAt,
    this.depositAmount,
    this.remainingAmount,
    this.paymentCode,
    this.escrowStatus,
    this.refundAmount,
    this.refundStatus,
    this.cancellationReason,
    this.cancelledBy,
    this.schedule = const [],
  });

  factory BookingDetailDto.fromJson(Map<String, dynamic> j) {
    final tutor = j['tutor'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    final rawSchedule = j['schedule'] as List<dynamic>? ?? [];
    return BookingDetailDto(
      bookingId: j['bookingId'] as int,
      status: j['status'] as String? ?? '',
      paymentStatus: j['paymentStatus'] as String? ?? '',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      finalPrice: (j['finalPrice'] as num?)?.toDouble() ?? 0,
      platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0,
      discountApplied: (j['discountApplied'] as num?)?.toDouble() ?? 0,
      sessionCount: j['sessionCount'] as int? ?? 0,
      teachingMode: j['teachingMode'] as String? ?? '',
      createdAt: j['createdAt'] as String? ?? '',
      tutorName: tutor?['fullName'] as String?,
      tutorAvatarUrl: tutor?['avatarUrl'] as String?,
      tutorHourlyRate: (tutor?['hourlyRate'] as num?)?.toDouble(),
      subjectName: subject?['subjectName'] as String?,
      packageType: (j['packageType'] as num?)?.toInt(),
      startDate: j['startDate'] as String?,
      paymentDueAt: j['paymentDueAt'] as String?,
      depositPaidAt: j['depositPaidAt'] as String?,
      remainingPaidAt: j['remainingPaidAt'] as String?,
      cancelledAt: j['cancelledAt'] as String?,
      depositAmount: (j['depositAmount'] as num?)?.toDouble(),
      remainingAmount: (j['remainingAmount'] as num?)?.toDouble(),
      paymentCode: j['paymentCode'] as String?,
      escrowStatus: j['escrowStatus'] as String?,
      refundAmount: (j['refundAmount'] as num?)?.toDouble(),
      refundStatus: j['refundStatus'] as String?,
      cancellationReason: j['cancellationReason'] as String?,
      cancelledBy: j['cancelledBy'] as String?,
      schedule: rawSchedule
          .map((e) => ScheduleSlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int bookingId;
  final String status;
  final String paymentStatus;
  final double price;
  final double finalPrice;
  final double platformFee;
  final double discountApplied;
  final int sessionCount;
  final String teachingMode;
  final String createdAt;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final double? tutorHourlyRate;
  final String? subjectName;
  final int? packageType;
  final String? startDate;
  final String? paymentDueAt;
  final String? depositPaidAt;
  final String? remainingPaidAt;
  final String? cancelledAt;

  DateTime? get depositPaidDt =>
      DateTime.tryParse(depositPaidAt ?? '')?.toLocal();
  DateTime? get remainingPaidDt =>
      DateTime.tryParse(remainingPaidAt ?? '')?.toLocal();
  DateTime? get cancelledDt => DateTime.tryParse(cancelledAt ?? '')?.toLocal();
  final double? depositAmount;
  final double? remainingAmount;
  final String? paymentCode;
  final String? escrowStatus;
  final double? refundAmount;
  final String? refundStatus;
  final String? cancellationReason;
  final String? cancelledBy;
  final List<ScheduleSlotDto> schedule;

  DateTime get createdAtDt =>
      DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();

  BookingStatusType get statusType => switch (status.toLowerCase()) {
    'pending_payment' || 'accepted' => BookingStatusType.pendingDeposit,
    'pending_tutor' => BookingStatusType.pendingTutor,
    'deposit_paid' => BookingStatusType.depositPaid,
    'pending_remaining_payment' => BookingStatusType.pendingRemaining,
    'paid' || 'ongoing' || 'active' => BookingStatusType.active,
    'completed' || 'closed' => BookingStatusType.completed,
    'cancelled' ||
    'cancelled_noshow' ||
    'refunded' => BookingStatusType.cancelled,
    'payment_timeout' => BookingStatusType.paymentTimeout,
    _ => BookingStatusType.pendingDeposit,
  };

  bool get canCancel => const {
    'pending_tutor',
    'accepted',
    'pending_payment',
    'deposit_paid',
    'active',
  }.contains(status);

  /// Buổi đầu đã xong, cần trả nốt để mở các buổi còn lại.
  bool get needsRemainingPayment =>
      status.toLowerCase() == 'pending_remaining_payment';

  /// Có nút thao tác ở cuối màn hình hay không.
  bool get hasBottomAction => canCancel || needsRemainingPayment;
}

// Booking list

class StudentBookingDto {
  const StudentBookingDto({
    required this.bookingId,
    required this.status,
    required this.paymentStatus,
    required this.finalPrice,
    required this.createdAt,
    this.tutorName,
    this.tutorAvatarUrl,
    this.subjectName,
    this.teachingMode,
    this.sessionCount,
    this.startDate,
    this.schedule,
  });

  factory StudentBookingDto.fromJson(Map<String, dynamic> j) {
    final tutor = j['tutor'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    final rawSchedule = j['schedule'] as List<dynamic>?;
    return StudentBookingDto(
      bookingId: j['bookingId'] as int,
      status: j['status'] as String? ?? '',
      paymentStatus: j['paymentStatus'] as String? ?? '',
      finalPrice: (j['finalPrice'] as num?)?.toDouble() ?? 0,
      createdAt: j['createdAt'] as String? ?? '',
      tutorName: tutor?['fullName'] as String?,
      tutorAvatarUrl: tutor?['avatarUrl'] as String?,
      subjectName: subject?['subjectName'] as String?,
      teachingMode: j['teachingMode'] as String?,
      sessionCount: j['sessionCount'] as int?,
      startDate: j['startDate'] as String?,
      schedule: rawSchedule
          ?.map((e) => ScheduleSlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int bookingId;
  final String status;
  final String paymentStatus;
  final double finalPrice;
  final String createdAt;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final String? subjectName;
  final String? teachingMode;
  final int? sessionCount;
  final String? startDate;
  final List<ScheduleSlotDto>? schedule;

  DateTime get createdAtDt =>
      DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now();

  BookingStatusType get statusType => switch (status.toLowerCase()) {
    'pending_payment' || 'accepted' => BookingStatusType.pendingDeposit,
    'pending_tutor' => BookingStatusType.pendingTutor,
    'deposit_paid' => BookingStatusType.depositPaid,
    'pending_remaining_payment' => BookingStatusType.pendingRemaining,
    'paid' || 'ongoing' || 'active' => BookingStatusType.active,
    'completed' || 'closed' => BookingStatusType.completed,
    'cancelled' ||
    'cancelled_noshow' ||
    'refunded' => BookingStatusType.cancelled,
    'payment_timeout' => BookingStatusType.paymentTimeout,
    _ => BookingStatusType.pendingDeposit,
  };
}

/// Theo đúng luồng BE: pending_payment → (trả cọc) → pending_tutor →
/// deposit_paid → ongoing → pending_remaining_payment → completed.
enum BookingStatusType {
  pendingDeposit,
  pendingTutor,
  depositPaid,
  active,
  pendingRemaining,
  completed,
  cancelled,
  paymentTimeout,
}

class StudentBookingPagedResult {
  const StudentBookingPagedResult({
    required this.items,
    required this.totalCount,
  });

  factory StudentBookingPagedResult.fromJson(Map<String, dynamic> j) {
    final content = j['content'] as Map<String, dynamic>? ?? j;
    final rawItems = content['items'] as List<dynamic>? ?? [];
    return StudentBookingPagedResult(
      items: rawItems
          .map((e) => StudentBookingDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: content['totalCount'] as int? ?? rawItems.length,
    );
  }

  final List<StudentBookingDto> items;
  final int totalCount;
}

class StudentSummaryDto {
  const StudentSummaryDto({
    required this.studentId,
    required this.fullName,
    this.gradeLevel,
    this.school,
    this.avatarUrl,
  });

  factory StudentSummaryDto.fromJson(Map<String, dynamic> json) =>
      StudentSummaryDto(
        studentId: json['studentId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        gradeLevel: json['gradeLevel'] as String?,
        school: json['school'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  final String studentId;
  final String fullName;
  final String? gradeLevel;
  final String? school;
  final String? avatarUrl;

  String get displayGrade => gradeLevel ?? school ?? '';
}
