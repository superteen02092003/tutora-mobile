class ScheduleSlotDto {
  const ScheduleSlotDto({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final int dayOfWeek;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}

class CreateBookingRequest {
  const CreateBookingRequest({
    required this.studentId,
    required this.tutorId,
    required this.subjectId,
    required this.teachingMode,
    required this.startDate,
    required this.schedule,
    this.locationCity,
    this.locationDistrict,
    this.locationWard,
    this.locationDetail,
    this.promotionCode,
  });

  final String studentId;
  final String tutorId;
  final int subjectId;
  final String teachingMode;
  final String startDate;
  final List<ScheduleSlotDto> schedule;
  final String? locationCity;
  final String? locationDistrict;
  final String? locationWard;
  final String? locationDetail;
  final String? promotionCode;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'studentId': studentId,
      'tutorId': tutorId,
      'subjectId': subjectId,
      'teachingMode': teachingMode,
      'startDate': startDate,
      'schedule': schedule.map((s) => s.toJson()).toList(),
    };
    if (locationCity?.isNotEmpty ?? false) m['locationCity'] = locationCity;
    if (locationDistrict?.isNotEmpty ?? false) {
      m['locationDistrict'] = locationDistrict;
    }
    if (locationWard?.isNotEmpty ?? false) m['locationWard'] = locationWard;
    if (locationDetail?.isNotEmpty ?? false) {
      m['locationDetail'] = locationDetail;
    }
    if (promotionCode?.isNotEmpty ?? false) m['promotionCode'] = promotionCode;
    return m;
  }
}

class CreateBookingResponse {
  const CreateBookingResponse({this.bookingId});

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? json;
    return CreateBookingResponse(
      bookingId: content['bookingId'] as int?,
    );
  }

  final int? bookingId;
}

class StudentSummaryDto {
  const StudentSummaryDto({
    required this.studentId,
    required this.fullName,
    this.gradeLevel,
    this.school,
    this.avatarUrl,
  });

  factory StudentSummaryDto.fromJson(Map<String, dynamic> json) =>
      StudentSummaryDto(
        studentId: json['studentId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        gradeLevel: json['gradeLevel'] as String?,
        school: json['school'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  final String studentId;
  final String fullName;
  final String? gradeLevel;
  final String? school;
  final String? avatarUrl;

  String get displayGrade => gradeLevel ?? school ?? '';
}
