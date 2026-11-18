import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/report_after_send_screens.dart';

/// V57-Done (Michael 13/11): ô "Buổi này" sau khi gửi báo cáo.
void main() {
  test('clock', () {
    expect(reportClock(1865), '31:05');
    expect(reportClock(5), '00:05');
  });

  test('stats from insights and Topi', () {
    final topi = LessonTopi.fromJson({
      'plan': {
        'gaps': [
          {'node': 'N7.01', 'title': 'Số hữu tỉ', 'seen_in_lessons': 1},
          {'node': 'N8.02', 'title': 'Dấu ngoặc', 'seen_in_lessons': 3},
        ],
        'steps': <dynamic>[],
      },
      'skills': {
        'proposed_changes': [
          {
            'node': 'N8.04',
            'from': 'improving',
            'to': 'standard',
            'star': true,
          },
          {'node': 'N8.02', 'from': 'to_do', 'to': 'improving', 'star': true},
          {'node': 'N7.09', 'from': 'standard', 'to': 'improving'},
        ],
      },
    });
    const insights = LessonInsightsDto(
      lessonId: 'l1',
      available: true,
      minutesRecorded: 86,
      minutesPlanned: 90,
    );
    final s = ReportDoneStats.from(insights, topi);
    expect(s.minutesRecorded, 86);
    expect(s.minutesPlanned, 90);
    expect(s.newGaps, 1);
    expect(s.improvedGaps, 2);
    expect(s.stars, 2);
    expect(s.isEmpty, isFalse);
  });

  test('nothing known → empty box', () {
    final s = ReportDoneStats.from(null, null);
    expect(s.isEmpty, isTrue);
    expect(s.stars, 0);
  });
}
