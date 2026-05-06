import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';

class BookingForm {
  BookingForm({
    this.studentId = '',
    this.subjectId = 0,
    this.teachingMode = 'online',
    String? startDate,
    this.schedule = const [],
    this.locationCity = '',
    this.locationDistrict = '',
    this.locationWard = '',
    this.locationDetail = '',
    this.slotDurationHours = 2.0,
  }) : startDate =
           startDate ?? DateTime.now().toIso8601String().substring(0, 10);

  final String studentId;
  final int subjectId;
  final String teachingMode;
  final String startDate;
  final List<ScheduleSlotDto> schedule;
  final String locationCity;
  final String locationDistrict;
  final String locationWard;
  final String locationDetail;
  final double slotDurationHours;

  BookingForm copyWith({
    String? studentId,
    int? subjectId,
    String? teachingMode,
    String? startDate,
    List<ScheduleSlotDto>? schedule,
    String? locationCity,
    String? locationDistrict,
    String? locationWard,
    String? locationDetail,
    double? slotDurationHours,
  }) => BookingForm(
    studentId: studentId ?? this.studentId,
    subjectId: subjectId ?? this.subjectId,
    teachingMode: teachingMode ?? this.teachingMode,
    startDate: startDate ?? this.startDate,
    schedule: schedule ?? this.schedule,
    locationCity: locationCity ?? this.locationCity,
    locationDistrict: locationDistrict ?? this.locationDistrict,
    locationWard: locationWard ?? this.locationWard,
    locationDetail: locationDetail ?? this.locationDetail,
    slotDurationHours: slotDurationHours ?? this.slotDurationHours,
  );

  bool get needsLocation =>
      teachingMode == 'offline' || teachingMode == 'hybrid';

  double get totalHoursPerMonth {
    double h = 0;
    for (final s in schedule) {
      final startM = toMins(s.startTime);
      final endM = toMins(s.endTime);
      h += (endM - startM) / 60.0;
    }
    return h * 4;
  }
}
