import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/features/student/data/models/ai_chat_models.dart';

export 'package:tutora/features/student/data/models/ai_chat_models.dart';

/// Một mảnh delta stream từ /solve.
class SolveDelta {
  const SolveDelta({required this.delta, required this.done});
  final String delta;
  final bool done;
}

/// Datasource giải toán AI — đi qua Tutora-Backend (/api/ai-chat)
class AiSolveDatasource {
  AiSolveDatasource(this._dio, this._ref);

  final Dio _dio;
  final Ref _ref;

  // (Dio, có auth interceptor)
  Future<List<AiChatSession>> getSessions() async {
    final resp = await _dio.get<dynamic>(
      '/ai-chat/sessions',
      queryParameters: {'chatType': 'homework'},
    );
    final content = _content(resp.data) as List<dynamic>? ?? const [];
    return content
        .map((e) => AiChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AiChatSession> createSession({String? title}) async {
    final resp = await _dio.post<dynamic>(
      '/ai-chat/sessions',
      data: {'sessionType': 'homework', 'title': ?title},
    );
    final content = _content(resp.data);
    if (content is! Map<String, dynamic>) {
      throw Exception('Không tạo được phiên trò chuyện');
    }
    return AiChatSession.fromJson(content);
  }

  Future<List<AiChatMessage>> getMessages(String sessionId) async {
    final resp = await _dio.get<dynamic>(
      '/ai-chat/sessions/$sessionId/messages',
      queryParameters: {'page': 1, 'pageSize': 100},
    );
    // BE trả PagedList<T> : List<T> -> serialize thành array trực tiếp
    final content = _content(resp.data);
    final items = content is List
        ? content
        : (content is Map<String, dynamic>
              ? (content['items'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    return items
        .map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteSession(String sessionId) async {
    await _dio.delete<dynamic>('/ai-chat/sessions/$sessionId');
  }

  /// Xoá TẤT CẢ phiên chat giải toán của user.
  Future<void> deleteAllSessions() async {
    await _dio.delete<dynamic>(
      '/ai-chat/sessions',
      queryParameters: {'chatType': 'homework'},
    );
  }

  // Solve stream (SSE — http.Request, tự gắn token)

  /// Gửi đề bài (ảnh base64 hoặc text) tới BE và nhận stream lời giải.
  Future<Stream<SolveDelta>> solveStream({
    required String sessionId,
    String? text,
    String? imageBase64,
    String? grade,
    String? chapter,
  }) async {
    final token = await _ref.read(secureStorageProvider).getAccessToken();
    final uri = Uri.parse('$appBaseUrl/api/ai-chat/sessions/$sessionId/solve');

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..body = json.encode({
        'text': ?text,
        'imageBase64': ?imageBase64,
        'grade': ?grade,
        'chapter': ?chapter,
      });

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception('AI API error: ${response.statusCode}');
    }

    final controller = StreamController<SolveDelta>();

    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (!line.startsWith('data:')) return;
            final payload = line.substring(5).trim();
            if (payload.isEmpty) return;
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              final delta = data['delta'] as String? ?? '';
              final done = data['done'] as bool? ?? false;
              controller.add(SolveDelta(delta: delta, done: done));
              if (done && !controller.isClosed) unawaited(controller.close());
            } catch (_) {}
          },
          onDone: () {
            if (!controller.isClosed) unawaited(controller.close());
            client.close();
          },
          onError: (Object e) {
            if (!controller.isClosed) controller.addError(e);
            client.close();
          },
          cancelOnError: true,
        );

    return controller.stream;
  }

  // BE bọc mọi response trong APIResponse { content, message, ... }.
  Object? _content(Object? data) {
    if (data is Map<String, dynamic>) return data['content'];
    return null;
  }
}

final aiSolveDatasourceProvider = Provider<AiSolveDatasource>(
  (ref) => AiSolveDatasource(ref.watch(apiClientProvider), ref),
);
