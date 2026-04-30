enum LessonStatus { upcoming, confirmed, pending, done }

class MockLesson {
  const MockLesson({
    required this.id,
    required this.tutorName,
    required this.subject,
    required this.topic,
    required this.date,
    required this.timeRange,
    required this.timeStart,
    required this.priceK,
    required this.status,
    this.isToday = false,
  });

  final String id;
  final String tutorName;
  final String subject;
  final String topic;
  final String date;
  final String timeRange; // '15:00 – 16:00'
  final String timeStart; // '15:00'
  final int priceK;
  final LessonStatus status;
  final bool isToday;
}

const kMockLessons = [
  MockLesson(
    id: 'u1',
    tutorName: 'Cô Mai Anh',
    subject: 'Toán 10',
    topic: 'Hệ thức Vi-ét',
    date: 'Hôm nay',
    timeRange: '15:00 – 16:00',
    timeStart: '15:00',
    priceK: 280,
    status: LessonStatus.upcoming,
    isToday: true,
  ),
  MockLesson(
    id: 'u2',
    tutorName: 'Thầy Đức Huy',
    subject: 'Hóa 10',
    topic: 'Cấu hình electron',
    date: 'Hôm nay',
    timeRange: '19:00 – 20:00',
    timeStart: '19:00',
    priceK: 220,
    status: LessonStatus.confirmed,
    isToday: true,
  ),
  MockLesson(
    id: 'u3',
    tutorName: 'Cô Mai Anh',
    subject: 'Toán 10',
    topic: 'Bất phương trình',
    date: 'T5, 2/5',
    timeRange: '17:00 – 18:00',
    timeStart: '17:00',
    priceK: 280,
    status: LessonStatus.confirmed,
  ),
  MockLesson(
    id: 'u4',
    tutorName: 'Cô Linh Chi',
    subject: 'Tiếng Anh',
    topic: 'Writing Task 2',
    date: 'T7, 4/5',
    timeRange: '10:00 – 11:30',
    timeStart: '10:00',
    priceK: 375,
    status: LessonStatus.pending,
  ),
  MockLesson(
    id: 'd1',
    tutorName: 'Cô Mai Anh',
    subject: 'Toán 10',
    topic: 'Đạo hàm cơ bản',
    date: '28/4',
    timeRange: '28/4 · 15:00',
    timeStart: '15:00',
    priceK: 280,
    status: LessonStatus.done,
  ),
  MockLesson(
    id: 'd2',
    tutorName: 'Thầy Quang',
    subject: 'Vật Lý 10',
    topic: 'Định luật III Newton',
    date: '25/4',
    timeRange: '25/4 · 18:00',
    timeStart: '18:00',
    priceK: 180,
    status: LessonStatus.done,
  ),
];

List<MockLesson> get kUpcomingLessons =>
    kMockLessons.where((l) => l.status != LessonStatus.done).toList();

List<MockLesson> get kDoneLessons =>
    kMockLessons.where((l) => l.status == LessonStatus.done).toList();

List<MockLesson> get kTodayLessons =>
    kMockLessons.where((l) => l.isToday).toList();

// April 2026 — days with sessions (day → count)
// April 1 = Wednesday → Mon-based offset = 2
const kMockSessionDaysApril = <int, int>{
  7: 1, 12: 1, 18: 2, 25: 1, 28: 1, 30: 2,
};

// Sessions by calendar day (April 2026)
Map<int, List<MockLesson>> get kMockAprilSessions => {
      30: kTodayLessons,
      28: kMockLessons.where((l) => l.id == 'd1').toList(),
      25: kMockLessons.where((l) => l.id == 'd2').toList(),
    };
