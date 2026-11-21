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

/// Một phần diễn biến buổi học.
class MinutesSectionDto {
  const MinutesSectionDto({this.title, this.details = const []});

  factory MinutesSectionDto.fromJson(Map<String, dynamic> j) =>
      MinutesSectionDto(
        title: _text(j['title']),
        details: SessionMinutesDto._strings(j['details']),
      );

  final String? title;
  final List<String> details;
}

/// Một bài đã làm — ghi theo dạng bài, không chép đề.
class MinutesExerciseDto {
  const MinutesExerciseDto({required this.type, this.result, this.note});

  factory MinutesExerciseDto.fromJson(Map<String, dynamic> j) =>
      MinutesExerciseDto(
        type: _text(j['type']) ?? '',
        result: _text(j['result']),
        note: _text(j['note']),
      );

  final String type;

  /// "Tự làm đúng" / "Đúng sau khi được gợi ý" / "Làm sai" / "Chưa làm xong" / "Gia sư làm mẫu".
  final String? result;
  final String? note;
}

/// Gợi ý về cách dạy: nhận xét + tình huống/câu hỏi gợi ý.
class TeachingNoteDto {
  const TeachingNoteDto({required this.content, this.example});

  factory TeachingNoteDto.fromJson(Map<String, dynamic> j) => TeachingNoteDto(
    content: _text(j['content']) ?? '',
    example: _text(j['example']),
  );

  final String content;
  final String? example;
}

String? _text(Object? v) {
  final s = v is String ? v.trim() : '';
  return s.isEmpty ? null : s;
}

List<T> _objects<T>(Object? v, T Function(Map<String, dynamic>) parse) =>
    v is List
    ? v.whereType<Map<String, dynamic>>().map(parse).toList()
    : const [];

/// Biên bản buổi học cho gia sư — đọc lại thay cho nghe lại cả buổi.
class SessionMinutesDto {
  const SessionMinutesDto({
    this.summary,
    this.keyPoints = const [],
    this.followUps = const [],
    this.sections = const [],
    this.exercises = const [],
    this.strengths = const [],
    this.difficulties = const [],
    this.usefulNotes = const [],
    this.teachingNotes = const [],
  });

  factory SessionMinutesDto.fromJson(Map<String, dynamic> j) =>
      SessionMinutesDto(
        summary: j['summary'] as String?,
        keyPoints: _strings(j['keyPoints']),
        followUps: _strings(j['followUps']),
        sections: _objects(
          j['sections'],
          MinutesSectionDto.fromJson,
        ).where((s) => s.title != null || s.details.isNotEmpty).toList(),
        exercises: _objects(
          j['exercises'],
          MinutesExerciseDto.fromJson,
        ).where((e) => e.type.isNotEmpty).toList(),
        strengths: _strings(j['strengths']),
        difficulties: _strings(j['difficulties']),
        usefulNotes: _strings(j['usefulNotes']),
        teachingNotes: _objects(
          j['teachingNotes'],
          TeachingNoteDto.fromJson,
        ).where((n) => n.content.isNotEmpty).toList(),
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

  /// Diễn biến buổi học theo thứ tự.
  final List<MinutesSectionDto> sections;

  /// Bài đã làm, theo dạng bài.
  final List<MinutesExerciseDto> exercises;

  /// Học sinh đã nắm.
  final List<String> strengths;

  /// Học sinh còn vướng.
  final List<String> difficulties;

  /// Thông tin hữu ích cho việc dạy.
  final List<String> usefulNotes;

  /// Gợi ý về cách dạy.
  final List<TeachingNoteDto> teachingNotes;

  bool get isEmpty =>
      (summary ?? '').trim().isEmpty &&
      keyPoints.isEmpty &&
      followUps.isEmpty &&
      sections.isEmpty &&
      exercises.isEmpty &&
      strengths.isEmpty &&
      difficulties.isEmpty &&
      usefulNotes.isEmpty &&
      teachingNotes.isEmpty;
}

/// Trạng thái bản ghi + báo cáo AI khi đã có.
/// Sau bao lâu thì báo "AI đang chậm" (một buổi 90 phút thường xong trong 1–2 phút).
const aiSlowAfter = Duration(minutes: 30);

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
    this.aiErrorKind,
    this.canRetry = true,
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
        aiErrorKind: j['aiErrorKind'] as String?,
        // Backend cũ không gửi trường này: vẫn cho thử lại như trước.
        canRetry: j['canRetry'] as bool? ?? true,
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

  /// Loại lỗi AI (billing · quota · auth · rate_limit · timeout · bad_response ·
  /// other · internal); null khi không lỗi hoặc backend cũ.
  final String? aiErrorKind;

  /// false khi lỗi do hệ thống AI của TopTutor (hết tiền, hết hạn mức, sai
  /// quyền): thử lại cũng không được, nên app ẩn nút "Thử lại AI".
  final bool canRetry;

  /// AI chưa xong sau [aiSlowAfter] kể từ khi buổi kết thúc: báo cho gia sư thay
  /// vì để "AI đang viết" mãi (Gemini hỏng 2026-11-06 mà không ai thấy).
  bool isAiSlow([DateTime? now]) {
    final end = endedAt;
    if (!(isAiRunning || status == 'processing') || end == null) return false;
    return (now ?? DateTime.now()).difference(end) > aiSlowAfter;
  }

  bool get isAiDone => aiStatus == 'completed';
  bool get isAiFailed => aiStatus == 'failed';
  bool get isAiRunning => aiStatus == 'pending' || aiStatus == 'processing';

  bool get isAwaitingApproval => status == 'awaiting_approval';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed' || isAiFailed;
}
