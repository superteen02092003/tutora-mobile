import 'package:tutora/features/tutor/data/models/recorder_models.dart';

// DTO cho nhóm API giai đoạn 1 (phase1-api.md, mục A–F): số liệu buổi học từ
// bản ghi, "ghi âm tốt" theo tuần, điểm danh, cài đặt nhắc lịch, nhật ký học.
// Parse dễ dãi như các DTO khác: thiếu / null → null hoặc mặc định.

int? _int(Object? v) => (v as num?)?.toInt();

double? _double(Object? v) => (v as num?)?.toDouble();

/// Giờ ISO UTC → giờ máy. Chuỗi không có múi giờ được hiểu là UTC (BE có chỗ
/// trả `timestamp without time zone` không kèm "Z").
DateTime? _time(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final hasZone = v.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(v);
  return DateTime.tryParse(hasZone ? v : '${v}Z')?.toLocal();
}

List<String> _strings(Object? v) =>
    (v is List ? v : const <dynamic>[]).whereType<String>().toList();

List<QuietStretch> _stretches(Object? v) => (v is List ? v : const <dynamic>[])
    .whereType<Map<String, dynamic>>()
    .map(QuietStretch.fromJson)
    .toList();

/// Giá trị `status` của `PUT /recorder/lessons/{id}/attendance` và trường
/// `attendance` trên buổi học.
abstract final class RecorderAttendance {
  static const present = 'present';
  static const absent = 'absent';
}

/// Nguồn của điểm danh (`attendanceSource`).
abstract final class RecorderAttendanceSource {
  /// Tự động: buổi có bản ghi.
  static const recording = 'recording';

  /// Gia sư tự đánh dấu.
  static const tutor = 'tutor';
}

/// Lý do vắng / không ghi âm (`reason` của điểm danh, `absenceReason`).
abstract final class RecorderAbsenceReason {
  static const cancelled = 'cancelled';
  static const pupilAbsent = 'pupil_absent';
  static const forgot = 'forgot';
  static const battery = 'battery';
  static const appProblem = 'app_problem';
  static const other = 'other';

  static const List<String> all = [
    cancelled,
    pupilAbsent,
    forgot,
    battery,
    appProblem,
    other,
  ];
}

/// Lý do huỷ buổi (`DELETE /recorder/lessons/{id}?reason=`).
abstract final class RecorderCancelReason {
  static const cancelled = 'cancelled';
  static const pupilAbsent = 'pupil_absent';
  static const other = 'other';

  /// Backend ghi khi buổi bị dời (buổi gốc chuyển sang `discarded`).
  static const moved = 'moved';

  static const List<String> all = [cancelled, pupilAbsent, other];
}

/// Phạm vi dời buổi (`PUT /recorder/lessons/{id}/schedule`).
enum RecorderMoveScope {
  /// Chỉ buổi này.
  thisLesson('this'),

  /// Buổi này và các buổi sau (đổi khung giờ hằng tuần).
  following('following')
  ;

  const RecorderMoveScope(this.apiValue);

  final String apiValue;
}

/// Một quãng học sinh im lặng ≥ 8 phút (tính từ đầu bản ghi).
class QuietStretch {
  const QuietStretch({required this.fromMin, required this.toMin});

  factory QuietStretch.fromJson(Map<String, dynamic> j) => QuietStretch(
    fromMin: _int(j['fromMin']) ?? 0,
    toMin: _int(j['toMin']) ?? 0,
  );

  final int fromMin;
  final int toMin;

  int get minutes => toMin - fromMin;

  Map<String, dynamic> toJson() => {'fromMin': fromMin, 'toMin': toMin};
}

/// Số liệu buổi học từ bản ghi (`GET /recording/app/{lessonId}/insights`).
///
/// Khi [available] = false (chưa có transcript / số liệu) các trường khác null.
class LessonInsightsDto {
  const LessonInsightsDto({
    required this.lessonId,
    this.available = false,
    this.metricsVersion,
    this.minutesRecorded,
    this.minutesPlanned,
    this.bothVoices,
    this.studentTalkShare,
    this.tutorTurns,
    this.studentTurns,
    this.tutorQuestions,
    this.avgWaitAfterQuestionSec,
    this.studentQuietStretches = const [],
    this.unclearMarks,
  });

  factory LessonInsightsDto.fromJson(Map<String, dynamic> j) =>
      LessonInsightsDto(
        lessonId: j['lessonId'] as String? ?? '',
        available: j['available'] as bool? ?? false,
        metricsVersion: j['metricsVersion'] as String?,
        minutesRecorded: _int(j['minutesRecorded']),
        minutesPlanned: _int(j['minutesPlanned']),
        bothVoices: j['bothVoices'] as bool?,
        studentTalkShare: _double(j['studentTalkShare']),
        tutorTurns: _int(j['tutorTurns']),
        studentTurns: _int(j['studentTurns']),
        tutorQuestions: _int(j['tutorQuestions']),
        avgWaitAfterQuestionSec: _double(j['avgWaitAfterQuestionSec']),
        studentQuietStretches: _stretches(j['studentQuietStretches']),
        unclearMarks: _int(j['unclearMarks']),
      );

