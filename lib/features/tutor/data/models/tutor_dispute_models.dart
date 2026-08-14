/// Model khiếu nại (tranh chấp) phía gia sư.
///
/// Backend: `GET /api/tutor/disputes` trả `PagedList<DisputeListResponse>` —
/// lớp này kế thừa `List<T>` nên serialize ra **mảng JSON**, không phải object
/// có `items`. Vì vậy `content` của envelope là một array.
library;

/// Trạng thái khiếu nại — khớp `DisputeStatus` của backend.
enum DisputeStatus {
  pending,
  investigating,
  confirmedNoShow,
  resolved,
  closed,
  unknown
  ;

  static DisputeStatus parse(String? raw) => switch (raw?.toLowerCase()) {
    'pending' => DisputeStatus.pending,
    'investigating' => DisputeStatus.investigating,
    'confirmed_no_show' || 'confirmednoshow' => DisputeStatus.confirmedNoShow,
    'resolved' => DisputeStatus.resolved,
    'closed' => DisputeStatus.closed,
    _ => DisputeStatus.unknown,
  };

  String get label => switch (this) {
    DisputeStatus.pending => 'Chờ xử lý',
    DisputeStatus.investigating => 'Đang điều tra',
    DisputeStatus.confirmedNoShow => 'Xác nhận vắng mặt',
    DisputeStatus.resolved => 'Đã giải quyết',
    DisputeStatus.closed => 'Đã đóng',
    DisputeStatus.unknown => 'Không xác định',
  };

  /// Còn cần gia sư theo dõi / phản hồi.
  bool get isOpen =>
      this == DisputeStatus.pending || this == DisputeStatus.investigating;
}

/// Loại khiếu nại — khớp `DisputeTypes` của backend.
enum DisputeType {
  noShow,
  quality,
  payment,
  other
  ;

  static DisputeType parse(String? raw) => switch (raw?.toLowerCase()) {
    'no_show' || 'noshow' => DisputeType.noShow,
    'quality' => DisputeType.quality,
    'payment' => DisputeType.payment,
    _ => DisputeType.other,
  };

  String get label => switch (this) {
    DisputeType.noShow => 'Vắng mặt',
    DisputeType.quality => 'Chất lượng',
    DisputeType.payment => 'Thanh toán',
    DisputeType.other => 'Khác',
  };
}

/// Một dòng trong danh sách khiếu nại.
class TutorDisputeDto {
  const TutorDisputeDto({
    required this.disputeId,
    required this.classSessionId,
    required this.type,
    required this.status,
    required this.reason,
    required this.createdByName,
    required this.sessionPrice,
    required this.createdAt,
  });

  factory TutorDisputeDto.fromJson(Map<String, dynamic> j) => TutorDisputeDto(
    disputeId: j['disputeId'] as int? ?? 0,
    classSessionId: j['classSessionId'] as int?,
    type: DisputeType.parse(j['disputeType'] as String?),
    status: DisputeStatus.parse(j['status'] as String?),
    reason: j['reason'] as String? ?? '',
    createdByName: j['createdByName'] as String? ?? 'Người học',
    sessionPrice: (j['classSessionPrice'] as num?)?.toDouble(),
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
  );

  final int disputeId;
  final int? classSessionId;
  final DisputeType type;
  final DisputeStatus status;
  final String reason;

  /// Người gửi khiếu nại (phụ huynh / học sinh).
  final String createdByName;
  final double? sessionPrice;
  final DateTime? createdAt;
}

/// Chi tiết một khiếu nại, kèm phần phản hồi của gia sư.
class TutorDisputeDetailDto {
  const TutorDisputeDetailDto({
    required this.disputeId,
    required this.classSessionId,
    required this.type,
    required this.status,
    required this.reason,
    required this.evidence,
    required this.createdByName,
    required this.createdAt,
    required this.tutorResponse,
    required this.tutorRespondedAt,
    required this.resolutionNote,
    required this.refundAmount,
    required this.sessionStart,
    required this.sessionPrice,
    required this.recordingUrl,
    required this.additionalEvidence,
  });

