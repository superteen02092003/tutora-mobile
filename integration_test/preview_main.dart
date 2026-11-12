// Chạy app thật trên máy ảo với backend GIẢ (dữ liệu bịa của bộ as-built),
// để xem giao diện mà không chạm server, token hay micro thật:
//
//   flutter run -t integration_test/preview_main.dart -d emulator-5554
//
// Đổi kịch bản: --dart-define=PREVIEW_SCENARIO=empty|error|loading|oneLesson
// (mặc định loaded). Không phải test; không chạy trong `flutter test`.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tutora/app.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';

import 'as_built/fake_backend.dart';
import 'as_built/fakes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';

  const name = String.fromEnvironment(
    'PREVIEW_SCENARIO',
    defaultValue: 'loaded',
  );
  final backend = FakeBackend()
    ..scenario = Scenario.values.firstWhere(
      (s) => s.name == name,
      orElse: () => Scenario.loaded,
    );
  // ".invalid" không bao giờ phân giải: request nào lọt khỏi fake sẽ lỗi ngay.
  final dio = Dio(BaseOptions(baseUrl: 'http://as-built.invalid/api'))
    ..httpClientAdapter = backend;
  final storage = FakeStorage()..welcomeSeen = true;

  runApp(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(dio),
        secureStorageProvider.overrideWithValue(storage),
        lessonRecordingProvider.overrideWith(
          (ref) => FakeRecordingNotifier(AppRecordingDatasource(dio)),
        ),
      ],
      child: const App(),
    ),
  );
}
