import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/ai_feedback_sheet.dart';

class _FakeAppRecording extends AppRecordingDatasource {
  _FakeAppRecording() : super(Dio());
  final sent = <(String, String, String?)>[];

  @override
  Future<void> reportAiFeedback(
    String recordingId, {
    required String reason,
    String? note,
  }) async => sent.add((recordingId, reason, note));
}

class _FakeRecorder extends RecorderDatasource {
  _FakeRecorder() : super(Dio());
  final deleted = <String>[];

  @override
  Future<void> deleteStudentPermanently(String id) async => deleted.add(id);
}

void main() {
  testWidgets('Báo nội dung AI sai: phải chọn lý do mới gửi được', (
    tester,
  ) async {
    final ds = _FakeAppRecording();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRecordingDatasourceProvider.overrideWithValue(ds)],
        child: const MaterialApp(
          home: Scaffold(body: AiFeedbackButton(recordingId: 'rec-1')),
        ),
      ),
    );

    await tester.tap(find.text('Báo nội dung AI sai'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(FilledButton, 'Gửi');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.text('Nhầm học sinh / thông tin của người khác'));
    await tester.enterText(find.byType(TextField), 'Tên bạn khác');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(ds.sent, [('rec-1', 'wrong_student', 'Tên bạn khác')]);
    expect(find.textContaining('Cảm ơn bạn đã báo'), findsOneWidget);
  });

  group('Xoá học sinh', () {
    const student = RecorderStudentDto(studentId: 's-1', fullName: 'Nguyễn An');

    Future<_FakeRecorder> openDelete(WidgetTester tester) async {
      final ds = _FakeRecorder();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recorderDatasourceProvider.overrideWithValue(ds)],
          child: const MaterialApp(
            home: TutorStudentFormScreen(student: student),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xoá học sinh'));
      await tester.pumpAndSettle();
      return ds;
    }

    testWidgets('xoá vĩnh viễn cần xác nhận rồi mới gọi API', (tester) async {
      final ds = await openDelete(tester);
      expect(find.text('Xoá vĩnh viễn học sinh này?'), findsOneWidget);
      expect(ds.deleted, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, 'Xoá vĩnh viễn'));
      await tester.pumpAndSettle();
      expect(ds.deleted, ['s-1']);
    });

    testWidgets('bấm "Thôi" thì không xoá', (tester) async {
      final ds = await openDelete(tester);
      await tester.tap(find.text('Thôi'));
      await tester.pumpAndSettle();
      expect(ds.deleted, isEmpty);
    });
  });
}
