import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/shared/services/fcm_notification_handler.dart';

/// Báo lỗi AI cho gia sư: loại lỗi, có thử lại được không, AI chậm.
void main() {
  Map<String, dynamic> json(Map<String, dynamic> extra) => {
    'recordingId': 'r1',
    'status': 'failed',
    'aiStatus': 'failed',
    ...extra,
  };

  test('system outage: no retry, tutor message from the backend', () {
    final s = AppRecordingStatusDto.fromJson(
      json({
        'aiErrorKind': 'billing',
        'canRetry': false,
        'errorMessage': 'Hệ thống AI của TopTutor đang tạm gián đoạn.',
      }),
    );
    expect(s.aiErrorKind, 'billing');
    expect(s.canRetry, isFalse);
    expect(s.errorMessage, contains('tạm gián đoạn'));
  });

  test('older backend without the fields still allows retry', () {
    final s = AppRecordingStatusDto.fromJson(json({}));
    expect(s.canRetry, isTrue);
    expect(s.aiErrorKind, isNull);
  });

  test('AI slow after 30 minutes from the end of the lesson', () {
    final end = DateTime(2026, 11, 22, 10);
    final s = AppRecordingStatusDto.fromJson({
      'recordingId': 'r1',
      'status': 'processing',
      'aiStatus': 'processing',
      'endedAt': end.toUtc().toIso8601String(),
    });
    expect(s.isAiSlow(end.add(const Duration(minutes: 29))), isFalse);
    expect(s.isAiSlow(end.add(const Duration(minutes: 31))), isTrue);
    final done = AppRecordingStatusDto.fromJson(
      json({'endedAt': end.toUtc().toIso8601String()}),
    );
    expect(done.isAiSlow(end.add(const Duration(hours: 5))), isFalse);
  });

  test('push types for report ready and AI failed', () {
    expect(lessonReportReadyType, 'lesson_report_ai_fill_ready');
    expect(lessonReportFailedType, 'lesson_report_ai_failed');
  });
}
