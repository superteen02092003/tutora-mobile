// ignore_for_file: avoid_print, avoid_redundant_argument_values, document_ignores, library_private_types_in_public_api
// Test tooling, not app code: console output and terse helpers are intended.
// As-built screenshots of the TopTutor tutor app.
//
// Runs the REAL app (real router, real screens, real providers and datasources)
// with three things replaced, all in-memory and fictional:
//   * the HTTP layer  -> as_built/fake_backend.dart (no network request)
//   * secure storage  -> as_built/fakes.dart (FakeStorage)
//   * the recorder    -> as_built/fakes.dart (FakeRecordingNotifier, no mic)
//
// On the phone:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/as_built_screens_test.dart -d <device> [--profile]
// Headless preview on the PC (no phone; approximate, see README):
//   flutter test integration_test/as_built_screens_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tutora/app.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/router/app_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/topi_before_lesson_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recorded_well_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_recording_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/tutor_report_review_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_booking_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_schedule/tutor_session_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';

import 'as_built/fake_backend.dart';
import 'as_built/fakes.dart';

// Set first thing in main(): a top-level initialiser would run lazily, after
// testWidgets had already created another binding.
late final IntegrationTestWidgetsFlutterBinding binding;

/// On a phone: the real surface is captured. Anywhere else (flutter test on the
/// PC) the app is drawn by the test renderer and saved to build/as_built_host.
final bool onDevice = Platform.isAndroid || Platform.isIOS;

const _fixtureDeviceSize = Size(968, 2376); // Galaxy Z Fold6, cover screen
const _fixtureDpr = 2.625;

class _Env {
  _Env(this.backend, this.storage, this.dio);
  final FakeBackend backend;
  final FakeStorage storage;
  final Dio dio;
  FakeRecordingNotifier? recorder;
}

late _Env env;
final GlobalKey _repaintKey = GlobalKey();
final List<String> shots = [];
final List<String> failures = [];
final List<String> uiErrors = [];
String _scene = '';
// --dart-define=AS_BUILT_START=45 continues numbering after screenshot 45.
int _n = const int.fromEnvironment('AS_BUILT_START');
bool _surfaceConverted = false;

String get _hostDir => 'build/as_built_host';

Future<void> settle(WidgetTester t, [int ms = 700]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    if (!onDevice) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> shot(WidgetTester t, String name) async {
  await settle(t, 300);
  final file = '${(++_n).toString().padLeft(2, '0')}_$name';
  if (onDevice) {
    if (!_surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      _surfaceConverted = true;
      await t.pump();
    }
    await binding.takeScreenshot(file);
  } else {
    final boundary =
        _repaintKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(_hostDir).createSync(recursive: true);
      File('$_hostDir/$file.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }
  shots.add(file);
}

/// Run one scene; a failure is recorded and the run goes on with the next one.
Future<void> scene(
  WidgetTester t,
  String name,
  Future<void> Function() body,
) async {
  _scene = name;
  try {
    await body();
  } on Object catch (e) {
    failures.add('$name: ${e.toString().split('\n').first}');
  }
  // Drop anything the scene left behind (exception from the last frame).
  t.takeException();
}

Future<void> launch(
  WidgetTester t, {
  Scenario scenario = Scenario.loaded,
  bool welcomeSeen = true,
  String? go,
  Object? extra,
  bool mic = true,
  int bookingClasses = 0,
}) async {
  await t.pumpWidget(const SizedBox.shrink());
  final backend = FakeBackend()
    ..scenario = scenario
    ..bookingClasses = bookingClasses;
  // ".invalid" never resolves: a request that bypassed the fake would fail.
  final dio = Dio(BaseOptions(baseUrl: 'http://as-built.invalid/api'))
    ..httpClientAdapter = backend;
  final storage = FakeStorage()..welcomeSeen = welcomeSeen;
  env = _Env(backend, storage, dio);

  await t.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(dio),
        secureStorageProvider.overrideWithValue(storage),
        lessonRecordingProvider.overrideWith((ref) {
          final n = FakeRecordingNotifier(AppRecordingDatasource(dio))
            ..micPermission = mic;
          env.recorder = n;
          return n;
        }),
      ],
      child: RepaintBoundary(key: _repaintKey, child: const App()),
    ),
  );
  await t.pump();
  if (go != null) await goTo(t, go, extra: extra);
}

