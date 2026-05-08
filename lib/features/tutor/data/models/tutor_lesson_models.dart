// GET /api/tutorlesson/lessons  &  /api/tutorlesson/calendar
class TutorLessonDto {
  const TutorLessonDto({
    required this.lessonId,
    required this.studentName,
    required this.subjectName,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.teachingMode,
  });

  factory TutorLessonDto.fromJson(Map<String, dynamic> j) => TutorLessonDto(
    lessonId: j['lessonId'] as int? ?? 0,
    studentName: j['studentName'] as String? ?? 'Học sinh',
    subjectName: j['subjectName'] as String? ?? '',
    scheduledStart: j['scheduledStart'] as String? ?? '',
    scheduledEnd: j['scheduledEnd'] as String? ?? '',
    status: j['status'] as String? ?? '',
    teachingMode: j['teachingMode'] as String?,
  );

  final int lessonId;
  final String studentName;
  final String subjectName;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final String? teachingMode;

  DateTime? get startDt => DateTime.tryParse(scheduledStart);
  DateTime? get endDt => DateTime.tryParse(scheduledEnd);

  String get timeStart {
    final dt = startDt;
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get timeEnd {
    final dt = endDt;
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool isSameDay(DateTime d) {
    final dt = startDt;
    if (dt == null) return false;
    return dt.year == d.year && dt.month == d.month && dt.day == d.day;
  }
}

// GET /api/tutor/availability/{tutorId}
class TutorAvailabilityDto {
  const TutorAvailabilityDto({
    required this.availabilityId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    this.specificDate,
  });

  factory TutorAvailabilityDto.fromJson(Map<String, dynamic> j) =>
      TutorAvailabilityDto(
        availabilityId: j['availabilityId'] as int? ?? 0,
        dayOfWeek: j['dayOfWeek'] as int? ?? 0,
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        isRecurring: j['isRecurring'] as bool? ?? false,
        specificDate: j['specificDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'isRecurring': isRecurring,
    if (specificDate != null) 'specificDate': specificDate,
  };

  final int availabilityId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isRecurring;
  final String? specificDate;
}

class CreateAvailabilityRequest {
  const CreateAvailabilityRequest({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    this.specificDate,
  });

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'isRecurring': isRecurring,
    if (specificDate != null) 'specificDate': specificDate,
  };

  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isRecurring;
  final String? specificDate;
}
