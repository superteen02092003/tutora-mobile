import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/report_after_send_screens.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';

/// Theo sau A2/A3 (Michael 16/11), dựng từ buổi 28/10 (Toán 10, mở chương hệ
/// thức lượng): thẻ ưu tiên ghi "Cần học" mà ô kỹ năng ghi "Tiến bộ"; ô kết quả
/// ghi "0 kỹ năng lên mức" dù học sinh tự làm đúng 8/11 bài.
void main() {
  final topi = LessonTopi.fromJson({
    'plan': {
      'gaps': [
        {
          'node': 'H10.03',
          'title': 'Giá trị lượng giác của góc 0°–180°',
          'level': 'to_do',
          'role': 'focus',
          'seen_in_lessons': 1,
        },
        {'node': 'N10.05', 'title': 'Bất phương trình', 'level': 'to_do'},
      ],
      'steps': <dynamic>[],
    },
    'skills': {
      'first_seen': [
        {'node': 'H10.03', 'level': 'improving'},
        {'node': 'H10.04', 'level': 'improving'},
        {'node': 'H10.05', 'level': 'improving'},
        {'node': 'H10.06', 'level': 'improving'},
      ],
      'proposed_changes': <dynamic>[],
    },
  });

  test('A2: gap level follows the skill level in the same lesson', () {
    final gaps = topi.plan!.gaps;
    final items = topi.skills!.items;
    expect(gapLevelInLesson(gaps[0], items), TopiLevel.improving);
    // No skill with that code in the lesson: keep the plan's level.
    expect(gapLevelInLesson(gaps[1], items), TopiLevel.toDo);
  });

  test('A3: a new-chapter lesson leads with new skills, not zero', () {
    const insights = LessonInsightsDto(
      lessonId: 'l1',
      available: true,
      minutesRecorded: 75,
      minutesPlanned: 120,
    );
    final s = ReportDoneStats.from(insights, topi);
    expect(s.improvedGaps, 0);
    expect(s.newSkills, 4);
    expect(s.newSkillsCanDo, 4);
    expect(s.leadWithNewSkills, isTrue);
  });

  test('A3: a skill levelled up still leads', () {
    final t = LessonTopi.fromJson({
      'skills': {
        'first_seen': [
          {'node': 'H10.04', 'level': 'improving'},
        ],
        'proposed_changes': [
          {'node': 'N10.05', 'from': 'to_do', 'to': 'improving', 'star': true},
        ],
      },
    });
    final s = ReportDoneStats.from(null, t);
    expect(s.improvedGaps, 1);
    expect(s.leadWithNewSkills, isFalse);
  });

  test('A3: new skills all still wrong → keep the zero line', () {
    final t = LessonTopi.fromJson({
      'skills': {
        'first_seen': [
          {'node': 'H10.04', 'level': 'to_do'},
        ],
        'proposed_changes': <dynamic>[],
      },
    });
    final s = ReportDoneStats.from(null, t);
    expect(s.newSkills, 1);
    expect(s.newSkillsCanDo, 0);
    expect(s.leadWithNewSkills, isFalse);
  });
}