GoRouter router(WidgetTester t) => ProviderScope.containerOf(
  t.element(find.byType(MaterialApp)),
).read(appRouterProvider);

Future<void> goTo(WidgetTester t, String path, {Object? extra}) async {
  router(t).go(path, extra: extra);
  await settle(t, 900);
}

Future<void> pushRoute(WidgetTester t, String path, {Object? extra}) async {
  unawaited(router(t).push<Object?>(path, extra: extra));
  await settle(t, 900);
}

/// A context under the root Navigator (for the screens' static open() helpers).
BuildContext navContext(WidgetTester t) =>
    t.element(find.byType(Navigator).first);

Future<void> tapText(
  WidgetTester t,
  String text, {
  bool contains = false,
  int index = 0,
}) async {
  final f = contains ? find.textContaining(text) : find.text(text);
  if (f.evaluate().isEmpty) throw StateError('text not found: "$text"');
  await t.tap(f.at(index), warnIfMissed: false);
  await settle(t, 800);
}

/// Types into the n-th text field by setting its controller (tester.enterText
/// shows nothing on the phone: the real IME is attached, not the test one).
Future<void> typeInto(WidgetTester t, int index, String text) async {
  final f = find.byType(EditableText);
  if (f.evaluate().length <= index) throw StateError('no text field #$index');
  t.widget<EditableText>(f.at(index)).controller.text = text;
  await t.pump(const Duration(milliseconds: 200));
}

/// Types into the text field whose label is [label] (independent of how many
/// fields the list has built, which changes with the layout).
Future<void> typeIntoLabeled(WidgetTester t, String label, String text) async {
  final field = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  if (field.evaluate().isEmpty) throw StateError('no text field "$label"');
  final f = find.descendant(
    of: field.first,
    matching: find.byType(EditableText),
  );
  t.widget<EditableText>(f).controller.text = text;
  await t.pump(const Duration(milliseconds: 200));
}

/// Tab bar V5.6: labels in sentence case ("Trang chủ") under an icon.
Future<void> tapTab(WidgetTester t, String label) =>
    tapFinder(t, find.bySemanticsLabel(label), 'tab $label');

Future<void> tapFinder(WidgetTester t, Finder f, String what) async {
  if (f.evaluate().isEmpty) throw StateError('not found: $what');
  await t.tap(f.first, warnIfMissed: false);
  await settle(t, 800);
}

Future<void> back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await settle(t, 700);
}

Future<void> scrollDown(WidgetTester t, [double dy = -700]) async {
  final lists = find.byType(Scrollable);
  if (lists.evaluate().isEmpty) throw StateError('nothing to scroll');
  await t.drag(lists.first, Offset(0, dy), warnIfMissed: false);
  await settle(t, 500);
}

/// Feed the (fake) microphone: [levels] cycled for [count] samples.
Future<void> feedSound(
  WidgetTester t,
  List<double> levels, {
  int count = 30,
}) async {
  for (var i = 0; i < count; i++) {
    // The app's own level listener throws on every sample (see README: "Bugs
    // found"); a guarded zone keeps that from failing the whole run.
    runZonedGuarded(() => env.recorder!.setLevel(levels[i % levels.length]), (
      e,
      st,
    ) {
      final msg = '$_scene: app error while feeding sound: $e';
      if (!uiErrors.contains(msg)) uiErrors.add(msg);
    });
    await t.pump(const Duration(milliseconds: 60));
  }
}

const _clear = [0.55, 0.8, 0.4, 0.7, 0.9, 0.5, 0.65, 0.35];
const _quiet = [0.02, 0.0, 0.03, 0.01, 0.0, 0.02, 0.01, 0.03];

