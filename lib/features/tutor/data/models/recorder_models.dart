/// "2026-09-21" ↔ DateTime (chỉ phần ngày). Backend dùng DateOnly.
DateTime? parseDateOnly(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final d = DateTime.tryParse(v);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

String? formatDateOnly(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

/// Số buổi của thời khoá biểu trong khoảng [from]..[until] (tính cả hai đầu).
int countScheduledLessons(
  List<RecorderScheduleSlot> slots,
  DateTime from,
  DateTime until,
) {
  if (slots.isEmpty || until.isBefore(from)) return 0;
  var n = 0;
  for (
    var d = DateTime(from.year, from.month, from.day);
    !d.isAfter(until);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    n += slots.where((s) => s.dayOfWeek == d.weekday).length;
  }
  return n;
}

/// Một khung giờ trong thời khoá biểu hằng tuần (giờ Việt Nam).
class RecorderScheduleSlot {
  const RecorderScheduleSlot({
    required this.dayOfWeek,
    required this.start,
    required this.end,
  });

  factory RecorderScheduleSlot.fromJson(Map<String, dynamic> j) =>
      RecorderScheduleSlot(
        dayOfWeek: (j['dayOfWeek'] as num?)?.toInt() ?? 1,
        start: j['start'] as String? ?? '00:00',
        end: j['end'] as String? ?? '00:00',
      );

  /// 1 = Thứ 2 … 7 = Chủ nhật.
  final int dayOfWeek;

  /// "HH:mm"
  final String start;
  final String end;

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'start': start,
    'end': end,
  };

  static const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String get dayLabel => dayLabels[(dayOfWeek - 1).clamp(0, 6)];

  /// "T2, T5 · 19:00–20:30" — gộp các ngày cùng khung giờ.
  static String summary(List<RecorderScheduleSlot> slots) {
    if (slots.isEmpty) return '';
    final byTime = <String, List<int>>{};
    for (final s in slots) {
      (byTime['${s.start}–${s.end}'] ??= []).add(s.dayOfWeek);
    }
    return byTime.entries
        .map((e) {
          final days = (e.value..sort())
              .map((d) => dayLabels[d - 1])
              .join(', ');
          return '$days · ${e.key}';
        })
        .join('; ');
  }
}

/// Học sinh ngoài nền tảng trong danh bạ của gia sư (`/api/recorder/students`).
///
/// Không phải tài khoản — chỉ là danh bạ. SĐT phụ huynh dùng để gửi báo cáo.
class RecorderStudentDto {
  const RecorderStudentDto({
    required this.studentId,
    required this.fullName,
    this.grade,
    this.subject,
    this.parentName,
    this.parentPhone,
    this.consentStatus = 'unknown',
    this.note,
    this.lessonCount = 0,
    this.lastLessonAt,
    this.schedule = const [],
    this.scheduleFrom,
    this.scheduleUntil,
    this.parentLinkStatus = 'none',
    this.parentLinkedAt,
    this.parentZaloName,
    this.inviteExpiresAt,
  });

  factory RecorderStudentDto.fromJson(Map<String, dynamic> j) =>
      RecorderStudentDto(
        studentId: j['studentId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? 'Học sinh',
        grade: (j['grade'] as num?)?.toInt(),
        subject: j['subject'] as String?,
        parentName: j['parentName'] as String?,
        parentPhone: j['parentPhone'] as String?,
        consentStatus: j['consentStatus'] as String? ?? 'unknown',
        note: j['note'] as String?,
        lessonCount: (j['lessonCount'] as num?)?.toInt() ?? 0,
        lastLessonAt: DateTime.tryParse(
          j['lastLessonAt'] as String? ?? '',
        )?.toLocal(),
        schedule: (j['schedule'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RecorderScheduleSlot.fromJson)
            .toList(),
        scheduleFrom: parseDateOnly(j['scheduleFrom']),
        scheduleUntil: parseDateOnly(j['scheduleUntil']),
        parentLinkStatus: j['parentLinkStatus'] as String? ?? 'none',
        parentLinkedAt: DateTime.tryParse(
          j['parentLinkedAt'] as String? ?? '',
        )?.toLocal(),
        parentZaloName: j['parentZaloName'] as String?,
        inviteExpiresAt: DateTime.tryParse(
          j['inviteExpiresAt'] as String? ?? '',
        )?.toLocal(),
      );

  final String studentId;
  final String fullName;
  final int? grade;
  final String? subject;
  final String? parentName;
  final String? parentPhone;

  /// unknown | tutor_confirmed | parent_confirmed | declined
  final String consentStatus;
  final String? note;
  final int lessonCount;
  final DateTime? lastLessonAt;

  /// Thời khoá biểu hằng tuần; rỗng = chưa đặt lịch.
  final List<RecorderScheduleSlot> schedule;

  /// Khoảng áp dụng lịch (ngày, giờ VN). [scheduleUntil] null = không giới hạn.
  final DateTime? scheduleFrom;
  final DateTime? scheduleUntil;

  bool get hasConsent =>
      consentStatus == 'tutor_confirmed' || consentStatus == 'parent_confirmed';
  bool get isDeclined => consentStatus == 'declined';

  /// Liên kết Zalo của phụ huynh qua Mini App: none | invited | linked | unfollowed.
  final String parentLinkStatus;
  final DateTime? parentLinkedAt;

  /// Tên Zalo của phụ huynh đã liên kết.
  final String? parentZaloName;

  /// Hạn link mời đang chờ phụ huynh mở.
  final DateTime? inviteExpiresAt;

  bool get isParentLinked =>
      parentLinkStatus == 'linked' || parentLinkStatus == 'unfollowed';

  /// "Toán · Lớp 9"
  String get subtitle => [
    if (subject != null && subject!.isNotEmpty) subject!,
    if (grade != null) 'Lớp $grade',
  ].join(' · ');
}

/// Dữ liệu form thêm / sửa học sinh.
class RecorderStudentInput {
  const RecorderStudentInput({
    required this.fullName,
    this.grade,
    this.subject,
    this.parentName,
    this.parentPhone,
    this.parentConsent = false,
    this.note,
    this.schedule,
    this.scheduleFrom,
    this.scheduleUntil,
  });

  final String fullName;
  final int? grade;
  final String? subject;
  final String? parentName;
  final String? parentPhone;
  final bool parentConsent;
  final String? note;

  /// null = giữ nguyên lịch trên server; rỗng = xoá lịch.
  final List<RecorderScheduleSlot>? schedule;
  final DateTime? scheduleFrom;
  final DateTime? scheduleUntil;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'grade': grade,
    'subject': _n(subject),
    'parentName': _n(parentName),
    'parentPhone': _n(parentPhone),
    'parentConsent': parentConsent,
    'note': _n(note),
    if (schedule != null) ...{
      'schedule': schedule!.map((e) => e.toJson()).toList(),
      'scheduleFrom': formatDateOnly(scheduleFrom),
      'scheduleUntil': formatDateOnly(scheduleUntil),
    },
  };

  static String? _n(String? v) =>
      v == null || v.trim().isEmpty ? null : v.trim();
}

/// Một buổi trong nhật ký (`/api/recorder/lessons`).
class RecorderLessonDto {
  const RecorderLessonDto({
    required this.lessonId,
    required this.studentName,
    required this.status,
    required this.aiStatus,
    this.studentId,
    this.classSessionId,
    this.grade,
    this.subject,
    this.scheduledStart,
    this.scheduledEnd,
    this.durationSec = 0,
    this.startedAt,
    this.approvedAt,
    this.deliveryChannel,
    this.deliveryStatus,
  });

  factory RecorderLessonDto.fromJson(Map<String, dynamic> j) {
    DateTime? t(String k) =>
        DateTime.tryParse(j[k] as String? ?? '')?.toLocal();
    return RecorderLessonDto(
      lessonId: j['lessonId'] as String? ?? '',
      studentId: j['studentId'] as String?,
      classSessionId: (j['classSessionId'] as num?)?.toInt(),
      studentName: j['studentName'] as String? ?? 'Học sinh',
      grade: (j['grade'] as num?)?.toInt(),
      subject: j['subject'] as String?,
      scheduledStart: t('scheduledStart'),
      scheduledEnd: t('scheduledEnd'),
      status: j['status'] as String? ?? 'scheduled',
      aiStatus: j['aiStatus'] as String? ?? 'none',
      durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
      startedAt: t('startedAt'),
      approvedAt: t('approvedAt'),
      deliveryChannel: j['deliveryChannel'] as String?,
      deliveryStatus: j['deliveryStatus'] as String?,
    );
  }

  final String lessonId;
  final String? studentId;
  final int? classSessionId;
  final String studentName;
  final int? grade;
  final String? subject;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;

  /// scheduled | recording | uploading | processing | awaiting_approval | sent | failed
  final String status;
  final String aiStatus;
  final int durationSec;
  final DateTime? startedAt;
  final DateTime? approvedAt;
  final String? deliveryChannel;
  final String? deliveryStatus;

  /// Ngày dùng để xếp lịch: giờ hẹn, hoặc giờ bắt đầu ghi nếu ghi ngay.
  DateTime? get when => scheduledStart ?? startedAt;
}

/// Link mời phụ huynh vừa tạo (`POST /recorder/students/{id}/parent-invite`).
class RecorderParentInviteDto {
  const RecorderParentInviteDto({
    required this.inviteUrl,
    required this.shareText,
    this.expiresAt,
  });

  factory RecorderParentInviteDto.fromJson(Map<String, dynamic> j) =>
      RecorderParentInviteDto(
        inviteUrl: j['inviteUrl'] as String? ?? '',
        shareText: j['shareText'] as String? ?? '',
        expiresAt: DateTime.tryParse(
          j['expiresAt'] as String? ?? '',
        )?.toLocal(),
      );

  final String inviteUrl;

  /// Tin nhắn mẫu có sẵn link — gia sư dán vào Zalo gửi phụ huynh.
  final String shareText;
  final DateTime? expiresAt;
}
