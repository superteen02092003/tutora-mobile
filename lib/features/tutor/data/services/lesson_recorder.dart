// `lessonRecorderCallback` là entry-point của foreground service nên analyzer
// coi file là "executable library" và báo nhầm unreachable_from_main.
// ignore_for_file: unreachable_from_main

import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Giữ cho tiến trình ghi âm sống khi app xuống nền. Không làm gì theo chu kỳ —
/// việc ghi nằm ở tiến trình chính; service chỉ tồn tại để Android không giết
/// app giữa buổi dạy, và để thông báo "đang ghi" luôn hiện.
@pragma('vm:entry-point')
void lessonRecorderCallback() {
  FlutterForegroundTask.setTaskHandler(_LessonRecorderTaskHandler());
}

class _LessonRecorderTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Một đoạn ghi đã đóng lại và sẵn sàng upload.
class RecordedSegment {
  const RecordedSegment({
    required this.index,
    required this.path,
    required this.bytes,
  });

  final int index;
  final String path;
  final int bytes;
}

enum RecorderFailure {
  /// Gia sư từ chối quyền micro.
  permissionDenied,

  /// Máy ghi âm của hệ điều hành không khởi động được.
  engineFailed,
}

class RecorderException implements Exception {
  const RecorderException(this.reason, [this.detail]);

  final RecorderFailure reason;
  final String? detail;

  String get message => switch (reason) {
    RecorderFailure.permissionDenied =>
      'Chưa có quyền dùng micro nên không ghi âm được buổi học.',
    RecorderFailure.engineFailed =>
      'Không khởi động được máy ghi âm của thiết bị.',
  };

  @override
  String toString() => detail == null ? message : '$message ($detail)';
}

/// Ghi âm buổi dạy ra các đoạn 5 phút liên tiếp.
///
/// Vì sao cắt đoạn thay vì một file dài:
///   • Mỗi đoạn đóng lại là upload được ngay trong lúc buổi học còn đang diễn
///     ra, nên lúc gia sư bấm kết thúc chỉ còn đoạn cuối phải chờ.
///   • App bị hệ điều hành giết giữa chừng thì chỉ mất đoạn đang dở, không mất
///     cả buổi.
///   • Bên server chép lời theo từng đoạn, không bao giờ chạm trần output token
///     của model như khi đưa nguyên buổi 90 phút.
///
/// Đánh đổi đã biết: giữa hai đoạn có một khe hở cỡ vài chục mili-giây do phải
/// đóng file này rồi mở file kia. Với bản ghi để tóm tắt nội dung buổi học thì
/// mất một âm tiết mỗi 5 phút là chấp nhận được; nếu sau này cần bản ghi liền
/// mạch tuyệt đối thì phải chuyển sang `startStream` và tự ghép file.
class LessonRecorder {
  LessonRecorder({Duration? segmentLength})
    : _segmentLength = segmentLength ?? const Duration(minutes: 5);

  static const _config = RecordConfig(
    // AAC-LC 32 kbps mono 16 kHz: đủ rõ cho lời nói, và buổi 90 phút chỉ ~22 MB
    // nên upload qua 4G không thành vấn đề. Model cũng hạ về 16 kHz nên lấy mẫu
    // cao hơn chỉ tốn dung lượng chứ không thêm thông tin.
    bitRate: 32000,
    numChannels: 1,
    sampleRate: 16000,
  );

  final Duration _segmentLength;
  final AudioRecorder _recorder = AudioRecorder();
  final List<RecordedSegment> _segments = [];

  final _segmentController = StreamController<RecordedSegment>.broadcast();

  Timer? _rotateTimer;
  Directory? _dir;
  int _nextIndex = 0;
  String? _currentPath;
  bool _paused = false;
  bool _running = false;

  /// Phát ra mỗi khi một đoạn đóng lại — tầng upload nghe stream này để đẩy
  /// từng đoạn đi ngay, không đợi hết buổi.
  Stream<RecordedSegment> get onSegmentClosed => _segmentController.stream;

  List<RecordedSegment> get segments => List.unmodifiable(_segments);
  bool get isRunning => _running;
  bool get isPaused => _paused;

