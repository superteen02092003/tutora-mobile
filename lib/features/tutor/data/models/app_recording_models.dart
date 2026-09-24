/// Kết quả mở một bản ghi cho buổi học.
class AppRecordingStartDto {
  const AppRecordingStartDto({
    required this.recordingId,
    required this.studentName,
    required this.uploadedParts,
  });

  factory AppRecordingStartDto.fromJson(Map<String, dynamic> j) =>
      AppRecordingStartDto(
        recordingId: j['recordingId'] as String? ?? '',
        studentName: j['studentName'] as String? ?? '',
        // > 0 khi mở lại bản ghi còn dở: app biết đánh số đoạn tiếp từ đâu.
        uploadedParts: j['uploadedParts'] as int? ?? 0,
      );

  final String recordingId;
  final String studentName;
  final int uploadedParts;
}

/// URL presigned để PUT thẳng một đoạn lên kho, không đi qua backend.
class AppRecordingUploadUrlDto {
  const AppRecordingUploadUrlDto({
    required this.partNumber,
    required this.url,
  });

  factory AppRecordingUploadUrlDto.fromJson(Map<String, dynamic> j) =>
      AppRecordingUploadUrlDto(
        partNumber: j['partNumber'] as int? ?? 0,
        url: j['url'] as String? ?? '',
      );

  final int partNumber;
  final String url;
}

/// Tóm tắt buổi (biên bản ngắn) cho gia sư — thay cho lời thoại đầy đủ.
class SessionMinutesDto {
  const SessionMinutesDto({
    this.summary,
    this.keyPoints = const [],
    this.followUps = const [],
  });

  factory SessionMinutesDto.fromJson(Map<String, dynamic> j) =>
      SessionMinutesDto(
        summary: j['summary'] as String?,
        keyPoints: _strings(j['keyPoints']),
        followUps: _strings(j['followUps']),
      );

  static List<String> _strings(Object? v) => v is List
      ? v
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
      : const [];

  final String? summary;

  /// Ý chính của buổi.
  final List<String> keyPoints;

  /// Việc cần làm buổi sau.
  final List<String> followUps;

  bool get isEmpty =>
      (summary ?? '').trim().isEmpty && keyPoints.isEmpty && followUps.isEmpty;
}

/// Trạng thái bản ghi + báo cáo AI khi đã có.
class AppRecordingStatusDto {
  const AppRecordingStatusDto({
    required this.recordingId,
    required this.status,
    required this.aiStatus,
    this.classSessionId,
    this.partCount = 0,
    this.bytes = 0,
    this.durationSec = 0,
    this.lessonContent,
    this.homework,
    this.tutorNotes,
    this.zaloContent,
    this.zaloHomework,
    this.zaloNotes,
    this.errorMessage,
    this.studentId,
    this.studentName = '',
    this.deliveryChannel,
    this.deliveryStatus,
    this.grade,
    this.subject,
    this.scheduledStart,
    this.startedAt,
    this.endedAt,
    this.approvedAt,
    this.sentAt,
    this.transcript,
    this.transcriptStatus = 'none',
    this.audioAvailable = false,
    this.audioExpiresAt,
    this.sessionMinutes,
    this.parentPhone,
    this.deliveryError,
  });

