import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';

void main() {
  final offH = DateTime.now().timeZoneOffset.inHours;

  test('đổi giờ UTC sang local theo offset máy', () {
    final r = availabilityToLocal(
      isoDayOfWeek: 1,
      startUtc: '07:00',
      endUtc: '10:00',
    );
    expect(r.startTime, '${((7 + offH) % 24).toString().padLeft(2, '0')}:00');
    expect(r.endTime, '${((10 + offH) % 24).toString().padLeft(2, '0')}:00');
  });

  test('giữ nguyên thứ, chỉ đổi giờ — khớp toLocalSlot bên web', () {
    // ISO 1 (T2) -> 1 theo quy ước app 0=CN..6=T7.
    expect(
      availabilityToLocal(
        isoDayOfWeek: 1,
        startUtc: '07:00',
        endUtc: '10:00',
      ).dayOfWeek,
      1,
    );
    // ISO 7 (CN) -> 0.
    expect(
      availabilityToLocal(
        isoDayOfWeek: 7,
        startUtc: '07:00',
        endUtc: '10:00',
      ).dayOfWeek,
      0,
    );
  });

  test('mọi thứ ISO đều ra dayOfWeek hợp lệ 0..6', () {
    for (var iso = 1; iso <= 7; iso++) {
      final r = availabilityToLocal(
        isoDayOfWeek: iso,
        startUtc: '02:00',
        endUtc: '04:00',
      );
      expect(r.dayOfWeek, inInclusiveRange(0, 6), reason: 'ISO $iso');
    }
  });

  test('độ dài khoảng rảnh không đổi sau khi quy đổi', () {
    final r = availabilityToLocal(
      isoDayOfWeek: 3,
      startUtc: '07:00',
      endUtc: '10:00',
    );
    final dur = (toMins(r.endTime) - toMins(r.startTime) + 1440) % 1440;
    expect(dur, 180);
  });
}
