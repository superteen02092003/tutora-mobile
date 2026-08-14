import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';

void main() {
  test('clamp khi tháng sau không có ngày đó (31/1 -> 28/2)', () {
    expect(bookingWindowEnd(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
    expect(bookingWindowEnd(DateTime(2026, 3, 31)), DateTime(2026, 4, 30));
    expect(bookingWindowEnd(DateTime(2026, 6, 15)), DateTime(2026, 7, 15));
  });

  test('thứ trùng ngày bắt đầu rơi 5 lần (cửa sổ tính cả 2 đầu)', () {
    // 17/08/2026 là thứ 2.
    final d = sessionDatesInWindow(start: DateTime(2026, 8, 17), weekdays: [1]);
    expect(d.length, 5);
  });

  test('thứ khác ngày bắt đầu rơi 4 lần', () {
    final d = sessionDatesInWindow(start: DateTime(2026, 8, 17), weekdays: [5]);
    expect(d.length, 4);
  });

  test('totalSessions khớp số ngày thật, không phải x4', () {
    final f = BookingForm(
      startDate: '2026-08-17',
      schedule: const [
        ScheduleSlotDto(dayOfWeek: 1, startTime: '07:00', endTime: '09:00'),
      ],
    );
    expect(f.totalSessions, 5);
    expect(f.totalHours, 10.0); // 5 buổi x 2h
  });

  test('nhiều buổi/tuần cộng dồn đúng', () {
    final f = BookingForm(
      startDate: '2026-08-17',
      schedule: const [
        ScheduleSlotDto(dayOfWeek: 1, startTime: '07:00', endTime: '09:00'),
        ScheduleSlotDto(dayOfWeek: 5, startTime: '07:00', endTime: '09:00'),
      ],
    );
    expect(f.totalSessions, 9); // 5 + 4
  });

  _durationGroup();
}

void _durationGroup() {
  test('slot sinh ra đúng thời lượng gia sư quy định (60 phút)', () {
    // addHours dựng endTime từ slotDurationHours, đây là nguồn gây 400 trước đây.
    expect(addHours('07:30', 1), '08:30');
    expect(toMins('08:30') - toMins('07:30'), 60);
  });

  test('1.5h sinh buổi 90 phút — sẽ bị BE từ chối nếu giá quy định 60', () {
    expect(addHours('07:30', 1.5), '09:00');
    expect(toMins('09:00') - toMins('07:30'), 90);
  });
}