  /// Biên độ âm thanh để vẽ sóng — trả null khi không ghi.
  Stream<Amplitude> amplitudeStream() =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 200));

  /// Thư mục chứa các đoạn của một buổi. Đặt theo recordingId (server cấp)
  /// để lần mở app sau còn tìm lại được bản ghi dở nếu app bị giết giữa buổi.
  static Future<Directory> segmentDir(String key) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/lesson_recordings/$key');
  }

  /// Các đoạn còn sót lại của một buổi — dùng để hỏi gia sư "kết thúc buổi cũ?"
  static Future<List<RecordedSegment>> recoverSegments(String key) async {
    final dir = await segmentDir(key);
    if (!dir.existsSync()) return const [];

    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.m4a'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    return [
      for (var i = 0; i < files.length; i++)
        RecordedSegment(
          index: i,
          path: files[i].path,
          bytes: files[i].lengthSync(),
        ),
    ];
  }

  /// Đã có quyền micro chưa — KHÔNG hiện hộp thoại xin quyền của hệ thống.
  /// Dùng để hiện màn giải thích trước khi xin quyền (yêu cầu của Google Play).
  Future<bool> hasMicPermission() => _recorder.hasPermission(request: false);

  Future<void> start(String key) async {
    if (_running) return;

    if (!await _recorder.hasPermission()) {
      throw const RecorderException(RecorderFailure.permissionDenied);
    }

    final dir = await segmentDir(key);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    _nextIndex = 0;
    _segments.clear();

    await _startForegroundService();

    try {
      await _openSegment();
    } on Exception catch (e) {
      await _stopForegroundService();
      throw RecorderException(RecorderFailure.engineFailed, e.toString());
    }

    _running = true;
    _paused = false;
    _scheduleRotation();
  }

  Future<void> pause() async {
    if (!_running || _paused) return;
    _rotateTimer?.cancel();
    await _recorder.pause();
    _paused = true;
  }

  Future<void> resume() async {
    if (!_running || !_paused) return;
    await _recorder.resume();
    _paused = false;
    _scheduleRotation();
  }

  /// Kết thúc buổi: đóng đoạn đang ghi và trả về toàn bộ đoạn theo thứ tự.
  Future<List<RecordedSegment>> stop() async {
    if (!_running) return segments;

    _rotateTimer?.cancel();
    _rotateTimer = null;
    await _closeSegment();
    await _stopForegroundService();

    _running = false;
    _paused = false;
    return segments;
  }

  /// Huỷ hẳn: dừng ghi và xoá mọi đoạn đã tạo. Dùng khi gia sư bấm huỷ, không
  /// dùng cho lỗi — lỗi thì giữ file lại để còn cứu.
  Future<void> discard() async {
    _rotateTimer?.cancel();
    _rotateTimer = null;
    if (_running) {
      await _recorder.cancel();
      await _stopForegroundService();
    }
    _running = false;
    _paused = false;
    _segments.clear();
    final dir = _dir;
    if (dir != null && dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  Future<void> dispose() async {
    _rotateTimer?.cancel();
    await _segmentController.close();
    await _recorder.dispose();
  }

  // ── nội bộ ────────────────────────────────────────────────────────────────

  void _scheduleRotation() {
    _rotateTimer?.cancel();
    _rotateTimer = Timer(_segmentLength, _rotate);
  }

  Future<void> _rotate() async {
    if (!_running || _paused) return;
    await _closeSegment();
    await _openSegment();
    _scheduleRotation();
  }

  Future<void> _openSegment() async {
    final dir = _dir!;
    // Số thứ tự đệm 0 để sort theo tên file ra đúng thứ tự thời gian.
    final name = 'part-${_nextIndex.toString().padLeft(4, '0')}.m4a';
    final path = '${dir.path}/$name';
    await _recorder.start(_config, path: path);
    _currentPath = path;
    _nextIndex++;
  }

  Future<void> _closeSegment() async {
    final path = await _recorder.stop() ?? _currentPath;
    _currentPath = null;
    if (path == null) return;

    final file = File(path);
    if (!file.existsSync()) return;

    final segment = RecordedSegment(
      index: _segments.length,
      path: path,
      bytes: file.lengthSync(),
    );
    _segments.add(segment);
    if (!_segmentController.isClosed) _segmentController.add(segment);
  }

  Future<void> _startForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tutora_lesson_recording',
        channelName: 'Ghi âm buổi học',
        channelDescription:
            'Hiện trong lúc Tutora đang ghi âm buổi dạy của bạn.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
      ),
    );

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      // Thông báo này vừa là yêu cầu kỹ thuật của foreground service, vừa là
      // chỉ báo bắt buộc theo chính sách cửa hàng: người trong phòng phải nhìn
      // thấy được là máy đang ghi.
      notificationTitle: 'Tutora đang ghi âm buổi học',
      notificationText: 'Chạm để quay lại app',
      callback: lessonRecorderCallback,
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