  factory TutorDisputeDetailDto.fromJson(Map<String, dynamic> j) {
    final session = j['classSession'] as Map<String, dynamic>?;
    final createdBy = j['createdBy'] as Map<String, dynamic>?;

    return TutorDisputeDetailDto(
      disputeId: j['disputeId'] as int? ?? 0,
      classSessionId: j['classSessionId'] as int?,
      type: DisputeType.parse(j['disputeType'] as String?),
      status: DisputeStatus.parse(j['status'] as String?),
      reason: j['reason'] as String? ?? '',
      evidence:
          (j['evidence'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      createdByName: createdBy?['fullName'] as String? ?? 'Người học',
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      tutorResponse: j['tutorResponse'] as String?,
      tutorRespondedAt: DateTime.tryParse(
        j['tutorRespondedAt'] as String? ?? '',
      ),
      resolutionNote: j['resolutionNote'] as String?,
      refundAmount: (j['refundAmount'] as num?)?.toDouble(),
      sessionStart: DateTime.tryParse(
        session?['scheduledStart'] as String? ?? '',
      ),
      sessionPrice: (session?['classSessionPrice'] as num?)?.toDouble(),
      recordingUrl: session?['recordingUrl'] as String?,
      additionalEvidence:
          (j['additionalEvidence'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DisputeEvidenceItem.fromJson)
              .toList() ??
          const [],
    );
  }

  final int disputeId;
  final int? classSessionId;
  final DisputeType type;
  final DisputeStatus status;
  final String reason;

  /// Ảnh/tệp người học nộp khi tạo khiếu nại.
  final List<String> evidence;
  final String createdByName;
  final DateTime? createdAt;

  /// Phản hồi gia sư đã gửi; null nghĩa là chưa phản hồi.
  final String? tutorResponse;
  final DateTime? tutorRespondedAt;
  final String? resolutionNote;
  final double? refundAmount;
  final DateTime? sessionStart;
  final double? sessionPrice;
  final String? recordingUrl;

  /// Bằng chứng nộp thêm từ cả hai phía sau khi khiếu nại được tạo.
  final List<DisputeEvidenceItem> additionalEvidence;

  /// Bằng chứng do chính gia sư nộp.
  List<DisputeEvidenceItem> get myEvidence =>
      additionalEvidence.where((e) => e.isFromTutor).toList();

  bool get hasResponded =>
      tutorResponse != null && tutorResponse!.trim().isNotEmpty;

  /// Gia sư chỉ được nộp phản hồi/bằng chứng vào hồ sơ khi khiếu nại còn ở
  /// `pending`. Từ `investigating` trở đi backend chặn (chỉ còn kênh chat với
  /// admin) — đừng nới thành `status.isOpen`.
  bool get canRespond => status == DisputeStatus.pending;

  /// Hạn phản hồi 48h kể từ lúc khiếu nại được tạo (khớp
  /// `TutorResponseDeadline` của backend).
  DateTime? get responseDeadline => createdAt?.add(const Duration(hours: 48));
}

/// Bằng chứng nộp thêm sau khi khiếu nại đã tạo (bảng `dispute_evidences`).
class DisputeEvidenceItem {
  const DisputeEvidenceItem({
    required this.id,
    required this.fileUrl,
    required this.source,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory DisputeEvidenceItem.fromJson(Map<String, dynamic> j) =>
      DisputeEvidenceItem(
        id: j['disputeEvidenceId'] as int? ?? 0,
        fileUrl: j['fileUrl'] as String? ?? '',
        source: j['source'] as String? ?? 'unknown',
        uploadedByName: j['uploadedByName'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );

  final int id;
  final String fileUrl;

  /// Bên nộp: `tutor` hoặc phía người học — backend dùng để tách hai luồng.
  final String source;
  final String uploadedByName;
  final DateTime? createdAt;

  bool get isFromTutor => source.toLowerCase() == 'tutor';
}

/// Một tin nhắn trong luồng trao đổi riêng giữa gia sư và admin.
class DisputeMessageDto {
  const DisputeMessageDto({
    required this.id,
    required this.message,
    required this.senderName,
    required this.senderRole,
    required this.createdAt,
  });

  factory DisputeMessageDto.fromJson(Map<String, dynamic> j) =>
      DisputeMessageDto(
        id: j['disputeMessageId'] as int? ?? 0,
        message: j['message'] as String? ?? '',
        senderName: j['senderName'] as String? ?? '',
        senderRole: j['senderRole'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );

  final int id;
  final String message;
  final String senderName;
  final String senderRole;
  final DateTime? createdAt;

  bool get isFromTutor => senderRole.toLowerCase() == 'tutor';
}
