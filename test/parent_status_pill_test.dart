import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_status_pill.dart';

void main() {
  Future<String> labelOf(
    WidgetTester tester,
    String status, {
    bool isPendingConfirm = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentStatusPill(
            status: status,
            isPendingConfirm: isPendingConfirm,
          ),
        ),
      ),
    );
    return tester.widget<Text>(find.byType(Text)).data!;
  }

  testWidgets('phủ đủ 9 trạng thái BE, không rơi vào "—"', (tester) async {
    expect(await labelOf(tester, 'scheduled'), 'Đã lên lịch');
    // Bug cũ: pill dùng key 'checkedin'/'noshow' không tồn tại ở BE -> hiện "—".
    expect(await labelOf(tester, 'in_progress'), 'Đang học');
    expect(await labelOf(tester, 'no_show'), 'Vắng mặt');
    expect(await labelOf(tester, 'reserved'), 'Chờ gia sư nhận');
    expect(await labelOf(tester, 'pending_confirmation'), 'Chờ xác nhận');
    expect(await labelOf(tester, 'completed'), 'Hoàn thành');
    expect(await labelOf(tester, 'disputed'), 'Tranh chấp');
    expect(await labelOf(tester, 'cancelled'), 'Đã huỷ');
    expect(await labelOf(tester, 'cancelled_noshow'), 'Đã huỷ');
  });

  testWidgets('isPendingConfirm thắng status', (tester) async {
    expect(
      await labelOf(tester, 'completed', isPendingConfirm: true),
      'Chờ xác nhận',
    );
  });
}
