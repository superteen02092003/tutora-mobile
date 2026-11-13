import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/lesson_insights_card.dart';

/// Thẻ số liệu từ bản ghi: hiện đúng các hàng khi có số, không vẽ gì khi chưa
/// có (`available` = false) hoặc đang tải.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester,
    Future<LessonInsightsDto> Function() load,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonInsightsProvider('l1').overrideWith((ref) => load()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LessonInsightsCard(lessonId: 'l1')),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('available insights show every row', (tester) async {
    await pump(
      tester,
      () async => LessonInsightsDto.fromJson({
        'lessonId': 'l1',
        'available': true,
        'minutesRecorded': 86,
        'minutesPlanned': 90,
        'bothVoices': true,
        'studentTalkShare': 0.31,
        'tutorQuestions': 42,
        'avgWaitAfterQuestionSec': 3.4,
        'studentQuietStretches': [
          {'fromMin': 0, 'toMin': 20},
        ],
      }),
    );
    expect(find.text('Nghe rõ cả hai giọng'), findsOneWidget);
    expect(find.text('Học sinh nói 31% thời gian'), findsOneWidget);
    expect(find.text('Học sinh ít nói phút 0–20'), findsOneWidget);
    expect(find.text('Xem mẹo ›'), findsOneWidget);
    expect(find.text('42 câu hỏi · chờ trung bình 3,4 giây'), findsOneWidget);
    expect(find.text('Ghi được 86/90 phút'), findsOneWidget);
    expect(find.text('Đo tự động từ bản ghi âm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one voice, no wait time', (tester) async {
    await pump(
      tester,
      () async => LessonInsightsDto.fromJson({
        'lessonId': 'l1',
        'available': true,
        'bothVoices': false,
        'tutorQuestions': 2,
      }),
    );
    expect(find.text('Chỉ nghe rõ một giọng'), findsOneWidget);
    expect(find.text('2 câu hỏi'), findsOneWidget);
    expect(find.textContaining('Ghi được'), findsNothing);
  });

  testWidgets('not available renders nothing', (tester) async {
    await pump(
      tester,
      () async =>
          LessonInsightsDto.fromJson({'lessonId': 'l1', 'available': false}),
    );
    expect(find.text('Đo tự động từ bản ghi âm'), findsNothing);
  });

  testWidgets('loading renders nothing', (tester) async {
    await pump(
      tester,
      () => Future<LessonInsightsDto>.delayed(
        const Duration(seconds: 5),
        () => const LessonInsightsDto(lessonId: 'l1'),
      ),
    );
    expect(find.text('Đo tự động từ bản ghi âm'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });
}
