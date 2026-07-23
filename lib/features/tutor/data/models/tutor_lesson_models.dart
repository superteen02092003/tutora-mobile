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

  factory TutorLessonDto.fromJson(Map<String, dynamic> j) {
    // Hỗ trợ cả list (ClassSessionResponse: có student/subject lồng nhau)
    // lẫn calendar (CalendarClassSessionResponse: studentName/subjectName phẳng).
    final student = j['student'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    return TutorLessonDto(
      lessonId: (j['classSessionId'] ?? j['lessonId']) as int? ?? 0,
      studentName:
          (j['studentName'] ?? student?['fullName']) as String? ?? 'Học sinh',
      subjectName:
          (j['subjectName'] ?? subject?['subjectName']) as String? ?? '',
      scheduledStart: j['scheduledStart'] as String? ?? '',
      scheduledEnd: j['scheduledEnd'] as String? ?? '',
      status: j['status'] as String? ?? '',
      teachingMode: j['teachingMode'] as String?,
    );
  }

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
  });

  factory TutorAvailabilityDto.fromJson(Map<String, dynamic> j) {
    // Backend: 0=Sun,1=Mon…6=Sat → Flutter: 1=Mon…7=Sun
    final raw = j['dayofweek'] as int? ?? j['dayOfWeek'] as int? ?? 0;
    final flutterDay = raw == 0 ? 7 : raw; // 0→7(Sun), 1–6 stay as 1–6
    return TutorAvailabilityDto(
      availabilityId:
          j['availabilityid'] as int? ?? j['availabilityId'] as int? ?? 0,
      dayOfWeek: flutterDay,
      startTime: j['starttime'] as String? ?? j['startTime'] as String? ?? '',
      endTime: j['endtime'] as String? ?? j['endTime'] as String? ?? '',
    );
  }

  final int availabilityId;
  // 1=Mon … 6=Sat, 7=Sun  (Flutter/UI convention)
  final int dayOfWeek;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"

  bool get isRecurring => true;
}

class CreateAvailabilityRequest {
  const CreateAvailabilityRequest({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  // Flutter 1=Mon…7=Sun → Backend 0=Sun,1=Mon…6=Sat
  Map<String, dynamic> toJson() => {
    'dayofweek': dayOfWeek == 7 ? 0 : dayOfWeek,
    'starttime': startTime,
    'endtime': endTime,
  };

  // dayOfWeek in Flutter convention (1=Mon…7=Sun)
  final int dayOfWeek;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
}
