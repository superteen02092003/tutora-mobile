import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/consent_text.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';

class _FakeRecorderDatasource extends RecorderDatasource {
  _FakeRecorderDatasource() : super(Dio());

  final created = <RecorderStudentInput>[];

  @override
  Future<RecorderStudentDto> createStudent(RecorderStudentInput input) async {
    created.add(input);
    return RecorderStudentDto(studentId: 's-1', fullName: input.fullName);
  }
}

void main() {
  late _FakeRecorderDatasource ds;

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ds = _FakeRecorderDatasource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [recorderDatasourceProvider.overrideWithValue(ds)],
        child: const MaterialApp(home: TutorStudentFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequired(
    WidgetTester tester, {
    String phone = '0901234567',
  }) async {
    Future<void> type(String label, String text) => tester.enterText(
      find.widgetWithText(TextFormField, label),
      text,
    );
    await type('Họ tên học sinh', 'Nguyễn An');
    await type('Môn (vd. Toán)', 'Toán');
    await type('Tên phụ huynh (vd. Chị Hương)', 'Chị Hương');
    await type('SĐT phụ huynh (có dùng Zalo)', phone);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lớp 7').last);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm học sinh'));
    await tester.pumpAndSettle();
  }

  testWidgets('chưa tick đồng ý của phụ huynh thì không thêm được học sinh', (
    tester,
  ) async {
    await pumpForm(tester);
    await fillRequired(tester);

    await submit(tester);

    expect(ds.created, isEmpty);
    expect(
      find.textContaining('Cần xác nhận phụ huynh đã đọc và đồng ý'),
      findsOneWidget,
    );
  });

  testWidgets('tick đồng ý thì gửi parentConsent + phiên bản nội dung', (
    tester,
  ) async {
    await pumpForm(tester);
    await fillRequired(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await submit(tester);

    expect(ds.created, hasLength(1));
    final json = ds.created.single.toJson();
    expect(json['parentConsent'], isTrue);
    expect(json['consentVersion'], consentTextVersion);
    expect(json['parentPhone'], '0901234567');
  });

  testWidgets('bỏ trống các ô bắt buộc thì báo lỗi, không gọi API', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await submit(tester);

    expect(ds.created, isEmpty);
    expect(find.text('Nhập họ tên học sinh'), findsOneWidget);
    expect(find.text('Chọn lớp'), findsOneWidget);
    expect(find.text('Nhập môn học'), findsOneWidget);
    expect(find.text('Nhập tên phụ huynh'), findsOneWidget);
    expect(find.text('Nhập số điện thoại phụ huynh'), findsOneWidget);
  });

  for (final phone in ['12345', '0901234', '090123456789', '1901234567']) {
    testWidgets('SĐT phụ huynh sai định dạng ($phone) bị chặn', (tester) async {
      await pumpForm(tester);
      await fillRequired(tester, phone: phone);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      await submit(tester);

      expect(ds.created, isEmpty);
      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    });
  }

  for (final phone in ['0901234567', '+84901234567', '090 123 4567']) {
    testWidgets('SĐT phụ huynh hợp lệ ($phone) được chấp nhận', (tester) async {
      await pumpForm(tester);
      await fillRequired(tester, phone: phone);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      await submit(tester);

      expect(ds.created, hasLength(1));
    });
  }
}
