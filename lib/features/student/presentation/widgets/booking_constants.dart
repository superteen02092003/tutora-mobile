import 'package:intl/intl.dart';

const List<String> kDayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

const List<String> kDayNamesLong = [
  'Chủ nhật',
  'Thứ 2',
  'Thứ 3',
  'Thứ 4',
  'Thứ 5',
  'Thứ 6',
  'Thứ 7',
];

const List<String> kTimeSlots = [
  '06:00',
  '06:30',
  '07:00',
  '07:30',
  '08:00',
  '08:30',
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
  '17:30',
  '18:00',
  '18:30',
  '19:00',
  '19:30',
  '20:00',
  '20:30',
  '21:00',
  '21:30',
];

// Thời lượng lấy từ durationMinutesPerSession của bảng giá, không cho chọn.

final NumberFormat kCurrencyFmt = NumberFormat('#,###', 'vi_VN');

String formatPrice(double amount) => '${kCurrencyFmt.format(amount.round())}đ';

String addHours(String time, double hours) {
  final totalMins = (toMins(time) + (hours * 60).round()) % (24 * 60);
  final rh = totalMins ~/ 60;
  final rm = totalMins % 60;
  return '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}';
}

/// Chấp nhận cả "HH:mm[:ss]" lẫn dạng 12 giờ theo locale ("2:30 CH") vì BE từng
/// trả giờ theo culture máy chủ; chuỗi không đọc được trả 0 thay vì ném lỗi.
int toMins(String t) {
  final raw = t.trim();
  if (raw.isEmpty) return 0;

  final upper = raw.toUpperCase();
  final isPm = upper.endsWith('CH') || upper.endsWith('PM');
  final isAm = upper.endsWith('SA') || upper.endsWith('AM');

  final digits = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
  if (digits == null) return 0;

  var h = int.tryParse(digits.group(1)!) ?? 0;
  final m = int.tryParse(digits.group(2)!) ?? 0;

  if (isPm && h < 12) h += 12;
  if (isAm && h == 12) h = 0;

  return (h % 24) * 60 + m % 60;
}

String utcTimeOfDayToLocal(String hhmm) => _minsToHhmm(_localMinsOf(hhmm).mins);

/// Giờ UTC → local kèm số ngày bị đẩy (22:00 T2 UTC = 05:00 T3 ở UTC+7).
({int mins, int dayShift}) _localMinsOf(String hhmm) {
  final total = toMins(hhmm) + DateTime.now().timeZoneOffset.inMinutes;
  const day = 24 * 60;
  // floorDiv/floorMod để offset âm (múi giờ phía tây) vẫn ra đúng.
  final shift = (total / day).floor();
  return (mins: total - shift * day, dayShift: shift);
}

String _minsToHhmm(int m) =>
    '${(m ~/ 60).toString().padLeft(2, '0')}:'
    '${(m % 60).toString().padLeft(2, '0')}';

/// Lịch rảnh lưu UTC ở BE. Đổi GIỜ sang local, GIỮ NGUYÊN thứ — khớp
/// `toLocalSlot` bên web (đúng với khung dạy 07:00–22:00).
({int dayOfWeek, String startTime, String endTime}) availabilityToLocal({
  required int isoDayOfWeek,
  required String startUtc,
  required String endUtc,
}) => (
  dayOfWeek: isoDayOfWeek % 7,
  startTime: utcTimeOfDayToLocal(startUtc),
  endTime: utcTimeOfDayToLocal(endUtc),
);

/// Một buổi cố định sau khi quy về giờ local (kèm thứ đã dịch nếu qua ngày).
({int dayOfWeek, String startTime, String endTime}) fixedSlotToLocal({
  required int isoDayOfWeek,
  required String startUtc,
  required String endUtc,
}) {
  final start = _localMinsOf(startUtc);
  // Giờ kết thúc bám theo ngày của giờ bắt đầu để buổi học không bị tách đôi.
  final durationMins =
      (toMins(endUtc) - toMins(startUtc) + 24 * 60) % (24 * 60);
  final endMins = (start.mins + durationMins) % (24 * 60);

  // BE dùng ISO 1=T2..7=CN, app dùng 0=CN..6=T7.
  final localIso = ((isoDayOfWeek - 1 + start.dayShift) % 7 + 7) % 7 + 1;
  return (
    dayOfWeek: localIso % 7,
    startTime: _minsToHhmm(start.mins),
    endTime: _minsToHhmm(endMins),
  );
}

/// Chuẩn hoá về "HH:mm" để so khớp với kTimeSlots.
String normalizeTime(String t) {
  final mins = toMins(t);
  final h = (mins ~/ 60).toString().padLeft(2, '0');
  final m = (mins % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

bool timeWithinSlot(String time, String slotStart, String slotEnd) =>
    toMins(time) >= toMins(slotStart) && toMins(time) < toMins(slotEnd);

/// Hạn = đúng ngày này tháng sau, tính cả ngày cuối; clamp 31/1 → 28/2.
DateTime bookingWindowEnd(DateTime start) {
  final lastDayNextMonth = DateTime(start.year, start.month + 2, 0).day;
  return DateTime(
    start.year,
    start.month + 1,
    start.day < lastDayNextMonth ? start.day : lastDayNextMonth,
  );
}

/// Đếm ngày học thật — cửa sổ tính cả 2 đầu nên có thể ra 5 buổi, đừng nhân ×4.
List<DateTime> sessionDatesInWindow({
  required DateTime start,
  required List<int> weekdays,
}) {
  if (weekdays.isEmpty) return const [];
  final end = bookingWindowEnd(start);
  final out = <DateTime>[];
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    final dow = d.weekday == DateTime.sunday ? 0 : d.weekday;
    if (weekdays.contains(dow)) out.add(DateTime(d.year, d.month, d.day));
  }
  return out;
}

/// Buổi trong ngày — nhóm các khung giờ cho dễ nhìn thay vì đổ một mảng dài.
enum DayPart { morning, afternoon, evening }

extension DayPartX on DayPart {
  /// Sáng 6:00–10:59 · Chiều 11:00–16:59 · Tối 17:00 trở đi.
  static DayPart of(String time) {
    final h = toMins(time) ~/ 60;
    if (h < 11) return DayPart.morning;
    if (h < 17) return DayPart.afternoon;
    return DayPart.evening;
  }

  String get label => switch (this) {
    DayPart.morning => 'Sáng',
    DayPart.afternoon => 'Chiều',
    DayPart.evening => 'Tối',
  };

  /// Khung giờ hiển thị kèm nhãn, giúp phụ huynh định vị nhanh.
  String get rangeLabel => switch (this) {
    DayPart.morning => '06:00 – 11:00',
    DayPart.afternoon => '11:00 – 17:00',
    DayPart.evening => 'Sau 17:00',
  };
}

/// Gom danh sách giờ bắt đầu thành 3 buổi, giữ nguyên thứ tự tăng dần.
Map<DayPart, List<String>> groupByDayPart(List<String> starts) {
  final sorted = [...starts]..sort((a, b) => toMins(a).compareTo(toMins(b)));
  final out = <DayPart, List<String>>{};
  for (final s in sorted) {
    out.putIfAbsent(DayPartX.of(s), () => []).add(s);
  }
  return out;
}
