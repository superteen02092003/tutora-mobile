import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart' show Amplitude;
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/models/app_recording_models.dart';
import 'package:tutora/features/tutor/data/services/lesson_recorder.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_recorder/recording_target.dart';

/// Trạng thái một lượt ghi âm buổi học.
class LessonRecordingState {
  const LessonRecordingState({
    this.lessonId,
    this.recordingId,
    this.studentName = '',
    this.uploadedParts = 0,
    this.uploadFailed = false,
    this.isRecording = false,
    this.isPaused = false,
    this.isFinishing = false,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.segments = const [],
    this.error,
  });

  final int? lessonId;

  /// Do server cấp lúc bấm ghi. App chỉ cầm id này — không bao giờ cầm tên
  /// phụ huynh, nên không thể gửi nhầm người.
  final String? recordingId;

  final String studentName;

  /// Số đoạn đã nằm an toàn trên kho.
  final int uploadedParts;

  /// Có đoạn nào upload hỏng và đang chờ thử lại.
  final bool uploadFailed;
  final bool isRecording;
  final bool isPaused;

  /// Đang đóng đoạn cuối — chặn bấm hai lần vào nút kết thúc.
  final bool isFinishing;

  final Duration elapsed;

  /// Biên độ đã chuẩn hoá 0..1 để vẽ sóng.
  final double level;

  final List<RecordedSegment> segments;
  final String? error;

  bool get isActive => isRecording && !isFinishing;

  int get totalBytes => segments.fold<int>(0, (sum, s) => sum + s.bytes);

