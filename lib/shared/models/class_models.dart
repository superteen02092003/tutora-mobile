import 'package:intl/intl.dart';

/// Một buổi học nằm trong lớp học (booking).
class ClassSessionSlotDto {
  const ClassSessionSlotDto({
    required this.classSessionId,
    required this.sessionIndex,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.price,
    this.isContinuation = false,
    this.isDisputeRelearn = false,
    this.originalClassSessionId,
  });

  factory ClassSessionSlotDto.fromJson(Map<String, dynamic> j) =>
      ClassSessionSlotDto(
        classSessionId: (j['classSessionId'] ?? j['lessonId'] ?? 0) as int,
        sessionIndex: (j['sessionIndex'] as num?)?.toInt() ?? 0,
        scheduledStart: j['scheduledStart'] as String? ?? '',
        scheduledEnd: j['scheduledEnd'] as String? ?? '',
        status: j['status'] as String? ?? '',
        price: (j['classSessionPrice'] as num?)?.toDouble(),
        isContinuation: j['isContinuation'] as bool? ?? false,
        isDisputeRelearn: j['isDisputeRelearn'] as bool? ?? false,
        originalClassSessionId: (j['originalClassSessionId'] as num?)?.toInt(),
      );

  final int classSessionId;

  /// Thứ tự buổi trong lớp (1-based) do BE đánh theo thời gian.
  final int sessionIndex;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final double? price;

  /// Buổi phụ — học nốt phần buổi gốc bị ngắt giữa chừng.
  final bool isContinuation;

  /// Buổi học lại — sau khi hoà giải tranh chấp.
  final bool isDisputeRelearn;

  /// Buổi gốc mà buổi này bám theo.
  final int? originalClassSessionId;

  /// Buổi sinh thêm ngoài gói.
  bool get isExtra => isContinuation || isDisputeRelearn;

  /// Nhãn ngắn — cùng từ vựng với BE và web.
  String? get linkLabel => isExtra ? 'Buổi học phụ' : null;

  DateTime get startDt =>
      DateTime.tryParse(scheduledStart)?.toLocal() ?? DateTime(2000);
  DateTime get endDt => DateTime.tryParse(scheduledEnd)?.toLocal() ?? startDt;

  String get timeStart => DateFormat('HH:mm').format(startDt);
  String get timeEnd => DateFormat('HH:mm').format(endDt);
  String get timeRange => '$timeStart – $timeEnd';
  String get dateLabel => DateFormat('dd/MM').format(startDt);
  String get weekdayLabel => _viWeekday(startDt.weekday);

  ClassSessionState get state => classSessionStateOf(status);

  /// Buổi giữ chỗ chờ thanh toán đợt 2 — chưa được kích hoạt nên không hiện
  /// trong lịch và không tính vào tiến độ.
  bool get isLocked => state == ClassSessionState.reserved;

  /// Buổi thật sự thuộc lớp. `no_show` VẪN tính
  bool get isCounted => !isLocked && state != ClassSessionState.cancelled;

  bool get countsTowardPackage => isCounted && !isExtra;

  bool get isFinished =>
      state == ClassSessionState.completed ||
      state == ClassSessionState.pendingConfirmation;

  bool get isToday {
    final now = DateTime.now();
    return startDt.year == now.year &&
        startDt.month == now.month &&
        startDt.day == now.day;
  }

  /// Phòng mở theo TRẠNG THÁI buổi học, không theo khung giờ (khớp BE).
  bool get canJoinNow =>
      state == ClassSessionState.scheduled ||
      state == ClassSessionState.inProgress;

  /// Đã tới sát giờ học (±15 phút) — chỉ để đổi nhãn, không chặn vào.
  bool get isWithinJoinWindow =>
      DateTime.now().isAfter(startDt.subtract(const Duration(minutes: 15)));
}

/// Một buổi thuộc gói kèm các buổi phụ / học lại sinh ra từ nó.
class ClassSessionChain {
  const ClassSessionChain({required this.parent, required this.children});

  final ClassSessionSlotDto parent;

  /// Buổi phụ / buổi học lại bám theo `parent`, đã sắp theo thời gian.
  final List<ClassSessionSlotDto> children;
}

