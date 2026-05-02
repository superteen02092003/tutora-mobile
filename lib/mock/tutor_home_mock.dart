// ── Tutor home mock data ──────────────────────────────────────────────────

const kMockTutorName = 'Cô Mai Anh';

const List<({String label, String value, String sub, String tone})>
kMockTutorStats = [
  (
    label: 'Doanh thu tháng',
    value: '12.4tr',
    sub: '+18% so tháng trước',
    tone: 'ink',
  ),
  (
    label: 'Buổi tuần này',
    value: '14',
    sub: '92% lấp đầy',
    tone: 'cream',
  ),
  (
    label: 'Đánh giá',
    value: '4.96',
    sub: '482 buổi',
    tone: 'cream',
  ),
  (
    label: 'Đang giữ tạm',
    value: '2.1tr',
    sub: '8 buổi · escrow',
    tone: 'gold',
  ),
];

class MockTutorSession {
  const MockTutorSession({
    required this.time,
    required this.studentName,
    required this.subject,
    required this.status,
    required this.ctaLabel,
    this.isNext = false,
  });

  final String time;
  final String studentName;
  final String subject;
  final String status;
  final String ctaLabel;
  final bool isNext;
}

const kMockTutorSessions = [
  MockTutorSession(
    time: '15:00',
    studentName: 'Linh Nguyễn',
    subject: 'Toán 10 · Hệ thức Vi-ét',
    status: 'Sắp diễn ra',
    ctaLabel: 'Vào lớp',
    isNext: true,
  ),
  MockTutorSession(
    time: '17:00',
    studentName: 'Bảo Trân',
    subject: 'Toán 11 · Đạo hàm',
    status: 'Đã xác nhận',
    ctaLabel: 'Chuẩn bị',
  ),
  MockTutorSession(
    time: '19:30',
    studentName: 'Đức Khang',
    subject: 'Lý 10 · Động lực học',
    status: 'Chờ check-in',
    ctaLabel: 'Xem',
  ),
];