RecordingTarget get _baoToday => const RecordingTarget(
  studentId: 'stu-bao',
  studentName: 'Bao',
  subjectName: 'Toán · Lớp 9',
  timeStart: '19:00',
  timeEnd: '20:30',
);

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
    Intl.defaultLocale = 'vi_VN';
  });

  testWidgets('as-built screens', (tester) async {
    if (!onDevice) {
      tester.view.physicalSize = _fixtureDeviceSize;
      tester.view.devicePixelRatio = _fixtureDpr;
      addTearDown(tester.view.reset);
      // Let the headless run fetch the fonts the way the app does (google_fonts
      // caches them through path_provider, which has no host implementation).
      HttpOverrides.global = null;
      final cache = Directory('build/as_built_host_cache')
        ..createSync(recursive: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => cache.absolute.path,
      );
    }

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (d) =>
        uiErrors.add('$_scene: ${d.exceptionAsString().split('\n').first}');
    addTearDown(() => FlutterError.onError = originalOnError);

    // ── 1 · Start-up and sign-in ────────────────────────────────────────────
    await scene(tester, 'splash', () async {
      await launch(tester);
      await shot(tester, 'splash_launch');
    });
    await scene(tester, 'login', () async {
      await launch(tester, go: AppRoutes.login);
      await shot(tester, 'login_empty');
      await typeInto(tester, 0, '0900000000');
      await typeInto(tester, 1, 'matkhau-gia');
      await shot(tester, 'login_filled');
    });
    await scene(tester, 'register', () async {
      await launch(tester, go: AppRoutes.login);
      await tapText(tester, 'Đăng ký', contains: true);
      await shot(tester, 'register_empty');
    });
    await scene(tester, 'forgot', () async {
      await launch(tester, go: AppRoutes.login);
      await tapText(tester, 'Quên mật khẩu', contains: true);
      await shot(tester, 'forgot_empty');
    });
    await scene(tester, 'otp', () async {
      await launch(
        tester,
        go: AppRoutes.otp,
        extra: const OtpArgs(phone: '0900000000', mode: OtpMode.register),
      );
      await shot(tester, 'otp_register');
    });

    // ── 2 · First run: welcome, then Home ───────────────────────────────────
    await scene(tester, 'welcome', () async {
      await launch(tester, welcomeSeen: false, go: AppRoutes.tutorHome);
      await shot(tester, 'welcome_first-run');
      await scrollDown(tester);
      await shot(tester, 'welcome_first-run_scrolled');
      await tapText(tester, 'Ghi âm hoạt động thế nào');
      await shot(tester, 'recording-tips_from-welcome');
      await back(tester);
      await tapText(tester, 'Bắt đầu');
      await shot(tester, 'tab-home_after-welcome');
    });

    // ── 3 · The four tabs: loaded, tab switching ────────────────────────────
    await scene(tester, 'tabs-loaded', () async {
      await launch(tester, go: AppRoutes.tutorHome);
      await shot(tester, 'tab-home_loaded');
      await scrollDown(tester);
      await shot(tester, 'tab-home_loaded_scrolled');
      await tapTab(tester, 'Lộ trình');
      await shot(tester, 'tab-path_loaded');
      await scrollDown(tester);
      await shot(tester, 'tab-path_loaded_scrolled');
      await tapTab(tester, 'Bài học');
      await shot(tester, 'tab-lessons_loaded');
      await tapTab(tester, 'Học sinh');
      await shot(tester, 'tab-students_loaded');
      // Bản ghi âm: không còn là tab (V5.6), mở như màn con.
      await goTo(tester, AppRoutes.tutorRecordings);
      await shot(tester, 'recordings_loaded');
      await scrollDown(tester);
      await shot(tester, 'recordings_loaded_scrolled');
    });
    for (final s in [Scenario.empty, Scenario.error, Scenario.loading]) {
      await scene(tester, 'tabs-${s.name}', () async {
        for (final (tab, path) in [
          ('home', AppRoutes.tutorHome),
          ('path', AppRoutes.tutorPath),
          ('lessons', AppRoutes.tutorSchedule),
          ('students', AppRoutes.tutorStudents),
          ('recordings', AppRoutes.tutorRecordings),
        ]) {
          await launch(tester, scenario: s, go: path);
          await shot(tester, 'tab-${tab}_${s.name}');
        }
      });
    }

    // ── 4 · Bell and settings ───────────────────────────────────────────────
    for (final s in [Scenario.loaded, Scenario.empty, Scenario.error]) {
      await scene(tester, 'notifications-${s.name}', () async {
        await launch(tester, scenario: s, go: AppRoutes.tutorHome);
        await tapFinder(tester, find.byTooltip('Thông báo'), 'bell');
        await shot(tester, 'notifications_${s.name}');
      });
    }
    await scene(tester, 'settings', () async {
      await launch(tester, go: AppRoutes.tutorHome);
      await tapFinder(tester, find.text('H'), 'avatar');
      await shot(tester, 'settings_top');
      await scrollDown(tester);
      await shot(tester, 'settings_scrolled');
      await tapText(tester, 'Xoá tài khoản');
      await shot(tester, 'settings_delete-account-sheet');
      await back(tester);
      await tapText(tester, 'Thông tin cá nhân');
      await shot(tester, 'settings_personal-info');
      await back(tester);
      await tapText(tester, 'Đổi mật khẩu');
      await shot(tester, 'settings_change-password');
      await back(tester);
      await tapText(tester, 'Mẹo ghi âm');
      await shot(tester, 'recording-tips_from-settings');
    });
    await scene(tester, 'settings-error', () async {
      await launch(
        tester,
        scenario: Scenario.error,
        go: AppRoutes.tutorProfile,
      );
      await shot(tester, 'settings_error');
    });

    // ── 5 · Recorder entry sheet (T6/T7) ────────────────────────────────────
    for (final (label, s) in [
      ('picker', Scenario.loaded),
      ('no-pupils-no-lesson', Scenario.empty),
      ('one-lesson-no-pupils', Scenario.oneLesson),
      ('loading', Scenario.loading),
      ('error', Scenario.error),
    ]) {
      await scene(tester, 'entry-$label', () async {
        await launch(tester, scenario: s, go: AppRoutes.tutorRecordings);
        await tapText(tester, 'Ghi âm buổi học', index: 0);
        await shot(tester, 'recorder-entry_$label');
        if (label == 'picker') {
          await scrollDown(tester, -500);
          await shot(tester, 'recorder-entry_picker_scrolled');
        }
      });
    }

    // ── 6 · Add a pupil ─────────────────────────────────────────────────────
    await scene(tester, 'add-pupil', () async {
      await launch(
        tester,
        scenario: Scenario.empty,
        go: AppRoutes.tutorRecordings,
      );
      await tapText(tester, 'Ghi âm buổi học', index: 0);
      await tapText(tester, 'Thêm học sinh', index: 0);
      await shot(tester, 'add-pupil_form-empty');
      // Submit empty: validation message.
      await tapFinder(
        tester,
        find.widgetWithText(FilledButton, 'Thêm học sinh'),
        'submit',
      );
      await shot(tester, 'add-pupil_form-validation');
      await typeIntoLabeled(tester, 'Họ tên học sinh', 'Minh An');
      await typeIntoLabeled(tester, 'Môn (vd. Toán)', 'Toán');
      await tapFinder(
        tester,
        find.byType(DropdownButtonFormField<int>),
        'grade',
      );
      await shot(tester, 'add-pupil_grade-menu');
      await tapText(tester, 'Lớp 8', index: 0);
      await tapText(tester, 'Thêm buổi trong tuần');
      await shot(tester, 'add-pupil_schedule-sheet');
      await tapText(tester, 'T2');
      await shot(tester, 'add-pupil_schedule-sheet_day-picked');
      await tapText(tester, 'Thêm vào lịch');
      await shot(tester, 'add-pupil_form-with-schedule');
      await scrollDown(tester);
      await typeIntoLabeled(
        tester,
        'Tên phụ huynh (vd. Chị Hương)',
        'Mẹ của An',
      );
      await typeIntoLabeled(
        tester,
        'SĐT phụ huynh (có dùng Zalo)',
        '0900000001',
      );
      await shot(tester, 'add-pupil_form-parent');
      await tapText(tester, 'Xem nội dung đồng ý');
      await shot(tester, 'add-pupil_consent-dialog');
      await back(tester);
      await tapFinder(tester, find.byType(Checkbox), 'consent checkbox');
      await shot(tester, 'add-pupil_form-ready-to-save');
    });

    // ── 7 · Pupil profile and edit ──────────────────────────────────────────
    for (final (id, label) in [
      ('stu-minh-an', 'minh-an'),
      ('stu-bao', 'bao'),
    ]) {
      await scene(tester, 'pupil-$label', () async {
        await launch(tester, go: AppRoutes.tutorHome);
        unawaited(TutorStudentDetailScreen.open(navContext(tester), id));
        await settle(tester, 1000);
        await shot(tester, 'pupil-detail_$label');
        await scrollDown(tester);
        await shot(tester, 'pupil-detail_${label}_scrolled');
        if (label == 'minh-an') {
          await scrollDown(tester, 900);
          await tapText(tester, 'Sửa');
          await shot(tester, 'pupil-edit_form');
          await tapFinder(tester, find.byTooltip('Xoá học sinh'), 'delete');
          await shot(tester, 'pupil-edit_delete-confirm');
          await tapText(tester, 'Thôi');
        }
      });
    }

    // ── 8 · Recording (T10) and "recorded well" (T11) ───────────────────────
    await scene(tester, 'mic-disclosure', () async {
      await launch(tester, mic: false, go: AppRoutes.tutorHome);
      await pushRoute(tester, AppRoutes.tutorRecording, extra: _baoToday);
      await shot(tester, 'recording_mic-disclosure-dialog');
      await tapText(tester, 'Tiếp tục');
      await shot(tester, 'recording_after-permission');
    });
    await scene(tester, 'recording', () async {
      await launch(tester, go: AppRoutes.tutorHome);
      await pushRoute(tester, AppRoutes.tutorRecording, extra: _baoToday);
      await shot(tester, 'recording_just-started');
      // Loud, clear input: the "Âm thanh" row should read "Rõ" (until commit
      // 905cfcc the waveform update threw and it always said "Không nghe").
      await feedSound(tester, _clear);
      await shot(tester, 'recording_loud-input');
      await feedSound(tester, _quiet);
      await shot(tester, 'recording_quiet-input');
      env.recorder!.setError(
        'Chưa gửi xong bản ghi. Bản ghi vẫn nằm an toàn trên máy, bạn thử '
        'lại khi có mạng ổn định hơn.',
      );
      await settle(tester, 300);
      await shot(tester, 'recording_upload-error');
      env.recorder!.setError(null);
      await tapText(tester, 'Tạm dừng');
      await shot(tester, 'recording_paused');
      await tapText(tester, 'Tiếp tục');
      await tapText(tester, 'Huỷ bản ghi');
      await shot(tester, 'recording_discard-confirm');
      await tapText(tester, 'Tiếp tục ghi');
      // Finish at 86 min (of 90 booked): slide to end -> T11 -> draft.
      env.recorder!.setElapsed(const Duration(minutes: 86, seconds: 3));
      await settle(tester, 300);
      final knob = find.byIcon(Icons.arrow_forward_rounded);
      if (knob.evaluate().isEmpty) {
        throw StateError('slide-to-end knob missing');
      }
      final g = await tester.startGesture(tester.getCenter(knob.first));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await g.up();
      await settle(tester, 1200);
      await shot(tester, 'recorded-well_from-real-flow');
      await tapText(tester, 'Mở bản nháp');
      await shot(tester, 'report-review_after-recorded-well');
    });
    // T11 straight from its route (fixed numbers, in case the flow above
    // could not be driven).
    await scene(tester, 'recorded-well-direct', () async {
      for (final (label, quiet, rec) in [
        ('clear', 0.08, 86),
        ('quiet', 0.4, 41),
      ]) {
        await launch(tester, go: AppRoutes.tutorHome);
        await pushRoute(
          tester,
          AppRoutes.tutorRecordedWell,
          extra: RecordedWellArgs(
            review: const ReportReviewArgs(
              recordingId: 'rec-ready',
              studentName: 'Minh An',
              subtitle: 'Toán · Lớp 8',
            ),
            recordedMin: rec,
            bookedMin: 90,
            quietShare: quiet,
          ),
        );
        await shot(tester, 'recorded-well_direct_$label');
        if (label == 'quiet') {
          await tapText(tester, 'Xem mẹo');
          await shot(tester, 'recording-tips_from-recorded-well');
        }
      }
    });

    // ── 9 · Report review: ready, AI writing, failed, sent, error ──────────
    for (final (id, label) in [
      ('rec-ready', 'ready'),
      ('rec-ai', 'ai-writing'),
      ('rec-failed', 'ai-failed'),
      ('rec-sent', 'sent'),
      ('rec-error', 'load-error'),
    ]) {
      await scene(tester, 'review-$label', () async {
        await launch(tester, go: AppRoutes.tutorHome);
        await pushRoute(
          tester,
          AppRoutes.tutorReportReview,
          extra: ReportReviewArgs(
            recordingId: id,
            studentName: id == 'rec-ai' || id == 'rec-failed'
                ? 'Bao'
                : 'Minh An',
            subtitle: id == 'rec-ai' || id == 'rec-failed'
                ? 'Toán · Lớp 9'
                : 'Toán · Lớp 8',
          ),
        );
        await shot(tester, 'report-review_$label');
        if (label == 'ready') {
          await scrollDown(tester);
          await shot(tester, 'report-review_ready_scrolled');
          await scrollDown(tester);
          await shot(tester, 'report-review_ready_bottom');
          await tapText(tester, 'Xem trước tin gửi phụ huynh');
          await shot(tester, 'report-preview_zalo');
          await scrollDown(tester);
          await shot(tester, 'report-preview_zalo_scrolled');
          // The fake backend accepts the send; nothing leaves the process.
          await tapText(tester, 'Gửi cho phụ huynh');
          await shot(tester, 'report-preview_after-send');
        }
        if (label == 'ai-failed') {
          await tapText(tester, 'Tự viết báo cáo');
          await shot(tester, 'report-review_ai-failed_manual');
        }
      });
    }
    await scene(tester, 'review-ai-feedback', () async {
      await launch(tester, go: AppRoutes.tutorHome);
      await pushRoute(
        tester,
        AppRoutes.tutorReportReview,
        extra: const ReportReviewArgs(
          recordingId: 'rec-ready',
          studentName: 'Minh An',
          subtitle: 'Toán · Lớp 8',
        ),
      );
      await scrollDown(tester, -1600);
      await tapText(tester, 'Báo nội dung AI sai');
      await shot(tester, 'report-review_ai-feedback-sheet');
    });
    await scene(tester, 'review-from-lessons-tab', () async {
      await launch(tester, go: AppRoutes.tutorSchedule);
      await shot(tester, 'tab-lessons_needs-you');
      await tapText(tester, 'Duyệt báo cáo', contains: true);
      await shot(tester, 'report-review_from-lessons-tab');
    });

    // ── 10 · A recorded lesson: report tab / minutes tab ────────────────────
    for (final (id, label) in [
      ('rec-ready', 'awaiting-approval'),
      ('rec-sent', 'sent'),
      ('rec-ai', 'ai-writing'),
      ('rec-failed', 'ai-failed'),
      ('rec-error', 'load-error'),
    ]) {
      await scene(tester, 'detail-$label', () async {
        await launch(tester, go: AppRoutes.tutorHome);
        await pushRoute(
          tester,
          AppRoutes.tutorRecordingDetail,
          extra: RecordingDetailArgs(recordingId: id, studentName: 'Minh An'),
        );
        await shot(tester, 'lesson-detail_${label}_tab-report');
        if (label == 'awaiting-approval' || label == 'sent') {
          await scrollDown(tester);
          await shot(tester, 'lesson-detail_${label}_tab-report_scrolled');
          await scrollDown(tester, 900);
          await tapText(tester, 'Tóm tắt buổi');
          await shot(tester, 'lesson-detail_${label}_tab-minutes');
          await scrollDown(tester);
          await shot(tester, 'lesson-detail_${label}_tab-minutes_scrolled');
        }
        if (label == 'ai-failed' || label == 'ai-writing') {
          await tapText(tester, 'Tóm tắt buổi');
          await shot(tester, 'lesson-detail_${label}_tab-minutes');
        }
      });
    }
    await scene(tester, 'detail-from-recordings-tab', () async {
      await launch(tester, go: AppRoutes.tutorRecordings);
      await scrollDown(tester);
      await shot(tester, 'tab-recordings_recent');
      await tapText(tester, 'Minh An', index: 0);
      await shot(tester, 'pupil-or-lesson_from-recordings-tab');
    });

    // ── 11 · Before the lesson (Topi) ───────────────────────────────────────
    await scene(tester, 'before-lesson', () async {
      await launch(tester, go: AppRoutes.tutorHome);
      await pushRoute(
        tester,
        AppRoutes.tutorBeforeLesson,
        extra: BeforeLessonArgs(
          lessonId: 'rec-ready',
          studentName: 'Minh An',
          nextLessonAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await shot(tester, 'before-lesson_plan');
      await scrollDown(tester);
      await shot(tester, 'before-lesson_plan_scrolled');
      await scrollDown(tester);
      await shot(tester, 'before-lesson_plan_bottom');
    });
    await scene(tester, 'before-lesson-no-plan', () async {
      await launch(tester, go: AppRoutes.tutorHome);
      await pushRoute(
        tester,
        AppRoutes.tutorBeforeLesson,
        extra: const BeforeLessonArgs(lessonId: 'rec-ai', studentName: 'Bao'),
      );
      await shot(tester, 'before-lesson_no-plan-yet');
    });
    await scene(tester, 'before-lesson-error', () async {
      await launch(tester, scenario: Scenario.error, go: AppRoutes.tutorHome);
      await pushRoute(
        tester,
        AppRoutes.tutorBeforeLesson,
        extra: const BeforeLessonArgs(
          lessonId: 'rec-ready',
          studentName: 'Minh An',
        ),
      );
      await shot(tester, 'before-lesson_flag-off-or-error');
    });

    // ── 12 · Booking-platform classes (legacy side of the app) ─────────────
    await scene(tester, 'booking-classes', () async {
      await launch(tester, bookingClasses: 5, go: AppRoutes.tutorHome);
      await scrollDown(tester, -1500);
      await shot(tester, 'tab-home_with-booking-classes');
      await tapText(tester, 'Xem tất cả');
      await shot(tester, 'all-classes');
      await tapText(tester, 'Linh', index: 0);
      await shot(tester, 'class-detail_linh');
      await scrollDown(tester);
      await shot(tester, 'class-detail_linh_scrolled');
    });
    await scene(tester, 'booking-detail', () async {
      await launch(tester, bookingClasses: 5, go: AppRoutes.tutorHome);
      final lesson = TutorLessonDto.fromJson({
        'classSessionId': 1011,
        'bookingId': 101,
        'studentName': 'Linh',
        'subjectName': 'Tiếng Anh',
        'scheduledStart': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'scheduledEnd': DateTime.now()
            .add(const Duration(days: 1, hours: 1))
            .toUtc()
            .toIso8601String(),
        'status': 'scheduled',
      });
      unawaited(
        Navigator.of(navContext(tester)).push<void>(
          MaterialPageRoute(
            builder: (_) => TutorBookingDetailScreen(lesson: lesson),
          ),
        ),
      );
      await settle(tester, 1000);
      await shot(tester, 'booking-detail_scheduled');
      await back(tester);
      unawaited(TutorSessionDetailScreen.open(navContext(tester), lesson));
      await settle(tester, 1000);
      await shot(tester, 'session-detail_scheduled');
    });
    await scene(tester, 'agenda-offplatform-lesson', () async {
      await launch(tester, go: AppRoutes.tutorSchedule);
      await tapText(tester, 'Bao', index: 0);
      await shot(tester, 'agenda_tap-offplatform-lesson');
    });
    await scene(tester, 'agenda-booking-lesson', () async {
      await launch(tester, bookingClasses: 2, go: AppRoutes.tutorSchedule);
      await shot(tester, 'tab-lessons_with-booking-classes');
      await tapText(tester, 'Linh', index: 0);
      await shot(tester, 'agenda_tap-booking-lesson');
    });

    // ── Summary for the README / the caller ─────────────────────────────────
    binding.reportData = <String, dynamic>{
      // keep what the binding already holds (the screenshots)
      ...?binding.reportData,
      'shots': shots,
      'failures': failures,
      'uiErrors': uiErrors,
      'fakeRequests': env.backend.log.length,
    };
    print(
      'AS-BUILT: ${shots.length} screenshots, ${failures.length} failed '
      'scenes, ${uiErrors.length} UI errors',
    );
    for (final f in failures) {
      print('AS-BUILT FAILED SCENE: $f');
    }
    for (final e in uiErrors) {
      print('AS-BUILT UI ERROR: $e');
    }
  });
}
