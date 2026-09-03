import 'package:flutter_test/flutter_test.dart';
import 'package:tutora/features/tutor/data/datasources/chat_datasource.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';

void main() {
  test('API messages are normalized from oldest to newest', () {
    final result = sortChatMessagesChronologically([
      _message(3, '2026-08-18T09:03:00Z'),
      _message(2, '2026-08-18T09:02:00Z'),
      _message(1, '2026-08-18T09:01:00Z'),
    ]);

    expect(result.map((message) => message.messageId), [1, 2, 3]);
  });

  test('message id keeps a stable order when timestamps match', () {
    final result = sortChatMessagesChronologically([
      _message(2, '2026-08-18T09:00:00Z'),
      _message(1, '2026-08-18T09:00:00Z'),
    ]);

    expect(result.map((message) => message.messageId), [1, 2]);
  });
}

ChatMessageDto _message(int id, String createdAt) => ChatMessageDto(
  messageId: id,
  channelId: 10,
  senderId: 'parent',
  senderName: 'Phụ huynh',
  content: 'Tin nhắn $id',
  messageType: 'text',
  createdAt: createdAt,
);
