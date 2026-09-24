import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_profile_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_change_password_screen.dart';

class _FakeProfileDatasource implements TutorProfileDatasource {
  final changes = <TutorChangePasswordRequest>[];

  @override
  Future<void> changePassword(TutorChangePasswordRequest request) async =>
      changes.add(request);

  // Các lời gọi khác (tải hồ sơ lúc mở màn) không liên quan tới test này.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(UnimplementedError());
}

/// Quy định mật khẩu phải khớp với web (TutorAccount): tối thiểu 8 ký tự,
/// khác mật khẩu cũ, xác nhận phải trùng.
void main() {
  late _FakeProfileDatasource ds;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String oldPass,
    required String newPass,
    required String confirm,
  }) async {
    ds = _FakeProfileDatasource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tutorProfileDatasourceProvider.overrideWithValue(ds)],
        child: const MaterialApp(home: TutorChangePasswordScreen()),
      ),
    );
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), oldPass);
    await tester.enterText(fields.at(1), newPass);
    await tester.enterText(fields.at(2), confirm);
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
  }

  testWidgets('mật khẩu mới dưới 8 ký tự bị chặn', (tester) async {
    await fillAndSubmit(
      tester,
      oldPass: 'oldpass123',
      newPass: 'abc1234',
      confirm: 'abc1234',
    );
    expect(find.text('Tối thiểu 8 ký tự'), findsOneWidget);
    expect(ds.changes, isEmpty);
  });

  testWidgets('mật khẩu mới trùng mật khẩu cũ bị chặn', (tester) async {
    await fillAndSubmit(
      tester,
      oldPass: 'samepass123',
      newPass: 'samepass123',
      confirm: 'samepass123',
    );
    expect(
      find.text('Mật khẩu mới không được trùng mật khẩu cũ'),
      findsOneWidget,
    );
  });

  testWidgets('xác nhận không khớp bị chặn', (tester) async {
    await fillAndSubmit(
      tester,
      oldPass: 'oldpass123',
      newPass: 'newpass123',
      confirm: 'newpass124',
    );
    expect(find.text('Mật khẩu không khớp'), findsOneWidget);
  });

  testWidgets('bỏ trống mật khẩu hiện tại bị chặn', (tester) async {
    await fillAndSubmit(
      tester,
      oldPass: '',
      newPass: 'newpass123',
      confirm: 'newpass123',
    );
    expect(find.text('Không được để trống'), findsOneWidget);
  });

  testWidgets('đúng 8 ký tự, khác mật khẩu cũ, khớp xác nhận thì hợp lệ', (
    tester,
  ) async {
    await fillAndSubmit(
      tester,
      oldPass: 'oldpass123',
      newPass: 'abcd1234',
      confirm: 'abcd1234',
    );
    expect(find.text('Tối thiểu 8 ký tự'), findsNothing);
    expect(
      find.text('Mật khẩu mới không được trùng mật khẩu cũ'),
      findsNothing,
    );
    expect(find.text('Mật khẩu không khớp'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(ds.changes, hasLength(1));
    expect(ds.changes.single.newPassword, 'abcd1234');
  });
}
