import 'package:tutora/shared/widgets/status_chip.dart';

// GET /api/tutorlesson/lessons  &  /api/tutorlesson/calendar
class TutorLessonDto {
  const TutorLessonDto({
    required this.lessonId,
    required this.bookingId,
    required this.studentName,
    required this.subjectName,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.checkOutTime,
    this.teachingMode,
  });

  factory TutorLessonDto.fromJson(Map<String, dynamic> j) {
    // Nhận cả dạng lồng (list) lẫn dạng phẳng (calendar).
    final student = j['student'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    return TutorLessonDto(
      lessonId: (j['classSessionId'] ?? j['lessonId']) as int? ?? 0,
      bookingId: j['bookingId'] as int?,
      studentName:
          (j['studentName'] ?? student?['fullName']) as String? ?? 'Học sinh',
      subjectName:
          (j['subjectName'] ?? subject?['subjectName']) as String? ?? '',
      scheduledStart: j['scheduledStart'] as String? ?? '',
      scheduledEnd: j['scheduledEnd'] as String? ?? '',
      status: j['status'] as String? ?? '',
      checkOutTime: j['checkOutTime'] as String?,
      teachingMode: j['teachingMode'] as String?,
    );
  }

  final int lessonId;

  /// Lớp chứa buổi này
  final int? bookingId;
  final String studentName;
  final String subjectName;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;

  /// Giờ gia sư rời phòng
  final String? checkOutTime;
  final String? teachingMode;

  // BE trả UTC tuyệt đối → .toLocal() mới ra giờ người dùng thấy.
  DateTime? get startDt => DateTime.tryParse(scheduledStart)?.toLocal();
  DateTime? get endDt => DateTime.tryParse(scheduledEnd)?.toLocal();

  String get _s => status.toLowerCase();

  bool get isScheduled => _s == 'scheduled';

  /// Mới giữ chỗ, học sinh chưa trả đợt 2 — chưa phải buổi được lên lịch.
  bool get isReserved => _s == 'reserved';

  bool get isInProgress => _s == 'in_progress';

  /// Đã gửi báo cáo, đang chờ học sinh xác nhận.
  bool get isPendingConfirmation => _s == 'pending_confirmation';

  bool get isCompleted => _s == 'completed';

  /// Đang có tranh chấp — tiền bị giữ tới khi admin xử lý.
  bool get isDisputed => _s == 'disputed';

  /// Một bên không vào lớp.
  bool get isNoShow => _s == 'no_show' || _s == 'cancelled_noshow';

  bool get isCancelled => _s == 'cancelled';

  /// Đã rời phòng mà vẫn in_progress = dạy xong, chỉ còn chờ gửi báo cáo.
  bool get isAwaitingReport => isInProgress && checkOutTime != null;

  /// Đang dạy thật (chưa checkout).
  bool get isLive => isInProgress && checkOutTime == null;

  /// Buổi đã xong xuôi, không còn việc phải làm.
  bool get isFinished => isCompleted || isPendingConfirmation;

  /// Buổi thật sự thuộc lớp — no_show vẫn tính, chỉ loại huỷ và giữ chỗ.
  bool get countsAsSession =>
      !isCancelled && !isReserved && _s != 'cancelled_noshow';

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

/// Một lớp (booking) — GET /api/tutor/classes; buổi học nằm bên trong lớp.
class TutorClassDto {
  const TutorClassDto({
    required this.bookingId,
    required this.studentName,
    required this.subjectName,
    required this.totalSessions,
    required this.completedSessions,
    required this.schedule,
    required this.nextSessionStart,
    required this.status,
  });

  factory TutorClassDto.fromJson(Map<String, dynamic> j) => TutorClassDto(
    bookingId: j['bookingId'] as int? ?? 0,
    studentName: j['studentName'] as String? ?? 'Học sinh',
    subjectName: j['subjectName'] as String? ?? '',
    totalSessions: j['totalSessions'] as int? ?? 0,
    completedSessions: j['completedSessions'] as int? ?? 0,
    schedule: j['schedule'] as String? ?? '',
    nextSessionStart: j['nextSessionStart'] as String?,
    status: j['status'] as String? ?? 'unknown',
  );

  final int bookingId;
  final String studentName;
  final String subjectName;
  final int totalSessions;
  final int completedSessions;

  /// Khung cố định dạng "T2 18:05, T4 14:30".
  final String schedule;
  final String? nextSessionStart;
  final String status;

  DateTime? get nextStartLocal =>
      DateTime.tryParse(nextSessionStart ?? '')?.toLocal();

  double get progress =>
      totalSessions == 0 ? 0 : completedSessions / totalSessions;

  /// DeriveClassStatus của BE không bao giờ trả 'cancelled'.
  bool get isFinished => status == 'completed';
}

class TutorClassPage {
  const TutorClassPage({required this.items, required this.totalCount});

  factory TutorClassPage.fromJson(Map<String, dynamic> j) => TutorClassPage(
    items: (j['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TutorClassDto.fromJson)
        .toList(),
    totalCount: j['totalCount'] as int? ?? 0,
  );

  final List<TutorClassDto> items;
  final int totalCount;
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

/// Nhãn + tông màu cho 9 trạng thái buổi học; nhiều màn dùng chung.
(String, ChipTone) lessonChip(String status) => switch (status.toLowerCase()) {
  'scheduled' || 'confirmed' => ('Sắp diễn ra', ChipTone.gold),
  'reserved' => ('Giữ chỗ', ChipTone.line),
  'in_progress' || 'inprogress' => ('Đang dạy', ChipTone.moss),
  'pending_confirmation' => ('Chờ xác nhận', ChipTone.gold),
  'completed' => ('Hoàn thành', ChipTone.ink),
  'disputed' => ('Đang tranh chấp', ChipTone.ox),
  'no_show' || 'cancelled_noshow' => ('Vắng mặt', ChipTone.ox),
  'cancelled' => ('Đã huỷ', ChipTone.ox),
  _ => (status, ChipTone.line),
};
