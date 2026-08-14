import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

/// Cách đặt lịch: tự chọn giờ rảnh của gia sư, hoặc lấy nguyên gói cố định.
enum BookingMode { manual, package }

class BookingForm {
  BookingForm({
    this.studentId = '',
    this.subjectId = 0,
    this.tutorSubjectGradePriceId = 0,
    this.selectedGradePrice,
    this.teachingMode = 'online',
    String? startDate,
    this.schedule = const [],
    this.locationCity = '',
    this.locationDistrict = '',
    this.locationWard = '',
    this.locationDetail = '',
    // Chỉ là giá trị tạm trước khi chọn môn; sau đó luôn lấy theo bảng giá.
    this.slotDurationHours = 1.0,
    this.bookingMode = BookingMode.manual,
    this.selectedPackage,
  }) : startDate =
           startDate ?? DateTime.now().toIso8601String().substring(0, 10);

  final String studentId;
  final int subjectId;

  final int tutorSubjectGradePriceId;

  final SubjectGradePriceDto? selectedGradePrice;
  final String teachingMode;
  final String startDate;
  final List<ScheduleSlotDto> schedule;
  final String locationCity;
  final String locationDistrict;
  final String locationWard;
  final String locationDetail;
  final double slotDurationHours;
  final BookingMode bookingMode;
  final TutorPackageDto? selectedPackage;

  BookingForm copyWith({
    String? studentId,
    int? subjectId,
    int? tutorSubjectGradePriceId,
    SubjectGradePriceDto? selectedGradePrice,
    String? teachingMode,
    String? startDate,
    List<ScheduleSlotDto>? schedule,
    String? locationCity,
    String? locationDistrict,
    String? locationWard,
    String? locationDetail,
    double? slotDurationHours,
    BookingMode? bookingMode,
    TutorPackageDto? selectedPackage,
    // copyWith dùng `??` nên không thể gán null; cờ này để bỏ chọn gói.
    bool clearPackage = false,
  }) => BookingForm(
    studentId: studentId ?? this.studentId,
    subjectId: subjectId ?? this.subjectId,
    tutorSubjectGradePriceId:
        tutorSubjectGradePriceId ?? this.tutorSubjectGradePriceId,
    selectedGradePrice: selectedGradePrice ?? this.selectedGradePrice,
    teachingMode: teachingMode ?? this.teachingMode,
    startDate: startDate ?? this.startDate,
    schedule: schedule ?? this.schedule,
    locationCity: locationCity ?? this.locationCity,
    locationDistrict: locationDistrict ?? this.locationDistrict,
    locationWard: locationWard ?? this.locationWard,
    locationDetail: locationDetail ?? this.locationDetail,
    slotDurationHours: slotDurationHours ?? this.slotDurationHours,
    bookingMode: bookingMode ?? this.bookingMode,
    selectedPackage: clearPackage
        ? null
        : (selectedPackage ?? this.selectedPackage),
  );

  bool get needsLocation =>
      teachingMode == 'offline' || teachingMode == 'hybrid';

  /// Số buổi thật trong cửa sổ đặt lịch — đếm theo ngày, KHÔNG nhân ×4.
  int get totalSessions {
    final start = DateTime.tryParse(startDate);
    if (start == null || schedule.isEmpty) return 0;
    var n = 0;
    for (final s in schedule) {
      n += sessionDatesInWindow(start: start, weekdays: [s.dayOfWeek]).length;
    }
    return n;
  }

  /// Tổng giờ tương ứng với [totalSessions].
  double get totalHours {
    final start = DateTime.tryParse(startDate);
    if (start == null) return 0;
    var h = 0.0;
    for (final s in schedule) {
      final hours = (toMins(s.endTime) - toMins(s.startTime)) / 60.0;
      h +=
          hours *
          sessionDatesInWindow(start: start, weekdays: [s.dayOfWeek]).length;
    }
    return h;
  }
}
