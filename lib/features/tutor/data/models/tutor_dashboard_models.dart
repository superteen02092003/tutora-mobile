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
  final List<TutorTodaySessionDto> todaySessions;
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