/// Gom buổi phụ / buổi học lại về đúng buổi GỐC thuộc gói, để danh sách buổi
/// không còn là một dãy phẳng lẫn lộn buổi mua và buổi bù.
List<ClassSessionChain> groupClassSessionChains(
  List<ClassSessionSlotDto> sessions,
) {
  final sorted = [...sessions]..sort((a, b) => a.startDt.compareTo(b.startDt));

  final byId = {for (final s in sorted) s.classSessionId: s};
  final roots = <int, List<ClassSessionSlotDto>>{};
  for (final s in sorted) {
    if (!s.isExtra) roots[s.classSessionId] = <ClassSessionSlotDto>[];
  }

  /// Lần ngược chuỗi tới buổi thuộc gói; null nếu không tới được.
  int? findRoot(ClassSessionSlotDto session) {
    // `seen` chặn lặp vô hạn nếu dữ liệu bị trỏ vòng (A → B → A).
    final seen = <int>{session.classSessionId};
    ClassSessionSlotDto? current = session;

    while (current?.originalClassSessionId != null) {
      final parentId = current!.originalClassSessionId!;
      if (!seen.add(parentId)) return null;
      if (roots.containsKey(parentId)) return parentId;
      current = byId[parentId];
    }
    return null;
  }

  // Buổi sinh thêm không tìm được gốc (buổi gốc ngoài trang này) vẫn phải hiện
  final orphans = <ClassSessionSlotDto>[];
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
      ClassSessionChain(parent: byId[e.key]!, children: e.value),
    for (final o in orphans)
      ClassSessionChain(parent: o, children: const <ClassSessionSlotDto>[]),
  ]..sort((a, b) => a.parent.startDt.compareTo(b.parent.startDt));
}

/// Buổi học sắp tới ở trang chủ — nguồn: GET /student/class-sessions/upcoming.
class UpcomingSessionDto {
  const UpcomingSessionDto({
    required this.classSessionId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.bookingId,
    this.subjectName,
    this.tutorName,
    this.meetingLink,
    this.checkOutTime,
    this.isContinuation = false,
    this.isDisputeRelearn = false,
    this.originalClassSessionId,
    this.skipConfirmedByBothSides = false,
    this.hasPendingReschedule = false,
  });

  factory UpcomingSessionDto.fromJson(Map<String, dynamic> j) =>
      UpcomingSessionDto(
        classSessionId: (j['classSessionId'] as num?)?.toInt() ?? 0,
        scheduledStart: j['scheduledStart'] as String? ?? '',
        scheduledEnd: j['scheduledEnd'] as String? ?? '',
        status: j['status'] as String? ?? '',
        bookingId: (j['bookingId'] as num?)?.toInt(),
        subjectName: j['subjectName'] as String?,
        tutorName: j['tutorName'] as String?,
        meetingLink: j['meetingLink'] as String?,
        checkOutTime: j['checkOutTime'] as String?,
        isContinuation: j['isContinuation'] as bool? ?? false,
        isDisputeRelearn: j['isDisputeRelearn'] as bool? ?? false,
        originalClassSessionId: (j['originalClassSessionId'] as num?)?.toInt(),
        skipConfirmedByBothSides:
            j['skipConfirmedByBothSides'] as bool? ?? false,
        hasPendingReschedule: j['hasPendingReschedule'] as bool? ?? false,
      );

  final int classSessionId;
  final String scheduledStart;
  final String scheduledEnd;
  final String status;
  final int? bookingId;
  final String? subjectName;
  final String? tutorName;
  final String? meetingLink;

  /// Có giờ check-out = BE đã đóng phòng vĩnh viễn.
  final String? checkOutTime;

  /// Buổi phụ — sinh ra để học nốt phần buổi gốc bị ngắt giữa chừng.
  final bool isContinuation;

  /// Buổi học lại — sinh ra sau khi hoà giải tranh chấp.
  final bool isDisputeRelearn;

  /// Buổi gốc mà buổi phụ / học lại này bám theo.
  final int? originalClassSessionId;

  /// Buổi phụ đã được hai bên đồng ý bỏ
  final bool skipConfirmedByBothSides;

  /// Đang có đề xuất đổi lịch chờ phản hồi.
  final bool hasPendingReschedule;

