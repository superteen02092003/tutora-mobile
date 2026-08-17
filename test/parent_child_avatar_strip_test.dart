import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_child_avatar_strip.dart';

void main() {
  final students = [
    const ParentStudentDto(
      studentId: 'STU-D0ED4DEC1D',
      fullName: 'Nguyễn Hải Quân',
    ),
    const ParentStudentDto(
      studentId: 'STU-A884EA5E30',
      fullName: 'Phạm Phương Nhi',
      avatarUrl: 'https://api.tutora.vn/uploads/avatars/nhi.png',
    ),
  ];

  Future<void> pump(WidgetTester tester, {String? selectedId}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentChildAvatarStrip(
            students: students,
            isLoading: false,
            selectedId: selectedId,
            onSelect: (_) {},
            onAddChild: () {},
            onNotif: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('hiện đủ chip mọi con, không chỉ nút Thêm con', (tester) async {
    await pump(tester, selectedId: 'STU-A884EA5E30');

    expect(find.text('Thêm con'), findsOneWidget);
    expect(find.text('QUÂN'), findsOneWidget);
    expect(find.text('NHI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con không có ảnh vẫn hiện chip (fallback chữ đầu)', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('QUÂN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuild không làm mất chip con', (tester) async {
    await pump(tester, selectedId: 'STU-A884EA5E30');
    expect(find.text('NHI'), findsOneWidget);

    // Bug cũ: FutureBuilder bọc ngoài rebuild -> strip chỉ còn nút "Thêm con".
    await pump(tester, selectedId: 'STU-D0ED4DEC1D');
    expect(find.text('QUÂN'), findsOneWidget);
    expect(find.text('NHI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
