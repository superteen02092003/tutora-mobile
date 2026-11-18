import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/report_after_send_screens.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_pupil_skills.dart';

/// Góp ý của Michael ở buổi họp 16/11 (canvas V58):
/// A1 thẻ kỹ năng không hiện mức bằng 0; A2 một kỹ năng chỉ có một mức;
/// A3 tab Nhận xét đưa số kỹ năng lên mức lên đầu.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const skills = [
    TopiPupilSkill(node: 'N9.15', level: TopiLevel.improving),
    TopiPupilSkill(node: 'N7.01', level: TopiLevel.toDo),
    TopiPupilSkill(node: 'N7.03', level: TopiLevel.toDo),
  ];

  Future<void> pump(WidgetTester tester, Widget child, List<Override> o) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: o,
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  group('A2 gapLevel', () {
    test('same skill code → the skill card level', () {
      const gap = TopiGap(rank: 1, node: 'N7.01', level: TopiLevel.improving);
      expect(gapLevel(gap, skills), TopiLevel.toDo);
    });

    test('no skill code → the plan level', () {
      const gap = TopiGap(rank: 1, title: 'Dấu của cos khi góc tù');
      expect(gapLevel(gap, skills), isNull);
      const gap2 = TopiGap(rank: 1, level: TopiLevel.improving);
      expect(gapLevel(gap2, skills), TopiLevel.improving);
    });
  });

  testWidgets('A1 skill card hides empty levels', (tester) async {
    await pump(
      tester,
      const PupilSkillsCard(studentId: 's1', studentName: 'An'),
      [
        topiFlagsNowProvider.overrideWithValue(const TopiFlags(skills: true)),
        pupilSkillsProvider('s1').overrideWith((ref) async => skills),
      ],
    );
    await tester.pump();
    expect(find.text('Topi đã gặp 3 kỹ năng toán'), findsOneWidget);
    expect(find.textContaining('Tiến bộ · 1'), findsOneWidget);
    expect(find.textContaining('Cần học · 2'), findsOneWidget);
    expect(find.textContaining('Vững · 0'), findsNothing);
    expect(find.textContaining('Chuẩn · 0'), findsNothing);
  });

  testWidgets('A3 lesson result: success first, then small rows', (
    tester,
  ) async {
    final topi = LessonTopi.fromJson({
      'plan': {
        'gaps': [
          {'title': 'Dấu của cos khi góc tù', 'seen_in_lessons': 1},
          {'title': 'Chọn định lí sin hay định lí cos', 'seen_in_lessons': 1},
          {'title': 'Xét đủ các đỉnh', 'seen_in_lessons': 2},
        ],
        'steps': <dynamic>[],
      },
      'skills': {'proposed_changes': <dynamic>[]},
    });
    await pump(
      tester,
      const LessonFeedbackSections(lessonId: 'l1', studentName: 'An'),
      [
        topiFlagsNowProvider.overrideWithValue(
          const TopiFlags(plan: true, tips: true, skills: true),
        ),
        lessonTopiProvider('l1').overrideWith((ref) async => topi),
        lessonInsightsProvider('l1').overrideWith(
          (ref) async => const LessonInsightsDto(
            lessonId: 'l1',
            available: true,
            minutesRecorded: 75,
            minutesPlanned: 120,
          ),
        ),
      ],
    );
    await tester.pump();
    expect(find.text('Kết quả buổi này'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('kỹ năng lên mức'), findsOneWidget);
    expect(
      find.textContaining('Chưa ghi nhận tiến bộ trong buổi này'),
      findsOneWidget,
    );
    expect(find.text('2 kỹ năng cần luyện'), findsOneWidget);
    expect(find.text('75 phút · lịch 120 phút'), findsOneWidget);
    expect(find.textContaining('lỗ hổng tiến bộ'), findsNothing);
  });
}