  /// Buổi sinh thêm ngoài gói (buổi phụ hoặc buổi học lại).
  bool get isExtra => isContinuation || isDisputeRelearn;

  /// Nhãn ngắn cho buổi sinh thêm — cùng từ vựng với BE và web.
  String? get linkLabel => isExtra ? 'Buổi học phụ' : null;

  DateTime get startDt =>
      DateTime.tryParse(scheduledStart)?.toLocal() ?? DateTime(2000);
  DateTime get endDt => DateTime.tryParse(scheduledEnd)?.toLocal() ?? startDt;

  String get timeStart => DateFormat('HH:mm').format(startDt);
  String get timeEnd => DateFormat('HH:mm').format(endDt);
  String get timeRange => '$timeStart – $timeEnd';
  String get title => subjectName ?? 'Buổi học';

  ClassSessionState get state => classSessionStateOf(status);

  bool get isToday {
    final now = DateTime.now();
    return startDt.year == now.year &&
        startDt.month == now.month &&
        startDt.day == now.day;
  }

  bool get isTomorrow {
    final t = DateTime.now().add(const Duration(days: 1));
    return startDt.year == t.year &&
        startDt.month == t.month &&
        startDt.day == t.day;
  }

  /// "Hôm nay", "Ngày mai", hoặc "Thứ 4, 20/08".
  String get dayLabel {
    if (isToday) return 'Hôm nay';
    if (isTomorrow) return 'Ngày mai';
    return '${_viWeekday(startDt.weekday)}, ${DateFormat('dd/MM').format(startDt)}';
  }

  DateTime? get checkOutDt =>
      checkOutTime == null ? null : DateTime.tryParse(checkOutTime!)?.toLocal();

  /// Bản ghi `in_progress` cũ quá hạn — BE tự kết thúc sau 30 phút kể từ giờ tan.
  bool get isOverdue {
    if (state != ClassSessionState.inProgress || checkOutDt != null) {
      return false;
    }
    return DateTime.now().isAfter(endDt.add(const Duration(minutes: 30)));
  }

  /// Phòng mở theo TRẠNG THÁI buổi học, không theo khung giờ (khớp BE).
  ///
  /// Khớp `canJoinLiveSession` bên web: buổi phụ mà hai bên đã đồng ý bỏ vẫn
  /// mang status `scheduled` cho tới khi gia sư nộp báo cáo buổi gốc, nhưng
  /// coi như đã chết — cho vào là học sinh ngồi chờ một phòng không ai tới.
  bool get canJoinNow {
    if (checkOutDt != null || isOverdue) return false;
    if (skipConfirmedByBothSides) return false;
    return state == ClassSessionState.scheduled ||
        state == ClassSessionState.inProgress;
  }

  /// Đã tới sát giờ học (±15 phút) — chỉ dùng để đổi nhãn nút, không chặn vào.
  bool get isWithinJoinWindow =>
      DateTime.now().isAfter(startDt.subtract(const Duration(minutes: 15)));

  /// Đếm ngược dễ đọc: "Còn 2 giờ 15 phút", "Đang diễn ra"…
  String get countdownLabel {
    if (state == ClassSessionState.inProgress) return 'Đang diễn ra';
    final diff = startDt.difference(DateTime.now());
    if (diff.isNegative) return 'Đang diễn ra';
    if (diff.inMinutes < 60) return 'Còn ${diff.inMinutes + 1} phút';
    if (diff.inHours < 24) {
      final mins = diff.inMinutes % 60;
      return mins == 0
          ? 'Còn ${diff.inHours} giờ'
          : 'Còn ${diff.inHours} giờ $mins phút';
    }
    return 'Còn ${diff.inDays} ngày';
  }
}

/// Trạng thái buổi học — gom từ chuỗi status của BE (ClassSessionStatus).
enum ClassSessionState {
  /// Buổi 2..N đã giữ chỗ nhưng CHƯA được kích hoạt vì phụ huynh mới trả cọc
  /// (chỉ mở buổi đầu). BE chuyển sang `scheduled` khi trả nốt phần còn lại.
  reserved,
  scheduled,
  inProgress,
  pendingConfirmation,
  completed,
  cancelled,
  disputed,
  noShow,
}