  final String lessonId;
  final bool available;
  final String? metricsVersion;
  final int? minutesRecorded;
  final int? minutesPlanned;
  final bool? bothVoices;

  /// 0..1 — số từ của học sinh / tổng số từ.
  final double? studentTalkShare;
  final int? tutorTurns;
  final int? studentTurns;
  final int? tutorQuestions;

  /// Null khi có ít hơn 3 mẫu.
  final double? avgWaitAfterQuestionSec;

  /// Dài nhất trước, tối đa 3.
  final List<QuietStretch> studentQuietStretches;
  final int? unclearMarks;
}

/// Một tuần trong `GET /recorder/weekly-recording`.
class WeeklyRecordingWeek {
  const WeeklyRecordingWeek({
    this.weekStart,
    this.lessonsDue = 0,
    this.recorded = 0,
    this.usable = 0,
    this.avgStudentTalkShare,
  });

  factory WeeklyRecordingWeek.fromJson(Map<String, dynamic> j) =>
      WeeklyRecordingWeek(
        weekStart: parseDateOnly(j['weekStart']),
        lessonsDue: _int(j['lessonsDue']) ?? 0,
        recorded: _int(j['recorded']) ?? 0,
        usable: _int(j['usable']) ?? 0,
        avgStudentTalkShare: _double(j['avgStudentTalkShare']),
      );

  /// Thứ Hai đầu tuần (chỉ phần ngày).
  final DateTime? weekStart;
  final int lessonsDue;
  final int recorded;

  /// Số buổi "ghi âm tốt".
  final int usable;
  final double? avgStudentTalkShare;
}

/// Buổi đã qua giờ nhưng không có bản ghi (tuần này + tuần trước).
class MissingRecording {
  const MissingRecording({
    required this.lessonId,
    required this.studentName,
    this.studentId,
    this.scheduledStart,
    this.attendance,
    this.absenceReason,
  });

  factory MissingRecording.fromJson(Map<String, dynamic> j) => MissingRecording(
    lessonId: j['lessonId'] as String? ?? '',
    studentId: j['studentId'] as String?,
    studentName: j['studentName'] as String? ?? 'Học sinh',
    scheduledStart: _time(j['scheduledStart']),
    attendance: j['attendance'] as String?,
    absenceReason: j['absenceReason'] as String?,
  );

  final String lessonId;
  final String? studentId;
  final String studentName;
  final DateTime? scheduledStart;

  /// present | absent | null (chưa điểm danh).
  final String? attendance;

  /// Một giá trị của [RecorderAbsenceReason] hoặc null.
  final String? absenceReason;

  /// Chưa có lý do — app hiện các chip lý do.
  bool get needsReason => absenceReason == null;
}

/// `GET /recorder/weekly-recording?weeks=n`.
class WeeklyRecordingDto {
  const WeeklyRecordingDto({this.weeks = const [], this.missing = const []});

