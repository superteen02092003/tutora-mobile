import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/course_renew.dart';

import '../integration_test/as_built/fake_backend.dart';

/// Hết khóa và gia hạn tháng mới cho học sinh ngoài nền tảng.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final today = DateTime(2026, 11, 13);

  RecorderStudentDto pupil({
    DateTime? until,
    String consent = 'tutor_confirmed',
    bool schedule = true,
  }) => RecorderStudentDto(
    studentId: 'stu-1',
    fullName: 'Khôi',
    grade: 9,
    subject: 'Toán',
    parentName: 'Mẹ Khôi',
    parentPhone: '+84900000003',
    consentStatus: consent,
    consentVersion: 'v1',
    note: 'Ghi chú',
    schedule: schedule
        ? const [
            RecorderScheduleSlot(dayOfWeek: 5, start: '18:00', end: '19:30'),
          ]
        : const [],
    scheduleFrom: DateTime(2026, 10),
    scheduleUntil: until,
  );

  group('courseEndAfterMonths', () {
    test('1 month from the 13th ends on the 12th', () {
      expect(courseEndAfterMonths(today, 1), DateTime(2026, 12, 12));
      expect(courseEndAfterMonths(today, 3), DateTime(2027, 2, 12));
    });
    test('from the 1st ends on the last day of the month', () {
      expect(
        courseEndAfterMonths(DateTime(2026, 11), 1),
        DateTime(2026, 11, 30),
      );
    });
    test('31 Jan + 1 month clamps to 28 Feb', () {
      expect(
        courseEndAfterMonths(DateTime(2027, 1, 31), 1),
        DateTime(2027, 2, 28),
      );
    });
  });

  group('courseStatus', () {
    test('ended, ending soon, active, open', () {
      expect(
        pupil(until: DateTime(2026, 11, 9)).courseStatus(today),
        CourseStatus.ended,
      );
      expect(
        pupil(until: today).courseStatus(today),
        CourseStatus.endingSoon,
      );
      expect(
        pupil(until: DateTime(2026, 11, 20)).courseStatus(today),
        CourseStatus.endingSoon,
      );
      expect(
        pupil(until: DateTime(2026, 11, 21)).courseStatus(today),
        CourseStatus.active,
      );
      expect(pupil().courseStatus(today), CourseStatus.open);
      expect(
        pupil(
          until: DateTime(2026, 11, 9),
          schedule: false,
        ).courseStatus(today),
        CourseStatus.open,
      );
    });
    test('status text', () {
      expect(
        courseStatusText(pupil(until: DateTime(2026, 11, 9)), today),
        'Hết khóa 09/11',
      );
      expect(courseStatusText(pupil(until: today), today), 'Hết khóa hôm nay');
      expect(
        courseStatusText(pupil(until: DateTime(2026, 11, 18)), today),
        'Còn 5 ngày · hết 18/11',
      );
      expect(
        courseStatusText(pupil(until: DateTime(2026, 12, 20)), today),
        'Học đến 20/12',
      );
      expect(courseStatusText(pupil(), today), isNull);
    });
  });

  group('renewInput', () {
    test('keeps every field, the schedule and the consent version', () {
      final j = pupil(
        until: DateTime(2026, 11, 9),
      ).renewInput(today, DateTime(2026, 12, 12)).toJson();
      expect(j['fullName'], 'Khôi');
      expect(j['parentPhone'], '+84900000003');
      expect(j['note'], 'Ghi chú');
      expect(j['parentConsent'], isTrue);
      expect(j['consentVersion'], 'v1');
      expect(j['schedule'], hasLength(1));
      expect(j['scheduleFrom'], '2026-11-13');
      expect(j['scheduleUntil'], '2026-12-12');
    });
    test('parent-confirmed pupil does not send a tutor consent', () {
      final j = pupil(
        consent: 'parent_confirmed',
      ).renewInput(today, DateTime(2026, 12, 12)).toJson();
      expect(j['parentConsent'], isFalse);
      expect(j.containsKey('consentVersion'), isFalse);
    });
  });

  testWidgets('renew panel: "+1 tháng" saves today → one month', (
    tester,
  ) async {
    final fake = FakeBackend(now: DateTime.now());
    final dio = Dio()..httpClientAdapter = fake;
    final khoi = RecorderStudentDto.fromJson(fake.studentKhoi());
    expect(khoi.courseStatus(), CourseStatus.ended);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recorderDatasourceProvider.overrideWithValue(RecorderDatasource(dio)),
        ],
        child: MaterialApp(
          home: Scaffold(body: CourseRenewPanel(student: khoi)),
        ),
      ),
    );
    expect(find.text('Khóa đã hết'), findsOneWidget);
    expect(find.text('+3 tháng'), findsOneWidget);

    await tester.tap(find.text('+1 tháng'));
    await tester.pumpAndSettle();

    expect(fake.log, contains('PUT /recorder/students/stu-khoi'));
    final n = DateTime.now();
    final from = DateTime(n.year, n.month, n.day);
    final renewed = RecorderStudentDto.fromJson(fake.studentKhoi());
    expect(renewed.scheduleFrom, from);
    expect(renewed.scheduleUntil, courseEndAfterMonths(from, 1));
    expect(find.textContaining('Đã gia hạn Khôi'), findsOneWidget);
  });
}
