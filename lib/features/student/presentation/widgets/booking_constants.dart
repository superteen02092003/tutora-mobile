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

const List<double> kSlotDurationOptions = [1, 1.5, 2, 2.5, 3];

final NumberFormat kCurrencyFmt = NumberFormat('#,###', 'vi_VN');

String formatPrice(double amount) => '${kCurrencyFmt.format(amount.round())}đ';

String addHours(String time, double hours) {
  final parts = time.split(':');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final totalMins = (h * 60 + m + (hours * 60).round()) % (24 * 60);
  final rh = totalMins ~/ 60;
  final rm = totalMins % 60;
  return '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}';
}

int toMins(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

bool timeWithinSlot(String time, String slotStart, String slotEnd) =>
    toMins(time) >= toMins(slotStart) && toMins(time) < toMins(slotEnd);
