import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';

/// Parse JSON của các API giai đoạn 1 (phase1-api.md A–F): đủ trường và
/// thiếu / null trường.
void main() {
  group('LessonInsightsDto', () {
    test('parses a full payload', () {
      final d = LessonInsightsDto.fromJson({
        'lessonId': 'l1',
        'available': true,
        'metricsVersion': 'score-b-v1',
        'minutesRecorded': 86,
        'minutesPlanned': 90,
        'bothVoices': true,
        'studentTalkShare': 0.31,
        'tutorTurns': 120,
        'studentTurns': 85,
        'tutorQuestions': 42,
        'avgWaitAfterQuestionSec': 3.4,
        'studentQuietStretches': [
          {'fromMin': 0, 'toMin': 20},
          {'fromMin': 50, 'toMin': 58.0},
        ],
        'unclearMarks': 3,
      });
      expect(d.lessonId, 'l1');
      expect(d.available, isTrue);
      expect(d.metricsVersion, 'score-b-v1');
      expect(d.minutesRecorded, 86);
      expect(d.minutesPlanned, 90);
      expect(d.bothVoices, isTrue);
      expect(d.studentTalkShare, 0.31);
      expect(d.tutorTurns, 120);
      expect(d.studentTurns, 85);
      expect(d.tutorQuestions, 42);
      expect(d.avgWaitAfterQuestionSec, 3.4);
      expect(d.studentQuietStretches, hasLength(2));
      expect(d.studentQuietStretches.first.fromMin, 0);
      expect(d.studentQuietStretches.first.toMin, 20);
      expect(d.studentQuietStretches.last.minutes, 8);
      expect(d.unclearMarks, 3);
    });

    test('not available: other fields null', () {
      final d = LessonInsightsDto.fromJson({
        'lessonId': 'l1',
        'available': false,
        'studentTalkShare': null,
        'studentQuietStretches': null,
      });
      expect(d.available, isFalse);
      expect(d.studentTalkShare, isNull);
      expect(d.minutesPlanned, isNull);
      expect(d.studentQuietStretches, isEmpty);
    });

    test('empty map', () {
      final d = LessonInsightsDto.fromJson(const {});
      expect(d.lessonId, '');
      expect(d.available, isFalse);
      expect(d.bothVoices, isNull);
      expect(d.unclearMarks, isNull);
    });

    test('integer share parses as double', () {
      final d = LessonInsightsDto.fromJson({'studentTalkShare': 1});
      expect(d.studentTalkShare, 1.0);
    });
  });

  group('WeeklyRecordingDto', () {
    test('parses weeks and missing', () {
      final d = WeeklyRecordingDto.fromJson({
        'weeks': [
          {
            'weekStart': '2026-11-02',
            'lessonsDue': 5,
            'recorded': 4,
            'usable': 4,
            'avgStudentTalkShare': 0.28,
          },
          {'weekStart': '2026-10-26'},
        ],
        'missing': [
          {
            'lessonId': 'm1',
            'studentId': 's1',
            'studentName': 'Bảo',
            'scheduledStart': '2026-11-07T02:00:00Z',
            'attendance': 'absent',
            'absenceReason': 'pupil_absent',
          },
          {'lessonId': 'm2'},
        ],
      });
      expect(d.weeks, hasLength(2));
      final w = d.currentWeek!;
      expect(w.weekStart, DateTime(2026, 11, 2));
      expect(w.lessonsDue, 5);
      expect(w.recorded, 4);
      expect(w.usable, 4);
      expect(w.avgStudentTalkShare, 0.28);
      final w2 = d.weeks[1];
      expect(w2.lessonsDue, 0);
      expect(w2.usable, 0);
      expect(w2.avgStudentTalkShare, isNull);

      final m = d.missing.first;
      expect(m.lessonId, 'm1');
      expect(m.studentId, 's1');
      expect(m.studentName, 'Bảo');
      expect(m.scheduledStart, DateTime.utc(2026, 11, 7, 2).toLocal());
      expect(m.attendance, 'absent');
      expect(m.absenceReason, RecorderAbsenceReason.pupilAbsent);
      expect(m.needsReason, isFalse);
      final m2 = d.missing[1];
      expect(m2.studentName, 'Học sinh');
      expect(m2.scheduledStart, isNull);
      expect(m2.needsReason, isTrue);
    });

    test('empty / null lists', () {
      final d = WeeklyRecordingDto.fromJson({'weeks': null});
      expect(d.weeks, isEmpty);
      expect(d.missing, isEmpty);
      expect(d.currentWeek, isNull);
    });
  });

  group('RecorderSettingsDto', () {
    test('parses values', () {
      final d = RecorderSettingsDto.fromJson({
        'lessonReminderMinutes': 45,
        'reportReadyPush': false,
      });
      expect(d.lessonReminderMinutes, 45);
      expect(d.reportReadyPush, isFalse);
      expect(d.remindersOn, isTrue);
    });

    test('explicit null reminder = off', () {
      final d = RecorderSettingsDto.fromJson({'lessonReminderMinutes': null});
      expect(d.lessonReminderMinutes, isNull);
      expect(d.remindersOn, isFalse);
      expect(d.reportReadyPush, isTrue);
    });

    test('missing keys = server defaults', () {
      final d = RecorderSettingsDto.fromJson(const {});
      expect(d.lessonReminderMinutes, 30);
      expect(d.reportReadyPush, isTrue);
    });

    test('copyWith and toJson', () {
      const d = RecorderSettingsDto();
      expect(d.copyWith(lessonReminderMinutes: 60).toJson(), {
        'lessonReminderMinutes': 60,
        'reportReadyPush': true,
      });
      expect(d.copyWith(clearReminder: true).toJson(), {
        'lessonReminderMinutes': null,
        'reportReadyPush': true,
      });
      expect(d.copyWith(reportReadyPush: false).lessonReminderMinutes, 30);
    });
  });

  group('StudentJournalDto', () {
    test('parses lessons', () {
      final d = StudentJournalDto.fromJson({
        'studentId': 's1',
        'month': '2026-11',
        'lessons': [
          {
            'lessonId': 'l1',
            'scheduledStart': '2026-11-09T12:00:00Z',
            'status': 'sent',
            'attendance': 'present',
            'absenceReason': null,
            'durationSec': 5160,
            'content': 'Hằng đẳng thức',
            'homework': 'Bài 4',
            'previousHomework': 'Bài 3',
            'exercisesCorrect': 4,
            'exercisesTotal': 6,
            'strengths': ['a', 'b'],
            'difficulties': ['c'],
            'studentTalkShare': 0.31,
            'studentQuietStretches': [
              {'fromMin': 0, 'toMin': 20},
            ],
            'comment': 'Tốt',
            'aiDrafted': true,
            'editedByTutor': false,
          },
        ],
      });
      expect(d.studentId, 's1');
      expect(d.month, '2026-11');
      final l = d.lessons.single;
      expect(l.lessonId, 'l1');
      expect(l.scheduledStart, DateTime.utc(2026, 11, 9, 12).toLocal());
      expect(l.status, 'sent');
      expect(l.attendance, 'present');
      expect(l.isAbsent, isFalse);
      expect(l.durationSec, 5160);
      expect(l.content, 'Hằng đẳng thức');
      expect(l.homework, 'Bài 4');
      expect(l.previousHomework, 'Bài 3');
      expect(l.exercisesCorrect, 4);
      expect(l.exercisesTotal, 6);
      expect(l.hasExercises, isTrue);
      expect(l.strengths, ['a', 'b']);
      expect(l.difficulties, ['c']);
      expect(l.studentTalkShare, 0.31);
      expect(l.studentQuietStretches.single.toMin, 20);
      expect(l.comment, 'Tốt');
      expect(l.aiDrafted, isTrue);
      expect(l.editedByTutor, isFalse);
    });

    test('missing fields', () {
      final d = StudentJournalDto.fromJson({
        'lessons': [
          {'lessonId': 'l2', 'strengths': null},
        ],
      });
      expect(d.studentId, '');
      expect(d.month, '');
      final l = d.lessons.single;
      expect(l.scheduledStart, isNull);
      expect(l.status, 'scheduled');
      expect(l.attendance, isNull);
      expect(l.durationSec, 0);
      expect(l.content, isNull);
      expect(l.exercisesCorrect, isNull);
      expect(l.hasExercises, isFalse);
      expect(l.strengths, isEmpty);
      expect(l.difficulties, isEmpty);
      expect(l.studentTalkShare, isNull);
      expect(l.studentQuietStretches, isEmpty);
      expect(l.aiDrafted, isFalse);
      expect(l.editedByTutor, isFalse);
    });

    test('empty map and month formatting', () {
      expect(StudentJournalDto.fromJson(const {}).lessons, isEmpty);
      expect(formatJournalMonth(DateTime(2026, 3, 15)), '2026-03');
    });
  });

  group('RescheduleProposalDto', () {
    test('parses BE times without zone as UTC', () {
      final d = RescheduleProposalDto.fromJson({
        'rescheduleProposalId': 7,
        'classSessionId': 1011,
        'status': 'Pending',
        'proposedScheduledStart': '2026-11-20T10:00:00',
        'expiresAt': '2026-11-19T10:00:00Z',
      });
      expect(d.rescheduleProposalId, 7);
      expect(d.classSessionId, 1011);
      expect(d.status, 'Pending');
      expect(
        d.proposedScheduledStart,
        DateTime.utc(2026, 11, 20, 10).toLocal(),
      );
      expect(d.expiresAt, DateTime.utc(2026, 11, 19, 10).toLocal());
    });

    test('empty map', () {
      final d = RescheduleProposalDto.fromJson(const {});
      expect(d.rescheduleProposalId, isNull);
      expect(d.proposedScheduledStart, isNull);
    });
  });

  group('RecorderLessonDto attendance fields', () {
    test('parses new fields', () {
      final d = RecorderLessonDto.fromJson({
        'lessonId': 'l1',
        'status': 'scheduled',
        'attendance': 'absent',
        'attendanceSource': 'tutor',
        'absenceReason': 'pupil_absent',
        'movedFromStart': '2026-11-10T12:00:00Z',
        'cancelReason': null,
      });
      expect(d.attendance, 'absent');
      expect(d.attendanceSource, 'tutor');
      expect(d.absenceReason, 'pupil_absent');
      expect(d.movedFromStart, DateTime.utc(2026, 11, 10, 12).toLocal());
      expect(d.cancelReason, isNull);
      expect(d.isAbsent, isTrue);
      expect(d.isPresent, isFalse);
      expect(d.autoPresent, isFalse);
      expect(d.isMoved, isTrue);
      expect(d.wasMovedAway, isFalse);
    });

    test('auto present from a recording', () {
      final d = RecorderLessonDto.fromJson({
        'lessonId': 'l1',
        'attendance': 'present',
        'attendanceSource': 'recording',
      });
      expect(d.autoPresent, isTrue);
      expect(d.isAbsent, isFalse);
    });

    test('moved-away original row', () {
      final d = RecorderLessonDto.fromJson({
        'lessonId': 'l1',
        'status': 'discarded',
        'cancelReason': 'moved',
      });
      expect(d.wasMovedAway, isTrue);
      expect(d.cancelReason, RecorderCancelReason.moved);
    });

    test('old payload without the new fields', () {
      final d = RecorderLessonDto.fromJson({
        'lessonId': 'l1',
        'studentName': 'Minh An',
        'status': 'sent',
        'aiStatus': 'completed',
        'movedFromStart': 'not a date',
      });
      expect(d.attendance, isNull);
      expect(d.attendanceSource, isNull);
      expect(d.absenceReason, isNull);
      expect(d.movedFromStart, isNull);
      expect(d.cancelReason, isNull);
      expect(d.isAbsent, isFalse);
      expect(d.autoPresent, isFalse);
      expect(d.isMoved, isFalse);
    });

    test('existing constructor still works without new params', () {
      const d = RecorderLessonDto(
        lessonId: 'l1',
        studentName: 'Bao',
        status: 'scheduled',
        aiStatus: 'none',
      );
      expect(d.attendance, isNull);
      expect(RecorderMoveScope.thisLesson.apiValue, 'this');
      expect(RecorderMoveScope.following.apiValue, 'following');
    });
  });
}
