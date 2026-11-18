// The base class names its constructor parameter `_api`; a private name cannot be forwarded.
// ignore_for_file: matching_super_parameters
// Test tooling, not app code: console output and terse helpers are intended.
// As-built screenshots: test doubles for the parts of the app that touch the
// device (secure storage, microphone) rather than the network.
import 'dart:convert';

import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/presentation/providers/lesson_recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';

String _b64(Map<String, Object?> m) =>
    base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');

/// A made-up, unsigned token that only says "tutor, not expired". It is built
/// at run time, never stored in the repo, and never sent anywhere: the fake
/// backend ignores it.
String fakeTutorToken() {
  final exp =
      DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
      1000;
  return [
    _b64({'alg': 'none', 'typ': 'JWT'}),
    _b64({
      'userId': '00000000-0000-0000-0000-00000000ha01',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Tutor',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name': 'Ha',
      'email': 'ha@example.com',
      'exp': exp,
    }),
    'x',
  ].join('.');
}

/// In-memory replacement for the Android keystore storage. The real tokens
/// of whoever is logged in on the phone are never read or written.
class FakeStorage extends SecureStorageService {
  String? access = fakeTutorToken();
  bool welcomeSeen = true;

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => access == null ? null : 'x';

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async => this.access = access;

  @override
  Future<void> clearTokens() async => access = null;

  @override
  Future<String?> getLiveSessionDeviceId() async => null;

  @override
  Future<void> saveLiveSessionDeviceId(String value) async {}

  @override
  Future<bool> getWelcomeSeen() async => welcomeSeen;

  @override
  Future<void> setWelcomeSeen() async => welcomeSeen = true;
}

/// Stand-in for the recorder: no microphone, no foreground service, no upload.
/// The test sets [state] to whatever the screenshot needs.
class FakeRecordingNotifier extends LessonRecordingNotifier {
  FakeRecordingNotifier(super.api);

  /// false = the microphone-permission disclosure dialog shows first.
  bool micPermission = true;

  @override
  Future<bool> hasMicPermission() async => micPermission;

  @override
  Future<void> start({
    required int lessonId,
    required String studentName,
    RecordingTarget? target,
  }) async {
    this.target = target;
    state = LessonRecordingState(
      lessonId: lessonId,
      studentName: studentName,
      recordingId: 'rec-new',
      isRecording: true,
      elapsed: const Duration(minutes: 47, seconds: 12),
      uploadedParts: 9,
    );
  }

  /// Sound level 0..1 as the microphone would report it.
  void setLevel(double level) => state = state.copyWith(level: level);

  void setElapsed(Duration d) => state = state.copyWith(elapsed: d);

  /// null clears the error line.
  void setError(String? message) => state = message == null
      ? state.copyWith(clearError: true)
      : state.copyWith(error: message);

  @override
  Future<void> togglePause() async {
    // The real notifier also resets the level to 0 on pause. That would reach
    // the screen's level listener, which throws as built (README: "Bugs
    // found") outside any zone this test can guard - so the level is kept.
    state = state.copyWith(isPaused: !state.isPaused);
  }

  @override
  Future<AppRecordingStatusDto?> finish() async {
    state = state.copyWith(isRecording: false, isFinishing: false);
    return const AppRecordingStatusDto(
      recordingId: 'rec-ready',
      status: 'processing',
      aiStatus: 'processing',
    );
  }

  @override
  Future<void> discard() async {
    state = const LessonRecordingState();
  }
}

/// Convenience for the test: build the notifier from the fake Dio's datasource.
FakeRecordingNotifier fakeRecorder(AppRecordingDatasource api) =>
    FakeRecordingNotifier(api);
