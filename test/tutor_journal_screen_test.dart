import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_journal_screen.dart';

/// Nhật ký học tập (V5.6 Journal) với dữ liệu giả qua ProviderScope.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final march = DateTime(2025, 3);

  StudentJournalDto journal(String month) => StudentJournalDto(
    studentId: 'stu-1',
    month: month,
    lessons: month != '2025-03'
        ? const []
        : [
            JournalLessonDto(
              lessonId: 'l1',
              scheduledStart: DateTime(2025, 3, 3, 19),
              status: 'sent',
              attendance: RecorderAttendance.present,
              durationSec: 5400,
              content: 'Ôn hằng đẳng thức (a+b)²',
              exercisesCorrect: 4,
              exercisesTotal: 6,
              difficulties: const ['Quên số hạng 2ab'],
            ),
            JournalLessonDto(
              lessonId: 'l2',
              scheduledStart: DateTime(2025, 3, 6, 19),
              attendance: RecorderAttendance.absent,
              absenceReason: RecorderAbsenceReason.pupilAbsent,
            ),
            JournalLessonDto(
              lessonId: 'l3',
              scheduledStart: DateTime(2025, 3, 10, 19),
              status: 'awaiting_approval',
              attendance: RecorderAttendance.present,
              durationSec: 5160,
              content: 'Phân tích đa thức bằng hằng đẳng thức',
              homework: '5 bài trên phiếu',
              previousHomework: 'Bài 3 trang 12',
              exercisesCorrect: 4,
              exercisesTotal: 5,
              strengths: const ['Tự làm trước'],
              studentTalkShare: 0.31,
              studentQuietStretches: const [
                QuietStretch(fromMin: 0, toMin: 20),
              ],
              comment: 'Tự nhận ra hằng đẳng thức.',
              aiDrafted: true,
            ),
          ],
  );

  Future<List<String>> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final requested = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentJournalProvider.overrideWith((ref, key) async {
            requested.add(key.month);
            return journal(key.month);
          }),
        ],
        child: MaterialApp(
          home: TutorJournalScreen(
            studentId: 'stu-1',
            studentName: 'Minh An',
            initialMonth: march,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return requested;
  }

  testWidgets('latest lesson is a full card, older ones are rows', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Nhật ký học tập'), findsOneWidget);
    expect(find.text('Minh An · Tháng 3/2025'), findsOneWidget);
    expect(find.text('2 buổi đã học · tự điền từ bản ghi âm'), findsOneWidget);
    // Thẻ buổi mới nhất (10/3).
    expect(find.text('Thứ Hai 10/3'), findsOneWidget);
    expect(find.text('Phân tích đa thức bằng hằng đẳng thức'), findsOneWidget);
    expect(find.text('Làm 4/5 bài'), findsOneWidget);
    expect(find.text('Bài 3 trang 12'), findsOneWidget);
    expect(find.text('5 bài trên phiếu'), findsOneWidget);
    expect(find.text('Tự làm trước'), findsOneWidget);
    expect(find.text('Nói 31%'), findsOneWidget);
    expect(find.text('Ít nói phút 0–20'), findsOneWidget);
    expect(find.text('Nháp AI'), findsOneWidget);
    expect(find.text('Tự nhận ra hằng đẳng thức.'), findsOneWidget);
    // Buổi trước: vắng có lý do, buổi có bản ghi có dòng ngắn.
    expect(find.text('Vắng · học sinh nghỉ'), findsOneWidget);
    expect(find.text('Ôn hằng đẳng thức (a+b)²'), findsOneWidget);
    expect(find.text('Bài cũ 4/6 · Quên số hạng 2ab'), findsOneWidget);
    expect(find.text('Bạn không phải gõ gì'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to an empty month shows the empty state', (
    tester,
  ) async {
    final requested = await pump(tester);
    await tester.tap(find.byTooltip('Tháng trước'));
    await tester.pumpAndSettle();
    expect(requested.last, '2025-02');
    expect(find.text('Minh An · Tháng 2/2025'), findsOneWidget);
    expect(find.text('Tháng này chưa có buổi học nào.'), findsOneWidget);
    expect(find.text('Bạn không phải gõ gì'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
