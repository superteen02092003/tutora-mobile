enum LobbyPhase {
  connecting,
  waiting,
  ready,
  ended,
  unavailable,
  blockedPayment,
  error,
}

/// Thông tin tĩnh của buổi học — event `lobbyInfo`.
class LobbyInfo {
  const LobbyInfo({
    required this.classSessionId,
    required this.tutorName,
    required this.studentName,
    required this.scheduledStart,
    required this.scheduledEnd,
  });

  factory LobbyInfo.fromJson(Map<String, dynamic> j) => LobbyInfo(
    classSessionId: (j['classSessionId'] as num?)?.toInt() ?? 0,
    tutorName: j['tutorName'] as String? ?? 'Gia sư',
    studentName: j['studentName'] as String? ?? 'Học sinh',
    scheduledStart: j['scheduledStart'] as String? ?? '',
    scheduledEnd: j['scheduledEnd'] as String? ?? '',
  );

  final int classSessionId;
  final String tutorName;
  final String studentName;
  final String scheduledStart;
  final String scheduledEnd;

  DateTime? get startDt => DateTime.tryParse(scheduledStart)?.toLocal();
  DateTime? get endDt => DateTime.tryParse(scheduledEnd)?.toLocal();
}

/// Ai đang đứng chờ trong lobby — event `lobbyState`.
class LobbyWaitingState {
  const LobbyWaitingState({
    required this.tutorWaiting,
    required this.studentWaiting,
  });

  factory LobbyWaitingState.fromJson(Map<String, dynamic> j) =>
      LobbyWaitingState(
        tutorWaiting: j['tutorWaiting'] as bool? ?? false,
        studentWaiting: j['studentWaiting'] as bool? ?? false,
      );

  final bool tutorWaiting;
  final bool studentWaiting;
}

/// Trùng lịch với buổi khác — event `scheduleConflict`.
class SessionScheduleConflict {
  const SessionScheduleConflict({required this.message});

  factory SessionScheduleConflict.fromJson(Map<String, dynamic> j) =>
      SessionScheduleConflict(
        message: j['message'] as String? ?? 'Buổi học đang trùng lịch khác.',
      );

  final String message;
}

/// Trạng thái xác nhận học ngoài giờ — event `scheduleChangeState`.
class ScheduleChangeState {
  const ScheduleChangeState({
    required this.requiresConfirmation,
    required this.canCurrentUserConfirm,
    required this.currentUserConfirmed,
    required this.admissionAllowed,
    required this.rescheduleProposalPending,
    this.status,
    this.adjustedScheduledStart,
    this.adjustedScheduledEnd,
    this.originalScheduledStart,
    this.originalScheduledEnd,
    this.expiresAt,
    this.conflict,
  });

  factory ScheduleChangeState.fromJson(Map<String, dynamic> j) {
    final c = j['scheduleConflict'] as Map<String, dynamic>?;
    return ScheduleChangeState(
      requiresConfirmation: j['requiresConfirmation'] as bool? ?? false,
      canCurrentUserConfirm: j['canCurrentUserConfirm'] as bool? ?? false,
      currentUserConfirmed: j['currentUserConfirmed'] as bool? ?? false,
      admissionAllowed: j['admissionAllowed'] as bool? ?? false,
      rescheduleProposalPending:
          j['rescheduleProposalPending'] as bool? ?? false,
      status: j['status'] as String?,
      adjustedScheduledStart: j['adjustedScheduledStart'] as String?,
      adjustedScheduledEnd: j['adjustedScheduledEnd'] as String?,
      originalScheduledStart: j['originalScheduledStart'] as String?,
      originalScheduledEnd: j['originalScheduledEnd'] as String?,
      expiresAt: j['expiresAt'] as String?,
      conflict: c == null ? null : SessionScheduleConflict.fromJson(c),
    );
  }

  final bool requiresConfirmation;
  final bool canCurrentUserConfirm;
  final bool currentUserConfirmed;
  final bool admissionAllowed;
  final bool rescheduleProposalPending;
  final String? status;
  final String? adjustedScheduledStart;
  final String? adjustedScheduledEnd;
  final String? originalScheduledStart;
  final String? originalScheduledEnd;
  final String? expiresAt;
  final SessionScheduleConflict? conflict;

  DateTime? get adjustedStartDt =>
      DateTime.tryParse(adjustedScheduledStart ?? '')?.toLocal();
  DateTime? get adjustedEndDt =>
      DateTime.tryParse(adjustedScheduledEnd ?? '')?.toLocal();

  /// Cần bạn bấm đồng ý/từ chối cho buổi học ngoài giờ đã đặt.
  bool get awaitingMyResponse =>
      requiresConfirmation && canCurrentUserConfirm && !currentUserConfirmed;
}