  factory WeeklyRecordingDto.fromJson(Map<String, dynamic> j) =>
      WeeklyRecordingDto(
        weeks: (j['weeks'] is List ? j['weeks'] as List : const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(WeeklyRecordingWeek.fromJson)
            .toList(),
        missing:
            (j['missing'] is List ? j['missing'] as List : const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(MissingRecording.fromJson)
                .toList(),
      );

  /// Mới nhất trước.
  final List<WeeklyRecordingWeek> weeks;
  final List<MissingRecording> missing;

  /// Tuần hiện tại (đầu danh sách), null nếu rỗng.
  WeeklyRecordingWeek? get currentWeek => weeks.isEmpty ? null : weeks.first;
}

/// Cài đặt nhắc lịch / thông báo của gia sư (`/recorder/settings`).
class RecorderSettingsDto {
  const RecorderSettingsDto({
    this.lessonReminderMinutes = defaultReminderMinutes,
    this.reportReadyPush = true,
  });

  /// Thiếu khoá → mặc định của server (30 phút); có khoá mà null → tắt nhắc.
  factory RecorderSettingsDto.fromJson(Map<String, dynamic> j) =>
      RecorderSettingsDto(
        lessonReminderMinutes: j.containsKey('lessonReminderMinutes')
            ? _int(j['lessonReminderMinutes'])
            : defaultReminderMinutes,
        reportReadyPush: j['reportReadyPush'] as bool? ?? true,
      );

  static const defaultReminderMinutes = 30;
  static const minReminderMinutes = 10;
  static const maxReminderMinutes = 120;

  /// Null = tắt nhắc, còn lại 10..120.
  final int? lessonReminderMinutes;

  /// false = không đẩy FCM khi báo cáo AI xong (thông báo trong app vẫn có).
  final bool reportReadyPush;

  bool get remindersOn => lessonReminderMinutes != null;

  /// [clearReminder] = true để tắt nhắc (đặt [lessonReminderMinutes] = null).
  RecorderSettingsDto copyWith({
    int? lessonReminderMinutes,
    bool clearReminder = false,
    bool? reportReadyPush,
  }) => RecorderSettingsDto(
    lessonReminderMinutes: clearReminder
        ? null
        : lessonReminderMinutes ?? this.lessonReminderMinutes,
    reportReadyPush: reportReadyPush ?? this.reportReadyPush,
  );

  Map<String, dynamic> toJson() => {
    'lessonReminderMinutes': lessonReminderMinutes,
    'reportReadyPush': reportReadyPush,
  };
}

/// Một buổi trong nhật ký học của học sinh.
class JournalLessonDto {
  const JournalLessonDto({
    required this.lessonId,
    this.scheduledStart,
    this.status = 'scheduled',
    this.attendance,
    this.absenceReason,
    this.durationSec = 0,
    this.content,
    this.homework,
    this.previousHomework,
    this.exercisesCorrect,
    this.exercisesTotal,
    this.strengths = const [],
    this.difficulties = const [],
    this.studentTalkShare,
    this.studentQuietStretches = const [],
    this.comment,
    this.aiDrafted = false,
    this.editedByTutor = false,
  });

  factory JournalLessonDto.fromJson(Map<String, dynamic> j) => JournalLessonDto(
    lessonId: j['lessonId'] as String? ?? '',
    scheduledStart: _time(j['scheduledStart']),
    status: j['status'] as String? ?? 'scheduled',
    attendance: j['attendance'] as String?,
    absenceReason: j['absenceReason'] as String?,
    durationSec: _int(j['durationSec']) ?? 0,
    content: j['content'] as String?,
    homework: j['homework'] as String?,
    previousHomework: j['previousHomework'] as String?,
    exercisesCorrect: _int(j['exercisesCorrect']),
    exercisesTotal: _int(j['exercisesTotal']),
    strengths: _strings(j['strengths']),
    difficulties: _strings(j['difficulties']),
    studentTalkShare: _double(j['studentTalkShare']),
    studentQuietStretches: _stretches(j['studentQuietStretches']),
    comment: j['comment'] as String?,
    aiDrafted: j['aiDrafted'] as bool? ?? false,
    editedByTutor: j['editedByTutor'] as bool? ?? false,
  );

  final String lessonId;
  final DateTime? scheduledStart;
  final String status;
  final String? attendance;
  final String? absenceReason;
  final int durationSec;
  final String? content;
  final String? homework;

  /// Bài về nhà của buổi trước của học sinh này.
  final String? previousHomework;
  final int? exercisesCorrect;
  final int? exercisesTotal;
  final List<String> strengths;
  final List<String> difficulties;
  final double? studentTalkShare;
  final List<QuietStretch> studentQuietStretches;
  final String? comment;

  /// true khi nội dung còn là bản AI viết (gia sư chưa duyệt / sửa).
  final bool aiDrafted;
  final bool editedByTutor;

  bool get isAbsent => attendance == RecorderAttendance.absent;
  bool get hasExercises => exercisesTotal != null && exercisesTotal! > 0;
}

/// `GET /recorder/students/{studentId}/journal?month=YYYY-MM`.
class StudentJournalDto {
  const StudentJournalDto({
    required this.studentId,
    required this.month,
    this.lessons = const [],
  });

  factory StudentJournalDto.fromJson(Map<String, dynamic> j) =>
      StudentJournalDto(
        studentId: j['studentId'] as String? ?? '',
        month: j['month'] as String? ?? '',
        lessons:
            (j['lessons'] is List ? j['lessons'] as List : const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(JournalLessonDto.fromJson)
                .toList(),
      );

  final String studentId;

  /// "YYYY-MM"
  final String month;

  /// Cũ → mới, không gồm buổi đã huỷ.
  final List<JournalLessonDto> lessons;
}

/// "2026-11" cho tháng của [d].
String formatJournalMonth(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// Kết quả gửi đề xuất dời buổi booking
/// (`POST /tutor/class-sessions/{id}/reschedule-proposal`).
class RescheduleProposalDto {
  const RescheduleProposalDto({
    this.rescheduleProposalId,
    this.classSessionId,
    this.status,
    this.originalScheduledStart,
    this.proposedScheduledStart,
    this.proposedScheduledEnd,
    this.reason,
    this.expiresAt,
    this.counterpartName,
  });

  factory RescheduleProposalDto.fromJson(Map<String, dynamic> j) =>
      RescheduleProposalDto(
        rescheduleProposalId: _int(j['rescheduleProposalId']),
        classSessionId: _int(j['classSessionId']),
        status: j['status'] as String?,
        originalScheduledStart: _time(j['originalScheduledStart']),
        proposedScheduledStart: _time(j['proposedScheduledStart']),
        proposedScheduledEnd: _time(j['proposedScheduledEnd']),
        reason: j['reason'] as String?,
        expiresAt: _time(j['expiresAt']),
        counterpartName: j['counterpartName'] as String?,
      );

  final int? rescheduleProposalId;
  final int? classSessionId;
  final String? status;
  final DateTime? originalScheduledStart;
  final DateTime? proposedScheduledStart;
  final DateTime? proposedScheduledEnd;
  final String? reason;
  final DateTime? expiresAt;

  /// Phụ huynh / học sinh cần đồng ý.
  final String? counterpartName;
}
