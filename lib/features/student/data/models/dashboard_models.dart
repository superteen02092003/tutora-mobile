class DashboardStats {
  const DashboardStats({
    required this.totalBookings,
    required this.totalLessons,
    required this.pendingCount,
    required this.completedCount,
  });

  final int totalBookings;
  final int totalLessons;
  final int pendingCount;
  final int completedCount;
}

class LessonSummaryDto {
  const LessonSummaryDto({
    required this.lessonId,
    required this.subjectName,
    required this.tutorName,
    required this.status,
    this.scheduledStart,
  });

  factory LessonSummaryDto.fromJson(Map<String, dynamic> j) => LessonSummaryDto(
    lessonId: j['lessonId'] as int? ?? 0,
    subjectName: j['subjectName'] as String? ?? '',
    tutorName: j['tutorName'] as String? ?? 'Gia sư',
    status: j['status'] as String? ?? '',
    scheduledStart:
        j['scheduledStartTime'] as String? ?? j['scheduledStart'] as String?,
  );

  final int lessonId;
  final String subjectName;
  final String tutorName;
  final String status;
  final String? scheduledStart;
}

class BookingSummaryDto {
  const BookingSummaryDto({
    required this.bookingId,
    required this.subjectName,
    required this.tutorName,
    required this.status,
    required this.sessionCount,
    required this.finalPrice,
  });

  factory BookingSummaryDto.fromJson(Map<String, dynamic> j) {
    final subject = j['subject'] as Map<String, dynamic>?;
    final tutor = j['tutor'] as Map<String, dynamic>?;
    return BookingSummaryDto(
      bookingId: j['bookingId'] as int? ?? 0,
      subjectName:
          subject?['subjectName'] as String? ?? 'Booking #${j['bookingId']}',
      tutorName: tutor?['fullName'] as String? ?? 'N/A',
      status: j['status'] as String? ?? '',
      sessionCount: j['sessionCount'] as int? ?? 0,
      finalPrice: (j['finalPrice'] as num?)?.toInt() ?? 0,
    );
  }

  final int bookingId;
  final String subjectName;
  final String tutorName;
  final String status;
  final int sessionCount;
  final int finalPrice;
}
