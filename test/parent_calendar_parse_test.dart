import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';

/// Phẳng lại `CalendarDayResponse` của BE — sao chép logic của
/// ParentDatasource.getCalendarLessons để khoá shape response.
List<ParentLessonDto> flattenCalendar(List<dynamic> days) => days
    .expand(
      (d) =>
          ((d as Map<String, dynamic>)['classSessions'] as List<dynamic>? ?? [])
              .map((e) => ParentLessonDto.fromJson(e as Map<String, dynamic>)),
    )
    .toList();

void main() {
  test(
    'calendar lồng theo ngày -> parse ra buổi thật, không phải ngày rỗng',
    () {
      final days = [
        {
          'date': '2026-08-18T00:00:00Z',
          'classSessions': [
            {
              'classSessionId': 768,
              'bookingId': 270,
              'scheduledStart': '2026-08-18T02:30:00Z',
              'scheduledEnd': '2026-08-18T03:30:00Z',
              'studentName': 'Phạm Phương Nhi',
              'tutorName': 'Lê Gia Nam',
              'subjectName': 'Vật Lý',
              'status': 'reserved',
            },
          ],
        },
        {
          'date': '2026-08-20T00:00:00Z',
          'classSessions': [
            {
              'classSessionId': 763,
              'scheduledStart': '2026-08-20T01:30:00Z',
              'scheduledEnd': '2026-08-20T02:30:00Z',
              'status': 'cancelled',
            },
            {
              'classSessionId': 770,
              'scheduledStart': '2026-08-20T01:30:00Z',
              'scheduledEnd': '2026-08-20T02:30:00Z',
              'status': 'scheduled',
            },
          ],
        },
      ];

      final lessons = flattenCalendar(days);

      expect(lessons.length, 3);
      expect(lessons.first.lessonId, 768);
      expect(lessons.first.subjectName, 'Vật Lý');
      // Bug cũ: parse trực tiếp phần tử ngày -> lessonId 0, scheduledStart rỗng.
      expect(lessons.every((l) => l.lessonId != 0), isTrue);
      expect(lessons.every((l) => l.scheduledStart.isNotEmpty), isTrue);
    },
  );

  test('endpoint theo con trả studentId để lọc, khác calendar chung', () {
    final l = ParentLessonDto.fromJson({
      'classSessionId': 768,
      'studentId': 'stu-1',
      'scheduledStart': '2026-08-18T02:30:00Z',
      'scheduledEnd': '2026-08-18T03:30:00Z',
      'status': 'scheduled',
    });

    expect(l.studentId, 'stu-1');
  });

  test(
    'isUpcoming giữ reserved (phụ huynh đã trả cọc), loại buổi đã xong/huỷ',
    () {
      ParentLessonDto withStatus(String s) => ParentLessonDto.fromJson({
        'classSessionId': 1,
        'scheduledStart': '2026-08-18T02:30:00Z',
        'scheduledEnd': '2026-08-18T03:30:00Z',
        'status': s,
      });

      expect(withStatus('scheduled').isUpcoming, isTrue);
      expect(withStatus('in_progress').isUpcoming, isTrue);
      expect(withStatus('pending_confirmation').isUpcoming, isTrue);
      // Khác bên gia sư: reserved không tính công nhưng phụ huynh vẫn phải thấy.
      expect(withStatus('reserved').isUpcoming, isTrue);
      expect(withStatus('reserved').isReserved, isTrue);

      expect(withStatus('cancelled').isUpcoming, isFalse);
      expect(withStatus('cancelled_noshow').isUpcoming, isFalse);
      expect(withStatus('completed').isUpcoming, isFalse);
      expect(withStatus('no_show').isUpcoming, isFalse);
      expect(withStatus('disputed').isUpcoming, isFalse);
      expect(withStatus('scheduled').isReserved, isFalse);
    },
  );

  test('avatar/ngày sinh của con parse được cả avatarURL lẫn avatarUrl', () {
    // BE StudentProfileResponse trả `avatarURL`/`birthDate` — bug cũ: đọc
    // `avatarUrl`/`birthdate` nên luôn null, phải fallback ảnh dicebear.
    final fromBe = ParentStudentDto.fromJson({
      'studentId': 'STU-A884EA5E30',
      'fullName': 'Phạm Phương Nhi',
      'avatarURL': 'https://api.tutora.vn/uploads/avatars/nhi.png',
      'birthDate': '2010-02-02',
    });
    expect(fromBe.avatarUrl, 'https://api.tutora.vn/uploads/avatars/nhi.png');
    expect(fromBe.birthdate, '2010-02-02');

    final camel = ParentStudentDto.fromJson({
      'studentId': 'STU-1',
      'fullName': 'A B',
      'avatarUrl': 'https://x/y.png',
      'birthdate': '2011-01-01',
    });
    expect(camel.avatarUrl, 'https://x/y.png');
    expect(camel.birthdate, '2011-01-01');
  });

  test('home stats phân biệt con đang học với tổng số con', () {
    // 2 con nhưng chỉ 1 con có booking đang hoạt động.
    final s = ParentHomeStatsDto.fromJson({
      'sessionsThisWeek': 3,
      'childrenLearning': 1,
      'childrenTotal': 2,
      'pendingConfirmation': 0,
    });

    expect(s.childrenLearning, 1);
    expect(s.childrenTotal, 2);
    expect(s.sessionsThisWeek, 3);

    // Thiếu field thì về 0, không crash.
    expect(ParentHomeStatsDto.fromJson(const {}).childrenLearning, 0);
  });
}
