import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';

/// Bản sao logic _conflictsBooked để khoá quy tắc chồng giờ.
bool conflicts({
  required DateTime startDate,
  required int weekday,
  required int startMins,
  required int durMins,
  required List<({DateTime start, DateTime end})> booked,
}) {
  for (final d in sessionDatesInWindow(start: startDate, weekdays: [weekday])) {
    final s = d.add(Duration(minutes: startMins));
    final e = s.add(Duration(minutes: durMins));
    if (booked.any((b) => s.isBefore(b.end) && e.isAfter(b.start))) return true;
  }
  return false;
}

void main() {
  final start = DateTime(2026, 8, 15); // T7

  test('trùng đúng giờ -> chặn', () {
    final booked = [
      (
        start: DateTime(2026, 8, 17, 14, 30),
        end: DateTime(2026, 8, 17, 15, 30),
      ),
    ];
    expect(
      conflicts(
        startDate: start,
        weekday: 1,
        startMins: 870,
        durMins: 60,
        booked: booked,
      ),
      isTrue,
    );
  });

  test('chồng một phần -> vẫn chặn', () {
    final booked = [
      (start: DateTime(2026, 8, 17, 15), end: DateTime(2026, 8, 17, 16)),
    ];
    expect(
      conflicts(
        startDate: start,
        weekday: 1,
        startMins: 870,
        durMins: 60,
        booked: booked,
      ),
      isTrue,
    );
  });

  test('kề nhau, không chồng -> cho chọn', () {
    // Đã dạy 15:30-16:30, chọn 14:30-15:30 → sát nhau nhưng không đè.
    final booked = [
      (
        start: DateTime(2026, 8, 17, 15, 30),
        end: DateTime(2026, 8, 17, 16, 30),
      ),
    ];
    expect(
      conflicts(
        startDate: start,
        weekday: 1,
        startMins: 870,
        durMins: 60,
        booked: booked,
      ),
      isFalse,
    );
  });

  test('trùng giờ nhưng khác ngày -> cho chọn', () {
    final booked = [
      (
        start: DateTime(2026, 9, 30, 14, 30),
        end: DateTime(2026, 9, 30, 15, 30),
      ),
    ];
    expect(
      conflicts(
        startDate: start,
        weekday: 1,
        startMins: 870,
        durMins: 60,
        booked: booked,
      ),
      isFalse,
    );
  });

  test('chỉ 1 trong 5 buổi bị trùng -> vẫn chặn cả khung', () {
    final booked = [
      (start: DateTime(2026, 9, 7, 14, 30), end: DateTime(2026, 9, 7, 15, 30)),
    ];
    expect(
      conflicts(
        startDate: start,
        weekday: 1,
        startMins: 870,
        durMins: 60,
        booked: booked,
      ),
      isTrue,
    );
  });
}
