import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/errors/app_exception.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';

/// AI lỗi nhưng audio còn: chi tiết buổi có nút "Thử lại AI" gọi /complete
/// trên đúng bản ghi cũ, thay vì để gia sư ghi lại (xoá mất buổi, 2026-11-20).
class _FakeDatasource extends AppRecordingDatasource {
  _FakeDatasource(this.current) : super(Dio());

  AppRecordingStatusDto current;
  final completeCalls = <(String, int)>[];

  /// Khác null: complete ném lỗi này (mất mạng, server từ chối).
  Exception? completeError;

  @override
  Future<AppRecordingStatusDto> status(String recordingId) async => current;

  @override
  Future<AppRecordingStatusDto> complete(
    String recordingId,
    int durationSec,
  ) async {
    completeCalls.add((recordingId, durationSec));
    final err = completeError;
    if (err != null) throw err;
    return current = AppRecordingStatusDto(
      recordingId: recordingId,
      status: 'processing',
      aiStatus: 'pending',
      partCount: current.partCount,
      durationSec: durationSec,
    );
  }
}

AppRecordingStatusDto _failed({int parts = 2}) => AppRecordingStatusDto(
  recordingId: 'rec-1',
  status: 'failed',
  aiStatus: 'failed',
  partCount: parts,
  durationSec: 483,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeDatasource> pump(
    WidgetTester tester,
    AppRecordingStatusDto s,
  ) async {
    // Rộng hơn điện thoại: font test (Ahem) to hơn font thật, hàng tab sẽ tràn.
    tester.view.physicalSize = const Size(1500, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = _FakeDatasource(s);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRecordingDatasourceProvider.overrideWithValue(fake),
          // Topi tắt: màn không gọi API thật.
          topiFlagsProvider.overrideWith((ref) async => TopiFlags.off),
        ],
        child: const MaterialApp(
          home: TutorRecordingDetailScreen(
            args: RecordingDetailArgs(recordingId: 'rec-1', studentName: 'An'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return fake;
  }

  testWidgets(
    'AI lỗi, còn audio: bấm "Thử lại AI" gọi complete trên bản ghi cũ',
    (tester) async {
      final fake = await pump(tester, _failed());

      final retry = find.text('Thử lại AI');
      expect(retry, findsOneWidget);
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();

      expect(fake.completeCalls, [('rec-1', 483)]);
      expect(find.text('Thử lại AI'), findsNothing);
      // Tháo màn để huỷ timer hỏi trạng thái mỗi 5 giây.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets(
    'Thử lại AI lỗi mạng: báo bằng SnackBar và nút bấm lại được',
    (tester) async {
      final fake = await pump(tester, _failed());
      fake.completeError = DioException(
        requestOptions: RequestOptions(path: '/recording/app/rec-1/complete'),
        type: DioExceptionType.connectionError,
      );

      final retry = find.text('Thử lại AI');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();
      await tester.pump();

      expect(fake.completeCalls, [('rec-1', 483)]);
      expect(
        find.text('Chưa gửi lại được cho AI. Kiểm tra mạng rồi bấm thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại AI'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    },
  );

  test('retryAiErrorMessage: ưu tiên câu backend trả về', () {
    final req = RequestOptions(path: '/x');
    expect(
      retryAiErrorMessage(
        DioException(
          requestOptions: req,
          response: Response<Map<String, dynamic>>(
            requestOptions: req,
            statusCode: 400,
            data: {'message': 'Buổi này đã được gửi.'},
          ),
          type: DioExceptionType.badResponse,
        ),
      ),
      'Buổi này đã được gửi.',
    );
    expect(
      retryAiErrorMessage(const NetworkException()),
      const NetworkException().message,
    );
    expect(
      retryAiErrorMessage(StateError('x')),
      'Chưa gửi lại được cho AI. Kiểm tra mạng rồi bấm thử lại.',
    );
  });

  testWidgets('AI lỗi, không có đoạn nào: không có nút "Thử lại AI"', (
    tester,
  ) async {
    await pump(tester, _failed(parts: 0));
    expect(find.text('Thử lại AI'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