  LessonRecordingState copyWith({
    int? lessonId,
    String? recordingId,
    String? studentName,
    int? uploadedParts,
    bool? uploadFailed,
    bool? isRecording,
    bool? isPaused,
    bool? isFinishing,
    Duration? elapsed,
    double? level,
    List<RecordedSegment>? segments,
    String? error,
    bool clearError = false,
  }) => LessonRecordingState(
    lessonId: lessonId ?? this.lessonId,
    recordingId: recordingId ?? this.recordingId,
    studentName: studentName ?? this.studentName,
    uploadedParts: uploadedParts ?? this.uploadedParts,
    uploadFailed: uploadFailed ?? this.uploadFailed,
    isRecording: isRecording ?? this.isRecording,
    isPaused: isPaused ?? this.isPaused,
    isFinishing: isFinishing ?? this.isFinishing,
    elapsed: elapsed ?? this.elapsed,
    level: level ?? this.level,
    segments: segments ?? this.segments,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Điều khiển máy ghi âm và giữ trạng thái cho màn "đang ghi".
///
/// Sống ở tầng provider chứ không trong State của màn hình, để bản ghi không
/// chết khi gia sư rời màn hình — họ sẽ rời thật, để tra bài hoặc xem lịch
/// giữa buổi.
class LessonRecordingNotifier extends StateNotifier<LessonRecordingState> {
  LessonRecordingNotifier(this._api) : super(const LessonRecordingState()) {
    unawaited(_sweepLocalRecordings());
  }

  final AppRecordingDatasource _api;

  /// Dọn thư mục bản ghi còn sót trên máy — từ bản app cũ chưa xoá sau khi
  /// upload, hoặc từ lượt ghi bị gián đoạn. Lỗi nào cũng bỏ qua: lần mở app
  /// sau thử lại.
  Future<void> _sweepLocalRecordings() async {
    try {
      final now = DateTime.now();
      for (final r in await LessonRecorder.localRecordings()) {
        if (r.key == state.recordingId) continue;
        String? status;
        var notFound = false;
        try {
          status = (await _api.status(r.key)).status;
        } on DioException catch (e) {
          notFound = e.response?.statusCode == 404;
        } on Object {
          // mất mạng / chưa đăng nhập: status để null
        }
        if (r.key == state.recordingId) continue;
        if (shouldDeleteLocalRecording(
          age: now.difference(r.modified),
          serverStatus: status,
          notFound: notFound,
        )) {
          await LessonRecorder.deleteSegments(r.key);
        }
      }
    } on Object catch (e) {
      debugPrint('[recorder] sweep local recordings failed: $e');
    }
  }

  /// Bản debug cắt đoạn 30 giây thay vì 5 phút: test 2–3 phút là đã có vài đoạn,
  /// đủ để đi qua bước ghép ffmpeg trên server. Bản release luôn là 5 phút.
  /// Đã có quyền micro chưa (không hiện hộp thoại xin quyền).
  Future<bool> hasMicPermission() => _recorder.hasMicPermission();

  final LessonRecorder _recorder = LessonRecorder(
    segmentLength: kDebugMode ? const Duration(seconds: 30) : null,
  );

  /// Hàng đợi upload chạy tuần tự. Song song không nhanh hơn trên 4G yếu, chỉ
  /// làm các đoạn tranh nhau băng thông và cùng timeout một lượt.
  Future<void> _uploadChain = Future<void>.value();

  /// Đoạn đầu tiên của lượt này được đánh số từ đây — khác 0 khi mở lại bản ghi
  /// còn dở, để không ghi đè các đoạn đã lên kho.
  int _partOffset = 0;

  /// Chỉ số (trong lượt ghi này) của các đoạn ĐÃ nằm trên kho.
  ///
  /// Phải là một tập, không được là một con số đếm: nếu đoạn 2 hỏng mà đoạn 3
  /// thành công thì bộ đếm lên 3, và mọi logic kiểu "bỏ qua đoạn có số nhỏ hơn
  /// bộ đếm" sẽ coi đoạn 2 là xong — buổi học lên server thiếu mất 5 phút ở
  /// giữa, AI tóm tắt thiếu, và không có lỗi nào hiện ra cho ai thấy.
  final Set<int> _uploaded = <int>{};

  Timer? _ticker;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<RecordedSegment>? _segmentSub;

  /// Buổi đang ghi — để nút mic ở thanh tab mở lại đúng màn "Đang ghi" khi
  /// gia sư đã thu nhỏ màn đó về trang chủ.
  RecordingTarget? target;

  Future<void> start({
    required int lessonId,
    required String studentName,
    RecordingTarget? target,
  }) async {
    if (state.isRecording) return;
    this.target = target;

    state = LessonRecordingState(lessonId: lessonId, studentName: studentName);

    // Mở bản ghi ở server TRƯỚC khi bật micro. Nếu buổi này không phải của gia
    // sư đang đăng nhập, hoặc kho lưu trữ chưa cấu hình, thì hỏng ngay lúc chưa
    // ghi gì — tốt hơn là phát hiện sau 90 phút và không có chỗ nào để gửi lên.
    AppRecordingStartDto opened;
    try {
      final t = target;
      if (t?.recorderLessonId != null) {
        opened = await _api.startLesson(t!.recorderLessonId!);
      } else if (t?.studentId != null) {
        opened = await _api.startStudent(t!.studentId!);
      } else {
        opened = await _api.start(lessonId);
      }
    } on Object catch (e) {
      state = state.copyWith(
        error: 'Không mở được bản ghi cho buổi học này: ${_serverMessage(e)}',
      );
      return;
    }

    _partOffset = opened.uploadedParts;
    _uploaded.clear();

    try {
      // Thư mục đoạn theo recordingId do server cấp — duy nhất cho mỗi buổi,
      // kể cả buổi ngoài nền tảng (không có lessonId số).
      await _recorder.start(opened.recordingId);
    } on RecorderException catch (e) {
      state = state.copyWith(error: e.message);
      return;
    }

    _segmentSub = _recorder.onSegmentClosed.listen((segment) {
      state = state.copyWith(segments: _recorder.segments);
      _enqueueUpload(segment);
    });

    _amplitudeSub = _recorder.amplitudeStream().listen((amp) {
      if (!state.isActive || state.isPaused) return;
      state = state.copyWith(level: _normalise(amp.current));
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPaused) return;
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
    });

    state = state.copyWith(
      isRecording: true,
      recordingId: opened.recordingId,
      uploadedParts: opened.uploadedParts,
      clearError: true,
    );
  }

  /// Nối một đoạn vào cuối hàng đợi upload. Lỗi không ném ra ngoài: đoạn vẫn
  /// nằm trên máy, `finish()` sẽ thử lại lượt cuối trước khi chốt.
  void _enqueueUpload(RecordedSegment segment) {
    final recordingId = state.recordingId;
    if (recordingId == null) return;

    _uploadChain = _uploadChain.then((_) async {
      if (_uploaded.contains(segment.index)) return;
      try {
        await _uploadSegment(recordingId, segment);
        _uploaded.add(segment.index);
        state = state.copyWith(
          uploadedParts: _partOffset + _uploaded.length,
          uploadFailed: false,
        );
      } on Object catch (e) {
        _logUploadError('part ${segment.index}', e);
        state = state.copyWith(uploadFailed: true);
      }
    });
  }

  Future<void> _uploadSegment(
    String recordingId,
    RecordedSegment segment,
  ) async {
    final partNumber = _partOffset + segment.index;
    final slot = await _api.uploadUrl(recordingId, partNumber);
    await _api.uploadPart(slot.url, File(segment.path));
  }

  /// Lấy câu backend trả về (`message` trong APIResponse) thay vì in nguyên
  /// DioException dài 10 dòng mà không nói nguyên nhân.
  static String _serverMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      final msg = data is Map ? (data['message'] ?? data['Message']) : null;
      final code = e.response?.statusCode;
      debugPrint(
        '[recorder] ${e.requestOptions.method} ${e.requestOptions.path} '
        '→ ${code ?? e.type.name}: $data',
      );
      if (msg is String && msg.trim().isNotEmpty) return msg;
      if (code == null) return 'không kết nối được máy chủ.';
      return 'lỗi máy chủ ($code).';
    }
    return e.toString();
  }

  /// Ghi rõ lý do upload hỏng (bước nào, mã HTTP, body S3) ra log debug.
  /// Trước đây lỗi bị nuốt, gia sư chỉ thấy câu chung chung.
  String _logUploadError(String what, Object e) {
    String why;
    if (e is DioException) {
      final res = e.response;
      final url = e.requestOptions.uri;
      final step = url.path.contains('/upload-url')
          ? 'upload-url'
          : 'PUT ${url.host}';
      final body = res?.data?.toString() ?? '';
      why =
          '$step · ${res?.statusCode ?? e.type.name} · '
          '${body.length > 300 ? body.substring(0, 300) : body}'
          '${res == null ? ' · ${e.message}' : ''}';
    } else {
      why = e.toString();
    }
    debugPrint('[recorder] upload $what failed: $why');
    return why;
  }

  Future<void> togglePause() async {
    if (!state.isActive) return;
    if (state.isPaused) {
      await _recorder.resume();
      state = state.copyWith(isPaused: false);
    } else {
      await _recorder.pause();
      state = state.copyWith(isPaused: true, level: 0);
    }
  }

  /// Kết thúc buổi — trả về các đoạn đã ghi để tầng upload xử lý.
  Future<AppRecordingStatusDto?> finish() async {
    if (!state.isRecording) return null;

    state = state.copyWith(isFinishing: true);
    final segments = await _recorder.stop();
    await _teardown();
    state = state.copyWith(segments: segments);

    final recordingId = state.recordingId;
    if (recordingId == null) {
      state = state.copyWith(isRecording: false, isFinishing: false, level: 0);
      return null;
    }

    // Chờ hàng đợi xả hết trước: nếu quét ngay thì một đoạn đang upload dở
    // sẽ bị đẩy lên lần thứ hai song song với chính nó.
    await _uploadChain;

    // Đoạn cuối vừa đóng, và mọi đoạn trước đó từng upload hỏng, được đẩy lại
    // ở đây. Quét theo tập các đoạn ĐÃ lên chứ không theo bộ đếm — xem
    // [_uploaded].
    for (final segment in segments) {
      if (_uploaded.contains(segment.index)) continue;
      try {
        await _uploadSegment(recordingId, segment);
        _uploaded.add(segment.index);
        state = state.copyWith(uploadedParts: _partOffset + _uploaded.length);
      } on Object catch (e) {
        final why = _logUploadError('part ${segment.index} (finish)', e);
        state = state.copyWith(
          isFinishing: false,
          uploadFailed: true,
          error:
              'Chưa gửi xong bản ghi. Bản ghi vẫn nằm an toàn trên máy, '
              'bạn thử lại khi có mạng ổn định hơn.'
              '${kDebugMode ? '\n[debug] $why' : ''}',
        );
        return null;
      }
    }

    try {
      final status = await _api.complete(recordingId, state.elapsed.inSeconds);
      // Server đã nhận đủ các đoạn → xoá bản trên máy (xem
      // LessonRecorder.deleteSegments). Xoá hỏng thì lần mở app sau dọn tiếp.
      try {
        await LessonRecorder.deleteSegments(recordingId);
      } on Object catch (e) {
        debugPrint('[recorder] delete local segments failed: $e');
      }
      state = state.copyWith(
        segments: const [],
        isRecording: false,
        isFinishing: false,
        isPaused: false,
        level: 0,
        uploadFailed: false,
        clearError: true,
      );
      return status;
    } on Object catch (e) {
      state = state.copyWith(
        isFinishing: false,
        error:
            'Đã tải bản ghi lên nhưng chưa chốt được buổi học: ${_serverMessage(e)}',
      );
      return null;
    }
  }

  /// Bỏ hẳn bản ghi và xoá file. Không dùng cho lỗi — lỗi thì giữ file để cứu.
  Future<void> discard() async {
    final recordingId = state.recordingId;
    await _recorder.discard();
    await _teardown();

    // Báo server để unique index nhường chỗ cho lần ghi mới của cùng buổi.
    // Hỏng ở bước này không chặn gia sư: bản ghi trên máy đã xoá, và lần start
    // sau sẽ mở lại đúng bản ghi cũ chứ không tạo bản trùng.
    if (recordingId != null) {
      try {
        await _api.discard(recordingId);
      } on Object {
        // bỏ qua có chủ đích
      }
    }
    state = const LessonRecordingState();
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _segmentSub?.cancel();
    _segmentSub = null;
  }

  /// dBFS (âm, ~-60..0) → 0..1 để vẽ. Dưới -50 dB coi như im lặng.
  static double _normalise(double dbfs) {
    const floor = -50.0;
    if (dbfs <= floor) return 0;
    if (dbfs >= 0) return 1;
    return (dbfs - floor) / -floor;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_amplitudeSub?.cancel());
    unawaited(_segmentSub?.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }
}

final lessonRecordingProvider =
    StateNotifierProvider<LessonRecordingNotifier, LessonRecordingState>(
      (ref) =>
          LessonRecordingNotifier(ref.read(appRecordingDatasourceProvider)),
    );
