import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';

void main() {
  test('day part boundaries', () {
    expect(DayPartX.of('06:00'), DayPart.morning);
    expect(DayPartX.of('10:30'), DayPart.morning);
    expect(DayPartX.of('11:00'), DayPart.afternoon);
    expect(DayPartX.of('16:30'), DayPart.afternoon);
    expect(DayPartX.of('17:00'), DayPart.evening);
    expect(DayPartX.of('21:30'), DayPart.evening);
  });

  test('toMins tolerates locale 12h form', () {
    expect(toMins('14:30'), 14 * 60 + 30);
    expect(toMins('12:00 SA'), 0);
    expect(toMins('2:30 CH'), 14 * 60 + 30);
    expect(toMins('12:00 CH'), 12 * 60);
    expect(toMins('rubbish'), 0);
  });

  test('normalizeTime pads', () {
    expect(normalizeTime('9:05'), '09:05');
    expect(normalizeTime('14:00:00'), '14:00');
  });

  test('groupByDayPart sorts and buckets', () {
    final g = groupByDayPart(['19:00', '07:00', '13:00', '08:30']);
    expect(g[DayPart.morning], ['07:00', '08:30']);
    expect(g[DayPart.afternoon], ['13:00']);
    expect(g[DayPart.evening], ['19:00']);
  });

  _utcGroup();
}

void _utcGroup() {
  final offsetH = DateTime.now().timeZoneOffset.inHours;

  test('fixedSlotToLocal shifts clock by machine offset', () {
    final r = fixedSlotToLocal(
      isoDayOfWeek: 1,
      startUtc: '07:00',
      endUtc: '09:00',
    );
    final expectedStart = (7 + offsetH) % 24;
    expect(r.startTime, '${expectedStart.toString().padLeft(2, '0')}:00');
    // Buổi vẫn dài đúng 2 tiếng sau khi đổi.
    expect(toMins(r.endTime) - toMins(r.startTime), 120);
  });

  test('fixedSlotToLocal keeps duration across midnight wrap', () {
    final r = fixedSlotToLocal(
      isoDayOfWeek: 3,
      startUtc: '22:00',
      endUtc: '23:30',
    );
    final dur = (toMins(r.endTime) - toMins(r.startTime) + 1440) % 1440;
    expect(dur, 90);
  });

  test('ISO day maps into 0=CN..6=T7 range', () {
    for (var iso = 1; iso <= 7; iso++) {
      final r = fixedSlotToLocal(
        isoDayOfWeek: iso,
        startUtc: '03:00',
        endUtc: '04:00',
      );
      expect(r.dayOfWeek, inInclusiveRange(0, 6), reason: 'ISO $iso');
    }
  });
}
