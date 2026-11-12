import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/lesson_move_sheet.dart';

/// Form "Đổi lịch buổi học": kiểm tra giờ, phạm vi áp dụng, đề xuất booking.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime(2026, 11, 13, 8);
  final start = DateTime(2026, 11, 14, 16, 30);
  final end = DateTime(2026, 11, 14, 18);

  Future<List<LessonMoveChoice>> pump(
    WidgetTester tester, {
    DateTime? from,
    DateTime? to,
    bool weekly = false,
    bool proposal = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final calls = <LessonMoveChoice>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonMoveSheet(
            studentName: 'Khôi',
            subtitle: 'Toán · Lớp 9',
            start: from ?? start,
            end: to ?? end,
            weekly: weekly,
            proposal: proposal,
            now: () => now,
            onSubmit: (c) async {
              calls.add(c);
              // false: sheet stays open (no route to pop in this test).
              return false;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return calls;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('move-save')));
    await tester.pump();
  }

  testWidgets('end before start is rejected', (tester) async {
    final calls = await pump(
      tester,
      from: DateTime(2026, 11, 14, 18),
      to: DateTime(2026, 11, 14, 17),
    );
    await save(tester);
    expect(find.text('Giờ kết thúc phải sau giờ bắt đầu.'), findsOneWidget);
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a time in the past is rejected', (tester) async {
    final calls = await pump(
      tester,
      from: DateTime(2026, 11, 12, 16),
      to: DateTime(2026, 11, 12, 17),
    );
    await save(tester);
    expect(find.text('Chọn một thời điểm chưa qua.'), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('unchanged time asks for a different one', (tester) async {
    final calls = await pump(tester);
    await save(tester);
    expect(find.text('Chọn ngày hoặc giờ khác với hiện tại.'), findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('scope options only for lessons from a weekly schedule', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Chỉ buổi này'), findsNothing);
    expect(find.text('Buổi này và các buổi sau'), findsNothing);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('weekly lesson: "following" scope is submitted', (tester) async {
    final calls = await pump(tester, weekly: true);
    expect(find.text('Chỉ buổi này'), findsOneWidget);
    expect(find.text('Buổi này và các buổi sau'), findsOneWidget);
    await tester.tap(find.byKey(const Key('move-scope-following')));
    await tester.pump();
    await save(tester);
    expect(calls, hasLength(1));
    expect(calls.single.scope, RecorderMoveScope.following);
    expect(calls.single.start, start);
    expect(calls.single.end, end);
  });

  testWidgets('booked lesson: proposal form, no scope', (tester) async {
    await pump(tester, weekly: true, proposal: true);
    expect(find.text('Đề xuất đổi lịch'), findsOneWidget);
    expect(find.text('Gửi đề xuất'), findsOneWidget);
    expect(find.text('Buổi này và các buổi sau'), findsNothing);
    expect(find.byKey(const Key('move-reason')), findsOneWidget);
  });

  test('weekly schedule match uses weekday + start time', () {
    const slots = [
      RecorderScheduleSlot(dayOfWeek: 6, start: '16:30', end: '18:00'),
    ];
    // 14/11/2026 là Thứ Bảy.
    expect(isFromWeeklySchedule(null, slots, start), isTrue);
    expect(
      isFromWeeklySchedule(null, slots, DateTime(2026, 11, 14, 17)),
      isFalse,
    );
    final moved = RecorderLessonDto(
      lessonId: 'x',
      studentName: 'Khôi',
      status: 'scheduled',
      aiStatus: 'none',
      movedFromStart: DateTime(2026, 11, 13, 16, 30),
    );
    expect(isFromWeeklySchedule(moved, slots, start), isFalse);
  });
}