ClassSessionState classSessionStateOf(String raw) =>
    switch (raw.toLowerCase()) {
      'reserved' => ClassSessionState.reserved,
      'scheduled' => ClassSessionState.scheduled,
      'in_progress' => ClassSessionState.inProgress,
      'pending_confirmation' => ClassSessionState.pendingConfirmation,
      'completed' => ClassSessionState.completed,
      // cancelled_noshow = huỷ vì vắng, KHÁC no_show (buổi đã diễn ra).
      'cancelled' || 'cancelled_noshow' => ClassSessionState.cancelled,
      'disputed' => ClassSessionState.disputed,
      'no_show' => ClassSessionState.noShow,
      _ => ClassSessionState.scheduled,
    };

/// Lớp học = một booking (một kỳ học với 1 gia sư, gồm nhiều buổi).
class StudentClassDto {
  const StudentClassDto({
    required this.bookingId,
    required this.status,
    required this.paymentStatus,
    required this.sessions,
    this.subjectName,
    this.subjectIconUrl,
    this.gradeName,
    this.tutorId,
    this.tutorName,
    this.tutorAvatarUrl,
    this.totalSessions,
    this.durationMinutes,
    this.startDate,
    this.finalPrice,
    this.remainingAmount,
    this.schedule = const [],
  });

