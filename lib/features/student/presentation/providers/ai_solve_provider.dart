import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/ai_solve_datasource.dart';

enum ChatStatus { idle, loadingSession, sending, streaming, ready, error }

class SolveChatState {
  const SolveChatState({
    this.status = ChatStatus.idle,
    this.sessionId,
    this.messages = const [],
    this.error,
  });

  final ChatStatus status;
  final String? sessionId;
  final List<AiChatMessage> messages;
  final String? error;

  bool get isBusy =>
      status == ChatStatus.sending || status == ChatStatus.streaming;

  /// Cho phép nhập/gửi khi không bận và đã có phiên.
  bool get canSend => !isBusy && sessionId != null;

  SolveChatState copyWith({
    ChatStatus? status,
    String? sessionId,
    List<AiChatMessage>? messages,
    String? error,
  }) => SolveChatState(
    status: status ?? this.status,
    sessionId: sessionId ?? this.sessionId,
    messages: messages ?? this.messages,
    error: error,
  );
}

class SolveChatNotifier extends StateNotifier<SolveChatState> {
  SolveChatNotifier(this._ds) : super(const SolveChatState());

  final AiSolveDatasource _ds;
  StreamSubscription<SolveDelta>? _sub;
  int _tmpCounter = 0;

  /// Bắt đầu phiên mới từ ảnh đề bài (camera/thư viện). Tạo session -> gửi ảnh.
  Future<void> startWithImage(String imageBase64, {String? grade}) async {
    state = const SolveChatState(status: ChatStatus.loadingSession);
    try {
      final session = await _ds.createSession();
      state = state.copyWith(
        status: ChatStatus.idle,
        sessionId: session.sessionId,
      );
      await _send(
        imageBase64: imageBase64,
        imageBytes: base64Decode(imageBase64),
        grade: grade,
        displayText: null,
      );
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, error: e.toString());
    }
  }

  /// Bắt đầu phiên mới từ đề bài gõ tay.
  Future<void> startWithText(String text, {String? grade}) async {
    state = const SolveChatState(status: ChatStatus.loadingSession);
    try {
      final session = await _ds.createSession();
      state = state.copyWith(
        status: ChatStatus.idle,
        sessionId: session.sessionId,
      );
      await _send(text: text, grade: grade, displayText: text);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, error: e.toString());
    }
  }

  /// Mở lại phiên cũ từ màn lịch sử — nạp toàn bộ tin nhắn.
  Future<void> openSession(String sessionId) async {
    state = SolveChatState(
      status: ChatStatus.loadingSession,
      sessionId: sessionId,
    );
    try {
      final msgs = await _ds.getMessages(sessionId);
      state = state.copyWith(status: ChatStatus.ready, messages: msgs);
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, error: e.toString());
    }
  }

  /// Gửi câu hỏi follow-up (gõ tay hoặc quick-action). BE tự nạp history.
  Future<void> sendFollowUp(String text) async {
    if (!state.canSend || text.trim().isEmpty) return;
    await _send(text: text.trim(), displayText: text.trim());
  }

  Future<void> _send({
    required String? displayText,
    String? text,
    String? imageBase64,
    Uint8List? imageBytes,
    String? grade,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    await _sub?.cancel();

    // 1. Optimistic: thêm bubble user (text hoặc ảnh vừa chụp) + bubble AI rỗng.
    final userMsg = (displayText == null && imageBytes == null)
        ? null
        : AiChatMessage(
            messageId: 'tmp-u-${_tmpCounter++}',
            role: ChatRole.user,
            content: displayText ?? '',
            localImage: imageBytes,
          );
    final aiMsg = AiChatMessage(
      messageId: 'tmp-a-${_tmpCounter++}',
      role: ChatRole.assistant,
      content: '',
      isStreaming: true,
    );

    state = state.copyWith(
      status: ChatStatus.streaming,
      messages: [
        ...state.messages,
        ?userMsg,
        aiMsg,
      ],
    );

    // 2. Stream lời giải, cập nhật bubble AI cuối cùng theo từng delta.
    var buffer = '';
    try {
      final stream = await _ds.solveStream(
        sessionId: sessionId,
        text: text,
        imageBase64: imageBase64,
        grade: grade,
      );
      _sub = stream.listen(
        (chunk) {
          buffer += chunk.delta;
          _updateLastAssistant(buffer, streaming: !chunk.done);
        },
        onDone: () {
          _updateLastAssistant(buffer, streaming: false);
          state = state.copyWith(status: ChatStatus.ready);
        },
        onError: (Object e) {
          _updateLastAssistant(
            buffer.isEmpty
                ? 'Xin lỗi, có lỗi khi tải lời giải. Bạn thử lại nhé!'
                : buffer,
            streaming: false,
          );
          state = state.copyWith(status: ChatStatus.ready);
        },
      );
    } catch (e) {
      _updateLastAssistant(
        'Xin lỗi, không kết nối được máy chủ. Bạn thử lại nhé!',
        streaming: false,
      );
      state = state.copyWith(status: ChatStatus.error, error: e.toString());
    }
  }

  void _updateLastAssistant(String content, {required bool streaming}) {
    final msgs = [...state.messages];
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].role == ChatRole.assistant) {
        msgs[i] = msgs[i].copyWith(content: content, isStreaming: streaming);
        break;
      }
    }
    state = state.copyWith(messages: msgs);
  }

  void reset() {
    unawaited(_sub?.cancel());
    state = const SolveChatState();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

final AutoDisposeStateNotifierProvider<SolveChatNotifier, SolveChatState>
solveChatProvider =
    StateNotifierProvider.autoDispose<SolveChatNotifier, SolveChatState>(
      (ref) => SolveChatNotifier(ref.watch(aiSolveDatasourceProvider)),
    );

// Danh sách phiên lịch sử (màn history).
final AutoDisposeFutureProvider<List<AiChatSession>> solveHistoryProvider =
    FutureProvider.autoDispose<List<AiChatSession>>(
      (ref) => ref.watch(aiSolveDatasourceProvider).getSessions(),
    );
