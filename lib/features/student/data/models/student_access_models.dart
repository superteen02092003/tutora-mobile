/// Kết quả OCR sau khi upload 2 mặt CCCD.
class CccdVerifyResult {
  const CccdVerifyResult({
    required this.ocrSuccess,
    required this.message,
    this.fullName,
    this.dateOfBirth,
    this.identityNumber,
  });

  factory CccdVerifyResult.fromJson(
    Map<String, dynamic> j, {
    String? fallbackMessage,
  }) => CccdVerifyResult(
    ocrSuccess: (j['ocrSuccess'] as bool?) ?? false,
    message:
        (j['message'] as String?) ??
        fallbackMessage ??
        'Đã gửi CCCD để xác minh.',
    fullName: j['fullName'] as String?,
    dateOfBirth: j['dateOfBirth'] as String?,
    identityNumber: j['identityNumber'] as String?,
  );

  final bool ocrSuccess;
  final String message;
  final String? fullName;
  final String? dateOfBirth;
  final String? identityNumber;

  /// Che 4 số cuối để không phơi số CCCD đầy đủ trên màn hình.
  String? get maskedIdentity {
    final id = identityNumber;
    if (id == null || id.length < 4) return id;
    return '${'•' * (id.length - 4)}${id.substring(id.length - 4)}';
  }
}

/// Quyền đặt lịch của học sinh — map theo
class BookingEligibilityDto {
  const BookingEligibilityDto({
    required this.canBook,
    required this.isParentManaged,
    required this.needProfile,
    required this.needAgeVerification,
    required this.isUnderage,
    this.reasonCode,
    this.reason,
    this.age,
  });

  factory BookingEligibilityDto.fromJson(Map<String, dynamic> json) {
    final c = json['content'] as Map<String, dynamic>? ?? json;
    return BookingEligibilityDto(
      canBook: (c['canBook'] as bool?) ?? false,
      isParentManaged: (c['isParentManaged'] as bool?) ?? false,
      needProfile: (c['needProfile'] as bool?) ?? false,
      needAgeVerification: (c['needAgeVerification'] as bool?) ?? false,
      isUnderage: (c['isUnderage'] as bool?) ?? false,
      reasonCode: c['reasonCode'] as String?,
      reason: c['reason'] as String?,
      age: (c['age'] as num?)?.toInt(),
    );
  }

  /// Không gọi được API → chặn đặt lịch nhưng KHÔNG hiện lý do sai lệch.
  const BookingEligibilityDto.blocked()
    : canBook = false,
      isParentManaged = false,
      needProfile = false,
      needAgeVerification = false,
      isUnderage = false,
      reasonCode = null,
      reason = null,
      age = null;

  final bool canBook;

  /// Tài khoản do phụ huynh tạo — chỉ học & theo dõi, bố mẹ mới đặt lịch được.
  final bool isParentManaged;
  final bool needProfile;
  final bool needAgeVerification;
  final bool isUnderage;
  final String? reasonCode;

  /// Lý do BE muốn hiển thị cho người dùng khi [canBook] = false.
  final String? reason;
  final int? age;
}
