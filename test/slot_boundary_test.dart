import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';

/// Bản sao logic sinh chip trong _timeSlotsForDay để khoá quy tắc biên.
List<String> slotsIn(String start, String end, int durMins) {
  final out = <String>[];
  var cur = toMins(start);
  final e = toMins(end);
  while (cur + durMins <= e) {
    out.add(
      '${(cur ~/ 60).toString().padLeft(2, '0')}:'
      '${(cur % 60).toString().padLeft(2, '0')}',
    );
    cur += 30;
  }
  return out;
}

void main() {
  test('rảnh 14:30-16:00, buổi 60p -> chỉ 2 mốc', () {
    expect(slotsIn('14:30', '16:00', 60), ['14:30', '15:00']);
  });

  test('rảnh 14:30-16:30, buổi 60p -> 15:30 hợp lệ vì kết thúc đúng 16:30', () {
    expect(slotsIn('14:30', '16:30', 60), ['14:30', '15:00', '15:30']);
  });

  test('buổi không bao giờ vượt quá giờ rảnh', () {
    for (final dur in [60, 90, 120]) {
      for (final s in slotsIn('14:30', '16:00', dur)) {
        expect(
          toMins(s) + dur <= toMins('16:00'),
          isTrue,
          reason: 'dur=$dur start=$s',
        );
      }
    }
  });

  test('khung ngắn hơn buổi học -> không có mốc nào', () {
    expect(slotsIn('14:30', '15:00', 60), isEmpty);
  });
}
