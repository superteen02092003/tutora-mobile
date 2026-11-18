import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_lesson_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';

import '../integration_test/as_built/fake_backend.dart';

/// Datasource giai đoạn 1 chạy qua backend giả (không mạng): đúng route,
/// đúng body, parse được dữ liệu giả.
void main() {
  late FakeBackend fake;
  late Dio dio;
  late RecorderDatasource recorder;

  setUp(() {
    fake = FakeBackend(now: DateTime(2026, 11, 13, 10));
    dio = Dio()..httpClientAdapter = fake;
    recorder = RecorderDatasource(dio);
  });

  test('insights: 9 Nov lesson has a quiet stretch 0–20', () async {
    final d = await AppRecordingDatasource(dio).getInsights('rec-ready');
    expect(fake.log.last, 'GET /recording/app/rec-ready/insights');
    expect(d.available, isTrue);
    expect(d.studentTalkShare, 0.31);
    expect(d.studentQuietStretches.single.toMin, 20);
    final none = await AppRecordingDatasource(dio).getInsights('rec-ai');
    expect(none.available, isFalse);
  });

  test('weekly recording: 4 usable of 5, Bao missing without reason', () async {
    final d = await recorder.getWeeklyRecording();
    expect(d.weeks, hasLength(2));
    expect(d.currentWeek!.usable, 4);
    expect(d.currentWeek!.lessonsDue, 5);
    final m = d.missing.single;
    expect(m.studentName, 'Bao');
    expect(m.scheduledStart!.weekday, DateTime.saturday);
    expect(m.needsReason, isTrue);
  });

  test('settings: defaults, then save', () async {
    final s = await recorder.getSettings();
    expect(s.lessonReminderMinutes, 30);
    expect(s.reportReadyPush, isTrue);
    final saved = await recorder.saveSettings(
      s.copyWith(clearReminder: true, reportReadyPush: false),
    );
    expect(saved.lessonReminderMinutes, isNull);
    expect(saved.reportReadyPush, isFalse);
    expect((await recorder.getSettings()).remindersOn, isFalse);
  });

  test('journal: Minh An, November, 3 lessons oldest first', () async {
    final j = await recorder.getJournal('stu-minh-an', '2026-11');
    expect(fake.log.last, 'GET /recorder/students/stu-minh-an/journal');
    expect(j.lessons, hasLength(3));
    expect(
      j.lessons.first.scheduledStart!.isBefore(j.lessons.last.scheduledStart!),
      isTrue,
    );
    expect(j.lessons.last.aiDrafted, isTrue);
    expect((await recorder.getJournal('stu-bao', '2026-11')).lessons, isEmpty);
  });

  test('attendance echoes the updated lesson', () async {
    final l = await recorder.setAttendance(
      'les-bao-sat',
      RecorderAttendance.absent,
      reason: RecorderAbsenceReason.pupilAbsent,
    );
    expect(l.lessonId, 'les-bao-sat');
    expect(l.isAbsent, isTrue);
    expect(l.attendanceSource, 'tutor');
    expect(l.absenceReason, 'pupil_absent');
  });

  test('move: scope this returns the new lesson', () async {
    final start = DateTime(2026, 11, 14, 19);
    final l = await recorder.moveLesson(
      'les-bao-today',
      start,
      start.add(const Duration(minutes: 90)),
      RecorderMoveScope.thisLesson,
    );
    expect(l.lessonId, 'les-bao-today-moved');
    expect(l.scheduledStart, start);
    expect(l.isMoved, isTrue);
  });

  test('cancel hits the delete route', () async {
    await recorder.cancelLesson(
      'les-an-today',
      reason: RecorderCancelReason.pupilAbsent,
    );
    expect(fake.log.last, 'DELETE /recorder/lessons/les-an-today');
  });

  test('reschedule proposal posts to the tutor route', () async {
    final start = DateTime(2026, 11, 20, 17);
    final p = await TutorLessonDatasource(
      dio,
    ).proposeReschedule(1013, start, 'Bận việc');
    expect(
      fake.log.last,
      'POST /tutor/class-sessions/1013/reschedule-proposal',
    );
    expect(p.classSessionId, 1013);
    expect(p.proposedScheduledStart, start);
    expect(p.reason, 'Bận việc');
  });

  test('error scenario fails like the other routes', () async {
    fake.scenario = Scenario.error;
    expect(recorder.getWeeklyRecording(), throwsA(isA<DioException>()));
  });
}
