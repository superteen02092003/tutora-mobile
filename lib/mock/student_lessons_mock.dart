enum LessonStatus { upcoming, confirmed, pending, completed }

class MockLesson {
  const MockLesson({
    required this.id,
    required this.tutorName,
    required this.subject,
    required this.topic,
    required this.dayLabel,
    required this.timeLabel,
    required this.fullDate,
    required this.status,
  });

  final String id;
  final String tutorName;
  final String subject;
  final String topic;
  final String dayLabel;  // 'T4', 'T5', etc.
  final String timeLabel; // '19:30'
  final String fullDate;  // 'T4 · 24/06'
  final LessonStatus status;
}

const kMockUpcomingLessons = [
  MockLesson(
    id: 'u1',
    tutorName: 'Cô Mai Anh',
    subject: 'Toán 10',
    topic: 'Hệ thức Vi-ét',
    dayLabel: 'T4',
    timeLabel: '19:30',
    fullDate: 'T4 · 24/06',
    status: LessonStatus.upcoming,
  ),
  MockLesson(
    id: 'u2',
    tutorName: 'Cô Linh Chi',
    subject: 'Tiếng Anh',
    topic: 'IELTS Writing Task 2',
    dayLabel: 'T5',
    timeLabel: '18:00',
    fullDate: 'T5 · 25/06',
    status: LessonStatus.confirmed,
  ),
  MockLesson(
    id: 'u3',
    tutorName: 'Thầy Đức Huy',
    subject: 'Hóa 10',
    topic: 'Cấu tạo nguyên tử',
    dayLabel: 'T7',
    timeLabel: '20:00',
    fullDate: 'T7 · 27/06',
    status: LessonStatus.pending,
  ),
];

const kMockCompletedLessons = [
  MockLesson(
    id: 'c1',
    tutorName: 'Cô Mai Anh',
    subject: 'Toán 10',
    topic: 'Phương trình bậc hai',
    dayLabel: 'T2',
    timeLabel: '19:00',
    fullDate: 'T2 · 19/06',
    status: LessonStatus.completed,
  ),
  MockLesson(
    id: 'c2',
    tutorName: 'Cô Linh Chi',
    subject: 'Tiếng Anh',
    topic: 'Grammar · Present Perfect',
    dayLabel: 'CN',
    timeLabel: '15:00',
    fullDate: 'CN · 16/06',
    status: LessonStatus.completed,
  ),
  MockLesson(
    id: 'c3',
    tutorName: 'Thầy Đức Huy',
    subject: 'Hóa 10',
    topic: 'Bảng tuần hoàn các nguyên tố',
    dayLabel: 'T6',
    timeLabel: '17:30',
    fullDate: 'T6 · 14/06',
    status: LessonStatus.completed,
  ),
];

class WeekDay {
  const WeekDay({
    required this.label,
    required this.date,
    required this.hasSession,
    this.isToday = false,
  });
  final String label;
  final String date;
  final bool hasSession;
  final bool isToday;
}

const kMockWeekDays = [
  WeekDay(label: 'T2', date: '23', hasSession: false),
  WeekDay(label: 'T3', date: '24', hasSession: false),
  WeekDay(label: 'T4', date: '25', hasSession: true, isToday: true),
  WeekDay(label: 'T5', date: '26', hasSession: true),
  WeekDay(label: 'T6', date: '27', hasSession: false),
  WeekDay(label: 'T7', date: '28', hasSession: true),
  WeekDay(label: 'CN', date: '29', hasSession: false),
];
