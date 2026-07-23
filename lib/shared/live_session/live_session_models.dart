// Model cho luồng vào phòng học Agora (lease-based).
//
// Backend: POST /api/agora/room/{classSessionId}/join|heartbeat|leave|takeover.
// Envelope payload nằm trong `content` (camelCase).

/// Danh tính thiết bị gửi kèm mỗi lần join/takeover.
class LiveSessionIdentity {
  const LiveSessionIdentity({
    required this.participationId,
    required this.deviceId,
    required this.deviceLabel,
  });

  /// GUID cho lần tham gia hiện tại (đổi mỗi lần join mới).
  final String participationId;

  /// GUID nhận diện thiết bị (lưu bền qua secure storage).
  final String deviceId;

  /// Nhãn thiết bị dễ đọc (VD: "Android · Pixel 7"), tối đa 120 ký tự.
  final String deviceLabel;

  Map<String, dynamic> toJson() => {
    'participationId': participationId,
    'deviceId': deviceId,
    'deviceLabel': deviceLabel,
  };
}

/// Thông tin phòng trả về sau join/takeover thành công.
class LiveSessionRoom {
  const LiveSessionRoom({
    required this.channel,
    required this.classSessionId,
    required this.uid,
    required this.token,
    required this.appId,
    required this.expireAt,
    required this.participationId,
    required this.leaseId,
    this.startedAt,
    this.tutorName = '',
    this.studentName = '',
    this.participantNames = const {},
    this.status,
    this.checkedIn = false,
  });

  factory LiveSessionRoom.fromJson(Map<String, dynamic> j) => LiveSessionRoom(
    channel: j['channel'] as String? ?? '',
    classSessionId: (j['classSessionId'] as num?)?.toInt() ?? 0,
    uid: j['uid'] as String? ?? '',
    token: j['token'] as String? ?? '',
    appId: j['appId'] as String? ?? '',
    expireAt: (j['expireAt'] as num?)?.toInt() ?? 0,
    participationId: j['participationId'] as String? ?? '',
    leaseId: j['leaseId'] as String? ?? '',
    startedAt: j['startedAt'] as String?,
    tutorName: j['tutorName'] as String? ?? '',
    studentName: j['studentName'] as String? ?? '',
    participantNames:
        (j['participantNames'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as String? ?? ''),
        ) ??
        const {},
    status: j['status'] as String?,
    checkedIn: j['checkedIn'] as bool? ?? false,
  );

  final String channel;
  final int classSessionId;

  /// Agora user account = UserId của người dùng.
  final String uid;

  /// RTC token — chỉ sống ~120s, phải gia hạn bằng cách join lại.
  final String token;
  final String appId;

  /// Unix seconds token hết hạn.
  final int expireAt;

  /// Lease credentials — dùng cho heartbeat/leave/takeover.
  final String participationId;
  final String leaseId;

  final String? startedAt;
  final String tutorName;
  final String studentName;
  final Map<String, String> participantNames;
  final String? status;
  final bool checkedIn;

  bool get isValid =>
      appId.isNotEmpty && channel.isNotEmpty && token.isNotEmpty;

  /// Lease dùng cho heartbeat/leave.
  Map<String, dynamic> get leaseJson => {
    'participationId': participationId,
    'leaseId': leaseId,
  };
}

/// Trạng thái presence trả về sau mỗi heartbeat.
class LiveSessionPresence {
  const LiveSessionPresence({
    required this.tutorPresent,
    required this.studentPresent,
    required this.isCheckedIn,
    required this.roomClosed,
    required this.blockedByPayment,
    required this.isRecording,
  });

  factory LiveSessionPresence.fromJson(Map<String, dynamic> j) =>
      LiveSessionPresence(
        tutorPresent: j['tutorPresent'] as bool? ?? false,
        studentPresent: j['studentPresent'] as bool? ?? false,
        isCheckedIn: j['isCheckedIn'] as bool? ?? false,
        roomClosed: j['roomClosed'] as bool? ?? false,
        blockedByPayment: j['blockedByPayment'] as bool? ?? false,
        isRecording: j['isRecording'] as bool? ?? false,
      );

  final bool tutorPresent;
  final bool studentPresent;
  final bool isCheckedIn;

  /// Phòng đã đóng — client phải tự rời.
  final bool roomClosed;

  /// Bị chặn do phụ huynh chưa thanh toán các buổi còn lại.
  final bool blockedByPayment;
  final bool isRecording;
}

/// Xung đột: phiên đang mở trên thiết bị khác (409 SESSION_ACTIVE_ON_ANOTHER_DEVICE).
class ActiveSessionConflict {
  const ActiveSessionConflict({
    required this.activeLeaseId,
    this.activeDeviceLabel,
  });

  final String activeLeaseId;
  final String? activeDeviceLabel;
}
