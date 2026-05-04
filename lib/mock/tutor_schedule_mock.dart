enum TutorBookingStatus { pending, accepted, paid, cancelled }

class TutorBookingMock {
  const TutorBookingMock({
    required this.id,
    required this.day,
    required this.month,
    required this.year,
    required this.timeStart,
    required this.timeEnd,
    required this.studentName,
    required this.subject,
    required this.status,
  });

  final int id;
  final int day;
  final int month;
  final int year;
  final String timeStart;
  final String timeEnd;
  final String studentName;
  final String subject;
  final TutorBookingStatus status;
}

const kTutorBookings = [
  TutorBookingMock(
    id: 1,
    day: 2,
    month: 5,
    year: 2026,
    timeStart: '09:00',
    timeEnd: '11:00',
    studentName: 'Minh Anh',
    subject: 'Toán 12',
    status: TutorBookingStatus.paid,
  ),
  TutorBookingMock(
    id: 2,
    day: 5,
    month: 5,
    year: 2026,
    timeStart: '14:00',
    timeEnd: '16:00',
    studentName: 'Quốc Bảo',
    subject: 'Toán 10',
    status: TutorBookingStatus.pending,
  ),
  TutorBookingMock(
    id: 3,
    day: 9,
    month: 5,
    year: 2026,
    timeStart: '09:00',
    timeEnd: '11:00',
    studentName: 'Minh Anh',
    subject: 'Toán 12',
    status: TutorBookingStatus.paid,
  ),
  TutorBookingMock(
    id: 4,
    day: 12,
    month: 5,
    year: 2026,
    timeStart: '15:00',
    timeEnd: '17:00',
    studentName: 'Linh Chi',
    subject: 'Anh văn B2',
    status: TutorBookingStatus.accepted,
  ),
  TutorBookingMock(
    id: 5,
    day: 20,
    month: 5,
    year: 2026,
    timeStart: '14:00',
    timeEnd: '16:00',
    studentName: 'Hoàng Nam',
    subject: 'Lý 11',
    status: TutorBookingStatus.pending,
  ),
];

// Day numbers available in May 2026
const kTutorAvailableDays = {
  1,
  3,
  4,
  6,
  8,
  10,
  11,
  13,
  15,
  17,
  18,
  19,
  22,
  24,
  25,
  26,
  29,
  31,
};

const kTutorTimeSlots = [
  '07:00',
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
  '18:00',
  '19:00',
  '20:00',
  '21:00',
];

const kDefaultSelectedSlots = {'09:00', '10:00', '14:00', '15:00', '16:00'};
