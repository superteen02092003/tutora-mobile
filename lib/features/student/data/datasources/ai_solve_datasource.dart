import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const _kBaseUrl = String.fromEnvironment(
  'AI_BASE_URL',
  defaultValue: 'https://tutora-iugm.onrender.com',
);
const _kApiKey = String.fromEnvironment('AI_API_KEY');

class AiSolveDatasource {
  Future<Stream<String>> solveStream({
    required String chatId,
    required String messageId,
    required String imageBase64,
    String? grade,
    String? chapter,
  }) async {
    final uri = Uri.parse('$_kBaseUrl/api/v1/solve');

    final body = json.encode({
      'image_base64': imageBase64,
      'grade': grade,
      'chapter': chapter,
      'chat_id': chatId,
      'message_id': messageId,
    });

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'X-API-Key': _kApiKey,
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      })
      ..body = body;

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception('AI API error: ${response.statusCode}');
    }

    final controller = StreamController<String>();

    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.startsWith('data: ')) {
              final payload = line.substring(6).trim();
              if (payload.isEmpty || payload == '[DONE]') return;
              try {
                final data = jsonDecode(payload) as Map<String, dynamic>;
                final delta = data['delta'] as String? ?? '';
                final done = data['done'] as bool? ?? false;
                if (delta.isNotEmpty) controller.add(delta);
                if (done && !controller.isClosed) unawaited(controller.close());
              } catch (_) {}
            }
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
}

final aiSolveDatasourceProvider = Provider<AiSolveDatasource>(
  (_) => AiSolveDatasource(),
);
