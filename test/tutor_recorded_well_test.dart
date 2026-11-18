import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recorded_well_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';

/// T11 không mở được bằng tay trên bản DEV (phải ghi âm thật vào production),
/// nên kiểm bằng test: hai trường hợp nghe rõ / nghe nhỏ, cỡ màn điện thoại,
/// không tràn chữ.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, RecordedWellArgs args) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: TutorRecordedWellScreen(args: args)),
    );
    await tester.pump();
  }

  const review = ReportReviewArgs(
    recordingId: 'r1',
    studentName: 'Minh An',
    subtitle: 'Toán · Lớp 8',
  );

  testWidgets('clear recording shows "Ghi âm tốt" and the draft button', (
    tester,
  ) async {
    await pump(
      tester,
      const RecordedWellArgs(
        review: review,
        recordedMin: 86,
        bookedMin: 90,
        quietShare: 0.1,
      ),
    );
    expect(find.text('Ghi âm tốt'), findsOneWidget);
    expect(find.text('Mở bản nháp'), findsOneWidget);
    expect(find.textContaining('86 / 90 phút'), findsWidgets);
    expect(find.text('Xem mẹo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quiet recording says so and offers tips', (tester) async {
    await pump(
      tester,
      const RecordedWellArgs(review: review, recordedMin: 41, quietShare: 0.4),
    );
    expect(find.text('Đã ghi xong'), findsOneWidget);
    expect(find.text('Âm thanh nhỏ khoảng 40% thời gian'), findsOneWidget);
    expect(find.text('Xem mẹo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
