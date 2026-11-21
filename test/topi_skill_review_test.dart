import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/features/tutor/data/datasources/topi_datasource.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/data/models/topi_review_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_skill_review.dart';

/// Màn D (Khanh 2026-11-22): gia sư bấm Đúng / Không đúng (lý do) cho từng kỹ năng.
class _Fake extends TopiDatasource {
  _Fake() : super(Dio());

  String status = 'proposed';
  String? reason;
  final calls = <String>[];

  SkillReviewItem get item => SkillReviewItem(
    id: 'e1',
    node: 'N8.01',
    nameVi: 'Hằng đẳng thức',
    fromLevel: 'to_do',
    toLevel: 'improving',
    status: status,
    reason: reason,
    exercise: 'Khai triển (x+4)²',
    atSec: 20,
    context: const [
      SkillReviewLine(
        seg: 0,
        start: 10,
        speaker: 'tutor',
        text: 'Khai triển cho cô.',
      ),
      SkillReviewLine(
        seg: 1,
        start: 20,
        speaker: 'student',
        text: 'Dạ x² cộng 16 ạ.',
        evidence: true,
      ),
    ],
  );

  @override
  Future<List<SkillReviewItem>> getSkillReview(String lessonId) async => [item];

  @override
  Future<List<SkillReviewItem>> reviewSkill(
    String eventId, {
    required String verdict,
    String? reason,
    String? correctedNode,
  }) async {
    calls.add('$verdict|${reason ?? ''}');
    status = verdict;
    this.reason = reason;
    return [item];
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_Fake> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = _Fake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          topiDatasourceProvider.overrideWithValue(fake),
          topiFlagsNowProvider.overrideWithValue(
            const TopiFlags(skills: true),
          ),
          lessonTopiProvider.overrideWith((ref, id) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopiSkillReviewSection(lessonId: 'l1', grade: 8),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('Thu gọn mặc định; bấm thì mở hội thoại; Đúng thì lưu xác nhận', (
    tester,
  ) async {
    final fake = await pump(tester);
    expect(find.text('Hằng đẳng thức'), findsOneWidget);
    expect(find.text('Dạ x² cộng 16 ạ.'), findsNothing);

    await tester.tap(find.text('Xem hội thoại ▾'));
    await tester.pumpAndSettle();
    expect(find.text('Dạ x² cộng 16 ạ.'), findsOneWidget);

    await tester.tap(find.text('Đúng'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['confirmed|']);
    expect(find.textContaining('Bạn xác nhận'), findsOneWidget);
  });

  testWidgets('Không đúng: chọn lý do thì lưu bác kèm lý do', (tester) async {
    final fake = await pump(tester);
    await tester.tap(find.text('Không đúng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bé sơ suất, tự sửa ngay'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['rejected|Bé sơ suất, tự sửa ngay']);
    expect(find.text('Đã bác · Bé sơ suất, tự sửa ngay'), findsOneWidget);
  });
}
