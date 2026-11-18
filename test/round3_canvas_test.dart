import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/report_after_send_screens.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_students_screen.dart';

/// V56-Classes (tìm kiếm, "Lớp 8 · T2, T5") và V56-Review / Sent (giờ gửi).
void main() {
  const bao = RecorderStudentDto(
    studentId: 's1',
    fullName: 'Bảo',
    grade: 9,
    schedule: [
      RecorderScheduleSlot(dayOfWeek: 4, start: '19:00', end: '20:30'),
      RecorderScheduleSlot(dayOfWeek: 2, start: '19:00', end: '20:30'),
    ],
  );

  test('search by name without accents, or by grade', () {
    expect(studentMatchesQuery(bao, ''), isTrue);
    expect(studentMatchesQuery(bao, 'bao'), isTrue);
    expect(studentMatchesQuery(bao, 'BẢO'), isTrue);
    expect(studentMatchesQuery(bao, '9'), isTrue);
    expect(studentMatchesQuery(bao, 'lớp 9'), isTrue);
    expect(studentMatchesQuery(bao, 'lop 8'), isFalse);
    expect(studentMatchesQuery(bao, 'an'), isFalse);
  });

  test('card line: grade and weekdays', () {
    expect(studentCardLine(bao), 'Lớp 9 · T3, T5');
    expect(
      studentCardLine(const RecorderStudentDto(studentId: 's', fullName: 'X')),
      '',
    );
  });

  test('Zalo quiet hours 21:30–06:30 Vietnam time', () {
    // 14:00 UTC = 21:00 VN → sends now.
    expect(zaloQuietMorning(DateTime.utc(2026, 11, 13, 14)), isNull);
    // 14:30 UTC = 21:30 VN → tomorrow morning.
    expect(zaloQuietMorning(DateTime.utc(2026, 11, 13, 14, 30)), 'sáng mai');
    // 22:00 UTC = 05:00 VN → this morning.
    expect(zaloQuietMorning(DateTime.utc(2026, 11, 13, 22)), 'sáng nay');
    // 23:30 UTC = 06:30 VN → sends now.
    expect(zaloQuietMorning(DateTime.utc(2026, 11, 13, 23, 30)), isNull);
  });

  ReportSentArgs sent({
    String? channel = 'zns',
    String? status = 'pending',
    DateTime? at,
    bool offPlatform = true,
  }) => ReportSentArgs(
    lessonId: 'l1',
    studentName: 'Minh An',
    offPlatform: offPlatform,
    approvedAtUtc: at ?? DateTime.utc(2026, 11, 13, 15),
    deliveryChannel: channel,
    deliveryStatus: status,
  );

  test('sent copy: scheduled at 06:30 at night, sent, booking, no phone', () {
    final night = reportSentCopy(sent());
    expect(night.title, 'Đã lên lịch gửi');
    expect(
      night.text,
      'Phụ huynh Minh An nhận báo cáo qua Zalo lúc 06:30 sáng mai.',
    );
    expect(reportSentCopy(sent(status: 'sent')).title, 'Đã gửi');
    expect(
      reportSentCopy(sent(at: DateTime.utc(2026, 11, 13, 3))).title,
      'Đang gửi',
    );
    expect(
      reportSentCopy(sent(channel: 'booking', offPlatform: false)).text,
      'Phụ huynh Minh An xem báo cáo trên TopTutor.',
    );
    expect(reportSentCopy(sent(channel: null, status: null)).title, 'Đã duyệt');
  });
}