  factory StudentClassDto.fromJson(Map<String, dynamic> j) {
    final tutor = j['tutor'] as Map<String, dynamic>?;
    final subject = j['subject'] as Map<String, dynamic>?;
    final grade = j['gradeLevel'] as Map<String, dynamic>?;
    final rawSessions = j['classSessions'] as List<dynamic>? ?? const [];
    final rawSchedule = j['schedule'] as List<dynamic>? ?? const [];

    final sessions =
        rawSessions
            .map(
              (e) => ClassSessionSlotDto.fromJson(e as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => a.startDt.compareTo(b.startDt));

    return StudentClassDto(
      bookingId: j['bookingId'] as int,
      status: j['status'] as String? ?? '',
      paymentStatus: j['paymentStatus'] as String? ?? '',
      subjectName: subject?['subjectName'] as String?,
      subjectIconUrl: subject?['iconUrl'] as String?,
      gradeName: grade?['gradeName'] as String?,
      tutorId: tutor?['tutorId'] as String?,
      tutorName: tutor?['fullName'] as String?,
      tutorAvatarUrl: tutor?['avatarUrl'] as String?,
      totalSessions:
          (j['totalSessions'] ?? j['sessionCount']) as int? ?? sessions.length,
      durationMinutes: (j['durationMinutesPerSession'] as num?)?.toInt(),
      startDate: j['startDate'] as String?,
      finalPrice: (j['finalPrice'] as num?)?.toDouble(),
      remainingAmount: (j['remainingAmount'] as num?)?.toDouble(),
      sessions: sessions,
      schedule: rawSchedule
          .map((e) => WeeklySlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int bookingId;
  final String status;
  final String paymentStatus;
  final String? subjectName;

  /// Icon môn học do CMS cấu hình — hiển thị trên card lớp.
  final String? subjectIconUrl;
  final String? gradeName;
  final String? tutorId;
  final String? tutorName;
  final String? tutorAvatarUrl;
  final int? totalSessions;
  final int? durationMinutes;
  final String? startDate;
  final double? finalPrice;
  final double? remainingAmount;

  /// Các buổi học thuộc lớp, đã sắp theo thời gian tăng dần.
  final List<ClassSessionSlotDto> sessions;

  /// Lịch cố định hằng tuần (thứ + giờ) của lớp.
  final List<WeeklySlotDto> schedule;

  String get title => subjectName ?? 'Lớp #$bookingId';

  String get subtitle {
    final parts = <String>[
      if (gradeName?.isNotEmpty ?? false) gradeName!,
      if (tutorName?.isNotEmpty ?? false) tutorName!,
    ];
    return parts.join(' · ');
  }

  ClassStatusType get statusType => switch (status.toLowerCase()) {
    'pending_payment' || 'accepted' => ClassStatusType.unpaid,
    'pending_tutor' => ClassStatusType.pendingTutor,
    'deposit_paid' => ClassStatusType.depositPaid,
    'pending_remaining_payment' => ClassStatusType.pendingRemaining,
    'paid' || 'ongoing' || 'active' => ClassStatusType.active,
    'completed' || 'closed' => ClassStatusType.completed,
    'cancelled' ||
    'cancelled_noshow' ||
    'cancelled_by_staff' ||
    'cancelled_by_dispute' ||
    'refunded' => ClassStatusType.cancelled,
    'payment_timeout' => ClassStatusType.expired,
    _ =>
      status.toLowerCase().startsWith('cancelled')
          ? ClassStatusType.cancelled
          : ClassStatusType.unpaid,
  };

  /// Chưa trả phí buổi đầu thì CHƯA phải lớp học — chỉ là đơn chờ thanh toán.
  bool get isAwaitingDeposit {
    final s = status.toLowerCase();
    return s == 'pending_payment' || s == 'accepted' || s == 'pending_tutor';
  }

  /// Lớp còn đang chạy — hiện ở tab "Đang học".
  bool get isOngoing =>
      !isAwaitingDeposit &&
      (statusType == ClassStatusType.depositPaid ||
          statusType == ClassStatusType.active ||
          statusType == ClassStatusType.pendingRemaining);

  /// Cần thanh toán nốt phần còn lại để mở các buổi tiếp theo.
  bool get needsRemainingPayment =>
      status.toLowerCase() == 'pending_remaining_payment' ||
      (remainingAmount ?? 0) > 0 &&
          paymentStatus.toLowerCase() == 'deposit_paid';

  // Tiến độ

  /// Mẫu số tiến độ = số buổi ĐÃ TRẢ TIỀN. Mới đặt cọc thì chỉ buổi đầu được
  /// mở nên là "x/1"; trả nốt đợt 2 mới mở hết và thành "x/N".
  int get countedSessions {
    final unlocked = sessions.where((s) => s.countsTowardPackage).length;
    if (unlocked > 0) return unlocked;
    // Chưa có buổi nào mở khoá: đang chờ cọc → chưa tính buổi nào.
    return sessions.any((s) => s.isLocked) ? 0 : (totalSessions ?? 0);
  }

  int get doneSessions =>
      sessions.where((s) => s.countsTowardPackage && s.isFinished).length;

  int get remainingSessions =>
      (countedSessions - doneSessions).clamp(0, countedSessions);

  /// 0.0 – 1.0. Trả 0 khi lớp chưa có buổi nào để tránh chia cho 0.
  double get progress {
    if (countedSessions == 0) return 0;
    return (doneSessions / countedSessions).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  /// Buổi kế tiếp chưa diễn ra — dùng cho dòng "Buổi tới" trên card lớp.
  ClassSessionSlotDto? get nextSession {
    final now = DateTime.now();
    for (final s in sessions) {
      if (!s.isCounted) continue;
      if (s.state == ClassSessionState.inProgress) return s;
      if (s.endDt.isAfter(now) && !s.isFinished) return s;
    }
    return null;
  }

  /// Buổi đang chờ học sinh xác nhận hoàn tất (nếu có).
  ClassSessionSlotDto? get awaitingConfirmSession {
    for (final s in sessions) {
      if (s.state == ClassSessionState.pendingConfirmation) return s;
    }
    return null;
  }

  DateTime? get startDateDt =>
      startDate == null ? null : DateTime.tryParse(startDate!)?.toLocal();

  /// Mô tả lịch tuần rút gọn, ví dụ "T3, T5 · 19:00".
  String get scheduleLabel {
    if (schedule.isEmpty) return '';

    final days = <int>[];
    for (final s in schedule) {
      if (!days.contains(s.dayOfWeek)) days.add(s.dayOfWeek);
    }
    days.sort();

    const maxDays = 3;
    final shown = days.take(maxDays).map(_viWeekdayShort).join(', ');
    final suffix = days.length > maxDays ? '…' : '';

    final time = schedule.first.startTime;
    return time.isEmpty ? '$shown$suffix' : '$shown$suffix · ${_hhmm(time)}';
  }
}

/// Khung giờ cố định hằng tuần của lớp.
class WeeklySlotDto {
  const WeeklySlotDto({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory WeeklySlotDto.fromJson(Map<String, dynamic> j) => WeeklySlotDto(
    dayOfWeek: (j['dayOfWeek'] as num?)?.toInt() ?? 0,
    startTime: j['startTime'] as String? ?? '',
    endTime: j['endTime'] as String? ?? '',
  );

  /// ISO: 1 = Thứ hai … 7 = Chủ nhật (BE quy đổi từ C# DayOfWeek sang ISO).
  final int dayOfWeek;
  final String startTime;
  final String endTime;
}

enum ClassStatusType {
  unpaid,
  pendingTutor,
  depositPaid,
  active,
  pendingRemaining,
  completed,
  cancelled,
  expired,
}

class StudentClassPagedResult {
  const StudentClassPagedResult({
    required this.items,
    required this.totalCount,
  });

  factory StudentClassPagedResult.fromJson(Map<String, dynamic> j) {
    final content = j['content'] as Map<String, dynamic>? ?? j;
    final rawItems = content['items'] as List<dynamic>? ?? const [];
    return StudentClassPagedResult(
      items: rawItems
          .map((e) => StudentClassDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: content['totalCount'] as int? ?? rawItems.length,
    );
  }

  final List<StudentClassDto> items;
  final int totalCount;
}

/// Tổng quan tiến độ học của học sinh
class StudyProgressSummary {
  const StudyProgressSummary({
    required this.activeClasses,
    required this.totalSessions,
    required this.doneSessions,
    required this.hoursLearned,
    required this.pendingConfirmCount,
    this.nextSession,
    this.nextSessionClassName,
  });

  factory StudyProgressSummary.fromClasses(List<StudentClassDto> classes) {
    final ongoing = classes.where((c) => c.isOngoing).toList();
    var total = 0;
    var done = 0;
    var minutes = 0;
    var pending = 0;
    ClassSessionSlotDto? next;
    String? nextClassName;

    for (final c in classes) {
      if (c.statusType == ClassStatusType.cancelled ||
          c.statusType == ClassStatusType.expired) {
        continue;
      }
      total += c.countedSessions;
      done += c.doneSessions;
      // Giờ đã học đếm CẢ buổi phụ
      minutes +=
          c.sessions.where((s) => s.isCounted && s.isFinished).length *
          (c.durationMinutes ?? 60);
      if (c.awaitingConfirmSession != null) pending++;

      final candidate = c.nextSession;
      if (candidate != null &&
          (next == null || candidate.startDt.isBefore(next.startDt))) {
        next = candidate;
        nextClassName = c.title;
      }
    }

    return StudyProgressSummary(
      activeClasses: ongoing.length,
      totalSessions: total,
      doneSessions: done,
      hoursLearned: minutes / 60,
      pendingConfirmCount: pending,
      nextSession: next,
      nextSessionClassName: nextClassName,
    );
  }

  final int activeClasses;
  final int totalSessions;
  final int doneSessions;
  final double hoursLearned;
  final int pendingConfirmCount;
  final ClassSessionSlotDto? nextSession;
  final String? nextSessionClassName;

  double get progress =>
      totalSessions == 0 ? 0 : (doneSessions / totalSessions).clamp(0.0, 1.0);

  int get progressPercent => (progress * 100).round();

  String get hoursLabel {
    if (hoursLearned >= 10) return hoursLearned.round().toString();
    return hoursLearned.toStringAsFixed(1).replaceAll('.0', '');
  }
}

String _viWeekday(int weekday) => const [
  'Thứ 2',
  'Thứ 3',
  'Thứ 4',
  'Thứ 5',
  'Thứ 6',
  'Thứ 7',
  'Chủ nhật',
][weekday - 1];

/// BE trả ISO: 1 = Thứ hai … 7 = Chủ nhật.
String _viWeekdayShort(int isoDayOfWeek) {
  const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  if (isoDayOfWeek < 1 || isoDayOfWeek > 7) return '';
  return labels[isoDayOfWeek - 1];
}

/// "19:00:00" → "19:00"
String _hhmm(String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  return '${parts[0].padLeft(2, '0')}:${parts[1]}';
}