  factory AppRecordingStatusDto.fromJson(Map<String, dynamic> j) =>
      AppRecordingStatusDto(
        recordingId: j['recordingId'] as String? ?? '',
        classSessionId: (j['classSessionId'] as num?)?.toInt(),
        status: j['status'] as String? ?? 'recording',
        aiStatus: j['aiStatus'] as String? ?? 'none',
        partCount: j['partCount'] as int? ?? 0,
        bytes: (j['bytes'] as num?)?.toInt() ?? 0,
        durationSec: j['durationSec'] as int? ?? 0,
        lessonContent: j['lessonContent'] as String?,
        homework: j['homework'] as String?,
        tutorNotes: j['tutorNotes'] as String?,
        zaloContent: j['zaloContent'] as String?,
        zaloHomework: j['zaloHomework'] as String?,
        zaloNotes: j['zaloNotes'] as String?,
        errorMessage: j['errorMessage'] as String?,
        studentId: j['studentId'] as String?,
        studentName: j['studentName'] as String? ?? '',
        deliveryChannel: j['deliveryChannel'] as String?,
        deliveryStatus: j['deliveryStatus'] as String?,
        grade: (j['grade'] as num?)?.toInt(),
        subject: j['subject'] as String?,
        scheduledStart: _t(j['scheduledStart']),
        startedAt: _t(j['startedAt']),
        endedAt: _t(j['endedAt']),
        approvedAt: _t(j['approvedAt']),
        sentAt: _t(j['sentAt']),
        transcript: j['transcript'] as String?,
        transcriptStatus: j['transcriptStatus'] as String? ?? 'none',
        audioAvailable: j['audioAvailable'] as bool? ?? false,
        audioExpiresAt: _t(j['audioExpiresAt']),
        sessionMinutes: j['sessionMinutes'] is Map<String, dynamic>
            ? SessionMinutesDto.fromJson(
                j['sessionMinutes'] as Map<String, dynamic>,
              )
            : null,
        parentPhone: j['parentPhone'] as String?,
        deliveryError: j['deliveryError'] as String?,
      );

  /// BE lưu `timestamp without time zone` theo UTC và trả về KHÔNG có "Z" —
  /// phải ép hiểu là UTC rồi mới đổi sang giờ máy.
  static DateTime? _t(Object? v) {
    if (v is! String || v.isEmpty) return null;
    final hasZone = v.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(v);
    return DateTime.tryParse(hasZone ? v : '${v}Z')?.toLocal();
  }

  final String recordingId;

  /// Có khi buổi thuộc booking; null với học sinh ngoài nền tảng.
  final int? classSessionId;

  /// Học sinh ngoài nền tảng (recorder.students).
  final String? studentId;
  final String studentName;

  /// booking | zns
  final String? deliveryChannel;

  /// pending | sent | failed
  final String? deliveryStatus;

  final int? grade;
  final String? subject;
  final DateTime? scheduledStart;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? approvedAt;
  final DateTime? sentAt;

  /// Lời thoại: mỗi dòng "[mm:ss] Gia sư: …".
  final String? transcript;

  /// none | pending | processing | completed | failed
  final String transcriptStatus;

  /// Còn file để nghe lại không (hết 30 ngày thì bị xoá).
  final bool audioAvailable;
  final DateTime? audioExpiresAt;

  /// Tóm tắt buổi; null với buổi cũ.
  final SessionMinutesDto? sessionMinutes;

  /// SĐT phụ huynh (để mở chat Zalo khi chia sẻ thủ công).
  final String? parentPhone;

  /// Lý do gửi Zalo thất bại (khi deliveryStatus = failed).
  final String? deliveryError;

  bool get isTranscriptRunning =>
      transcriptStatus == 'pending' || transcriptStatus == 'processing';

  /// recording | uploading | processing | awaiting_approval | sent | failed | discarded
  final String status;

  /// pending | processing | completed | failed | none
  final String aiStatus;

  final int partCount;
  final int bytes;
  final int durationSec;
  final String? lessonContent;
  final String? homework;
  final String? tutorNotes;

  /// Tin Zalo ngắn gửi phụ huynh (≤ 90 ký tự mỗi mục): bản gia sư đã duyệt,
  /// chưa duyệt thì là bản nháp AI; null với buổi cũ.
  final String? zaloContent;
  final String? zaloHomework;
  final String? zaloNotes;
  final String? errorMessage;

  bool get isAiDone => aiStatus == 'completed';
  bool get isAiFailed => aiStatus == 'failed';
  bool get isAiRunning => aiStatus == 'pending' || aiStatus == 'processing';

  bool get isAwaitingApproval => status == 'awaiting_approval';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed' || isAiFailed;
}
