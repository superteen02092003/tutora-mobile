import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/ai_solve_datasource.dart';
import 'package:uuid/uuid.dart';

// State
enum SolveStatus { idle, loading, streaming, done, error }

class SolveState {
  const SolveState({
    this.status = SolveStatus.idle,
    this.rawText = '',
    this.steps = const [],
    this.finalAnswer = '',
    this.error,
    this.chatId,
  });

  final SolveStatus status;
  final String rawText;
  final List<SolveStep> steps;
  final String finalAnswer;
  final String? error;
  final String? chatId;

  bool get isLoading => status == SolveStatus.loading;
  bool get isStreaming => status == SolveStatus.streaming;
  bool get isDone => status == SolveStatus.done;

  SolveState copyWith({
    SolveStatus? status,
    String? rawText,
    List<SolveStep>? steps,
    String? finalAnswer,
    String? error,
    String? chatId,
  }) => SolveState(
    status: status ?? this.status,
    rawText: rawText ?? this.rawText,
    steps: steps ?? this.steps,
    finalAnswer: finalAnswer ?? this.finalAnswer,
    error: error ?? this.error,
    chatId: chatId ?? this.chatId,
  );
}

class SolveStep {
  const SolveStep({required this.title, required this.content});
  final String title;
  final String content;
}

class _StreamParser {
  final _stepRe = RegExp(r'\*\*Bước\s+\d+\s*[:\-–]\s*(.+?)\*\*');
  final _answerRe = RegExp(r'\*\*Kết quả là:\*\*\s*(.+)$', multiLine: true);

  List<SolveStep> parseSteps(String text) {
    final steps = <SolveStep>[];
    final matches = _stepRe.allMatches(text).toList();

    for (var i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)?.trim() ?? '';
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      var content = text.substring(start, end).trim();

      final answerMatch = _answerRe.firstMatch(content);
      if (answerMatch != null) {
        content = content.substring(0, answerMatch.start).trim();
      }
      if (title.isNotEmpty) {
        steps.add(SolveStep(title: title, content: content));
      }
    }
    return steps;
  }

  String parseFinalAnswer(String text) {
    final match = _answerRe.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }
}

// Notifier
class AiSolveNotifier extends StateNotifier<SolveState> {
  AiSolveNotifier(this._datasource) : super(const SolveState());

  final AiSolveDatasource _datasource;
  final _parser = _StreamParser();
  final _uuid = const Uuid();
  StreamSubscription<String>? _sub;

  Future<void> solve(String imageBase64) async {
    await _sub?.cancel();

    final chatId = _uuid.v4();
    final messageId = _uuid.v4();

    state = SolveState(status: SolveStatus.loading, chatId: chatId);

    try {
      final stream = await _datasource.solveStream(
        chatId: chatId,
        messageId: messageId,
        imageBase64: imageBase64,
      );

      var buffer = '';

      _sub = stream.listen(
        (delta) {
          buffer += delta;
          state = state.copyWith(
            status: SolveStatus.streaming,
            rawText: buffer,
            steps: _parser.parseSteps(buffer),
            finalAnswer: _parser.parseFinalAnswer(buffer),
          );
        },
        onDone: () {
          state = state.copyWith(
            status: SolveStatus.done,
            steps: _parser.parseSteps(buffer),
            finalAnswer: _parser.parseFinalAnswer(buffer),
          );
        },
        onError: (Object e) {
          state = state.copyWith(
            status: SolveStatus.error,
            error: e.toString(),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: SolveStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    unawaited(_sub?.cancel() ?? Future.value());
    state = const SolveState();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future.value());
    super.dispose();
  }
}

final AutoDisposeStateNotifierProvider<AiSolveNotifier, SolveState>
aiSolveProvider =
    StateNotifierProvider.autoDispose<AiSolveNotifier, SolveState>(
      (ref) => AiSolveNotifier(ref.watch(aiSolveDatasourceProvider)),
    );
