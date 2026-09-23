import 'package:tutora/features/tutor/data/models/recorder_models.dart';
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
    this.calendarDate,
    this.isContinuation = false,
    this.isDisputeRelearn = false,
    this.originalClassSessionId,
    this.skipConfirmedByBothSides = false,
    this.recorderLessonId,
    this.recorderStudentId,
    this.recorderStatus,
  });

  /// Buổi của học sinh ngoài nền tảng (recorder.lessons) hiển thị chung lịch.
  ///
  /// Đổi trạng thái sang từ vựng của buổi booking để lịch vẽ đúng: đã ghi
  /// nhưng chưa duyệt báo cáo = "đang chờ báo cáo", đã duyệt = "xong".
  factory TutorLessonDto.fromRecorder(RecorderLessonDto l) {
    final status = switch (l.status) {
      'sent' => 'completed',
      'recording' || 'uploading' => 'in_progress',
      'processing' || 'awaiting_approval' || 'failed' => 'in_progress',
      _ => 'scheduled',
    };
    final recorded = {
      'processing',
      'awaiting_approval',
      'failed',
    }.contains(l.status);
    final start = l.scheduledStart ?? l.startedAt;
    final end =
        l.scheduledEnd ??
        (start != null && l.durationSec > 0
            ? start.add(Duration(seconds: l.durationSec))
            : start?.add(const Duration(minutes: 90)));
    return TutorLessonDto(
      lessonId: 0,
      bookingId: null,
      studentName: l.studentName,
      subjectName: [
        if (l.subject != null && l.subject!.isNotEmpty) l.subject!,
        if (l.grade != null) 'Lớp ${l.grade}',
      ].join(' · '),
      scheduledStart: start?.toUtc().toIso8601String() ?? '',
      scheduledEnd: end?.toUtc().toIso8601String() ?? '',
      status: status,
      // Có checkOutTime + in_progress = "chờ báo cáo" theo quy ước của lịch.
      checkOutTime: recorded
          ? (l.startedAt ?? start)?.toUtc().toIso8601String()
          : null,
      recorderLessonId: l.lessonId,
      recorderStudentId: l.studentId,
      recorderStatus: l.status,
    );
  }

  /// [calendarDate] là khoá ngày do BE gom sẵn — xem [TutorLessonDto.calendarDate].
  factory TutorLessonDto.fromJson(
    Map<String, dynamic> j, {
    DateTime? calendarDate,
  }) {
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
      calendarDate: calendarDate,
      isContinuation: j['isContinuation'] as bool? ?? false,
      isDisputeRelearn: j['isDisputeRelearn'] as bool? ?? false,
      originalClassSessionId: j['originalClassSessionId'] as int?,
      skipConfirmedByBothSides: j['skipConfirmedByBothSides'] as bool? ?? false,
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

  /// Ngày mà BE xếp buổi này vào, theo giờ VN.
  final DateTime? calendarDate;

  /// Buổi phụ, sinh ra khi buổi gốc bị báo ngắt giữa chừng, để học nốt.
  final bool isContinuation;

  /// Buổi học lại, sinh ra khi hoà giải tranh chấp chọn phương án "học lại".
  final bool isDisputeRelearn;

  /// Buổi gốc mà buổi phụ / buổi học lại này trỏ về.
  final int? originalClassSessionId;

  /// Buổi phụ đã được cả hai phía đồng ý bỏ
  final bool skipConfirmedByBothSides;

  /// Có khi là buổi của học sinh ngoài nền tảng (recorder.lessons).
  final String? recorderLessonId;
  final String? recorderStudentId;

  /// Trạng thái gốc bên recorder (scheduled | recording | … | sent).
  final String? recorderStatus;

  bool get isOffPlatform => recorderLessonId != null;

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

  /// Buổi gốc bị báo ngắt giữa chừng
  bool get isInterrupted => _s == 'interrupted';

  /// Một bên không vào lớp.
  bool get isNoShow => _s == 'no_show' || _s == 'cancelled_noshow';

  bool get isCancelled => _s == 'cancelled';

  /// Đã rời phòng mà vẫn in_progress = dạy xong, chỉ còn chờ gửi báo cáo.
  /// Buổi bị ngắt mà hai bên đã bỏ buổi phụ cũng đang chờ báo cáo.
  bool get isAwaitingReport =>
      (isInProgress && checkOutTime != null) || isInterrupted;

  /// Đang dạy thật (chưa checkout). Buổi phụ đã bị bỏ thì không vào lớp được.
  bool get isLive =>
      isInProgress && checkOutTime == null && !skipConfirmedByBothSides;

  /// Buổi đã xong xuôi, không còn việc phải làm. `interrupted` KHÔNG tính:
  /// gia sư vẫn còn phải học nốt hoặc nộp báo cáo.
  bool get isFinished => isCompleted || isPendingConfirmation;

  /// Nhãn cho buổi sinh thêm
  String? get linkLabel =>
      isOffPlatform ? 'Ngoài Tutora' : (isExtra ? 'Buổi học phụ' : null);

  /// Buổi SINH THÊM để bù cho buổi gốc
  bool get isExtra => isContinuation || isDisputeRelearn;

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
    final dt = calendarDate ?? startDt;
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
    this.reservedSessions = 0,
    this.nextReservedStart,
    this.bookingStatus,
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
    reservedSessions: j['reservedSessions'] as int? ?? 0,
    nextReservedStart: j['nextReservedStart'] as String?,
    bookingStatus: j['bookingStatus'] as String?,
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

  /// Buổi đã tạo sẵn nhưng CHƯA mở vì phụ huynh chưa trả nốt tiền.
  final int reservedSessions;

  /// Giờ dự kiến của buổi giữ chỗ sớm nhất; chưa phải lịch chắc chắn.
  final String? nextReservedStart;

  /// Trạng thái booking (xem BookingStatus của BE).
  final String? bookingStatus;

  DateTime? get nextStartLocal =>
      DateTime.tryParse(nextSessionStart ?? '')?.toLocal();

  DateTime? get nextReservedLocal =>
      DateTime.tryParse(nextReservedStart ?? '')?.toLocal();

  /// Hết buổi mở nhưng còn buổi giữ chỗ — đang kẹt chờ thanh toán đợt 2.
  bool get isWaitingRemainingPayment =>
      nextSessionStart == null && reservedSessions > 0;

  /// Mẫu số của tiến độ = tổng số buổi của gói.
  int get totalWithReserved => reservedSessions == 0
      ? totalSessions
      : (totalSessions > reservedSessions
            ? totalSessions
            : totalSessions + reservedSessions);

  double get progress =>
      totalWithReserved == 0 ? 0 : completedSessions / totalWithReserved;

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
    // TutorAvailabilityResponse dùng cùng quy ước với UI: 1=Mon…7=Sun.
    // (Khác ScheduleItemResponse của booking, vốn theo DayOfWeek .NET 0=Sun.)
    return TutorAvailabilityDto(
      availabilityId:
          j['availabilityid'] as int? ?? j['availabilityId'] as int? ?? 0,
      dayOfWeek: j['dayofweek'] as int? ?? j['dayOfWeek'] as int? ?? 1,
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

  // Backend validate Range(1,7) với 7=Chủ nhật — gửi thẳng, không quy về 0.
  Map<String, dynamic> toJson() => {
    'dayofweek': dayOfWeek,
    'starttime': startTime,
    'endtime': endTime,
  };

  // dayOfWeek in Flutter convention (1=Mon…7=Sun)
  final int dayOfWeek;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
}

/// Một buổi thuộc gói cùng các buổi sinh thêm bám vào nó.
class SessionChain {
  const SessionChain({required this.parent, required this.children});

  final TutorLessonDto parent;

  /// Buổi phụ / buổi học lại, đã sắp theo thời gian.
  final List<TutorLessonDto> children;
}

/// Gom buổi phụ / buổi học lại về đúng buổi GỐC thuộc gói.
List<SessionChain> groupSessionChains(List<TutorLessonDto> sessions) {
  final sorted = [...sessions]
    ..sort((a, b) {
      final x = a.startDt;
      final y = b.startDt;
      if (x == null || y == null) return 0;
      return x.compareTo(y);
    });

  final byId = {for (final s in sorted) s.lessonId: s};
  final roots = <int, List<TutorLessonDto>>{};
  for (final s in sorted) {
    if (!s.isExtra) roots[s.lessonId] = <TutorLessonDto>[];
  }

  /// Lần ngược chuỗi tới buổi thuộc gói; null nếu không tới được.
  int? findRoot(TutorLessonDto session) {
    // `seen` chặn lặp vô hạn nếu dữ liệu bị trỏ vòng (A → B → A).
    final seen = <int>{session.lessonId};
    TutorLessonDto? current = session;

    while (current?.originalClassSessionId != null) {
      final parentId = current!.originalClassSessionId!;
      if (!seen.add(parentId)) return null;
      if (roots.containsKey(parentId)) return parentId;
      current = byId[parentId];
    }
    return null;
  }

  // Buổi sinh thêm không tìm được gốc (buổi gốc ngoài trang này) vẫn phải hiện
  final orphans = <TutorLessonDto>[];
  for (final s in sorted) {
    if (!s.isExtra) continue;
    final rootId = findRoot(s);
    if (rootId != null) {
      roots[rootId]!.add(s);
    } else {
      orphans.add(s);
    }
  }

  return [
    for (final e in roots.entries)
      SessionChain(parent: byId[e.key]!, children: e.value),
    for (final o in orphans)
      SessionChain(parent: o, children: const <TutorLessonDto>[]),
  ]..sort((a, b) {
    final x = a.parent.startDt;
    final y = b.parent.startDt;
    if (x == null || y == null) return 0;
    return x.compareTo(y);
  });
}

/// Nhãn + tông màu cho 9 trạng thái buổi học; nhiều màn dùng chung.
(String, ChipTone) lessonChip(String status) => switch (status.toLowerCase()) {
  'scheduled' || 'confirmed' => ('Sắp diễn ra', ChipTone.gold),
  'reserved' => ('Giữ chỗ', ChipTone.line),
  'in_progress' || 'inprogress' => ('Đang dạy', ChipTone.moss),
  'pending_confirmation' => ('Chờ xác nhận', ChipTone.gold),
  // Buổi gốc bị báo ngắt giữa chừng — chờ buổi phụ học nốt hoặc 2 bên bỏ.
  'interrupted' => ('Học dở dang', ChipTone.gold),
  'completed' => ('Hoàn thành', ChipTone.ink),
  'disputed' => ('Đang tranh chấp', ChipTone.ox),
  'no_show' || 'cancelled_noshow' => ('Vắng mặt', ChipTone.ox),
  'cancelled' => ('Đã huỷ', ChipTone.ox),
  _ => (status, ChipTone.line),
};

/// Phần chi tiết của một buổi (GET /api/class-sessions/{id}) mà lịch không có.
class TutorSessionDetailDto {
  const TutorSessionDetailDto({this.price, this.gradeName});

  factory TutorSessionDetailDto.fromJson(Map<String, dynamic> j) {
    final student = j['student'] as Map<String, dynamic>?;
    return TutorSessionDetailDto(
      price: (j['classSessionPrice'] as num?)?.toDouble(),
      gradeName:
          (student?['gradeLevelName'] ?? student?['gradeLevel']) as String?,
    );
  }

  /// Học phí buổi (VND).
  final double? price;

  /// "Lớp 9" — khối lớp của học sinh.
  final String? gradeName;
}
